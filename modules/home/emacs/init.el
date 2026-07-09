;; init.el --- user init file  -*- lexical-binding: t -*-

;;; Commentary:

;;; Code:

(add-to-list 'load-path (expand-file-name "elisp" user-emacs-directory))

(defvar xdg-bin (or (getenv "XDG_BIN_HOME") "~/.local/bin/")
  "The XDG bin base directory.")
(defvar xdg-cache (or (getenv "XDG_CACHE_HOME") "~/.cache/")
  "The XDG cache base directory.")
(defvar emacs-cache-dir (expand-file-name "emacs/" xdg-cache)
  "The emacs cache directory")
(defvar xdg-config (or (getenv "XDG_CONFIG_HOME") "~/.config/")
  "The XDG config base directory.")
(defvar xdg-data (or (getenv "XDG_DATA_HOME") "~/.local/share/")
  "The XDG data base directory.")
(defvar xdg-lib (or (getenv "XDG_LIB_HOME") "~/.local/lib/")
  "The XDG lib base directory.")

(defvar emacs-cache-dir (expand-file-name "emacs/" xdg-cache)
  "Path to the Emacs cache directory.")

;; Create the directory if it does not exist
(unless (file-exists-p emacs-cache-dir)
  (make-directory emacs-cache-dir t))

(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("elpa"  . "https://elpa.gnu.org/packages/") t)

(package-initialize)

;; Instaleaza use-package dacă lipsește
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)

(setq use-package-always-ensure t
      package-install-upgrade-built-in t)

;; Forțează încărcarea versiunii noi de Org înainte ca restul fișierului să o declanșeze pe cea veche
(use-package org
  :ensure t
  :demand t)

(defmacro quiet! (&rest forms)
  "Run FORMS without making any noise."
  `(if init-file-debug
       (progn ,@forms)
     (let ((message-log-max nil))
       (with-temp-message (or (current-message) "") ,@forms))))

(defun quiet-function-advice (orig-fn &rest args)
  "Advice used to make a function quiet.
Call ORIG-FN with ARGS and suppress the output.  Usage:

  (advice-add \\='orig-fn :around #\\='quiet-function-advice)"
  (quiet! (apply orig-fn args)))

(defmacro define-repl (fn-name buffer-name command &rest args)
  "Define a REPL function named FN-NAME running COMMAND inside BUFFER-NAME."
  (let ((repl-buffer (concat "*" buffer-name "*")))
    `(defun ,fn-name ()
       ,(format "Run an inferior instance of %s inside Emacs." command)
       (interactive)
       (let ((buffer (get-buffer-create ,repl-buffer)))
         (unless (comint-check-proc ,repl-buffer)
           (apply 'make-comint-in-buffer ,buffer-name buffer ,command nil ,args))
         (pop-to-buffer buffer)))))

(defun local/get-secret (key)
  (with-temp-buffer
    (insert-file-contents (expand-file-name key "~/.config/sops-nix/secrets/"))
    (string-trim (buffer-string))))

(use-package exec-path-from-shell
  :ensure t
  :demand t
  :config
  (customize-set-variable 'exec-path-from-shell-variables
                        '("PATH" "MANPATH" "DPOM_CONFIG"
                          "LANG" "LC_ALL" "SSH_AUTH_SOCK"
                          "XDG_BIN_HOME"  "XDG_CACHE_HOME"
                          "XDG_CONFIG_HOME" "XDG_DATA_HOME"
                          "XDG_LIB_HOME"))
  (customize-set-variable 'exec-path-from-shell-check-startup-files nil)
  (when (memq window-system '(mac ns x pgtk))
    (exec-path-from-shell-initialize)
    (exec-path-from-shell-copy-envs '("SSH_AUTH_SOCK" "GPG_AGENT_INFO"))))

(setq custom-file (expand-file-name "custom.el" temporary-file-directory))

(setq auto-mode-case-fold nil)

(setq bidi-inhibit-bpa t)
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)

(setq fast-but-imprecise-scrolling t)
(setq jit-lock-defer-time 0)

(use-package gcmh
  :ensure t
  :demand t
  :init
  (setq gcmh-idle-delay 5)
  (setq gcmh-high-cons-threshold (* 16 1024 1024)) ; 16MB
  (setq gcmh-verbose init-file-debug)
  :config
  (gcmh-mode))

(defgroup local nil
  "Local defined variables and functions."
  :tag "Local"
  :group 'config)

(defcustom local/pers-dir "~/pers/"
  "Personal directory."
  :type '(directory)
  :group 'local)

(defcustom local/work-dir "~/work/"
  "Work related directory."
  :type '(directory)
  :group 'local)

(defcustom local/admin-dir "~/.dotfiles/"
  "Directory of the system configurations."
  :type '(directory)
  :group 'local)

(defcustom local/plan-dir (file-name-as-directory (expand-file-name "plan" local/pers-dir))
  "Plan directory."
  :type '(directory)
  :group 'local)

(defcustom local/notes-dir (file-name-as-directory (expand-file-name "notes" local/pers-dir))
  "Org-roam notes directory."
  :type '(directory)
  :group 'local)

(defcustom local/backlog-file (expand-file-name "Backlog.org" local/plan-dir)
  "Backlog tasks and notes file."
  :type '(file)
  :group 'local)

(defcustom local/config-file (expand-file-name "Emacs.txt" local/admin-dir)
  "Emacs config file."
  :type '(file)
  :group 'local)

(defcustom local/private-dir (file-name-as-directory (local/get-secret "private_dir"))
  "Private info directory."
  :type '(directory)
  :group 'local)

(defcustom local/accounts-file (expand-file-name "Cont.gpg" local/private-dir)
  "Personal accounts file."
  :type '(file)
  :group 'local)

(defcustom local/contacts-file (expand-file-name "contacts.org" local/private-dir)
  "Contacts file."
  :type '(file)
  :group 'local)

(defcustom local/resources-dir (file-name-as-directory (expand-file-name "resources" local/notes-dir))
  "Notes resources directory."
  :type '(directory)
  :group 'local)

(defcustom local/bibliography-file (expand-file-name "dpom.bib" local/resources-dir)
  "Bibliography file."
  :type '(file)
  :group 'local)

(defcustom local/bibliography-library-path (list local/resources-dir)
  "Bibliography library directory."
  :type '(list directory)
  :group 'local)

(let ((personal-settings (expand-file-name "local.el" user-emacs-directory)))
  (when (file-exists-p personal-settings)
        (load-file personal-settings)))

(setq calendar-date-style 'iso)
(setq mark-diary-entries-in-calendar t)
(setq org-agenda-include-diary t)
(setq local/diary-file "~/.config/emacs-default/diary")
(defun getcal (url)
  "Download ics file and add to diary"
  (let ((tmpfile (url-file-local-copy url)))
    (icalendar-import-file tmpfile local/diary-file t)
    (kill-buffer (car (last (split-string tmpfile "/"))))
    )
  )

;; Revert Dired and other buffers
(customize-set-variable 'global-auto-revert-non-file-buffers t)

;; Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)

;; Use spaces instead of tabs
(setq-default indent-tabs-mode nil)

;; Use "y" and "n" to confirm/negate prompt instead of "yes" and "no"
;; Using `advice' here to make it easy to reverse in custom
;; configurations with `(advice-remove 'yes-or-no-p #'y-or-n-p)'
;;
;; N.B. Emacs 28 has a variable for using short answers, which should
;; be preferred if using that version or higher.
(if (boundp 'use-short-answers)
    (setq use-short-answers t)
  (advice-add 'yes-or-no-p :override #'y-or-n-p))



;; Do not saves duplicates in kill-ring
(customize-set-variable 'kill-do-not-save-duplicates t)

;; Make scrolling less stuttered
(setq-default
 auto-window-vscroll nil
 fast-but-imprecise-scrolling t
 scroll-conservatively 101
 scroll-margin 0
 scroll-preserve-screen-position t)

;; Better support for files with long lines
(setq-default
  bidi-paragraph-direction 'left-to-right
  bidi-inhibit-bpa t)
(global-so-long-mode 1)

;; Make shebang (#!) file executable when saved
(add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p)

  (setq-default large-file-warning-threshold nil)

  (setq-default vc-follow-symlinks t)

  (setq ad-redefinition-action 'accept)

(setq
 ediff-make-buffers-readonly-at-startup nil
 ediff-show-clashes-only t
 ediff-split-window-function 'split-window-horizontally
 ediff-window-setup-function 'ediff-setup-windows-plain)

  (column-number-mode)

(setq browse-url-browser-function 'browse-url-default-browser)

(setq-default
 buffer-file-coding-system 'utf-8-unix
 default-file-name-coding-system 'utf-8-unix
 default-keyboard-coding-system 'utf-8-unix
 default-process-coding-system '(utf-8-unix . utf-8-unix)
 default-sendmail-coding-system 'utf-8-unix
 default-terminal-coding-system 'utf-8-unix)

(setq max-lisp-eval-depth 10000)

(require 'cl-lib)
(require 'cl-extra)

(defgroup local-ui '()
  "User interface related configuration."
  :tag "Local UI"
  :group 'local)

(setq-default inhibit-startup-message t)
(scroll-bar-mode -1)  ; Disable visible scrollbar
(tool-bar-mode -1)    ; Disable the toolbar
(tooltip-mode -1)     ; Disable tooltips
(set-fringe-mode 10)  ; Give some breathing room
(menu-bar-mode 1)    ; Enable the menu bar
(setq visible-bell t) ; Set up the visible bell

(setq-default
  mouse-wheel-scroll-amount '(1 ((shift) . 1)  ((control) . nil)) ;; one line at a time
  mouse-wheel-progressive-speed nil ;; don't accelerate scrolling
  mouse-wheel-follow-mouse 't ;; scroll window under mouse
 scroll-margin 2 ; scroll with 2 line margin for continuity
;; keyboard scroll one line at a time instead of jumping
 scroll-step            1
 scroll-conservatively  10000)

    ;; (set-frame-parameter (selected-frame) 'alpha '(90 . 90))
    ;; (add-to-list 'default-frame-alist '(alpha . (90 . 90)))
    (set-frame-parameter (selected-frame) 'fullscreen 'maximized)
    (add-to-list 'default-frame-alist '(fullscreen . maximized))

(use-package fontaine
  :ensure t
  :demand t
  :config
  (setq fontaine-latest-state-file
        (locate-user-emacs-file "fontaine-latest-state.eld"))
  (setq fontaine-presets
        '((tiny
           :default-family "Aporetic Serif Mono"
           :default-height 130)
          (small
           :default-family "Aporetic Serif Mono"
           :default-height 150)
          (regular
           :default-height 200)
          (medium
           :default-height 220)
          (large
           :default-weight semilight
           :default-height 240
           :bold-weight extrabold)
          (presentation
           :default-weight semilight
           :default-height 280
           :bold-weight extrabold)
          (jumbo
           :default-weight semilight
           :default-height 300
           :bold-weight extrabold)
          (t
           :default-family "Aporetic Serif Mono"
           :default-weight regular
           :default-height 180
           :fixed-pitch-family "Aporetic Serif Mono" ; Forțează-l și aici
           :fixed-pitch-weight nil
           :fixed-pitch-height 1.0
           :variable-pitch-family "Aporetic Serif"
           :variable-pitch-weight nil
           :variable-pitch-height 1.1 ; De obicei fontul serif arată mai mic, 1.1 ajută
           :bold-family nil
           :bold-weight bold
           :italic-family nil ; Dacă fontul are variantă italic, lasă nil să o folosească pe cea nativă
           :italic-slant italic
           :line-spacing nil)))

  ;; Recover last preset or fall back to desired style from
  ;; `fontaine-presets'.
  (fontaine-set-preset (or (fontaine-restore-latest-preset) 'small))

  ;; The other side of `fontaine-restore-latest-preset'.
  (add-hook 'kill-emacs-hook #'fontaine-store-latest-preset)
  )

(defun local/iw-set-font-size ()
  "Adjust the font size in all windows."
  (interactive)
  (let (font-size)
    (setq font-size (read-number "Text size: "))
    (set-frame-font (font-spec :size font-size) t `(,(selected-frame)))))

(use-package ef-themes
  :ensure t
  :demand t
  :config
  (load-theme 'ef-elea-dark t))

(use-package nerd-icons
    :ensure t
    :demand t)

(use-package nerd-icons-completion
  :ensure t
  :demand t
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode #'nerd-icons-completion-marginalia-setup))

(use-package nerd-icons-corfu
  :ensure t
  :demand t
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package nerd-icons-dired
  :ensure t
  :demand t
  :config
  (add-hook 'dired-mode-hook 'nerd-icons-dired-mode))

(autoload 'iimage-mode "iimage" "Support Inline image minor mode." t)
(autoload 'turn-on-iimage-mode "iimage" "Turn on Inline image minor mode." t)
;;
;; ** Display images in *Info* buffer.
;;
;; (add-hook 'info-mode-hook 'turn-on-iimage-mode)
;;

(use-package minions
  :ensure t
  :demand t
  :config
  (minions-mode 1))

;; (custom-set-faces '(mode-line ((t (:height 0.85))))
;;                   '(mode-line-inactive ((t (:height 0.85)))))

(global-subword-mode 1)
(column-number-mode 1)      ; Show the column number
(global-hl-line-mode t)
(window-divider-mode 1)



;; (setq select-active-regions nil)

(use-package cliphist
  :config
  (setq cliphist-cc-kill-ring t))

(cond
 ((string= (getenv "XDG_SESSION_TYPE") "wayland")
  (progn
    (setq wl-copy-process nil)
    (customize-set-variable 'x-select-enable-clipboard-manager nil)
    (defun wl-copy (text)
      (setq wl-copy-process (make-process :name "wl-copy"
                                          :buffer nil
                                          :command '("wl-copy" "-f" "-n")
                                          :connection-type 'pipe
                                          :noquery t))
      (process-send-string wl-copy-process text)
      (process-send-eof wl-copy-process))
    (defun wl-paste ()
      (if (and wl-copy-process (process-live-p wl-copy-process))
          nil ; should return nil if we're the current paste owner
        (shell-command-to-string "wl-paste -n | tr -d \r")))
    (setq interprogram-cut-function 'wl-copy)
    (setq interprogram-paste-function 'wl-paste)))

 ((eq system-type 'darwin)
  (progn
    ;; Clipboard pentru macOS GUI
    ;; Forțează utilizarea clipboard-ului sistemului prin funcțiile interne
    (setq interprogram-cut-function 'gui-select-text)
    (setq interprogram-paste-function 'gui-selection-value)
    (setq select-enable-clipboard t)   ; Permite copierea către clipboard-ul sistemului
    (setq select-enable-primary t)     ; Permite utilizarea selecției primare (pentru mouse)
    (setq save-interprogram-paste-before-kill t) ; Salvează ce era în clipboard înainte de a tăia în Emacs
    (setq mouse-drag-copy-region t)    ; Copiază automat regiunea selectată cu mouse-ul
    ))

 (t
   (progn
      (setq x-select-enable-clipboard t)
      (customize-set-variable 'x-select-enable-clipboard-manager t)
      (defun xsel-cut-function (text &optional push)
        (with-temp-buffer
          (insert text)
          (call-process-region (point-min) (point-max) "xsel" nil 0 nil "--clipboard" "--input")))
      (defun xsel-paste-function()

        (let ((xsel-output (shell-command-to-string "xsel --clipboard --output")))
          (unless (string= (car kill-ring) xsel-output)
            xsel-output )))
      (setq interprogram-cut-function 'xsel-cut-function)
      (setq interprogram-paste-function 'xsel-paste-function))))

(use-package ansi-color
  :ensure nil
  :config
  (add-hook 'shell-mode-hook  #'ansi-color-for-comint-mode-on)
  (defun endless/colorize-compilation ()
    "Colorize from `compilation-filter-start' to `point'."
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region compilation-filter-start (point))))
  (add-to-list 'comint-output-filter-functions 'ansi-color-process-output)
  (add-hook 'compilation-filter-hook #'endless/colorize-compilation)
  (add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)
  (add-hook 'eshell-preoutput-filter-functions 'ansi-color-filter-apply))

;; add visual pulse when changing focus, like beacon but built-in
;; from from https://karthinks.com/software/batteries-included-with-emacs/
(defun pulse-line (&rest _)
  "Pulse the current line."
  (pulse-momentary-highlight-one-line (point)))

(dolist (command '(scroll-up-command scroll-down-command
                                     recenter-top-bottom other-window))
  (advice-add command :after #'pulse-line))

(customize-set-variable 'split-width-threshold 0)
(customize-set-variable 'split-height-threshold nil)

(setq tab-always-indent 'complete)

(setq completion-cycle-threshold 3)

(use-package completion-preview
  :hook
  ((comint-mode-hook
    eshell-mode-hook
    prog-mode-hook
    text-mode-hook) . completion-preview-mode)
  (minibuffer-setup-hook . completion-preview-enable-in-minibuffer)
  :bind
  (:map completion-preview-active-mode-map
        ("TAB" . completion-preview-complete)
        ("C-e" . completion-preview-insert)
        ("M-n" . completion-preview-next-candidate)
        ("M-p" . completion-preview-prev-candidate)
        ("M-i" . completion-preview-insert))
  :init
  (setq completion-preview-adapt-background-color nil)
  (setq completion-preview-minimum-symbol-length 2)
  :config
  (defun completion-preview-enable-in-minibuffer ()
    "Enable Corfu completion in the minibuffer, e.g., `eval-expression'."
    (when (where-is-internal #'completion-at-point (list (current-local-map)))
      (completion-preview-mode 1)))

  (cl-pushnew 'org-self-insert-command completion-preview-commands :test #'equal))

(use-package corfu
  :ensure t
  :demand t
  :commands
  (corfu-mode
   corfu-indexed-mode
   global-corfu-mode)
  :bind
  (:map corfu-map
        ([return] . nil)
        ("RET" . nil)
        ("TAB" . corfu-expand)
        ([tab] . corfu-expand)
        ("S-TAB" . corfu-previous)
        ([backtab] . corfu-previous)
        ("C-e" . corfu-complete))
  :custom
  (corfu-cycle t)
  (corfu-preselect 'first)
  :config
  (global-corfu-mode 1)
  (defun local/corfu-enable-in-minibuffer ()
    (when (where-is-internal #'completion-at-point minibuffer-local-map)
      (setq-local corfu-auto nil) ; opțional: fără auto-complete în minibuffer
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'local/corfu-enable-in-minibuffer))

(use-package dabbrev
  :init
  (setq dabbrev-case-replace nil)
  (setq dabbrev-ignored-buffer-regexps '("\\.\\(?:pdf\\|jpe?g\\|png\\)\\'")))

(use-package tempel
  :ensure t
  :demand t
  :commands
  (tempel-expand)
  :bind
  (("M-+" . tempel-complete)
   ("M-*" . tempel-insert))
  :init

  ;; Setup completion at point
  (defun tempel-setup-capf ()
    ;; Add the Tempel Capf to `completion-at-point-functions'.
    ;; `tempel-expand' only triggers on exact matches. Alternatively use
    ;; `tempel-complete' if you want to see all matches, but then you
    ;; should also configure `tempel-trigger-prefix', such that Tempel
    ;; does not trigger too often when you don't expect it. NOTE: We add
    ;; `tempel-expand' *before* the main programming mode Capf, such
    ;; that it will be tried first.
    (setq-local completion-at-point-functions
                (cons #'tempel-expand
                      completion-at-point-functions)))

  (add-hook 'conf-mode-hook 'tempel-setup-capf)
  (add-hook 'prog-mode-hook 'tempel-setup-capf)
  (add-hook 'text-mode-hook 'tempel-setup-capf)

  :config
  (set-face-attribute 'tempel-field nil :background 'unspecified :inherit 'default)
  (setq tempel-path (concat user-emacs-directory "templates/*.eld")))

(use-package cape
  :ensure t
  :demand t
  :commands
  (cape-capf-silent)
  :functions
  (cape-capf-buster
   cape-capf-super)
  :bind
  (([remap dabbrev-expand] . cape-dabbrev)
   (:prefix-map completion-prefix-map :prefix "M-P"
                ("d" . cape-dabbrev)
                ("h" . cape-history)
                ("f" . cape-file)
                ("k" . cape-keyword)
                ("M-P" . completion-at-point)
                ("p" . cape-pcomplete)
                ("s" . cape-elisp-symbol)
                ("a" . cape-abbrev)
                ("l" . cape-line)
                ("w" . cape-dict)
                ("\\" . cape-tex)
                ("&" . cape-sgml)
                ("r" . cape-rfc1345))
   (:map corfu-map
         ("C-x C-f" . cape-file)))
  :init
  ;; Use cape-dict for dictionary completion.
  (setq cape-dict-file (getenv "WORDLIST"))
  (setq text-mode-ispell-word-completion nil)
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  :config
  (defun init-cape-comint-capf ()
    (setq-local completion-at-point-functions
                (list (apply #'cape-capf-super
                             #'cape-history
                             (cl-remove-if-not #'functionp completion-at-point-functions)))))

  (defun init-cape-prog-capf ()
    "Configurează capf-urile pentru prog-mode folosind cape."
    (setq-local completion-at-point-functions
                (list (cape-capf-super
                       #'tempel-expand
                       #'cape-dabbrev
                       #'cape-keyword
                       #'cape-file))))

  (defun init-cape-text-capf ()
    (add-hook 'completion-at-point-functions #'cape-file nil t)
    (add-hook 'completion-at-point-functions #'cape-dict 10 t))

  (setf (symbol-function 'cape-pcomplete) (cape-capf-interactive #'pcomplete-completions-at-point))
  (advice-add 'pcomplete-completions-at-point :around #'cape-capf-silent)

  ;; Org
  (with-eval-after-load 'org
    (require 'cape-keyword)
    (add-hook 'org-mode-hook #'local/cape-capf-setup-org)
    (defun local/cape-capf-setup-org ()
      (require 'org-roam)
      (add-to-list 'completion-at-point-functions #'org-roam-complete-link-at-point)
      (add-to-list 'completion-at-point-functions #'local/cape-org-src-keywords))
    (defun local/cape-org-src-keywords ()
      "Complete keywords in Org babel source blocks.
Looks up the source block's language in `cape-keyword-list' to
provide language-specific keyword completion."
      (when-let* ((info (org-babel-get-src-block-info 'light))
                  (lang (car info))
                  (mode (org-src-get-lang-mode lang))
                  (kw (or (alist-get mode cape-keyword-list)
                          (when-let* ((remap (rassq mode major-mode-remap-alist)))
                            (alist-get (car remap) cape-keyword-list)))))
        (while (and (consp kw) (symbolp (car kw)))
          (setq kw (alist-get (car kw) cape-keyword-list)))
        (when (consp kw)
          (let ((bounds (bounds-of-thing-at-point 'symbol)))
            (when bounds
              (list (car bounds) (cdr bounds) kw
                    :annotation-function (lambda (_) " Keyword")
                    :exclusive 'no)))))))
  (add-hook 'comint-mode-hook #'init-cape-comint-capf)
  (add-hook 'eshell-mode-hook #'init-cape-comint-capf)
  (add-hook 'prog-mode-hook  #'init-cape-prog-capf)
  (add-hook 'text-mode-hook  #'init-cape-text-capf)
  )

(use-package orderless
  :ensure t
  :init
  (setq completion-styles '(substring orderless))
  (setq completion-category-defaults nil)
  (setq completion-category-overrides '((file (styles basic partial-completion)))))

(use-package embark
  :ensure t
  :commands
  (embark-prefix-help-command)
  :bind
  (("C-h B" . embark-bindings)
   ("M-O" . embark-dwim)
   ("M-o" . embark-act)
   (:map vertico-map ("C-SPC" . embark-select)))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  (setq embark-indicators
        '(embark-verbose-indicator
          embark-highlight-indicator
          embark-isearch-highlight-indicator)))

(use-package embark-consult
  :ensure t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package marginalia
  :ensure t
  :defer 2
  :commands
  (marginalia-mode)
  :config
  (setq marginalia-align 'right)
  (setq marginalia-max-relative-age 0)
  (marginalia-mode 1))

(use-package vertico
  :ensure t
  :demand t
  :commands
  (vertico-insert
   vertico-exit)
  :init
  (defun vertico-move-end-of-line-or-insert (arg)
    "Move to end of line or insert current candidate.
   ARG lines can be used.

   When only one candidate exists exit input after insert."
    (interactive "p")
    (if (eolp)
        (progn
          (vertico-insert)
          (when (= vertico--total 1)
            (vertico-exit)))
      (move-end-of-line arg)))
  :config
  (setq vertico-cycle t)
  (setq vertico-resize nil)
  (add-hook 'minibuffer-setup #'vertico-repeat-save) ; Make sure vertico state is saved
  (add-hook 'rfn-eshadow-update-overlay #'vertico-directory-tidy) ; Clean up file path when typing
  (require 'vertico-directory)
  (require 'vertico-quick)
  (vertico-mode)
  :bind
  (:map vertico-map
    ("<backspace>"   . vertico-directory-delete-char)
    ("<escape>"      . minibuffer-keyboard-quit)
    ("?"             . minibuffer-completion-help)
    ("C-<backspace>" . vertico-directory-delete-word)
    ("C-e"           . vertico-move-end-of-line-or-insert)
    ("C-M-n"         . vertico-next-group)
    ("C-M-p"         . vertico-previous-group)
    ("TAB"           . minibuffer-complete)
    ("C-j"           . vertico-next)
    ("C-k"           . vertico-previous)
    ("C-o"           . vertico-quick-exit)
    ("C-w"           . vertico-directory-delete-word)
    ("M-F"           . vertico-multiform-flat)
    ("M-G"           . vertico-multiform-grid)
    ("M-R"           . vertico-multiform-reverse)
    ("M-RET"         . minibuffer-force-complete-and-exit)
    ("M-TAB"         . vertico-quick-insert)
    ("M-U"           . vertico-multiform-unobtrusive)
    ("M-h"           . vertico-directory-up)))

(setq enable-recursive-minibuffers t)

(setq minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))
(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

(setq max-mini-window-height 0.3)
(setq resize-mini-windows 'grow-only)

(defun disable-minibuffer-window-fringes (&rest _)
  "Disable the window fringes for minibuffer window."
  (set-window-fringes (minibuffer-window) 0 0 nil))
(add-hook 'minibuffer-setup-hook #'disable-minibuffer-window-fringes)

(setq history-delete-duplicates t)
(setq history-length 500)

(use-package savehist
  :ensure nil
  :demand t
  :config
  (setq savehist-file (expand-file-name "savehist" emacs-cache-dir))
  (setq history-length 500)
  (setq history-delete-duplicates t)
  (setq savehist-save-minibuffer-history t)
  (add-to-list 'savehist-additional-variables 'kill-ring)
  (savehist-mode 1))

(add-to-list 'debug-ignored-errors 'minibuffer-quit)

(use-package browse-url
  :bind
  (:map goto-map
        ("u" . browse-url-at-point)
        ("U" . browse-url)))

(use-package goto-chg
  :ensure t
  :bind
  ((:map goto-map ("SPC" . goto-last-change))
   (:repeat-map goto-chg-repeat-map
                ("SPC" . goto-last-change)
                ("[" . goto-last-change)
                ("]" . goto-last-change-reverse))))

(use-package link-hint
  :ensure t
  :bind
  (:map goto-map
        ("l" . link-hint-open-link)
        ("L" . link-hint-copy-link)))

(use-package recentf
  :defer 1
  :custom
  (recentf-exclude
        (list "/tmp/"                        ; Temp-files
              "/dev/shm"                     ; Potential secrets
              "/ssh:"                        ; Files over SSH
              "/nix/store"                   ; Files in Nix store
              "/TAGS$"                       ; Tag files
              "^/\\.git/.+$"                 ; Git contents
              "\\.?ido\\.last$"
              "\\.revive$"
              "^/var/folders/.+$"
              (concat "^" emacs-cache-dir ".+$")))
  (recentf-filename-handlers '(abbreviate-file-name))
  (recentf-max-menu-items 0)
  (recentf-max-saved-items 300)
  (recentf-auto-cleanup 'never)
  :config
  (quiet! (recentf-mode 1))
  (customize-set-variable 'recentf-save-file
                          (expand-file-name "recentf" emacs-cache-dir)))

(use-package saveplace
  :defer 2
  :config
  (save-place-mode 1))

(defvar *protected-buffers* '("*scratch*" "*Messages*")
  "Buffers that cannot be killed.")

(defun local/protected-buffers ()
  "Protects some buffers from being killed."
  (dolist (buffer *protected-buffers*)
    (with-current-buffer buffer
      (emacs-lock-mode 'kill))))

(add-hook 'after-init-hook #'local/protected-buffers)

(use-package popper
  :ensure t
  :demand t
  :init
  (setq popper-window-height 12
        popper-reference-buffers
         '("^\\*eshell\\*"
           "^vterm"
           "\\*Messages\\*"
           "Output\\*$"
           "\\*devdocs\\*"
           "\\*envrc\\*"
           "^\\*eldoc"
           help-mode
           helpful-mode
           compilation-mode
           elisp-refs-mode
           ghelp-page-mode
           (lambda (buf)
             (with-current-buffer buf
               (derived-mode-p '(compilation-mode
                                 comint-mode
                                 help-mode))))))
  (popper-mode +1)
  (popper-echo-mode +1))

(use-package midnight
  :ensure nil
  :demand t
  :config
  (midnight-mode))

(customize-set-variable 'undo-tree-auto-save-history nil)

(use-package undo-fu
  :ensure t
  :demand t
  :custom
  (undo-fu-allow-undo-in-region t)
  :config
  (global-unset-key (kbd "C-z"))
  ;; (global-set-key (kbd "C-z")   'undo-fu-only-undo)
  ;; (global-set-key (kbd "C-S-z") 'undo-fu-only-redo)
  (global-set-key (kbd "C-z") 'undo-fu-only-redo)
  )

(use-package autorevert
  :hook
  (image-mode-hook . auto-revert-mode)
  :init
  (setq auto-revert-verbose nil))

(defmacro make-find (functionname filename)
  (let ((funsymbol (intern (concat "find-" functionname))))
    `(defun ,funsymbol () (interactive) (find-file  ,filename))))

(make-find "config" local/config-file)
(make-find "accounts" local/accounts-file)
(make-find "contacts" local/contacts-file)

(defun find-notebook ()
  (interactive)
  (let ((dir (locate-dominating-file default-directory "Notebook.org")))
    (if dir
        (find-file-other-window (expand-file-name "Notebook.org"  dir))
      (message "No Notebook"))
    ))

(defun local/search-in-files ()
  (interactive)
  (consult-grep t))

(use-package dired
  :ensure nil
  :hook
  (dired-mode-hook . auto-revert-mode)
  (dired-mode-hook . hl-line-mode)
  (dired-mode-hook . dired-hide-details-mode)
  :custom
  (dired-recursive-copies 'always)
  (dired-recursive-deletes 'always)
  (dired-isearch-filenames 'dwim)
  (dired-hide-details-hide-symlink-targets nil)
  (delete-by-moving-to-trash t)
  (dired-auto-revert-buffer t)

  (dired-dwim-target t)
  :config
  (file-name-shadow-mode 1)
  (if (eq system-type 'darwin)
    (setq dired-use-ls-dired nil)
    (setq dired-listing-switches "-AFhlv --group-directories-first"))
  (autoload 'dired-async-mode "dired-async.el" nil t))

;; Folosește GNU ls pe macOS dacă este disponibil
(when (eq system-type 'darwin)
  (let ((gls (executable-find "gls")))
    (if gls
        (setq insert-directory-program gls)
      (setq dired-use-ls-dired nil)))) ; Fallback dacă gls nu e găsit

(use-package wdired
  :after dired
  :bind
  (:map dired-mode-map ("C-c '" . wdired-change-to-wdired-mode)))

(use-package async
  :ensure t
  :demand t
  :config
  (dired-async-mode 1))

(defun local/sudo-find-file (file)
  "Open FILE as root."
  (interactive "FOpen file as root: ")
  (when (file-writable-p file)
    (user-error "File is user writeable, aborting sudo"))
  (find-file (if (file-remote-p file)
                 (concat "/" (file-remote-p file 'method) ":"
                         (file-remote-p file 'user) "@" (file-remote-p file 'host)
                         "|sudo:root@"
                         (file-remote-p file 'host) ":" (file-remote-p file 'localname))
               (concat "/sudo:root@localhost:" file))))

(use-package wgrep
  :ensure t
  :demand t
  :custom
  (wgrep-auto-save-buffer t)
  (wgrep-change-readonly-file t)
  :bind ( :map grep-mode-map
          ("e" . wgrep-change-to-wgrep-mode)
          ("C-x C-q" . wgrep-change-to-wgrep-mode)
          ("C-c C-c" . wgrep-finish-edit)))

(use-package consult-dir
  :ensure t
  :demand t
  :commands consult-dir
  :custom
  (consult-dir-shadow-filenames t)
  (consult-dir-sources '(consult-dir--source-bookmark
                         consult-dir--source-default
                         consult-dir--source-project
                         consult-dir--source-recentf)))

(use-package trashed
  :ensure t
  :demand t
  :commands (trashed)
  :config
  (setq trashed-action-confirmer 'y-or-n-p)
  (setq trashed-use-header-line t)
  (setq trashed-sort-key '("Date deleted" . t))
  (setq trashed-date-format "%Y-%m-%d %H:%M:%S"))

(require 'windmove)

(defun local/win-move-sep-left (arg)
  "Move window splitter left."
  (interactive "p")
  (if (let ((windmove-wrap-around))
        (windmove-find-other-window 'right))
      (shrink-window-horizontally arg)
    (enlarge-window-horizontally arg)))

(defun local/win-move-sep-right (arg)
  "Move window splitter right."
  (interactive "p")
  (if (let ((windmove-wrap-around))
        (windmove-find-other-window 'right))
      (enlarge-window-horizontally arg)
    (shrink-window-horizontally arg)))

(defun local/win-move-sep-up (arg)
  "Move window splitter up."
  (interactive "p")
  (if (let ((windmove-wrap-around))
        (windmove-find-other-window 'up))
      (enlarge-window arg)
    (shrink-window arg)))

(defun local/win-move-sep-down (arg)
  "Move window splitter down."
  (interactive "p")
  (if (let ((windmove-wrap-around))
        (windmove-find-other-window 'up))
      (shrink-window arg)
    (enlarge-window arg)))

(require 'transient)
(transient-define-prefix local/win-resize ()
  "Resize windows"
  :transient-suffix     'transient--do-stay
  :transient-non-suffix 'transient--do-warn
  ["Actions"
   ("b" "balance" balance-windows :transient nil)
   ("h" "X←" local/win-move-sep-left)
   ("j" "X↓" local/win-move-sep-down)
   ("k" "X↑" local/win-move-sep-up)
   ("l" "X→" local/win-move-sep-right)])

(require 'transient)
(transient-define-prefix local/win-zoom ()
  "Zoom window"
  :transient-suffix     'transient--do-stay
  :transient-non-suffix 'transient--do-warn
  ["Actions"
   ("0" "reset" local/win-zoom-reset :transient nil)
   ("-" "-" text-scale-decrease)
   ("=" "+" text-scale-increase)])

(use-package ace-window
  :ensure t
  :custom
  (aw-dispatch-always t)
  :init
  (setq aw-dispatch-alist
        '((?? aw-show-dispatch-help)
          (?= local/ace-window-zoom "Zoom Text")
          (?F aw-split-window-fair "Split Fair Window")
          (?M aw-move-window "Move Window")
          (?v aw-split-window-horz "Split Horz Window")
          (?c aw-copy-window "Copy Window")
          (?e aw-execute-command-other-window "Execute Command Other Window")
          (?j aw-switch-buffer-in-window "Select Buffer")
          (?m aw-swap-window "Swap Windows")
          (?n aw-flip-window)
          (?o delete-other-windows "Delete Other Windows")
          (?r local/ace-window-resize "Resize Windows")
          (?t local/ace-window-toggle-split "Toggle Windows Split")
          (?u aw-switch-buffer-other-window "Switch Buffer Other Window")
          (?b aw-split-window-vert "Split Vert Window")
          (?x aw-delete-window "Delete Window")))
  :config
  (eval-when-compile
    (defmacro local/embark-ace-action (fn)
      `(defun ,(intern (concat "local/embark-ace-" (symbol-name fn))) ()
         (interactive)
         (with-demoted-errors "%s"
           (require 'ace-window)
           (let ((aw-dispatch-always t))
             (aw-switch-to-window (aw-select nil))
             (call-interactively (symbol-function ',fn)))))))

  (defun local/ace-window-resize (window)
    "Ace-window command to resize the WINDOW."
    (aw-switch-to-window window)
    (unwind-protect
        (local/win-resize)
      (aw-flip-window)))
  (defun local/ace-window-zoom (window)
    "Ace-window command to zoom the WINDOW text."
    (aw-switch-to-window window)
    (unwind-protect
        (local/win-zoom)
      (aw-flip-window)))
  (defun local/ace-window-toggle-split (window)
    "Ace-window command to toggle the WINDOWs split."
    (aw-switch-to-window window)
    (unwind-protect
        (local/win-toggle-split)
      (aw-flip-window)))

  (defun local/win-zoom-reset ()
    (interactive)
    (text-scale-increase 0))

  (defun local/win-toggle-split ()
    (interactive)
    (if (= (count-windows) 2)
        (let* ((this-win-buffer (window-buffer))
               (next-win-buffer (window-buffer (next-window)))
               (this-win-edges (window-edges (selected-window)))
               (next-win-edges (window-edges (next-window)))
               (this-win-2nd (not (and (<= (car this-win-edges)
                                           (car next-win-edges))
                                       (<= (cadr this-win-edges)
                                           (cadr next-win-edges)))))
               (splitter
                (if (= (car this-win-edges)
                       (car (window-edges (next-window))))
                    'split-window-horizontally
                  'split-window-vertically)))
          (delete-other-windows)
          (let ((first-win (selected-window)))
            (funcall splitter)
            (if this-win-2nd (other-window 1))
            (set-window-buffer (selected-window) this-win-buffer)
            (set-window-buffer (next-window) next-win-buffer)
            (select-window first-win)
            (if this-win-2nd (other-window 1))))))

  (defun local/swap-up-down ()
    (interactive)
    (if (window-in-direction 'above)
        (aw-swap-window (window-in-direction 'above))
      (aw-swap-window (window-in-direction 'below))))

  (defun local/swap-left-right ()
    (interactive)
    (if (window-in-direction 'right)
        (aw-swap-window (window-in-direction 'right))
      (aw-swap-window (window-in-direction 'left))))
  )

(use-package avy
  :ensure t
  :demand t
  :custom
  (avy-all-windows 'all-frames)
  :config
  (defun local/avy-kill-whole-line (pt)
    (save-excursion
      (goto-char pt)
      (kill-whole-line))
    (select-window
     (cdr
      (ring-ref avy-ring 0)))
    t)

  (defun local/avy-copy-whole-line (pt)
    (save-excursion
      (goto-char pt)
      (cl-destructuring-bind (start . end)
          (bounds-of-thing-at-point 'line)
        (copy-region-as-kill start end)))
    (select-window
     (cdr
      (ring-ref avy-ring 0)))
    t)

  (defun local/avy-yank-whole-line (pt)
    (local/avy-copy-whole-line pt)
    (save-excursion (yank))
    t)

  (defun local/avy-teleport-whole-line (pt)
    (local/avy-kill-whole-line pt)
    (save-excursion (yank)) t)

  (defun local/avy-mark-to-char (pt)
    (activate-mark)
    (goto-char pt)))
(global-set-key (kbd "<f9>") #'avy-goto-char)

(use-package bookmark
  :ensure nil
  :init
  (setq bookmark-save-flag 1
      bookmark-default-file (expand-file-name "bookmarks" emacs-cache-dir)))

(use-package org
  :ensure nil
  ;; :demand t
  :custom
  (org-archive-location "%s_archive::")
  (org-capture-bookmark nil)
  (org-cycle-separator-lines 2)
  (org-directory local/pers-dir)
  (org-edit-src-content-indentation 2)
  (org-ellipsis " ▾")
  (org-fold-catch-invisible-edits 'smart)
  (org-fold-show-context-detail t)
  (org-fontify-quote-and-verse-blocks t)
  (org-hide-block-startup nil)
  (org-hide-emphasis-markers t)
  ;; (org-id-locations-file (expand-file-name ".org-id-locations" emacs-cache-dir))
  (org-imenu-depth 4)
  (org-mouse-1-follows-link t)
  (org-return-follows-link t)
  (org-src-fontify-natively t)
  (org-src-preserve-indentation nil)
  (org-src-tab-acts-natively t)
  (org-startup-folded 'content)
  ;; org-fold-show-context-detail '((agenda . local)
  ;;                                (bookmark-jump . lineage)
  ;;                                (isearch . lineage)
  ;; (default . canonical))
  ;; Avoid accidentally editing folded regions, say by adding text after an Org “⋯”.
  :config
  (require 'org-tempo)
  (defun local/org-mode-setup ()
    (org-indent-mode 0)
    (auto-fill-mode 0)
    (visual-line-mode 0))
  (add-hook 'org-mode-hook #'local/org-mode-setup)
  (add-hook 'auto-save-hook #'org-save-all-org-buffers)
  )

(with-eval-after-load 'org
  (setf (cdr (assoc 'file org-link-frame-setup)) 'find-file))

(with-eval-after-load 'org
  (setq org-refile-targets '((nil :maxlevel . 1)
                             (org-agenda-files :maxlevel . 2)
                             ))

  (setq org-outline-path-complete-in-steps nil)
  (setq org-refile-use-outline-path t))

(with-eval-after-load 'ispell
  (add-to-list 'ispell-skip-region-alist '(":\\(PROPERTIES\\|LOGBOOK\\):" . ":END:"))
  (add-to-list 'ispell-skip-region-alist '("#\\+begin_src" . "#\\+end_src")))

(use-package org-superstar
  :ensure t
  :demand t
  :after org
  :custom
  (org-superstar-remove-leading-stars t)
  (org-superstar-headline-bullets-list '("●" "■" "►" "○" "□" "▷"))
  :config
  (add-hook 'org-mode-hook (lambda () (org-superstar-mode 1))))

(defun local/date-iso ()
  "Insert the current date, ISO format, eg. 2016-12-09."
  (interactive)
  (insert (format-time-string "%F")))

(defun local/date-iso-with-time ()
  "Insert the current date, ISO format with time, eg. 2016-12-09T14:34:54+0100."
  (interactive)
  (insert (format-time-string "%FT%T%z")))

(defun local/org-table-recalculate-all ()
  "Recalculate all values in a table."
  (interactive)
  (org-table-recalculate 'iterate))

(use-package org-appear
  :ensure t
  :demand t
  :custom
  (org-hide-emphasis-markers t)
  :hook org-mode-hook)

(use-package org-roam
  :ensure t
  :demand t
  :custom
  (org-roam-directory local/notes-dir)
  (org-roam-db-location (expand-file-name "org-roam.db" emacs-cache-dir))
  (org-roam-graph-viewer "/usr/bin/google-chrome-stable")
  (org-roam-completion-everywhere nil)
  (org-roam-node-display-template   (concat "${title:*} "
                                            (propertize "${tags:20}" 'face 'org-tag)))
  :config
  (org-roam-db-autosync-mode 1)
  (require 'org-roam-protocol))

(defun local/insert-roam-link ()
  "Inserts an Org-roam link."
  (interactive)
  (insert "[[roam:]]")
  (backward-char 2))

(use-package key-chord
  :ensure t
  :demand t
  :config
  (key-chord-mode 1)
  (key-chord-define-global "[[" #'local/insert-roam-link))

(use-package org-roam-ui
  :ensure t
  :demand t
  :after org-roam
  :commands (org-roam-ui-mode)
  :hook org-roam-mode)

(defun local/org-roam-rg-search ()
  "Search org-roam directory using consult-ripgrep. With live-preview."
  (interactive)
  (let ((consult-ripgrep-command "rg --null --ignore-case --type org --line-buffered --color=always --max-columns=500 --no-heading --line-number . -e ARG OPTS"))
    (consult-ripgrep org-roam-directory)))

(use-package org-transclusion
  :ensure t
  :custom (org-transclusion-include-first-section t))

(with-eval-after-load 'transient
  (transient-define-prefix local/notes-menu ()
    "notes menu"
    [["Commands"
      ("/" "search" local/org-roam-rg-search)
      ("a" "add alias" org-roam-alias-add)
      ("b" "switch-to-buffer" org-roam-buffer-toggle)
      ("c" "capture" org-roam-capture)
      ("f" "find" org-roam-node-find)
      ("i" "create id" org-id-get-create)
      ("n" "insert node" org-roam-node-insert)
      ;; ("q" "ql search" org-ql-search)
      ]
     ["References"
      ("ra" "add ref" org-roam-ref-add)
      ("rb" "add bib ref" citar-org-roam-ref-add)]
     ["Transclude"
      ("ta" "add" org-transclusion-add)
      ("tA" "add all" org-transclusion-add-all)
      ("tl" "link" org-transclusion-make-from-link)
      ("tm" "mode" org-transclusion-mode)]
     ;; ["Journal"
     ;;  ("jd" "date" org-roam-dailies-goto-date)
     ;;  ("jj" "journal" org-roam-dailies-capture-today)]
     ["Server"
      ("sd" "sync db" org-roam-db-sync)
      ("si" "sync id" org-roam-update-org-id-locations)
      ;; ("sg" "graph" org-roam-graph)
      ("ss" "start" org-roam-ui-mode)]]))

(use-package ispell
  :ensure nil
  :init
  ;; Setăm DICPATH pentru ca Hunspell să găsească fișierele .aff și .dic
  (setenv "DICPATH" (concat (getenv "HOME") "/.nix-profile/share/hunspell"))
  :custom
  (ispell-program-name "hunspell")
  (ispell-dictionary "en_GB,ro_RO" "Configure English and Romanian.")
  (ispell-personal-dictionary "~/.config/emacs/.hunspell_personal")
  (text-mode-ispell-word-completion nil)
  :config
  ;; Configure `LANG`, otherwise ispell.el cannot find a 'default
  ;; dictionary' even though multiple dictionaries will be configured
  ;; in next line.
  (setenv "LANG" "en_GB")
  ;; Resetăm variabilele interne pentru a forța o scanare nouă
  (setq ispell-hunspell-dict-paths-alist nil)
  ;; Forțăm ispell să recunoască setările Hunspell
  (ispell-set-spellchecker-params)
  ;; Verificăm dacă dicționarele au fost găsite înainte de a le activa
  (if (and (boundp 'ispell-hunspell-dict-paths-alist)
           ispell-hunspell-dict-paths-alist)
      (ispell-hunspell-add-multi-dic ispell-dictionary)
    (message "Ispell Error: Nu am putut popula ispell-hunspell-dict-paths-alist. Verifica DICPATH."))
  ;; Creăm fișierul personal dacă nu există
  (unless (file-exists-p ispell-personal-dictionary)
    (write-region "" nil ispell-personal-dictionary nil 0)))

(require 'whitespace)

(defun local/surround (begin end open close)
  "Put OPEN at START and CLOSE at END of the region.
If you omit CLOSE, it will reuse OPEN."
  (interactive  "r\nsStart: \nsEnd: ")
  (when (string= close "")
    (setq close open))
  (save-excursion
    (goto-char end)
    (insert close)
    (goto-char begin)
    (insert open)))

(add-to-list 'insert-pair-alist (list ?\= ?\=))
(add-to-list 'insert-pair-alist (list ?\~ ?\~))
(global-set-key (kbd "M-=") 'insert-pair)
(global-set-key (kbd "M-\"") 'insert-pair)
(global-set-key (kbd "M-~") 'insert-pair)
(global-set-key (kbd "M-[") 'insert-pair)
(global-set-key (kbd "M-{") 'insert-pair)

(use-package citar
  :ensure t
  :demand t
  :custom
  (citar-bibliography (list local/bibliography-file))
  (citar-library-paths (list local/resources-dir))
  (citar-notes-paths (list local/notes-dir)) ;; Unde stau notițele
  :config
  ;; Această linie leagă Citar de Org-Roam pentru comanda "Open Notes"
  (setq citar-notes-source 'citar-org-roam))

(use-package citar-org-roam
  :ensure t
  :after (citar org-roam)
  :config
  (citar-org-roam-mode)

  ;; Setează formatul titlului pentru notițele de lectură
  (setq citar-org-roam-note-title-template "${author} - ${title}")

  ;; Configurare template pentru notița nouă
  (setq org-roam-capture-templates
        (append org-roam-capture-templates
                '(("b" "bibliografie" plain
                   "%?"
                   :target (file+head "referinte/${citekey}.org"
                                      "#+title: ${title}\n#+roam_key:\n")
                   :unnarrowed t)))))

(setq view-read-only t)

(use-package csv-mode
  :ensure t)

(with-eval-after-load 'org
  (require 'org-capture)
  (defalias #'cape-super-capf #'cape-capf-super)
  (defvar local/org-task-template
    "* TODO %?\n%a\n"
    "Template for task.")
  (defvar local/org-note-template
    "* %T\n%?\n"
    "Template for note.")
  (defvar local/org-contact-template
    "* %(org-contacts-template-name)
  :PROPERTIES:
  :ADDRESS:
  :BIRTHDAY: %^{yyyy-mm-dd}
  :EMAIL: %(org-contacts-template-email)
  :NOTE: %^{NOTE}
  :END:"
    "Template for org-contacts.")
  (setq org-capture-templates `(("c" "Contact" entry (file+headline local/backlog-file "Contacts"),
                                 local/org-contact-template
                                 :empty-lines 1 :clock-resume t :prepend t)
                                ("n" "Note" entry (file+headline local/backlog-file "Notes"),
                                 local/org-note-template
                                 :empty-lines 1 :clock-resume t :prepend t)
                                ("t" "Task" entry (file+headline local/backlog-file "Tasks"),
                                 local/org-task-template
                                 :empty-lines 1 :clock-resume t :prepend t))))

(with-eval-after-load 'org
  (setq org-latex-pdf-process
      '("xelatex -interaction nonstopmode -output-directory %o %f"
        "xelatex -interaction nonstopmode -output-directory %o %f"
        "xelatex -interaction nonstopmode -output-directory %o %f")
        org-latex-compiler "xelatex"
        ;; org-latex-compiler "lualatex"
        org-preview-latex-default-process 'dvisvgm
        org-export-backends '(ascii html icalendar latex md odt org)
        org-latex-default-packages-alist (quote
                                          (("T1" "fontenc" t)
                                           ("" "fixltx2e" nil)
                                           ("" "graphicx" t)
                                           ("" "longtable" nil)
                                           ("" "float" nil)
                                           ("" "wrapfig" nil)
                                           ("" "rotating" nil)
                                           ("normalem" "ulem" t)
                                           ("" "amsmath" t)
                                           ("" "textcomp" t)
                                           ("" "marvosym" t)
                                           ("" "wasysym" t)
                                           ("" "amssymb" t)
                                           ;; ("" "minted" t)
                                           ("" "hyperref" nil)
                                           "\\tolerance=1000"))
        ;; org-latex-listings (quote minted)
        org-latex-minted-options (quote
                                  (("fontsize" "\\footnotesize")
                                   ("linenos" "true")
                                   ("xleftmargin" "0em"))))
  )

(use-package ox-json
  :ensure t)
;; (use-package ox-epub
;;   :ensure t)
;; (use-package ox-jira
;;   :ensure t)
(with-eval-after-load 'org
  (require 'org-src)
  (setq org-src-tab-acts-natively t
        org-src-fontify-natively t
        org-src-window-setup 'split-window-right
        org-src-preserve-indentation t)
  (org-babel-do-load-languages
   'org-babel-load-languages
   (append org-babel-load-languages
           '((C . t)
             (css . t)
             (ditaa . t)
             (gnuplot . t)
             (java . t)
             (js . t)
             (latex . t)
             (makefile . t)
             (org . t)
             (python . t)
             (scheme . t)
             (sqlite . t)
             (sql . t)
             ;; (xml . t)
             ))))

(use-package plantuml-mode
  :ensure t
  :after org
  :mode "\\.\\(plantuml\\|puml\\)\\'"
  :custom
  ;; (plantuml-jar-path "~/.local/lib/plantuml.jar")
  ;; (org-plantuml-jar-path plantuml-jar-path)
  ;; (plantuml-defaultexec-mode 'jar)
  (plantuml-default-exec-mode 'executable)
  (plantuml-executable-path "~/.nix-profile/bin/plantuml")
  :config
  (add-to-list 'org-src-lang-modes '("plantuml" . plantuml))
  (require 'ob-plantuml)
  (with-eval-after-load 'org
    (add-to-list 'org-babel-load-languages '(plantuml . t))
    (setq org-plantuml-exec-mode 'plantuml
          org-plantuml-executable-path plantuml-executable-path)))

(use-package graphviz-dot-mode
  :ensure t
  :demand t
  :hook
  (graphviz-dot-mode . flycheck-mode)
  :custom
  (graphviz-dot-indent-width 4)
  (graphviz-dot-preview-extension "svg")
  :config
  (with-eval-after-load 'org
    (add-to-list 'org-src-lang-modes '("dot" . graphviz-dot))
    (org-babel-do-load-languages
     'org-babel-load-languages
     '((dot . t)))))

(use-package mermaid-mode
  :ensure t
  :mode "\\.mmd\\'"
  :bind (:map mermaid-mode-map
              ("C-c C-p" . local/mermaid-preview))
  :config
  (defun local/mermaid-preview ()
    "Render the current mermaid buffer to PNG via mmdc and display it.
Works with both file-visiting buffers and temp buffers (e.g. *mermaid-edit*)."
    (interactive)
    (let* ((input (or (buffer-file-name)
                      (let ((f (make-temp-file "mermaid-" nil ".mmd")))
                        (write-region (point-min) (point-max) f nil 'silent)
                        f)))
           (output (concat (file-name-sans-extension input) ".png")))
      (let ((exit-code (call-process "mmdc" nil (get-buffer-create "*mmdc-errors*") t
                                     "-i" input
                                     "-o" output
                                     "--scale" "2"
                                     "-q")))
        (if (and (eq exit-code 0) (file-exists-p output))
            (progn
              (kill-buffer "*mmdc-errors*")
              (find-file-other-window output))
          (user-error "mmdc failed (exit %d): %s" exit-code
                      (with-current-buffer "*mmdc-errors*"
                        (buffer-string))))))))

(use-package ob-mermaid
  :ensure t
  :after org
  :config
  (add-to-list 'org-src-lang-modes '("mermaid" . mermaid))
  (with-eval-after-load 'org
    (org-babel-do-load-languages
     'org-babel-load-languages
     '((mermaid . t)))))

(with-eval-after-load 'transient
  (transient-define-prefix local/mermaid-menu ()
    "mermaid menu"
    [("'" "jump source" org-edit-src-exit)
     ("m" "edit mermaid block" local/markdown-edit-mermaid)
     ("v" "view mermaid block" local/mermaid-preview)
     ("j" "jump" local/jump-menu)]))

(use-package org-make-toc
  :ensure t
  :custom
  (org-make-toc-insert-custom-ids t))

(defun local/goto-first-header ()
  "Jump backward to the first header in the buffer."
  (interactive)
  (goto-char (point-min))
  (org-next-visible-heading 1))

(defun local/goto-last-header ()
  "Jump forward to the last header in the buffer."
  (interactive)
  (goto-char (point-max))
  (org-previous-visible-heading 1))

(defun local/goto-first-child ()
  "Jump forward to first child of this header."
  (interactive)
  (outline-show-children 1)
  (outline-next-visible-heading 1))

(with-eval-after-load 'transient
  (transient-define-prefix local/header-menu ()
    "header menu"
    :transient-suffix     'transient--do-stay
    :transient-non-suffix 'transient--do-warn
    [["Cursor"
      ("j" "down" org-forward-heading-same-level)
      ("k" "up" org-backward-heading-same-level)
      ("l" "forward" local/goto-first-child)
      ("h" "backward" outline-up-heading)
      ("0" "first header" local/goto-first-header)
      ("$" "last header" local/goto-last-header)]
     ["Move"
      ("-" "sort" org-sort-entries)
      ("J" "move down" org-move-subtree-down)
      ("K" "move up" org-move-subtree-up)
      ("L" "move right" org-shiftmetaright)
      ("H" "move left" org-shiftmetaleft)]
     ["Edit"
      ("~" "toggle" org-toggle-heading)
      ("i" "new" org-insert-heading-after-current  :transient nil)]
     ["Misc"
      ("/" "search" imenu)
      ("a" "show all" org-show-all)
      ("f" "toggle folding" org-cycle)
      ("F" "toggle global visibility" org-shifttab)]]))

(with-eval-after-load 'transient
  (defun src-first-src ()
    "Jump backward to the first src in the buffer."
    (interactive)
    (goto-char (point-min))
    (org-babel-next-src-block))

  (defun src-last-src ()
    "Jump forward to the last src in the buffer."
    (interactive)
    (end-of-buffer)
    (org-babel-previous-src-block))

  (transient-define-prefix local/src-menu ()
    "src menu"
    :transient-suffix     'transient--do-stay
    :transient-non-suffix 'transient--do-warn
    [["Cursor"
      ("h" "goto src head" org-babel-goto-src-block-head)
      ("j" "down" org-babel-next-src-block)
      ("k" "up" org-babel-previous-src-block)
      ("n" "goto named src" org-babel-goto-named-src-block)
      ("-" "first src" src-first-src)
      ("$" "last src" src-last-src)]
     ["Edit"
      ("'" "edit special" org-edit-special :transient nil)
      ("a" "header arg" org-babel-insert-header-arg)
      ("s" "split src block" org-babel-demarcate-block :transient nil)]
     ["Misc"
      ("t" "tangle" org-babel-tangle  :transient nil)
      ;; ("e" "eval" org-babel-execute-src)
      ("r" "switch to code" org-babel-switch-to-session-with-code)
      ("?" "info" org-babel-view-src-block-info)
      ("!" "check" org-babel-check-src-block)]]))

(with-eval-after-load 'transient
  (transient-define-prefix local/org-menu ()
    "org menu"
    [["Edit1"
      ("'" "edit special" org-edit-special)
      ("-" "sort" org-sort)
      ("c" "cycle bullets" org-cycle-list-bullet :transient t)
      ("i" "item" org-insert-item)
      ("ef" "footnote" org-footnote-action)
      ("eg" "tags" org-set-tags-command)
      ("eh" "heading" org-toggle-heading)]
     ["Edit2"
      ("ei" "item" org-toggle-item)
      ("el" "link"  (lambda ()
                      (interactive)
                      (call-interactively 'org-insert-link)))
      ("ep" "property" org-set-property)
      ;; ("er" "reference" org-ref-insert-link)
      ("ew" "drawer" org-insert-drawer)
      ("ex" "id" org-id-get-create)]
     ["Misc"
                                        ;("h" "header" local/header-menu)
                                        ;("g" "send to chatgpt" gptel-send )
      ("o" "open at point" org-open-at-point)
      ("O" "jump back" org-mark-ring-goto)
                                        ;("s" "src" local/src-menu)
      ("vm" "preview latex" org-latex-preview)
      ("vi" "preview images" org-display-inline-images)]
     ["SubMenus"
      ("h" "header" local/header-menu)
      ("s" "src" local/src-menu)]
     ["Tools"
      ("ta" "archive" org-archive-subtree)
      ("tc" "recalculate" local/org-table-recalculate-all)
      ("td" "detangle" org-babel-detangle)
      ("te" "eval sexp" eval-last-sexp)
      ("tr" "refile" org-refile)
      ("tt" "tangle" org-babel-tangle)
      ("tx" "export" org-export-dispatch)]]))

(defun local/org-settings-hook ()
  (local-set-key (kbd "C-c k") 'local/org-menu))

(add-hook 'org-mode-hook #'local/org-settings-hook)

(with-eval-after-load 'org
  (require 'org-agenda)
  (setq org-agenda-dim-blocked-tasks t
        org-agenda-span 1
        org-clock-continuously t
        org-agenda-start-on-weekday nil
        org-agenda-start-day "-0d"
        org-agenda-files  (list
                           local/plan-dir
                           local/contacts-file)
        calendar-set-date-style 'iso))

(defmacro make-goto (functionname filename)
  (let ((funsymbol (intern (concat "goto-" functionname))))
    `(defun ,funsymbol () (interactive) (find-file (expand-file-name ,filename local/plan-dir)))))

(make-goto "pers" "Pers.org")
(make-goto "work" "Work.org")
(make-find "backlog" local/backlog-file)

(defun local/get-plan (plan-file)
  (interactive
  (list (read-file-name "Plan file: " local/plan-dir)))
  (find-file (expand-file-name plan-file local/plan-dir)))

(with-eval-after-load 'org
  (customize-set-variable 'org-todo-keywords
                          '((sequence "TODO(t)" "INPROGRESS(i)" "|" "DONE(d)")
                            (sequence "WAITING(w)" "|")
                            (sequence "|" "CANCELLED(c)")))
  (customize-set-variable 'org-agenda-skip-scheduled-if-done t)
  (customize-set-variable 'org-agenda-skip-deadline-if-done  t)
  (require 'org-faces)
  (customize-set-variable 'org-todo-keyword-faces
                          '(("TODO"       :foreground "#7c7c75" :weight normal :underline t)
                            ("WAITING"    :foreground "#9f7efe" :weight normal :underline t)
                            ("INPROGRESS" :foreground "#0098dd" :weight normal :underline t)
                            ("DONE"       :foreground "#50a14f" :weight normal :underline t)
                            ("CANCELLED"  :foreground "#ff6480" :weight normal :underline t)))
  (customize-set-variable 'org-priority-faces
                          '((?A :foreground "#e45649")
                            (?B :foreground "#da8548")
                            (?C :foreground "#0098dd")))
  (custom-set-faces '(org-done ((t (:weight bold :strike-through t))))
                    '(org-headline-done ((((class color) (min-colors 16)
                                           (background dark)) (:strike-through t)))))

  )

(with-eval-after-load 'org
  (require 'org-clock)
  ;; Save the running clock and all clock history when exiting Emacs, load it on startup
  (customize-set-variable 'org-clock-persist t)
  ;; Resume clocking task on clock-in if the clock is open
  (customize-set-variable 'org-clock-in-resume t)
  ;; Change task state to INPROGRESS when clocking in
  (customize-set-variable 'org-clock-in-switch-to-state "INPROGRESS")
  ;; Separate drawers for clocking and logs
  (customize-set-variable 'org-drawers (quote ("PROPERTIES" "LOGBOOK")))
  ;; Sometimes I change tasks I'm clocking quickly - this removes clocked tasks with 0:00 duration
  (customize-set-variable 'org-clock-out-remove-zero-time-clocks t)
  ;; Clock out when moving task to a done state
  (customize-set-variable 'org-clock-out-when-done t)
  ;; Enable auto clock resolution for finding open clocks
  (customize-set-variable 'org-clock-auto-clock-resolution (quote when-no-clock-is-running))
  ;; Include current clocking task in clock reports
  (customize-set-variable 'org-clock-report-include-clocking-task t)
  (customize-set-variable 'org-clock-continuously nil)
  (customize-set-variable 'org-clock-persist-file (expand-file-name (format "%s/emacs/org-clock-save.el" xdg-cache)))
  (customize-set-variable 'org-show-notification-handler (lambda (msg) (alert msg)))
  (add-hook 'kill-emacs-hook #'org-clock-save)

  (defun local/start-task ()
    (interactive)
    (let ((current-prefix-arg 4))
      (call-interactively 'org-clock-in)))
  )

(with-eval-after-load 'org
  (require 'org-contacts)
  (customize-set-variable 'org-contacts-files (list local/contacts-file)))

(transient-define-prefix local/agenda-menu ()
  "agenda menu"
  [["View"
    ("a" "agenda" org-agenda-list)
    ("D" "day" org-agenda-day-view)
    ("W" "week" org-agenda-week-view)
    ("M" "month" org-agenda-month-view)]
   ["Agenda"
    ("r" "refile" org-refile)
    ("s" "schedule" org-schedule)
    ("t" "todo" org-todo)]
   ["Clock"
    ("i" "in" org-agenda-clock-in)
    ("o" "out" org-agenda-clock-out)
    ("c" "cancel" org-clock-cancel)]
   ["Files"
    ("b" "backlog" find-backlog)
    ("f" "find plan file" local/get-plan)
    ("p" "pers" goto-pers)
    ("w" "work" goto-work)]])

(use-package ent
  :ensure t
  :vc (:url "https://github.com/dpom/ent" :lisp-dir "lisp")
  :demand t)

(defalias 'convert-ent
  (kmacro "C-s t a s k <return> f : <return> <escape> u <backspace> w M-\" f ' <backspace> d d <return> i : d o c SPC M-c t <backspace> <escape> f \" 1 <left> <return> i : a c t i o n SPC <escape>"))

(use-package magit
  :ensure t
  :demand t
  :commands (magit-status magit-blame)
  ;; :hook
  ;; (magit-pre-refresh . diff-hl-magit-pre-refresh)
  ;; (magit-post-refresh . diff-hl-magit-post-refresh)
  )

(use-package diff-hl
  :ensure t
  :commands (diff-hl-mode diff-hl-dired-mode)
  ;; :autoload (diff-hl-magit-pre-refresh diff-hl-magit-post-refresh)
  :hook
  ((prog-mode conf-mode) . diff-hl-mode))

(use-package smerge-mode
    :ensure nil
  :commands smerge-mode)

(use-package git-timemachine
    :ensure t)

  (use-package forge
    :ensure t
    :demand t
    :after magit
    :custom
    (forge-database-file (expand-file-name "forge-database.sqlite" emacs-cache-dir)))
;; (with-eval-after-load 'magit
;;   (require 'forge))

(defcustom lemacs-docker-executable 'docker
  "The executable to be used with docker-mode."
  :type '(choice
           (const :tag "docker" docker)
           (const :tag "podman" podman))
  :group 'lemacs)

(use-package docker
  :defer t
  :ensure t
  :bind ("C-c d" . docker)
  :config
  (pcase lemacs-docker-executable
    ('docker
     (setf docker-command "docker"
           docker-compose-command "docker-compose"))
    ('podman
     (setf docker-command "podman"
           docker-compose-command "podman-compose"))))

(use-package dockerfile-mode
  :defer t
  :ensure t
  :config
  (pcase lemacs-docker-executable
    ('docker
     (setq dockerfile-mode-command "docker"))
    ('podman
     (setq dockerfile-docker-command "podman"))))

(use-package ledger-mode
  :ensure t
  :mode "\\.lgr\\'"
  :custom
   (ledger-use-iso-dates t)
   (ledger-reports '(("bal" "%(binary) -f %(ledger-file) bal")
                    ("bal this quarter" "%(binary) -f %(ledger-file) --period \"this quarter\" bal")
                    ("bal last quarter" "%(binary) -f %(ledger-file) --period \"last quarter\" bal")
                    ("reg" "%(binary) -f %(ledger-file) reg")
                    ("payee" "%(binary) -f %(ledger-file) reg @%(payee)")
                    ("account" "%(binary) -f %(ledger-file) reg %(account)"))))

(setq auth-sources '(password-store
                     "~/.authinfo.gpg"))

(use-package pass
  :ensure t
  :demand t
  :commands pass
  :custom
   (pass-show-keybindings nil)
   (pass-username-fallback-on-filename t)
   :config
   (require 'password-store)
   (defun local/pass-kill-recursiv ()
     (interactive)
     (let ((entry (pass-directory-at-point)))
       (when (yes-or-no-p (format "Do you want remove the entry %s? " entry))
         (password-store-remove entry)
         (pass-update-buffer)))))

(require 'auth-source-pass)
(auth-source-pass-enable)

(use-package pinentry
  :ensure t
  :demand t
  :config
  (setq epa-pinentry-mode 'loopback)
  (when (fboundp 'pinentry-start)
    (pinentry-start)))

(require 'epa-file)
(epa-file-enable)

(use-package mu4e
  :ensure nil
  :custom
  (user-mail-address   "dan.pomohaci@pm.me")
  (user-full-name      "Dan Pomohaci")
  (mu4e-sent-folder    "/Proton/Sent")
  (mu4e-drafts-folder  "/Proton/Drafts")
  (mu4e-trash-folder   "/Proton/Trash")
  (mu4e-refile-folder  "/Proton/Archive")
  ;; Trimitere mesaje
  (message-send-mail-function 'smtpmail-send-it)
  (smtpmail-default-smtp-server  "127.0.0.1")
  (smtpmail-smtp-server  "127.0.0.1")
  (smtpmail-smtp-service  1025)

  ;; actualizare automata si indexare
  (mu4e-maildir "~/Maildir")
  (mu4e-get-mail-command "mbsync -V -a")
  (mu4e-update-interval (* 10 60) "update every 10 minutes")
  (mu4e-change-filenames-when-moving t "work better for mbsync")
  (mu4e-index-cleanup t)
  (mu4e-index-lazy-check nil)

  ;; setari interfata
  (mu4e-attachment-dir "~/Downloads")
  (mu4e-html2text-command "pandoc -f html -t plain")
  (mu4e-view-show-images t)
  (mu4e-show-images t)
  (mu4e-view-image-max-width 800)
  (mu4e-image-max-width 800)
  (mu4e-confirm-quit nil)
  (mu4e-headers-auto-update t)
  (mu4e-compose-signature-auto-include nil)
  (mu4e-sent-messages-behavior 'delete)
  (message-kill-buffer-on-exit t)
  (mu4e-compose-dont-reply-to-self t)
  (mu4e-view-show-addresses t)
  (mu4e-use-fancy-chars t)
  (mu4e-headers-results-limit 500)

  ;; bookmarks
  (mu4e-bookmarks '((:name  "Unread messages"
                            :query "flag:unread AND NOT flag:trashed"
                            :key ?u)
                    (:name "INBOX"
                           :query "maildir:/Proton/INBOX"
                           :key ?b)
                    (:name "Today's messages"
                           :query "maildir:/Proton/01_Plan_Today"
                           :key ?t)
                    (:name "Last week"
                           :query "maildir:/Proton/02_Plan_Week"
                           :key ?w)
                    (:name "Last month"
                           :query "maildir:/Proton/03_Plan_Month"
                           :key ?m)
                    (:name "Last year"
                           :query "maildir:/Proton/04_Plan_Year"
                           :key ?a)))
  ;; (mu4e-maildir-shortcuts '((:maildir "/gmail/INBOX" :key ?i)
  ;;                           (:maildir "/gmail/Spam"  :key ?s)
  ;;                           (:maildir "/drafts"      :key ?d)
  ;;                           (:maildir "/gmail/year"  :key ?a)
  ;;                           (:maildir "/gmail/month" :key ?m)
  ;;                           (:maildir "/gmail/week"  :key ?w)
  ;;                           (:maildir "/gmail/today" :key ?t)))
  )


;; (use-package mu4e-alert
;;   :ensure t
;;   :config
;;   (when (executable-find "notify-send")
;;     (mu4e-alert-set-default-style 'libnotify))
;;   (add-hook 'after-init #'mu4e-alert-enable-notifications)
;;   (add-hook 'after-init #'mu4e-alert-enable-mode-line-display)
;; ;; view
;; <<email-view>>
;; ;; compose
;; <<email-compose>>
;; ;; spell check
;; )

(defgroup ai nil
  "Local AI group."
  :tag "AI"
  :group 'local)

 (defun local/get-ollama-models ()
  "Return a list of ollama model names present in the system."
  (interactive)
 (let* ((output (shell-command-to-string "ollama list"))
         (lines (split-string output "\n" t))
         (models '()))
    ;; Skip the header line
    (dolist (line (cdr lines))
      (when (string-match "^\\([^ ]+\\)" line)

        (push (intern (match-string 1 line)) models)))
    (nreverse models)))

(defun local/get-gemini-key ()
    "Extrage cheia API pentru Gemini din ~/.authinfo"
    (let ((match (auth-source-search :host "api.google.com" :user "apikey")))
      (if match
          (let ((secret (plist-get (car match) :secret)))
            (if (functionp secret) (funcall secret) secret))
        (error "Nu am găsit cheia API în ~/.authinfo"))))

(use-package gptel
  :ensure t
  :demand t
  :commands (gptel gptel-send)
  :config
  (require 'subr-x)
  (setq gptel-playback t
        gptel-default-mode 'org-mode
        gptel-default-model 'gemma4:e4b
        gptel-cache '(message system tool)
        gptel-track-media t
        gptel-ollama-backend (gptel-make-ollama "Ollama"
                        :host "localhost:11434"
                        :stream t
                        :models (local/get-ollama-models)))
  (gptel-make-gemini "Gemini"
    :stream t
    :key #'local/get-gemini-key
    :models '(gemini-2.5-flash
            gemini-2.5-pro))
  (setq gptel-backend gptel-ollama-backend))

  (with-eval-after-load 'gptel
      (global-set-key (kbd "<f5>") 'gptel-send)
      (global-set-key (kbd "<f6>") 'gptel-menu)
      (global-set-key (kbd "<f7>") 'gptel-abort)

      (require 'gptel-integrations))

  (use-package gptel-prompts
    :after (gptel)
    :vc (:url "https://github.com/jwiegley/gptel-prompts")
    :ensure t
    :demand t
    :custom
    (gptel-prompts-directory (expand-file-name "ai-prompts/" local/pers-dir))
    :config
    (gptel-prompts-update))

(use-package llm-tool-collection
  :ensure t
  :vc (:url "https://github.com/skissue/llm-tool-collection")
  :demand t
  :after gptel)

(use-package ragmacs
  :ensure t
  :vc (:url "https://github.com/positron-solutions/ragmacs")
  :after gptel)

(with-eval-after-load 'gptel
  (defun local/extract-emacs-package-readme (package-name)
    "Extract and return the README file for package PACKAGE-NAME.
This version attempts to robustly find the source directory for
packages, including those managed by straight.el.
Return =nil' if no README was found."
    (if (stringp package-name)
        (let* (;; 1. Get the path to the library file as Emacs knows it (e.g., .../straight/build/PKG/PKG.el)
               (library-file-in-load-path (find-library-name package-name))

               ;; 2. Get the canonical, true path to this library file.
               ;; For straight.el, if library-file-in-load-path is a symlink like
               ;; .../build/PKG/PKG.el -> .../repos/PKG/PKG.el,
               ;; this will resolve to .../repos/PKG/PKG.el.
               (true-library-file-path (when library-file-in-load-path
                                         (file-truename library-file-in-load-path)))

               ;; 3. Get the directory containing the true library file.
               ;; This should be the actual source directory (e.g., .../straight/repos/PKG/).
               (package-source-dir (when true-library-file-path
                                     (file-name-directory true-library-file-path)))

               ;; 4. Locate the README within this source directory using your helper.
               ;; local/locate-readme-in-directory returns an absolute path.
               (readme-full-path (when (and package-source-dir (file-directory-p package-source-dir))
                                   (local/locate-readme-in-directory package-source-dir))))

          (if readme-full-path
              (with-temp-buffer
                (goto-char (point-min))
                (insert (format "README file for package %s (from directory %s):\n\n"
                                package-name
                                ;; Show the directory where the README was actually found
                                (file-name-directory readme-full-path))) ; This is package-source-dir
                (insert-file-contents readme-full-path)
                (buffer-string))
            (progn
              ;; More detailed warning for debugging
              (warn (format (concat "No README file found for package '%s'.\n"
                                    "  Searched in directory: %s\n"
                                    "  Library file in load-path: %s\n"
                                    "  Resolved true library file path: %s")
                            package-name
                            (or package-source-dir "unknown or not a directory")
                            (or library-file-in-load-path "not found by find-library-name")
                            (or true-library-file-path "could not be resolved by file-truename")))
              nil)))
      (progn
        (warn "PACKAGE-NAME argument must be the package name as a string.")
        nil)))

  (gptel-make-tool
   :name "emacs_package_readme"
   :description "Return the README file for a package - please use this to understand what a package does prior to deciding whether to pull the package source code."
   :category "emacs"
   :include t
   :function #'local/extract-emacs-package-readme
   :args (list '(:name "package_name"
                       :type string
                       :description "Name of the Emacs package."
                       :optional nil))))

(with-eval-after-load 'gptel
  (defun local/extract-emacs-package-source (package &optional FULL)
    "Extract and return a simple structured text document with the primary source for package PACKAGE.
If FULL is not nil, return all source files."
    (if (stringp package)
        (let* ((library-path (find-library-name package))
               (all-elisp (directory-files (f-dirname library-path) t ".*\\.el\\(\\.gz\\)?$")))
          (with-temp-buffer
            ;; run through the list of .el files
            ;; start with the "primary" .el file, returned by =find-library-name=

            (goto-char (point-min))
            (insert (format "\n* file %s (primary)\n" library-path))
            (insert (concat "#+begin" "_src emacs-lisp\n"))
            (insert-file library-path)
            (goto-char (point-max))
            (insert (concat "\n#+end" "_src\n"))
            (when FULL
              (dolist (file (remove library-path all-elisp))
                (insert (format "\n* file %s\n" file))
                (insert (concat "#+begin" "_src emacs-lisp\n"))
                (insert-file file)
                (goto-char (point-max))
                (insert (concat "\n#+end" "_src\n"))))
            (buffer-string)))
      (warn "PACKAGE must be the package name as a string.")))

  (gptel-make-tool
   :name "emacs_package_source"
   :description "Fetch all source code for the given Emacs package, using `find-library'."
   :category "emacs"
   :include nil
   :function #'local/extract-emacs-package-source
   :args (list '(:name "package_name"
                       :type string
                       :description "Name of the Emacs package."
                       :optional nil)
               '(:name "full_source"
                       :type boolean
                       :description "If true/t, return source from ALL source code files in the package, not just the primary source file. Let this default in most cases to save on tokens!"
                       :optional t))))

(with-eval-after-load 'gptel
  (defun local/extract-function-source (function-name)
    "Extract and return the source code of a callable FUNCTION-NAME, if possible."
    (when (fboundp (intern function-name))
      (let ((source))
        (condition-case err
            ;; `find-function-noselect' returns the buffer and position.
            (let ((buf-pos (find-function-noselect (intern function-name))))
              (when buf-pos
                (let ((buffer (car buf-pos))
                      (pos (cdr buf-pos)))
                  (with-current-buffer buffer
                    (save-excursion
                      (goto-char pos)
                      (let ((start (point)))
                        ;; Move to the end of the function definition.
                        (end-of-defun)
                        ;; Extract source code.
                        (setq source (buffer-substring-no-properties start (point)))))))))
          (error
           ;; Handle errors gracefully by printing a message.
           (message "Error finding source for %s: %s" function-name (error-message-string err))))
        source)))

  ;; Usage example
  ;; (my-extract-callable-source 'your-function-name)

  (gptel-make-tool
   :name "emacs_function_source"
   :include t
   :function #'local/extract-function-source
   :description "Return source code for Emacs functions, be they written in Emacs Lisp (Elisp) or C"
   :category "emacs"
   :args (list '(:name "function_name"
                       :type string
                       :description "the function name"
                       :optional nil))))

(with-eval-after-load 'gptel
  (get 'gptel-tools 'variable-documentation)

  (gptel-make-tool
   :name "emacs_variable_properties"
   :include t
   :function (lambda (variable)
               (let ((variable (if (symbolp variable)
                                   variable
                                 (intern variable)
                                 )))
                 (if (boundp variable)
                     (symbol-plist variable)
                   (format "Variable %s is not bound" variable))))

   :description "Get properties on an Emacs variable.  Use this to get documentation string for variables, as well as more obscure properties such as safety as local variable etc."
   :category "emacs"
   :args (list '(:name "variable"
                       :type string
                       :description "the symbol"))))

(with-eval-after-load 'gptel
  (defun local/get-info-manuals-with-description ()
    "Return text of all Info manuals with their simple descriptions.
This is what you see when you evoke C-h i or run (info)."
    (with-temp-buffer
      (Info-insert-dir)
      (buffer-substring-no-properties (point-min) (point-max))))

  (gptel-make-tool
   :name "emacs_info_manuals"
   :include nil
   :function #'local/get-info-manuals-with-description
   :description "Get text showing all known Info manuals with their description. Format is human-readable manual name, info manual short file name in parens, description."
   :category "emacs"))

(with-eval-after-load 'gptel
  (defun local/list-linux-man-pages (&optional s)
    "Return text showing installed Linux man pages with descriptions - optionally provide a substring match to limit the number of results."
    (let ((s (or s ""))
          (shell-command-dont-erase-buffer nil))
      (with-current-buffer "*man-pages*"
        (delete-region (point-min) (point-max))
        (shell-command (format "LANG=en_US.UTF-8 /usr/bin/man -k \"%s\"" s) t)
        (buffer-string)
        )))

  (gptel-make-tool
   :name "list_man_pages"
   :description "Return list of installed Linux man pages with descriptions - optionally provide a substring match to limit the number of results."
   :include nil
   :function #'local/list-linux-man-pages
   :category "emacs"
   :args (list '(:name "search_substring"
                       :type string
                       :optional t
                       :description "A substring to limit results of all man pages.  e.g. \"media\" or \"office\""))))

(with-eval-after-load 'gptel
  (gptel-make-tool
   :name "org_mode_cheatsheet"
   :description "Quick and easy to read cheat sheet for Org Mode syntax - refer to this whenever you start a project or session requiring org mode syntax production, and whenver you want to make use of advanced features."
   :include t
   :function (lambda ()
               (with-temp-buffer
                 (insert-file-contents "~/pers/ai-prompts/org-mode-syntax-cheat-sheet-for-llms.txt")
                 (buffer-string)))
   :category: "emacs"))

(use-package mcp
  :ensure t
  :demand t
  :after gptel
  :custom (mcp-hub-servers
           `(("clj" .
              (:command "clojure"
               :args ("-Sdeps",
               (concat "{:deps"
                       " {"
                       " org.slf4j/slf4j-nop {:mvn/version \"2.0.16\"}"
                       " com.bhauman/clojure-mcp {:git/url \"https://github.com/bhauman/clojure-mcp\" :git/sha \""
                       "89feeb0be877e06e129aa84ce16522f8b0a36c38" ; mcp sha code
                       "\"}}"
                       " :aliases {:mcp {:exec-fn clojure-mcp.main/start-mcp-server}}}"),
                "-X:mcp",
                ":port",
                "7888")))
             ("github" .
               (:command "docker"
                :args ("run" "-i" "--rm"
                         "-e" "GITHUB_PERSONAL_ACCESS_TOKEN"
                         "ghcr.io/github/github-mcp-server")
                :env (:GITHUB_PERSONAL_ACCESS_TOKEN ,(lambda () (auth-source-pass-get 'secret "github.com/personal-api-key")))))
              ("duckduckgo" . (:command "uvx" :args ("duckduckgo-mcp-server")))
              ("nixos" . (:command "nix" :args ("run" "github:utensils/mcp-nixos" "--")))
              ("fetch" . (:command "uvx" :args ("mcp-server-fetch")))
              ("filesystem" . (:command "npx" :args ("-y" "@modelcontextprotocol/server-filesystem" ,(getenv "HOME"))))
              ("sequential-thinking" . (:command "npx" :args ("-y" "@modelcontextprotocol/server-sequential-thinking")))
             ))
  :config (require 'mcp-hub))

(defun get-ai-prompt (filename)
      (with-temp-buffer
        (insert-file-contents filename)
        (buffer-string)))

(with-eval-after-load 'gptel
  (gptel-make-preset 'introspect
    :pre (lambda () (require 'ragmacs))
    :system (get-ai-prompt (expand-file-name "introspection.md" gptel-prompts-directory))
    :tools '("introspection")))

(with-eval-after-load 'gptel
  (gptel-make-preset 'ollama
    :description "ollama"
    :pre (lambda () (require 'llm-tool-collection))
    :backend "Ollama"
    :model 'gpt-oss:latest
    :highlight-mode 't
    :confirm-tool-calls 'auto
    :include-tool-results 't)
  )

(with-eval-after-load 'gptel
  (gptel-make-preset 'elisp
    :description "helper for elisp"
    :pre (lambda () (progn
            (require 'llm-tool-collection)
            (require 'ragmacs)))
    :backend "Ollama"
    :model 'gpt-oss:latest
    :system "You are an Emacs maven. Reply only with the most appropiate built-in Emacs or cl-lib command for the task I specify. Do NOT generate any additional details or comments."
    :tools '("emacs" "introspection")
    :confirm-tool-calls nil
    :include-reasoning nil                ;sets gptel-include-reasoning
    :include-tool-results nil)
  )

(with-eval-after-load 'gptel
  (gptel-make-preset 'codex
    :description "local coding agent"
    :pre (lambda () (require 'llm-tool-collection))
    :backend "Ollama"
    :model 'qwen2.5-coder:latest
    :system "You are Codex, a highly capable coding agent. Help the user
write correct, idiomatic, well-structured code. When asked to implement
something, think step by step, consider edge cases, and provide complete
solutions. Use the available tools to search, read, and understand the
codebase before making changes."
    :highlight-mode 't
    :confirm-tool-calls 'auto
    :include-tool-results 't)
  )

(use-package gptel-agent
  :ensure t
  :after gptel
  :config (gptel-agent-update))         ;Read files from agents directories

(use-package eca
  :ensure t
  :demand t
  :config
  (setq eca-extra-args '("--verbose")))

(with-eval-after-load 'gptel
  ;; modele de llm: TranslateGemma:4b llama3.1:8b
  (defcustom local/translate-llm "TranslateGemma:4b"
    "LLM for translations."
    :type 'string
    :group 'ai)

  (defun local/translate (replace)
    "Automatically translate between RO and EN using Ollama.
With a prefix (C-u), replace the selected region."
    (interactive "P")
    (if (use-region-p)
        (let* ((text (buffer-substring-no-properties (region-beginning) (region-end)))
               (system-msg "You are a professional translator. The text is in Romanian and translate it to English.  Provide ONLY the English translation, no chatter.")
               ;; Setăm modelul aici
               (gptel-model local/translate-llm)
               (gptel-backend (gptel-get-backend "Ollama")))
          (gptel-request text
            :system system-msg
            :callback (lambda (response info)
                        (if response
                            (with-current-buffer (plist-get info :buffer)
                              (delete-region (region-beginning) (region-end))
                              (insert response))
                          (message "Error: %s" info)))))
    (message "Please select a text first!"))))

(defcustom local/response-format
  (concat "Format all the response exclusively in org-mode syntax\n"
          "- Use titles with asterisks (*, **, ***).\n"
          "- Use code blocks like " (format "#+begin%src clojure ... #+end%src" "_" "_") " for examples.\n"
          "- Use Org tables for performance comparisons if applicable.\n"
          "- Put keywords between tildes (~code~).")
  "Fragment of the system prompt to format the response."
  :type 'string
  :group 'ai)

(use-package agent-shell
  :ensure t
  :demand t
  :vc (:url "https://github.com/xenodium/agent-shell")
  :config
  (setq agent-shell-google-authentication
      (agent-shell-google-make-authentication :login t))
  (setq agent-shell-prefer-viewport-interaction t))

(with-eval-after-load 'transient
  (transient-define-prefix local/ai-menu ()
    "ai menu"
    [["agent-shell"
      ("aa" "agent" agent-shell)
      ("ad" "add-dwim" agent-shell-send-dwim)
      ("ae" "edit prompt" agent-shell-prompt-compose)
      ("af" "add file" agent-shell-send-file)
      ("ar" "add-region" agent-shell-send-region)]
      ["gptel"
      ("d" "add" gptel-add)
      ("f" "add file" gptel-add-file)
      ("u" "main" gptel)
      ("m" "menu" gptel-menu)
      ;; ("o" "org prop" gptel-org-set-properties)
      ("q" "quit" gptel-abort)
      ("r" "rewrite" gptel-rewrite)
      ("s" "send" gptel-send)
      ;; ("t" "topic" gptel-org-set-topic)
      ]
     ["mcp"
      ("ps" "start" mcp-hub-start-all-server)
      ("pc" "connect" gptel-mcp-connect)
      ("po" "close" mcp-hub-close-all-server)
      ("pl" "log" mcp-hub-view-log)]]))

(use-package pdf-tools
  :ensure t
  :demand t
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  ;; Activează pdf-tools. :no-query evită întrebările despre compilare pe NixOS
  (pdf-tools-install :no-query)
  ;; Opțional: afișează PDF-ul adaptat lățimii paginii implicit
  (setq-default pdf-view-display-size 'fit-page)
  (setq pdf-annot-activate-created-annotations t)
  (define-key pdf-view-mode-map (kbd "G") 'pdf-view-goto-page)
  (define-key pdf-view-mode-map (kbd "!") 'pdf-view-position-to-register)
  (define-key pdf-view-mode-map (kbd "@") 'pdf-view-jump-to-register))

  (use-package elfeed
    :ensure t
    :demand t
    :custom
    (elfeed-db-directory
     (expand-file-name "elfeed" emacs-cache-dir))
     (elfeed-show-entry-switch 'display-buffer))

  (use-package elfeed-org
    :ensure t
    :demand t
    :config
    (elfeed-org)
    :custom
    (rmh-elfeed-org-files (list (expand-file-name "elfeed.org" local/private-dir))))

(use-package direnv
  :ensure t
  :demand t
  :config
  (direnv-mode))

(customize-set-variable 'whitespace-action '(auto-cleanup))
(add-hook 'before-save-hook 'whitespace-cleanup)

(use-package eldoc
  :demand t
  :config
  (global-eldoc-mode)
  (keymap-set help-map "k" #'eldoc-doc-buffer))

(use-package helpful
  :ensure t
  :demand t
  :bind
  (:map help-map
        ("h" . helpful-at-point)
        ("C" . helpful-command)
        ("M" . helpful-macro)))

(use-package devdocs
  :ensure t
  :bind
  (:map goto-map ("K" . devdocs-lookup)))

(electric-pair-mode 1) ; auto-insert matching bracket

(show-paren-mode 1)    ; turn on paren match highlighting
(customize-set-variable 'show-paren-when-point-inside-paren t)
(customize-set-variable 'show-paren-when-point-in-periphery t)
(add-hook 'prog-mode-hook 'show-paren-mode)
(setq show-paren-context-when-offscreen t)

(use-package rainbow-delimiters
  :ensure t
  :vc (:url "https://github.com/Fanael/rainbow-delimiters")
  :demand t
  ;; :commands rainbow-delimiters-mode
  :custom (rainbow-delimiters-max-face-count 5)
  :config
  (add-hook 'prog-mode-hook  'rainbow-delimiters-mode))

(use-package highlight-indent-guides
  :ensure t
  :demand t
  :hook (prog-mode . highlight-indent-guides-mode)
  :custom
  (highlight-indent-guides-method 'character) ; use characters for indent guidesg
  (highlight-indent-guides-responsive t); highlight indentation based on current line
  (highlight-indent-guides-character ?\|); set character
  (highlight-indent-guides-auto-enabled 'top))

(use-package aggressive-indent
  :ensure t
  :config
  ;; (global-aggressive-indent-mode 1)
  (add-to-list 'aggressive-indent-excluded-modes 'python-mode)
  (add-to-list 'aggressive-indent-excluded-modes 'python-ts-mode)
  )

(use-package compile
  :custom (compilation-scroll-output t))

(use-package treesit-auto
  :ensure t
  :demand t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))


(dolist (mapping
           '((bash-mode . bash-ts-mode)
             (c++-mode . c++-ts-mode)
             (c-mode . c-ts-mode)
             (conf-toml-mode . toml-ts-mode)
             (css-mode . css-ts-mode)
             (css-mode . css-ts-mode)
             (go-mode . go-ts-mode)
             (html-mode. html-ts-mode)
             (js-json-mode . json-ts-mode)
             (js2-mode . js-ts-mode)
             (json-mode . json-ts-mode)
             (python-mode . python-ts-mode)
             (rust-mode . rust-ts-mode)
             (typescript-mode . typescript-ts-mode)
             (yaml-mode . yaml-ts-mode)))
    (add-to-list 'major-mode-remap-alist mapping))

(setq treesit-extra-load-path
      (list (expand-file-name "tree-sitter" user-emacs-directory)
            ;; Adaugă calea din profilul tău Nix (valabil pentru Home Manager sau System)
            "/run/current-system/sw/lib/tree-sitter"
            "~/.nix-profile/lib/tree-sitter"))

(defun run-non-ts-hooks ()
  (let ((major-name (symbol-name major-mode)))
    (when (string-match-p ".*-ts-mode" major-name)
      (run-hooks (intern (concat (replace-regexp-in-string "-ts" "" major-name) "-hook"))))))

(add-hook 'prog-mode-hook 'run-non-ts-hooks)
(setq treesit-font-lock-level 4)

(use-package hideshow
  :ensure nil
  :functions
  (hs-fold-overlay-ellipsis)
  :hook
  (prog-mode . hs-minor-mode)
  :init
  (setq hs-hide-comments-when-hiding-all nil)
  (setq hs-allow-nesting t)
  (setq hs-set-up-overlay #'hs-fold-overlay-ellipsis)
  :config
  (defun hs-fold-overlay-ellipsis (ov)
    (when (eq 'code (overlay-get ov 'hs))
      (overlay-put
       ov 'display (propertize " … " 'face 'font-lock-comment-face))))
  (defun local/toggle-fold ()
    (interactive)
    (save-excursion
      (end-of-line)
      (hs-toggle-hiding)))
  (defun local/hide-level ()
    (interactive)
    (hs-hide-level 1)))

(use-package fold-dwim
  :ensure t
  :demand t
  :config
  (global-set-key (kbd "<f8>")      'fold-dwim-toggle)
  (global-set-key (kbd "<M-f8>")    'fold-dwim-hide-all)
  (global-set-key (kbd "<S-M-f8>")  'fold-dwim-show-all))

(use-package flycheck
  :ensure t
  :demand t
  :commands (flycheck-previous-error
             flycheck-next-error
             flycheck-first-error)
  :config
  (global-flycheck-mode)
  (setq-default flycheck-disabled-checkers '(org-lint)))

(use-package apheleia
  :ensure t
  :demand t
  :config
  ;; 1. Define the elisp-autofmt command for Apheleia
  ;; We use 'inplace' or 'stdout' flags if the tool supports them
  (setf (alist-get 'elisp-autofmt apheleia-formatters)
        '("elisp-autofmt" "--stdin" "--stdout"))

  ;; 2. Map the major mode to our new formatter
  (setf (alist-get 'emacs-lisp-mode apheleia-mode-alist) 'elisp-autofmt)
(dolist (formatter '((nix . ("nix" "fmt" "--" "-"))
                       (xmllint . ("xmllint" "--format" "-"))
                       (rufo . ("rufo" "--simple-exit"))))
    (cl-pushnew formatter apheleia-formatters :test #'equal))
  (apheleia-global-mode +1))

(add-to-list 'safe-local-variable-values '(apheleia-formatter . treefmt))

(add-hook 'prog-mode-hook 'display-line-numbers-mode)

(use-package xref
  :commands
  (xref-show-definitions-completing-read)
  :bind
  (:map goto-map ("o" . xref-find-definitions-other-window))
  :config
  (setq xref-search-program 'ripgrep)
  (remove-hook 'xref-backend-functions #'etags--xref-backend))

(use-package etags
  :init
  (setq tags-add-tables nil))

(use-package dumb-jump
  :ensure t
  :hook
  (xref-backend-functions . dumb-jump-xref-activate)
  :init
  (setq dumb-jump-default-project user-emacs-directory)
  (setq dumb-jump-selector 'completing-read))

(with-eval-after-load 'transient
  (transient-define-prefix local/jump-menu ()
      "jump menu"
      [("a" "apropos" xref-find-apropos)
       ("b" "back" xref-go-back)
       ("d" "definition" xref-find-definitions)
       ("g" "first-error" flycheck-first-error)
       ("j" "next-ref" xref-next-line)
       ("k" "prev-ref" xref-prev-line)
       ("r" "references" xref-find-references)
       ;; ("p" "prev-error" flymake-goto-prev-error)
       ("p" "prev-error" flycheck-previous-error)
       ("o" "open" org-open-at-point)
       ;; ("n" "next-error" flymake-goto-next-error)
       ("n" "next-error" flycheck-next-error)
       ("N" "ns" cider-find-ns)]))

(use-package lsp-mode
    :ensure t
    :demand t
    :hook (lsp-mode . lsp-enable-which-key-integration)
    :config
    ;; (add-hook 'prog-mode-hook
    ;;         (lambda ()
    ;;           (unless (derived-mode-p 'emacs-lisp-mode)
    ;;             (lsp-deferred))))
    )

(use-package lsp-ui
    :ensure t
    :demand t)
;; (use-package lsp-treemacs
;;     :ensure t)
;; (lsp-treemacs-sync-mode 1)
(use-package consult-lsp
    :ensure t)
(with-eval-after-load 'transient
  (transient-define-prefix local/lsp-menu ()
    "lsp menu"
    [["Server"
      ("l" "start" lsp)
      ("sd" "disconnect" lsp-disconnect)
      ("sh" "describe session" lsp-describe-session)
      ("sq" "quit" lsp-workspace-shutdown)
      ("sr" "restart" lsp-workspace-restart)]
     ["Format"
      ("==" "buffer" lsp-format-buffer)
      ("=r" "region" lsp-format-region)]
     ["Toggles"
      ("td" "ui doc-mode" lsp-ui-doc-mode)
      ("tf" "type formating" lsp-toggle-on-type-formatting)
      ("th" "type highlight" lsp-toggle-symbol-highlight)
      ("ti" "log io" lsp-toggle-trace-io)
      ("tn" "signature" lsp-toggle-signature-auto-activate)
      ("ts" "sideline" lsp-ui-sideline-mode)
      ;; ("tt" "treemacs" lsp-treemacs-sync-mode)
      ("tu" "ui-mode" lsp-ui-mode)
      ]
     ["Jump"
      ("j/" "search project" consult-lsp-symbols)
      ("j?" "search local" consult-lsp-file-symbols)
      ("ja" "apropos" xref-find-apropos)
      ("jd" "declaration" lsp-find-declaration)
      ;; ("je" "error list" lsp-treemacs-errors-list)
      ("jj" "definition" lsp-find-definition)
      ("jJ" "peek definitions" lsp-ui-peek-find-definitions)
      ;; ("jh" "hierarchy" lsp-treemacs-call-hierarchy)
      ("ji" "implementation" lsp-find-implementation)
      ("jI" "peek implementations" lsp-ui-peek-find-implementation)
      ("jr" "references" lsp-find-references)
      ("jR" "peek references" lsp-ui-peek-find-references)
      ("jt" "type def" lsp-find-type-definition)
      ("jS" "peek workspace symbol" lsp-ui-peek-find-workspace-symbol)]
     ["Help"
      ("hg" "glance symbol" lsp-ui-doc-glance)
      ("hh" "thing at point" lsp-describe-thing-at-point)
      ("hs" "signature" lsp-signature-activate)]
     ["Refactor"
      ("ro" "organize imports" lsp-organize-imports)
      ("rr" "rename" lsp-rename)]
     ["Action"
      ("aa" "code actions" lsp-execute-code-action)
      ("ah" "highlight symbol" lsp-document-highlight)
      ]]))

(require 'project)
(setq project-list-file (expand-file-name "projects" emacs-cache-dir))
(setq project-switch-commands 'project-dired)

(defun local/mynew ()
  "Create PROJECT layout based on one of my templates."
  (interactive)
  (let ((template (completing-read "Template: "
                                   '( "cljproj" "default" "lpyproj" "pyproj"))))
    (shell-command (format "nix flake init --refresh -t git+https://github.com/dpom/mynixpkgs#%s" template))))

(with-eval-after-load 'transient
  (transient-define-prefix local/project-menu ()
    "project menu"
    [("/" "search" consult-git-grep)
     ("b" "switch to buffer" project-switch-to-buffer)
     ("f" "find file" project-find-file)
     ;; ("j" "load state" project-x-window-state-load)
     ("k" "kill buffers" project-kill-buffers)
     ("n" "new" local/mynew)
     ("p" "switch" project-switch-project)
     ("r" "replace" project-query-replace-regexp)
     ;; ("w" "save state" project-x-window-state-save)
     ]))

(use-package just-mode
  :ensure t
  :demand t
  :mode "justfile")

(defun local/display-image-from-file (temp-file)
  "Citește imaginea dintr-un fișier temporar și o afișează."
  (let* ((buffer-name "*Steno Preview*")
         (buffer (get-buffer-create buffer-name))
         (img (create-image temp-file nil nil))) ; nil la început înseamnă că e cale de fișier
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert-image img)
        (image-mode)))
    (display-buffer buffer '((display-buffer-reuse-window
                             display-buffer-at-bottom)))))

(use-package helpful
  :ensure t
  :demand t
  :config
    (global-set-key [remap describe-command] #'helpful-command)
    (global-set-key [remap describe-key] #'helpful-key))

  (use-package elisp-lint
      :ensure t)

(use-package elisp-autofmt
  :ensure t
  :demand t
  :vc (:url "https://github.com/emacsmirror/elisp-autofmt")
  :commands (elisp-autofmt-mode elisp-autofmt-buffer))

(use-package erk
  :ensure nil)

(with-eval-after-load 'gptel

  (defcustom local/elisp-review-llm 'qwen2.5-coder:32b
    "LLM for elisp coder review."
    :type 'symbol
    :group 'ai)

  (gptel-make-preset 'elisp-review
    :description "preset for elisp review"
    :pre (lambda () (progn
                      (require 'llm-tool-collection)
                      (require 'ragmacs)))
    :backend "Ollama"
    :model 'local/elisp-review-llm
    :system 'elisp-expert2
    :highlight-mode 't
    :stream 't
    :temperature 1.0
    :tools '("emacs" "introspection")
    :confirm-tool-calls 'auto
    :include-tool-results 't
    :include-reasoning 't)
  )

(defun local/review-elisp ()
  "Review the current Emacs Lisp region or defun using gptel."
  (interactive)
  (let* ((bounds (if (use-region-p)
                     (cons (region-beginning) (region-end))
                   (bounds-of-thing-at-point 'defun)))
         (code (when bounds (buffer-substring-no-properties (car bounds) (cdr bounds)))))
    (unless bounds
      (user-error "No code found at point to review"))
    (let* ((prompt (format "@elisp-review You are an Emacs Lisp expert. Please review the following code for:
1. Logic errors or bugs.
2. Performance improvements.
3. Idiomatic Elisp style (use of built-ins, cl-lib, or dash).
4. Documentation and naming clarity.

Code:
```elisp
%s
```
%s
" code local/response-format))
               (gptel-model  local/elisp-review-llm)
               (gptel-backend (gptel-get-backend "Ollama")))
      (gptel-request prompt
        :callback (lambda (response info)
                    (if response
                        (with-current-buffer (get-buffer-create "*Elisp Review*")
                          (erase-buffer)
                          (org-mode)
                          (insert response)
                          (display-buffer (current-buffer)))
                      (message "Error: %s" info)))))))

(with-eval-after-load 'transient
  (transient-define-prefix local/elisp-menu ()
  "elisp menu"
  [["Eval"
    ("eb" "buffer"
     eval-buffer)
    ("ef" "function" eval-defun)
    ("ee" "last sexp" eval-last-sexp)
    ("em" "macro" emacs-lisp-macroexpand)
    ("er" "region" eval-region)]
   ["Project"
    ("pf" "find" erk-find)
    ("pj" "jump" erk-jump-defs)
    ("pm" "manual" erk-preview-manual)
    ("pp" "reload project" erk-reload-project-package)
    ("pr" "readme" erk-preview-readme)
    ("pt" "reload tests" erk-reload-project-tests)]
   ["Tools"
    ("=" "check parens" check-parens)
    ("'" "jump source" org-edit-src-exit)
    ;; ("f" "format" elisp-autofmt-buffer)
    ("r" "ielm" ielm)
    ("t" "test" ert)
    ("j" "jump" local/jump-menu)
    ("u" "ai review" local/review-elisp)]]))

(use-package flycheck-clj-kondo
  :ensure t
  :demand t)

(use-package clojure-mode
  :ensure t
  :mode
   "\\.\\(clj\\|edn\\|bb\\|ply\\)\\'"
   ("\\.cljc\\'" . clojurec-mode)
   ("\\.cljs\\'" . clojurescript-mode)
  :custom
  (clojure-indent-style 'align-arguments)
  (clojure-indent-keyword-style 'align-arguments)
  :config
  ;; (setq lsp-clojure-custom-server-command '("bash" "-c" "clojure-lsp"))
  (require 'flycheck-clj-kondo)
  (cl-pushnew '("src/\\([^/]+\\)\\.clj\\'" "test/\\1_test.clj") find-sibling-rules :test #'equal)
  (cl-pushnew '("test/\\([^/]+\\)_test\\.clj\\'" "src/\\1.clj") find-sibling-rules :test #'equal))
;; (add-to-list 'major-mode-remap-alist '(clojure-mode . clojure-mode)) ; for clojure files default is clojure-mode

(use-package ob-clojure
  :ensure nil
  :after org
  :demand t
  :config
  (add-to-list 'org-babel-load-languages '(clojure . t)))

(use-package clojure-ts-mode
  :ensure nil
  :vc (:url "https://github.com/clojure-emacs/clojure-ts-mode")
  :mode "\\.\\(clj\\|cljs\\|cljc\\|edn\\|bb\\|ply\\)\\'"
  :custom
  (clojure-ts-indent-style 'semantic)
  (clojure-ts-comment-macro-font-lock-body nil)
  (clojure-ts-toplevel-inside-comment-form t)
  :config
  (setopt clojure-ts-auto-remap t)
  ;; (require 'flycheck-clj-kondo)
  )
(add-to-list 'major-mode-remap-alist '(clojure-mode . clojure-ts-mode)) ; for clojure files default is clojure-mode
(setq clojure-verify-major-mode nil)

(use-package cider
  :ensure t
  :demand t
  :hook
  ;; (clojure-ts-mode . cider-mode)
  (clojure-mode . cider-mode)
  :custom
  (cider-inject-jack-in-dependencies-at-jack-in t)
  (cider-overlays-use-font-lock t)
  (cider-preferred-build-tool 'clojure-cli)
  (cider-repl-buffer-size-limit 100000)
  (cider-repl-display-help-banner nil)
  (cider-repl-display-in-current-window nil)
  (cider-repl-pop-to-buffer-on-connect nil)
  (cider-repl-result-prefix ";; => ")
  (cider-repl-use-pretty-printing t)
  (cider-switch-to-repl-on-insert nil)
  (nrepl-use-ssh-fallback-for-remote-hosts t)
  :config
  (with-eval-after-load 'popper
    (cl-pushnew 'cider-test-report-mode popper-reference-buffers :test #'equal))
  (defun local/kit-reset ()
    (interactive)
    (cider-insert-in-repl "(reset)" t))

  (defun local/cider-tap-last-and-show-debugger ()
    (interactive)
    (cider-interactive-eval "(tap> *1)")
    (shell-command "i3-msg '[title=\"Flowstorm debugger\"] scratchpad show'"))

  (defun local/clj-dev-tool-bench ()
    (interactive)
    (let* ((current-ns (cider-current-ns))
           (form (cider-last-sexp))
           (clj-cmd (format "(do (require 'criterium.core) (criterium.core/quick-bench %s))" form)))
      (cider-interactive-eval clj-cmd nil nil `(("ns" ,current-ns)))))

  (defun local/clj-dev-tool-profile ()
    (interactive)
    (let* ((current-ns (cider-current-ns))
           (form (cider-last-sexp))
           (clj-cmd (format "(do (require 'clj-async-profiler.core) (clj-async-profiler.core/profile %s))" form)))
            (cider-interactive-eval clj-cmd nil nil `(("ns" ,current-ns)))
            (shell-command "xdg-open \"file:///tmp/clj-async-profiler/results/\""))))

(with-eval-after-load 'apheleia
  (setf (alist-get 'cljfmt apheleia-formatters)
        '("cljfmt" "fix" file))
  (setf (alist-get 'clojure-mode apheleia-mode-alist) 'cljfmt))

    (defvar cljtest-error-regexp
    '(cljtest "FAIL in (.+) (\\(.+\\):\\([0-9,]+\\))" 1 2))
    (defvar kibit-error-regexp
    '(kibit "At \\(.+\\):\\([0-9,]+\\):" 1 2))
    (defvar eastwood-error-regexp
    '(eastwood "Directory: \\(.+\\)" 1))
    (defvar kondo-error-regexp
    '(kondo "\\(.+\\):\\([0-9,]+\\):" 1 2))

    (with-eval-after-load 'compile
    (add-to-list 'compilation-error-regexp-alist-alist cljtest-error-regexp)
    (add-to-list 'compilation-error-regexp-alist 'cljtest)

    (add-to-list 'compilation-error-regexp-alist-alist kibit-error-regexp)
    (add-to-list 'compilation-error-regexp-alist 'kibit)

    (add-to-list 'compilation-error-regexp-alist-alist kondo-error-regexp)
    (add-to-list 'compilation-error-regexp-alist 'kondo)

    (add-to-list 'compilation-error-regexp-alist-alist eastwood-error-regexp)
    (add-to-list 'compilation-error-regexp-alist 'eastwood))

  (add-to-list 'safe-local-variable-values
              '(org-babel-clojure-backend . cider))
  (add-to-list 'safe-local-variable-values
                '(cider-lein-parameters . "shadow-srv :headless :host localhost"))
  (add-to-list 'safe-local-variable-values
              '(cider-ns-refresh-after-fn . "integrant.repl/resume"))
  (add-to-list 'safe-local-variable-values
              '(cider-ns-refresh-before-fn . "integrant.repl/suspend"))

    (use-package html-to-hiccup
        :ensure t
      ;; :init
      ;; (local/vc-install :repo "dpom/html-to-hiccup")
    :commands html-to-hiccup-convert-region)

(defun local/clerk-show ()
  (interactive)
  (when-let
      ((filename
        (buffer-file-name)))
    (save-buffer)
    (cider-interactive-eval
     (concat "(nextjournal.clerk/show! \"" filename "\")"))))

(use-package clay
  :ensure t
  :demand t)

(with-eval-after-load 'gptel

  (defcustom local/clojure-review-llm 'deepseek-coder:6.7b
    "LLM for clojure coder review."
    :type 'symbol
    :group 'ai)

  (gptel-make-preset 'clojure-review
    :description "preset for clojure review"
    :backend "Ollama"
    :model 'local/clojure-review-llm
    :system 'clojure-expert
    :highlight-mode 't
    :stream 't
    :temperature 1.0
    :confirm-tool-calls 'auto
    :include-tool-results 't
    :include-reasoning 't)

  (defun local/review-clojure ()
    "Send the Clojure code from the region or buffer to Ollama for code review.
Interactive usage: Mark a region and invoke this command; otherwise, it will process the entire buffer."
    (interactive)
    (let ((gptel-backend (gptel-get-backend "Ollama"))
          (gptel-model local/clojure-review-llm)
          (system-msg (concat "You are a functional programming and Clojure expert.
Analyze the following code and provide suggestions regarding:
1. Idiomaticity (correct use of core functions, threading macros -> and ->>).
2. Performance (avoiding reflection, proper use of lazy sequences).
3. Clarity and style (naming, structure)." local/response-format)))
      (gptel-request
          (if (use-region-p)
              (buffer-substring-no-properties (region-beginning) (region-end))
            (buffer-substring-no-properties (point-min) (point-max)))
        :system system-msg
        :callback (lambda (response info)
                    (if response
                        (with-current-buffer (get-buffer-create "*Clojure Review*")
                          (let ((inhibit-read-only t))
                            (erase-buffer)
                            (org-mode)
                            (insert "* Code Review Clojure\n\n")
                            (insert response)
                            (display-buffer (current-buffer))))
                      (message "Eroare la obținerea review-ului: %s" info))))))

  (defun local/generate-clojure-tests ()
    "Generează teste unitare pentru funcția Clojure selectată (sau buffer) folosind Ollama."
    (interactive)
    (let ((gptel-backend (gptel-get-backend "Ollama"))
          (gptel-model local/clojure-review-llm)
           (system-msg (concat
                        "Ești un expert în testare Clojure.\n"
                        "Analizează codul sursă și generează un set complet de teste unitare folosind `clojure.test`.\n"
                        "Reguli:\n"
                        "1. Include cazuri de succes (happy path) și cazuri de eroare (edge cases).\n"
                        "2. Dacă funcția este pură, folosește `is (= ...)` intensiv.\n"
                        "3. Formatează totul în Org-mode cu blocuri "
                        (format "#+begin%src clojure." "_") "\n"
                        "4. Explică pe scurt ce testează fiecare caz folosind subtitluri Org-mode (*).")))
      (gptel-request
          (if (use-region-p)
              (buffer-substring-no-properties (region-beginning) (region-end))
            (buffer-substring-no-properties (point-min) (point-max)))
        :system system-msg
        :callback (lambda (response info)
                    (if response
                        (with-current-buffer (get-buffer-create "*Clojure Tests*")
                          (let ((inhibit-read-only t))
                            (erase-buffer)
                            (org-mode)
                            (insert "#+TITLE: Unit Tests Generated\n\n")
                            (insert response)
                            (display-buffer (current-buffer))))
                      (message "Eroare la generare: %s" info)))))))

;; (require 'cider)
;; (use-package cljstyle-format
;;     :ensure t)

(with-eval-after-load 'transient
  (transient-define-prefix local/clojure-menu ()
  "clojure menu"
  [["Eval"
    ("ea" "all" cider-load-all-project-ns)
    ("eb" "buffer" cider-load-buffer)
    ("ee" "form before cursor" cider-eval-last-sexp)
    ("e;" "comment eval form" cider-pprint-eval-last-sexp-to-comment)
    ("eE" "print eval form" cider-pprint-eval-last-sexp)
    ("ef" "top level" cider-eval-defun-at-point)
    ("ei" "interrupt" cider-interrupt)
    ;; ("em" "macro" cider-macroexpand-1)
    ("en" "ns" cider-eval-ns-form)
    ("er" "region" cider-eval-region)]
   ["Help"
    ;; ("ha" "apropos" cider-apropos)
    ;; ("hc" "classpath" cider-classpath)
    ("he" "inspect last res" cider-inspect-last-result)
    ("hh" "doc" cider-doc)
    ("hj" "javadoc" cider-javadoc)
    ("hn" "namespace" cider-browse-ns)
    ;; ("hr" "reference book" clojure-essential-ref)
    ("hs" "spec" cider-browse-spec)]
   ["REPL"
    ("rc" "connect" cider-connect-clj)
    ("re" "inspect last eval" cider-inspect-last-result)
    ;; ("rd" "clear" cider-clear-repl-buffer)
    ("rj" "jack in" cider-jack-in)
    ("rh" "info" sesman-info)
    ("rx" "exit" sesman-quit)
    ("rs" "switch" cider-switch-to-repl-buffer)
    ("rt" "tap" local/cider-tap-last-and-show-debugger)
    ;; ("rl" "reload" cider-ns-reload)
    ("kr" "reset" local/kit-reset)]
   ["Test"
    ("ta" "all tests" cider-test-run-project-tests)
    ("tn" "namespace tests" cider-test-run-ns-tests)
    ("tt" "test at point" cider-test-run-test)
    ("tu" "generate tests" local/generate-clojure-tests)]
   ["Clay"
    ("cc" "save clay" clay-make-ns-html)
    ("ce" "eval" clay-make-last-sexp)
    ("cs" "start clay" clay-start)]
   ["Tools"
    ("SPC" "align" clojure-align)
    ("=" "check parens" check-parens)
    ("'" "jump source" org-edit-src-exit)
    ("u" "ai review" local/review-clojure)
    ("b" "benchmarks" local/clj-dev-tool-bench)
    ;; ("c" "clerk" local/clerk-show)
    ("f" "format" apheleia-format-buffer)
    ("l" "lsp" local/lsp-menu)
    ("p" "profile" local/clj-dev-tool-profile)
    ("j" "jump" local/jump-menu)]])
  )

    (use-package yaml-mode
      :ensure t
      :mode "\\.ya?ml\\'")

(with-eval-after-load 'transient
  (transient-define-prefix local/yaml-menu ()
  "yaml menu"
  [("'" "jump source" org-edit-src-exit)
   ;; ("l" "lsp" local/lsp-menu)
   ("j" "jump" local/jump-menu)]))

(use-package js2-mode
  :ensure t
  :mode "\\.jsx?\\'"
  :custom (js2-mode-show-strict-warnings nil)
  :config
  (defun local/set-js-indentation ()
    (setq-default js-indent-level 2)
    (setq-default tab-width 2))

  ;; Use js2-mode for Node scripts
  (add-to-list 'magic-mode-alist '("#!/usr/bin/env node" . js2-mode))
  ;; Don't use built-in syntax checking

  (add-hook 'local/set-js-indentation 'js2-imenu-extras-mode)
  (add-hook 'json-mode-hook 'local/set-js-indentation))

(use-package json-mode
  :ensure t
  :mode "\\.json\\'"
  :config
  (defun local/json-array-of-numbers-on-one-line (encode array)
    "Prints the arrays of numbers in one line."
    (let* ((json-encoding-pretty-print
            (and json-encoding-pretty-print
                 (not (cl-loop for x across array always (numberp x)))))
           (json-encoding-separator (if json-encoding-pretty-print "," ", ")))
      (funcall encode array)))
  (advice-add 'json-encode-array :around #'local/json-array-of-numbers-on-one-line))

    ;; get json path
    (use-package json-snatcher
        :ensure t)

(use-package json-reformat
  :ensure t)

(with-eval-after-load 'transient
  (transient-define-prefix local/js-menu ()
  "js menu"
  [("'" "jump source" org-edit-src-exit)
   ("f" "format" json-reformat-region)
   ("l" "lsp" local/lsp-menu)
   ("j" "jump" local/jump-menu)
   ("s" "snatch" jsons-print-path)]))

    (use-package vterm
      :ensure t
    :custom (vterm-max-scrollback 10000))

    (require 'sh-script)
    (add-hook 'after-save 'executable-make-buffer-file-executable-if-script-p)

(with-eval-after-load 'org
  (add-to-list 'org-babel-load-languages '(shell . t)))

    (use-package emacsql
        :ensure t)

    (defun upcase-sql-keywords ()
      (interactive)
    (save-excursion
        (dolist (keywords sql-mode-postgres-font-lock-keywords)
        (goto-char (point-min))
        (while (re-search-forward (car keywords) nil t)
            (goto-char (+ 1 (match-beginning 0)))
            (when (eql font-lock-keyword-face (face-at-point))
            (backward-char)
            (upcase-word 1)
            (forward-char))))))

    (use-package sqlformat
      :ensure t
      :config
      (setq sqlformat-command 'pgformatter)
      (setq sqlformat-args '("-s2" "-g")))

  (defun remove-trailing-newline (point)
  (if (= (char-before point) ?\n)
      (- point 1)
      point))

  (defun local/sql-format (start end)
  "Formats the selected sql `sqlformat'"
  (interactive "r")
  (shell-command-on-region
  ;; beginning and end of buffer
  start
  (remove-trailing-newline end)
  ;; command and parameters
  "sqlformat -k upper -r -s -"
  ;; output buffer
  (current-buffer)
  ;; replace?
  t
  ;; name of the error buffer
  "*Sqlformat Error Buffer*"
  ;; show error buffer?
  t))

    (put 'sql-product 'safe-local-variable #'symbolp)
    (put 'sql-sqlite-login-params 'safe-local-variable (lambda (_) t))

(with-eval-after-load 'transient
  (transient-define-prefix local/sql-menu ()
  "sql menu"
  [["Eval"
    ("eb" "buffer" sql-send-buffer)
    ("ee" "string" sql-send-string)
    ("ef" "paragraf" sql-send-paragraph)
    ("er" "region" sql-send-region)]
   ["Help"
    ("ha" "all" sql-list-all)
    ("ht" "table" sql-list-table)]
   ["REPL"
    ("rc" "connect" sql-product-interactive)
    ("rs" "switch" sql-show-sqli-buffer)
    ]
   ["Tools"
    ("'" "jump source" org-edit-src-exit)
    ("f" "format" sqlformat)
    ;; ("l" "lsp" local/lsp-menu)
    ("j" "jump" local/jump-menu)]]))

(use-package request
  :ensure t
  :demand t)

(use-package web-mode
  :ensure t
  :mode "(\\.\\(html?\\|ejs\\|tsx\\|jsx\\)\\'"
  :custom
  (web-mode-code-indent-offset 2)
  (web-mode-markup-indent-offset 2)
  (web-mode-attribute-indent-offset 2)
  (web-mode-enable-css-colorization t)
  (web-mode-enable-auto-pairing t))

;; 1. Start the server with `httpd-start'
;; 2. Use `impatient-mode' on any buffer
(use-package skewer-mode
    :ensure t)
(use-package impatient-mode
    :ensure t)
(use-package rainbow-mode
  :ensure t
  :demand t
  :config
  (dolist (hook '(css-mode-hook
                  html-mode-hook
                  org-mode))
    (add-hook hook (lambda () (rainbow-mode t)))) )

(use-package web-beautify
    :ensure t)

(with-eval-after-load 'transient
  (transient-define-prefix local/html-menu ()
  "html menu"
  [("'" "jump source" org-edit-src-exit)
   ("f" "format" web-beautify-html)
   ("i" "impatient" impatient-mode)
   ("j" "jump" local/jump-menu)
   ;; ("l" "lsp" local/lsp-menu)
   ("s" "start server" httpd-start)]))

(use-package lsp-tailwindcss
  :ensure t
  :init
  (setq lsp-tailwindcss-add-on-mode t))

(use-package restclient
  :ensure t)

(use-package ob-restclient
  :ensure t
  :config
  (add-to-list 'org-babel-load-languages '(restclient . t)))

(use-package ob-http
  :ensure t
  :config
  (add-to-list 'org-babel-load-languages '(http . t)))

;; (use-package company-restclient
;;   :ensure t)

;; (with-eval-after-load 'cape
;;     (add-to-list 'completion-at-point-functions
;;                  (cape-company-to-capf #'company-restclient)))

    (with-eval-after-load 'restclient
    (defun restclient-get-var (var-name)
        (let ((buf-name (buffer-name (current-buffer)))
            (buf-point (point)))
        (restclient-get-var-at-point var-name buf-name buf-point)))

    (defun restclient-elisp-result-function (args offset)
        (goto-char offset)
        (let ((form (read (current-buffer))))
        (lambda ()
            (eval form)))))

(use-package python
  :demand t
  :mode ("\\.py\\'" . python-mode)
  :init
  (add-to-list 'major-mode-remap-alist '(python-mode . python-mode))
  :custom
  (python-indent-guess-indent-offset-verbose nil)
  (python-shell-completion-native-enable nil)
  :config
  (defun local/python-shell-send-line ()
    "Send the current line to shell"
    (interactive)
    (let ((python-mode-hook nil)
          (start (point-at-bol))
          (end (point-at-eol)))
      (python-shell-send-region start end)))
  (defun local/python-shell-send-buffer ()
    "Send buffer content to shell and switch to it in insert mode."
    (interactive)
    (let ((python-mode-hook nil))
      (python-shell-send-buffer)))

  (defun local/python-shell-send-region (start end)
    "Send region content to shell and switch to it in insert mode."
    (interactive "r")
    (let ((python-mode-hook nil))
      (python-shell-send-region start end)))

  (defun local/python-format-buffer ()
    "Bind possible python formatters."
    (interactive)
    (pcase python-formatter
      ('yapf (yapfify-buffer))
      ('black (blacken-buffer))
      (code (message "Unknown formatter: %S" code))))

  (defun local/python-eval-print-last-sexp ()
    "Print result of evaluating current line into current buffer."
    (interactive)
    (let ((res (python-shell-send-string-no-output
                ;; modify to get a different sexp
                (buffer-substring (line-beginning-position)
                                  (line-end-position))))
          (standard-output (current-buffer)))
      (when res
        (terpri)
        (princ res)
        (terpri))))
  )

(use-package poetry
 :ensure t)

    (put 'python-shell-interpreter 'safe-local-variable #'stringp)

(use-package py-vterm-interaction
  :hook (python-mode . py-vterm-interaction-mode)
  :hook (python-ts-mode . py-vterm-interaction-mode)
  :config
  ;;; Suggested:
  (setq-default py-vterm-interaction-repl-program "ipython")
  (setq-default py-vterm-interaction-silent-cells t)
  )

(with-eval-after-load 'transient
  (transient-define-prefix local/python-menu ()
  "python menu"
  [["Eval"
    ;; ("eb" "buffer" local/python-shell-send-buffer)
    ;; ("ee" "line" local/python-shell-send-line)
    ;; ("e;" "line" local/python-eval-print-last-sexp)
    ;; ("er" "region" local/python-shell-send-region)
    ("eb" "buffer" py-vterm-interaction-send-buffer)
    ("ee" "line" py-vterm-interaction-send-region-or-current-line)
    ]
   ["Help"
    ("ha" "all" python-describe-at-point)]
   ["REPL"
    ;; ("rj" "run" run-python)
    ;; ("rs" "switch" python-shell-switch-to-shell)
    ("rs" "switch" py-vterm-interaction-switch-to-repl-buffer)
    ]
   ["Tools"
    ("'" "jump source" org-edit-src-exit)
    ("f" "format" local/python-format-buffer)
    ("j" "jump" local/jump-menu)
    ;; ("l" "lsp" local/lsp-menu)
    ("p" "poetry" poetry)]]))

(use-package nxml-mode
  :ensure nil
  :mode "\\.xml\\'"
  :config
  ;; (add-hook 'nxml-mode-hook #'lsp-deferred)
  ;; (remove-hook 'nxml-mode-hook #'lsp-deferred)

  (add-hook 'nxml-mode-hook (lambda() (hs-minor-mode 1)))
  (add-to-list 'hs-special-modes-alist
               '(nxml-mode
                 "<!--\\|<[^/>]*[^/]>" ;; regexp for start block
                 "-->\\|</[^/>]*[^/]>" ;; regexp for end block
                 "<!--"
                 nxml-forward-element
                 nil))
  (defun local/toggle-level ()
    "mainly to be used in nxml mode"
    (interactive)
    (hs-show-block)
    (hs-hide-level 1))
  (define-key nxml-mode-map "<mouse-3>" 'local/toggle-level))

(use-package ebnf-mode
    :ensure t
  :config
  (require 'ebnf2ps))

(defun local/c-settings ()
    (c-set-style "bsd")
    (setq indent-tabs-mode nil
          c-basic-offset 2))

(use-package cc-mode
  :ensure nil
  :config
  (add-hook 'c++-mode-hook #'local/c-settings))

(use-package arduino-mode
  :ensure t
  :mode ("\\.ino\\'" . arduino-mode)
  :config
  (add-hook 'arduino-mode-hook #'local/c-settings))

(use-package nix-mode
  :ensure t
  :mode ("\\.nix\\'" "\\.nix.in\\'"))

(use-package ob-nix
  :ensure t
  :after org
  :demand t
  :config
  (add-to-list 'org-babel-load-languages '(nix . t)))

(use-package nix-drv-mode
  :ensure nix-mode
  :mode "\\.drv\\'")

(use-package nix-shell
  :ensure nix-mode
  :commands (nix-shell-unpack nix-shell-configure nix-shell-build))

(use-package nix-repl
  :ensure nix-mode
  :commands (nix-repl))

;; (add-hook 'prog-mode-hook
;;           (lambda ()
;;             (add-hook 'before-save-hook 'eglot-format nil t)))

(with-eval-after-load 'eglot
  (dolist (mode '((nix-mode . ("nixd"))))
    (add-to-list 'eglot-server-programs mode)))

(use-package graphql-mode
    :ensure t)

(use-package ob-graphql
    :ensure t
    :after org
    :config
    (add-to-list 'org-babel-load-languages '(graphql . t)))

(use-package markdown-mode
  :ensure t
  :bind (:map markdown-mode-map
              ("C-c C-p" . local/markdown-preview)
              ("C-c '" . local/markdown-edit-mermaid))
  :config
  (setq markdown-command "marked")
  (dolist (face '((markdown-header-face-1 . 1.2)
                  (markdown-header-face-2 . 1.1)
                  (markdown-header-face-3 . 1.0)
                  (markdown-header-face-4 . 1.0)
                  (markdown-header-face-5 . 1.0)))
    (set-face-attribute (car face) nil :weight 'normal :height (cdr face)))
  (defun local/markdown-preview ()
    "Render the current Markdown buffer to HTML with mermaid diagrams and preview in eww."
    (interactive)
    (let* ((temp-dir (make-temp-file "md-preview-" t))
           (img-count 0)
           (md-file (expand-file-name "content.md" temp-dir))
           (html-file (expand-file-name "preview.html" temp-dir)))
      (write-region (point-min) (point-max) md-file nil 'silent)
      (with-temp-buffer
        (insert-file-contents md-file)
        (goto-char (point-min))
        (while (re-search-forward "^```mermaid[ \t]*\n" nil t)
          (let* ((opening-start (match-beginning 0))
                 (diagram-start (point))
                 (diagram-end (re-search-forward "^```[ \t]*$" nil t))
                 mmd-file img-file diagram exit-code)
            (unless diagram-end
              (user-error "Unclosed mermaid code block"))
            (cl-incf img-count)
            (setq mmd-file (format "%s/diagram-%d.mmd" temp-dir img-count)
                  img-file (format "%s/diagram-%d.png" temp-dir img-count)
                  diagram (buffer-substring-no-properties diagram-start
                                                          (- diagram-end 4)))
            (with-temp-buffer
              (insert diagram)
              (write-region (point-min) (point-max) mmd-file nil 'silent))
            (setq exit-code (call-process "mmdc" nil (get-buffer-create "*mmdc-errors*") nil
                                           "-i" mmd-file "-o" img-file "--scale" "2" "-q"))
            (if (not (and (eq exit-code 0) (file-exists-p img-file)))
                (user-error "mmdc failed (exit %d): %s" exit-code
                            (with-current-buffer "*mmdc-errors*" (buffer-string))))
            (kill-buffer "*mmdc-errors*")
            (delete-region opening-start (point))
            (insert (format "\n<img src=\"%s\">\n" img-file))))
        (write-region (point-min) (point-max) md-file nil 'silent))
      (let ((exit-code (call-process "pandoc" nil (get-buffer-create "*pandoc-errors*")
                                     nil md-file "-o" html-file "-s")))
        (if (not (and (eq exit-code 0) (file-exists-p html-file)))
            (user-error "pandoc failed (exit %d): %s" exit-code
                        (with-current-buffer "*pandoc-errors*" (buffer-string))))
        (kill-buffer "*pandoc-errors*"))
      (eww-open-file html-file)))
  (defvar-local local/markdown-edit-parent nil
    "Cons (PARENT-BUFFER . OPENING-LINE) for mermaid edit session.")
  (defun local/markdown-edit-mermaid ()
    "Edit the mermaid code block at point in a dedicated mermaid-mode buffer.
  In markdown-mode: extracts the block and opens it for editing.
  In mermaid-mode (edit buffer): saves content back and closes."
    (interactive)
    (if (derived-mode-p 'mermaid-mode)
        (local/mermaid-edit-done)
      (local/markdown-edit-mermaid-start)))
  (defun local/markdown-edit-mermaid-start ()
    "Open mermaid code block at point in a new mermaid-mode buffer."
    (let* ((orig (point))
           (open-pos (and (derived-mode-p 'markdown-mode)
                          (save-excursion
                            (re-search-backward "^```mermaid[ \t]*\n" nil t))))
           bounds)
      (unless open-pos
        (user-error "Point is not in a mermaid code block"))
      (save-excursion
        (let* ((block-start (match-end 0))
               (open-line (line-number-at-pos (match-beginning 0))))
          (goto-char block-start)
          (let ((close-pos (re-search-forward "^```[ \t]*$" nil t)))
            (unless (and close-pos (<= block-start orig) (>= (point) orig))
              (user-error "Point is not in a mermaid code block"))
            (setq bounds (list open-line block-start (match-beginning 0))))))
      (let ((content (buffer-substring-no-properties (nth 1 bounds) (nth 2 bounds)))
            (parent-buffer (current-buffer))
            (edit-buffer (generate-new-buffer "*mermaid-edit*")))
        (with-current-buffer edit-buffer
          (mermaid-mode)
          (insert (string-trim-right content))
          (goto-char (point-min))
          (setq-local local/markdown-edit-parent
                      (cons parent-buffer (nth 0 bounds))))
        (switch-to-buffer-other-window edit-buffer)
        (message "Edit mermaid block. %s to save and return."
                 (substitute-command-keys "\\[local/markdown-edit-mermaid]")))))
  (defun local/mermaid-edit-done ()
    "Save mermaid edit buffer content back to the parent markdown buffer."
    (interactive)
    (unless local/markdown-edit-parent
      (user-error "Not editing a mermaid block"))
    (let* ((content (buffer-string))
           (parent-buffer (car local/markdown-edit-parent))
           (open-line (cdr local/markdown-edit-parent))
           (edit-buffer (current-buffer)))
      (with-current-buffer parent-buffer
        (save-excursion
          (goto-char (point-min))
          (forward-line (1- open-line))
          (if (looking-at "^```mermaid")
              (progn
                (forward-line)
                (let ((start (point)))
                  (re-search-forward "^```[ \t]*\n")
                  (delete-region start (point))
                  (insert (string-trim-right content))
                  (insert "\n```\n")))
            (user-error "Mermaid block no longer exists at line %d" open-line))))
      (kill-buffer edit-buffer)
      (switch-to-buffer parent-buffer)
      (message "Mermaid block updated"))))

(with-eval-after-load 'transient
  (transient-define-prefix local/markdown-menu ()
    "markdown menu"
    [("'" "edit mermaid block" local/markdown-edit-mermaid)
     ("v" "preview" local/markdown-preview)
     ("j" "jump" local/jump-menu)]))

(use-package which-key
  :ensure t
  :demand t
  :custom (which-key-sort-order 'which-key-prefix-then-key-order)
  :config
  (which-key-mode 1))

(use-package transient
  :ensure t
  :demand t
  :config
  (setq transient-default-level 5)
  (transient-bind-q-to-quit))

 (defun local/specific-menu-command ()
  "call different menus depending on what's current major mode."
  (interactive)
  (cond
   ((string-equal major-mode "org-mode") (local/org-menu))
   ((string-equal major-mode "clojure-mode") (local/clojure-menu))
   ((string-equal major-mode "clojurescript-mode") (local/clojure-menu))
   ((string-equal major-mode "clojurec-mode") (local/clojure-menu))
   ((string-equal major-mode "clojure-ts-mode") (local/clojure-menu))
   ((string-equal major-mode "emacs-lisp-mode") (local/elisp-menu))
   ((string-equal major-mode "python-mode") (local/python-menu))
   ((string-equal major-mode "python-ts-mode") (local/python-menu))
   ((string-equal major-mode "web-mode") (local/html-menu))
   ((string-equal major-mode "sql-mode") (local/sql-menu))
   ((string-equal major-mode "js-mode") (local/js-menu))
   ((string-equal major-mode "json-mode") (local/js-menu))
   ((string-equal major-mode "yaml-mode") (local/yaml-menu))
   ((string-equal major-mode "markdown-mode") (local/markdown-menu))
   ((string-equal major-mode "mermaid-mode") (local/mermaid-menu))

   ;; if nothing match, use generic prog menu
   (t (local/prog-menu))))
(define-key mode-specific-map "\\" 'local/specific-menu-command)
(keymap-global-set "C-." 'local/specific-menu-command)

(defun local/scratch-buffer ()
  "Open a new scratch buffer."
  (interactive)
  (switch-to-buffer "*scratch*"))

(with-eval-after-load 'transient
  (transient-define-prefix local/buffer-menu ()
    "buffer menu"
    [("b" "switch buffer" consult-buffer)
     ("B" "ibuffer" ibuffer)
     ("d" "kill current buffer" kill-this-buffer)
     ("f" "display popper" popper-toggle)
     ("j" "cycle popper" popper-cycle)
     ("k" "pick & kill" kill-buffer)
     ("K" "kill regexp buffers" kill-matching-buffers-no-ask)
     ("l" "list buffers" list-buffers)
     ("r" "rename buffer" rename-buffer)
     ("s" "open scratch" local/scratch-buffer)
     ("t" "toggle popper" popper-toggle-type)]))

(with-eval-after-load 'transient
  (transient-define-prefix local/prog-menu ()
    "prog menu"
    [("'" "jump source" org-edit-src-exit)
     ("l" "lsp" local/lsp-menu)
     ("f" "format" apheleia-format-buffer)
     ("j" "jump" local/jump-menu)]))

(with-eval-after-load 'transient
  (transient-define-prefix local/file-menu ()
    "file menu"
    [[("SPC" "locate" consult-locate)
      ("." "dir other window" dired-jump-other-window)
      ("/" "grep" local/search-in-files)
      ("a" "accounts" find-accounts)
      ("c" "contacts" find-contacts)]
     [("d" "dired" consult-dir)
      ("e" "emacs config" find-config)
      ("f" "find file" find-file)
      ("l" "find library" find-library)]
     [("n" "notebook" find-notebook)
      ("p" "at point" find-file-at-point)
      ("r" "recently opened files" consult-recent-file)
      ("s" "save file" save-buffer)
      ("w" "save as" write-file)]]))

(with-eval-after-load 'transient
  (transient-define-prefix local/git-menu ()
    "git menu"
    [("b" "blame" magit-blame)
     ("c" "clone" magit-clone )
     ("y" "status" magit-status)
     ("i" "init" magit-init )
     ("l" "log (current file)" magit-log-buffer-file)
     ("L" "log (project)" magit-log-current)
     ("t" "timemachine" git-timemachine)]))

(with-eval-after-load 'transient
(transient-define-prefix local/help-menu ()
  "help menu"
  [("a" "apropos" apropos)
   ("A" "apropos doc" apropos-documentation)
   ("b" "bindings" describe-bindings)
   ("f" "function" describe-function)
   ("k" "key" describe-key)
   ("m" "mode" describe-mode)
   ("n" "minor mode" describe-minor-mode)
   ("v" "variable" describe-variable)]))

(with-eval-after-load 'transient
  (transient-define-prefix local/toggle-menu ()
    "toggle menu"
    [["General"
      ("SPC" "whitespace mode" whitespace-mode)
      ("e" "debug on error" toggle-debug-on-error)
      ("f" "folding" hs-minor-mode)
      ;; ("f" "folding" treesit-fold-mode)
      ("q" "debug on quit" toggle-debug-on-quit)
      ("m" "minor modes" minions-minor-modes-menu)
      ("o" "set font" fontaine-set-preset)
      ("r" "read-only" read-only-mode)
      ("s" "font size" local/iw-set-font-size)
      ]
     ["Programming"
      ("p|" "indent guide" highlight-indent-guides-mode)
      ("pa" "aggresive indent" aggressive-indent-mode)
      ("pn" "line number" display-line-numbers-mode)
      ("pm" "smerge" smerge-mode)
      ;; ("pd" "side dir" dirvish-side)
      ]
     ["Writing"
      ("wi" "input method" set-input-method)
      ("wt" "truncate lines" toggle-truncate-lines)
      ("wy" "flyspel" flyspell-mode)]]))

(define-key mode-specific-map "'"  'org-capture)
(define-key mode-specific-map "+"  'local/translate)
(define-key mode-specific-map "-"  'sort-lines)
(define-key mode-specific-map "/"  'consult-line)
(define-key mode-specific-map "A"  'agent-shell)
(define-key mode-specific-map "C"  'calendar)
(define-key mode-specific-map "E"  'eshell)
(define-key mode-specific-map "M"  'mu4e)
(define-key mode-specific-map "O"  'org-clock-out)
(define-key mode-specific-map "R"  'elfeed)
(define-key mode-specific-map "S"  'local/start-task)
(define-key mode-specific-map "T"  'vterm)
(define-key mode-specific-map "W"  'pass)
(define-key mode-specific-map "a"  'local/agenda-menu)
(define-key mode-specific-map "b"  'local/buffer-menu)
(define-key mode-specific-map "d"  'local/date-iso)
(define-key mode-specific-map "f"  'local/file-menu)
(define-key mode-specific-map "i"  'consult-imenu)
(define-key mode-specific-map "j"  'local/jump-menu)
(define-key mode-specific-map "l"  'org-store-link)
(define-key mode-specific-map "n"  'local/notes-menu)
(define-key mode-specific-map "p"  'local/project-menu)
(define-key mode-specific-map "s"  'local/scratch-buffer)
(define-key mode-specific-map "t"  'local/toggle-menu)
(define-key mode-specific-map "u"  'local/ai-menu)
(define-key mode-specific-map "w"  'ace-window)
(define-key mode-specific-map "y"  'local/git-menu)
(define-key mode-specific-map "z"  'ent-run)

(let ((normal-keybindings '(("<escape>" "ignore") ("`" "local/surround") ("!" "bookmark-set") ("@" "bookmark-jump") ("#" "meow-comment") ("$" "repeat") ("%" "meow-query-replace") ("&" "meow-query-replace-regexp") ("'" "repeat") ("(" "meow-expand-1") (")" "meow-expand-2") ("*" "goto-last-change") ("+" "meow-expand-4") ("/" "meow-search") ("=" "indent-region") ("?" "meow-cheatsheet") ("[" "meow-beginning-of-thing") ("]" "meow-end-of-thing") ("{" "meow-expand-5") ("}" "meow-expand-3") ("\\" "local/specific-menu-command") (1 "meow-expand-1") (2 "meow-expand-2") (3 "meow-expand-3") (4 "meow-expand-4") (5 "meow-expand-5") (6 "meow-expand-6") (7 "meow-expand-7") (8 "meow-expand-8") (9 "meow-expand-9") (0 "meow-expand-0") ("-" "negative-argument") (";" "meow-reverse") ("," "meow-inner-of-thing") ("." "meow-bounds-of-thing") ("<" "meow-beginning-of-thing") (">" "meow-end-of-thing") ("a" "meow-append") ("A" "meow-open-below") ("b" "meow-back-word") ("B" "meow-back-symbol") ("c" "meow-change") ("d" "meow-delete") ("D" "meow-backward-delete") ("e" "meow-next-word") ("E" "meow-next-symbol") ("f" "meow-find") ("g" "meow-cancel-selection") ("G" "meow-grab") ("h" "meow-left") ("H" "meow-left-expand") ("i" "meow-insert") ("I" "meow-open-above") ("j" "meow-next") ("J" "meow-next-expand") ("k" "meow-prev") ("K" "meow-prev-expand") ("l" "meow-right") ("L" "meow-right-expand") ("m" "meow-join") ("n" "meow-search") ("o" "meow-block") ("O" "meow-to-block") ("p" "meow-yank") ("P" "meow-yank-pop") ("q" "meow-quit") ("Q" "meow-goto-line") ("r" "meow-replace") ("R" "meow-swap-grab") ("s" "meow-kill") ("t" "meow-till") ("u" "meow-undo") ("U" "meow-undo-in-selection") ("v" "meow-visit") ("w" "meow-mark-word") ("W" "meow-mark-symbol") ("x" "meow-line") ("X" "meow-goto-line") ("y" "meow-save") ("z" "meow-pop-selection")))
      (motion-keybindings '(("<escape>" "ignore") ("j" "meow-next") ("k" "meow-prev")))
      (leader-keybindings '((1 "meow-digit-argument") (2 "meow-digit-argument") (3 "meow-digit-argument") (4 "meow-digit-argument") (5 "meow-digit-argument") (6 "meow-digit-argument") (7 "meow-digit-argument") (8 "meow-digit-argument") (9 "meow-digit-argument") (0 "meow-digit-argument") ("?" "meow-keypad-describe-key") ("e" "dispatch: C-x C-e"))))
  (defun meow-setup ()
    (let ((parse-def (lambda (x)
                       (cons (format "%s" (car x))
                             (if (string-prefix-p "dispatch:" (cadr x))
                                 (string-trim (substring (cadr x) 9))
                               (intern (cadr x)))))))
      (apply #'meow-normal-define-key (mapcar parse-def normal-keybindings))
      (apply #'meow-motion-overwrite-define-key (mapcar parse-def motion-keybindings))
      (apply #'meow-leader-define-key (mapcar parse-def leader-keybindings))))
)

(use-package meow
  :ensure t
  :custom (meow-char-thing-table '((?\( . round)
                                   (?\[ . square)
                                   (?\{ . curly)
                                   (?\" . string)
                                   (?e . symbol)
                                   (?w . window)
                                   (?b . buffer)
                                   (?p . paragraph)
                                   (?l . line)
                                   (?v . visual-line)
                                   (?d . defun)
                                   (?. . sentence)))
  :config

  ;; custom indicator
  (setq meow-replace-state-name-list '((normal . "🅝")
                                       (beacon . "🅑")
                                       (insert . "🅘")
                                       (motion . "🅜")
                                       (keypad . "🅚")))

  ;; custom variables
  (setq meow-esc-delay 0.1)

  (meow-thing-register 'angle '(pair ("<")
                                     (">"))
                       '(pair ("<")
                              (">")))

  (add-to-list 'meow-char-thing-table '(?< . angle))

  (add-to-list 'meow-mode-state-list '(cargo-process-mode . motion))
  (add-to-list 'meow-mode-state-list '(emms-playlist-mode . motion))
  (add-to-list 'meow-mode-state-list '(agent-shell-mode . insert))
  (add-to-list 'meow-mode-state-list '(agent-shell-viewport-view-mode . motion))
  (add-to-list 'meow-mode-state-list '(agent-shell-viewport-edit-mode . insert))

  (meow-setup)
  (meow-setup-indicator)
  (meow-global-mode 1)
  )

(server-start)
