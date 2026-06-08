;;; ob-gptel.el --- org-babel support for gptel (LLM prompts in Org) -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Minimal org-babel integration for the gptel package.
;;
;; Put this file in your load-path and add:
;;   (require 'ob-gptel)
;;   (add-to-list 'org-babel-load-languages '(gptel . t))
;;   (org-babel-do-load-languages 'org-babel-load-languages org-babel-load-languages)
;;
;; Example block:
;; #+BEGIN_SRC gptel :model gpt-4o :system "You are a concise assistant." :temperature 0.3 :file answer.txt
;; Summarize the benefits of literate programming in 5 bullet points.
;; #+END_SRC
;;
;; Supported header arguments (all optional):
;; :model        (string)  Model name (overrides =org-babel-gptel-default-model=)
;; :system       (string)  System prompt
;; :temperature  (number)  Sampling temperature
;; :max-tokens   (number)  Max tokens (if supported by backend)
;; :timeout      (number)  Seconds to wait (default =org-babel-gptel-timeout=)
;; :file         (string)  If given, write response to file and return its path
;; :append       (yes/no)  If :file is given and :append yes, append instead of overwrite
;; :vars-header  (yes/no)  Prepend variable values to the prompt (default yes)
;; :json         (yes/no)  Hint that JSON is desired; adds an instruction
;; :stream       (yes/no)  (Experimental) attempt streaming (falls back to normal if unsupported)
;; :retry        (integer) Retry count on transient errors (default 1)
;;
;; Variables passed via :var become part of a “Variables” preamble (if :vars-header yes).
;;
;; NOTE: This implementation attempts synchronous behavior over an async API.
;; It may need refinement depending on changes in =gptel= upstream.

(require 'cl-lib)
(require 'org)
(require 'ob)
(require 'org-macs)

(declare-function gptel-request "gptel" (prompt &rest plist))

(defgroup org-babel-gptel nil
  "Org Babel support for gptel (LLM interaction)."
  :group 'org-babel)

(defcustom org-babel-gptel-default-model "gpt-4o"
  "Default model name used when :model header not provided."
  :type 'string
  :group 'org-babel-gptel)

(defcustom org-babel-gptel-timeout 120
  "Default timeout in seconds for waiting on LLM responses."
  :type 'integer
  :group 'org-babel-gptel)

(defcustom org-babel-gptel-default-temperature 0.7
  "Default temperature if none specified."
  :type 'number
  :group 'org-babel-gptel)

(defcustom org-babel-gptel-insert-json-hint "Respond ONLY with valid JSON for the answer above."
  "Instruction appended when :json yes is provided."
  :type 'string
  :group 'org-babel-gptel)

(defcustom org-babel-gptel-strip-leading-whitespace t
  "If non-nil, trim leading/trailing whitespace from responses."
  :type 'boolean
  :group 'org-babel-gptel)

(defcustom org-babel-gptel-debug nil
  "If non-nil, log debug messages to /Messages/."
  :type 'boolean
  :group 'org-babel-gptel)

(defvar org-babel-header-args:gptel
  '((model        . :any)
    (system       . :any)
    (temperature  . :any)
    (max-tokens   . :any)
    (timeout      . :any)
    (file         . :any)
    (append       . ((yes no)))
    (vars-header  . ((yes no)))
    (json         . ((yes no)))
    (stream       . ((yes no)))
    (retry        . :any))
  "gptel-specific header arguments.")

(add-to-list 'org-src-lang-modes '("gptel" . text))

(defun org-babel-gptel--debug (fmt &rest args)
  (when org-babel-gptel-debug
    (apply #'message (concat "[ob-gptel] " fmt) args)))

(defun org-babel-gptel--plist-assoc (key alist)
  (cdr (assq key alist)))

(defun org-babel-gptel--yes-p (val)
  (and val (not (eq val 'no)) (not (string= (format "%s" val) "no"))))

(defun org-babel-gptel--coerce-number (val default)
  (cond
   ((null val) default)
   ((numberp val) val)
   ((string-match-p "\\=[0-9.]+\\'" (format "%s" val))
    (string-to-number (format "%s" val)))
   (t default)))

(defun org-babel-gptel--format-var (name value)
  (format "%s = %s"
          name
          (cond
           ((stringp value) (replace-regexp-in-string "\n\\'" "" value))
           ((numberp value) (number-to-string value))
           ((listp value) (format "%S" value))
           ((vectorp value) (format "%S" value))
           (t (format "%S" value)))))

(defun org-babel-gptel--build-prompt (body vars params)
  (let* ((vars-header (org-babel-gptel--yes-p (org-babel-gptel--plist-assoc :vars-header params)))
         (json (org-babel-gptel--yes-p (org-babel-gptel--plist-assoc :json params)))
         (vars-section
          (when (and vars-header vars)
            (concat "Variables:\n"
                    (mapconcat (lambda (v)
                                 (org-babel-gptel--format-var (car v) (cdr v)))
                               vars
                               "\n")
                    "\n\n")))
         (json-hint (when json (concat "\n\n" org-babel-gptel-insert-json-hint "\n")))
         (final (concat (or vars-section "")
                        body
                        (or json-hint ""))))
    final))

(defun org-babel-gptel--safe-require ()
  (unless (require 'gptel nil 'noerror)
    (error "gptel package not found; please install gptel")))

(defun org-babel-gptel--collect-vars (params)
  "Return alist of variable bindings from PARAMS suitable for embedding."
  (org-babel--get-vars params))

(defun org-babel-gptel--retry (times thunk)
  (let (last-err)
    (cl-loop for attempt from 1 to times
             do (condition-case err
                    (cl-return (funcall thunk))
                  (error
                   (setq last-err err)
                   (org-babel-gptel--debug "Attempt %d failed: %S" attempt err)
                   (sleep-for 0.5))))
    (when last-err
      (signal (car last-err) (cdr last-err)))))

(defun org-babel-gptel--synchronous-request (prompt plist timeout stream)
  "Perform a synchronous gptel-request with PROMPT.
PLIST are keyword args forwarded to gptel-request (excluding :callback).
TIMEOUT in seconds. If STREAM non-nil, accumulate partials.
Return response string."
  (let ((done nil)
        (acc "")
        (start-time (float-time)))
    (apply #'gptel-request
           prompt
           :callback
           (lambda (chunk _meta)
             ;; chunk may be nil or final; we treat every non-nil as content
             (when chunk
               (setq acc (concat acc chunk)))
             ;; Heuristic: mark done when not streaming, or when chunk nil.
             (unless stream
               (setq done t))
             (when (and stream (null chunk))
               (setq done t)))
           (cl-loop for (k v) on plist by #'cddr
                    append (list k v)))
    (while (and (not done)
                (< (- (float-time) start-time) timeout))
      (accept-process-output nil 0.1))
    (unless done
      (org-babel-gptel--debug "Timeout reached after %s seconds" timeout))
    (when org-babel-gptel-strip-leading-whitespace
      (setq acc (string-trim acc)))
    acc))

;;;###autoload
(defun org-babel-execute:gptel (body params)
  "Execute a block of gptel (LLM) code with org-babel.
BODY is the prompt content; PARAMS holds header arguments."
  (org-babel-gptel--safe-require)
  (let* ((vars (org-babel-gptel--collect-vars params))
         (model (or (org-babel-gptel--plist-assoc :model params)
                    org-babel-gptel-default-model))
         (system (org-babel-gptel--plist-assoc :system params))
         (temperature (org-babel-gptel--coerce-number
                       (org-babel-gptel--plist-assoc :temperature params)
                       org-babel-gptel-default-temperature))
         (max-tokens (org-babel-gptel--plist-assoc :max-tokens params))
         (timeout (org-babel-gptel--coerce-number
                   (org-babel-gptel--plist-assoc :timeout params)
                   org-babel-gptel-timeout))
         (stream (org-babel-gptel--yes-p (org-babel-gptel--plist-assoc :stream params)))
         (retry (max 1 (org-babel-gptel--coerce-number
                        (org-babel-gptel--plist-assoc :retry params) 1)))
         (file (org-babel-gptel--plist-assoc :file params))
         (appendp (org-babel-gptel--yes-p (org-babel-gptel--plist-assoc :append params)))
         (prompt (org-babel-gptel--build-prompt body vars params))
         (plist '()))
    (when model (setq plist (plist-put plist :model model)))
    (when system (setq plist (plist-put plist :system system)))
    (when (numberp temperature) (setq plist (plist-put plist :temperature temperature)))
    (when (and max-tokens (not (string-empty-p (format "%s" max-tokens))))
      (setq plist (plist-put plist :max-tokens (if (numberp max-tokens)
                                                   max-tokens
                                                 (string-to-number (format "%s" max-tokens))))))
    (when stream (setq plist (plist-put plist :stream t)))
    (org-babel-gptel--debug "Requesting model=%s temp=%s timeout=%s stream=%s"
                            model temperature timeout stream)
    (let* ((response
            (org-babel-gptel--retry
             retry
             (lambda ()
               (org-babel-gptel--synchronous-request prompt plist timeout stream))))
           (result (or response "")))
      (when file
        (make-directory (file-name-directory (expand-file-name file)) t)
        (with-temp-buffer
          (when (and appendp (file-exists-p file))
            (insert-file-contents file))
          (goto-char (point-max))
            ;; Ensure newline separation if appending
          (when (and appendp (> (buffer-size) 0) (not (bolp)))
            (insert "\n"))
          (insert result)
          (write-region (point-min) (point-max) file))
        (setq result file))
      result)))

;;;###autoload
(eval-after-load 'org
  '(add-to-list 'org-babel-load-languages '(gptel . t)))

(provide 'ob-gptel)
;;; ob-gptel.el ends here
