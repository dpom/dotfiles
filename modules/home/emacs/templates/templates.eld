fundamental-mode

(today (format-time-string "%Y-%m-%d"))
(hdr "#!/usr/bin/env bash" n)

prog-mode

(fixme (if (derived-mode-p 'emacs-lisp-mode) ";; " comment-start) "FIXME ")
(todo (if (derived-mode-p 'emacs-lisp-mode) ";; " comment-start) "TODO ")
(bug (if (derived-mode-p 'emacs-lisp-mode) ";; " comment-start) "BUG ")
(hack (if (derived-mode-p 'emacs-lisp-mode) ";; " comment-start) "HACK ")

emacs-lisp-mode

(advice "(defun " (p "adv" name) " (&rest app)" n> p n> "(apply app))" n> "(advice-add #'" (p "fun") " " (p ":around") " #'" (s name) ")")
(alias "(defalias '" p " '" p ")")
(aload "(with-eval-after-load '" p n> r> ")")
(andlet "(and-let* (" p ")" n> r> ")")
(autoload ";;;###autoload")
(command "(defun " p " (" p ")\n  \"" p "\"" n> "(interactive" p ")" n> r> ")")
(cond "(cond" n "(" q "))" >)
(const "(defconst " p "\n  \"" p "\")")
(custom "(defcustom " p "\n  \"" p "\"" n> ":type '" p ")")
(dolist "(dolist (" p ")" n> r> ")")
(dotimes "(dotimes (" p ")" n> r> ")")
(ent ";;; .ent.el --- local ent config file -*- lexical-binding: t; -*-" n n
     ";;; Commentary:" n n
     ";;; Code:" n n
     ";; project settings" n
     "(setq ent-project-home (file-name-directory (if load-file-name load-file-name buffer-file-name)))" n
     "(setq ent-project-name \"\")" n n
     "(ent-load-default-tasks)" n n
     ";; Aux functions" n n
     ";; Tasks" n n
     "(provide '.ent)" n
     ";;; .ent.el ends here" n n
     ";; Local Variables:" n
     ";; no-byte-compile: t" n
     ";; no-update-autoloads: t" n
     ";; End:")
(face "(defface " p " '((t :inherit " p "))\n  \"" p "\")")
(fun "(defun " p " (" p ")\n  \"" p "\"" n> r> ")")
(group "(defgroup " p " nil\n  \"" p "\"" n> ":group '" p n> ":prefix \"" p "-\")")
(header ";;; " (file-name-nondirectory (or (buffer-file-name) (buffer-name))) " -- " p " -*- lexical-binding: t -*-" n  ";;; Commentary:" n ";;; Code:" n n)
(iflet "(if-let* (" p ")" n> r> ")")
(let "(let (" p ")" n> r> ")")
(lett "(let* (" p ")" n> r> ")")
(local "(defvar-local " p "\n  \"" p "\")")
(loop "(cl-loop for " p " in " p " do" n> r> ")")
(macro "(defmacro " p " (" p ")\n  \"" p "\"" n> r> ")")
(pcase "(pcase " (p "scrutinee") n "(" q "))" >)
(pcaselet "(pcase-let (" p ")" n> r> ")")
(pcaselett "(pcase-let* (" p ")" n> r> ")")
(provide "(provide '" (file-name-base (or (buffer-file-name) (buffer-name))) ")" n  ";;; " (file-name-nondirectory (or (buffer-file-name) (buffer-name))) " ends here" n)
(pt "(point)")
(rec "(letrec (" p ")" n> r> ")")
(task "(task :" (p "task:") " '() \"\" \"\")" n)
(var "(defvar " p "\n  \"" p "\")")
(whenlet "(when-let* (" p ")" n> r> ")")
(whilelet "(while-let (" p ")" n> r> ")")

eshell-mode

(for " (p "i") " in " p " { " q " }")
(while "while { " " p " } { " q " }")
(until "until { " p " } { " q " }")
(if "if { " p " } { " q " }")
(ife "if { " p " } { " p " } { " q " }")
(unl "unless { " p " } { " q " }")
(unle "unless { " p " } { " p " } { " q " }")

nix-mode

(empty-sha256-hash "0000000000000000000000000000000000000000000000000000")
(empty-sri-hash "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
(fetchFromGitHub > "fetchFromGitHub {" n> "owner = \"" (p "owner" owner) "\";" n> "repo = \"" (p "repo" repo) "\";" n> "rev = \"" (p "rev" rev) "\";" n> "hash = \"" (p "hash" hash) "\";" n> "};")
(mkOption > "mkOption {" n> "type = " (p "type" type) ";" n> "default = " (p "default" default) ";" n> "description = \"" (p "description" description) "\";" n> "};")

org-mode

(center "#+begin_center" n> r> n> "#+end_center")
(clj "#+begin_src clojure" n> n> "#+end_src" :post (forward-line -1))
(comment "#+begin_comment" n> r> n> "#+end_comment")
(elisp "#+begin_src emacs-lisp " n> n> "#+end_src" :post (forward-line -1))
(example "#+begin_example" n> r> n> "#+end_example")
(img "#+ATTR_LaTeX: :width 0.8\textwidth :options keepaspectratio" n> "file:" p)
(plantuml "  #+begin_src plantuml :results verbatim" n "@startuml" n "@enduml" n> "#+end_src")
(quote "#+begin_quote" n> r> n> "#+end_quote")
(src "#+begin_src "
      (p (completing-read "Language: "
                               (mapcar #'symbol-name
                                       (mapcar #'car org-babel-load-languages)) nil nil))
      n> n> "#+end_src")
(title "#+title: " p n "#+author: " p n "#+language: " p n n)
(verse "#+begin_verse" n> r> n> "#+end_verse")
