;;; .ent.el --- local ent config file -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:


;; project settings
(setq ent-project-home (file-name-directory (if load-file-name load-file-name buffer-file-name)))
(setq ent-project-name "dotfiles")
(setq ent-clean-regexp ".*~$\\|.*sync-conflict.*$")
(setq org-files '("Config.txt" "Emacs.txt"))

(ent-load-default-tasks)

;; Aux functions

(defun file-parens-balanced-p (file)
  "Return t if FILE has matched parentheses, nil otherwise.
Returns nil if the file does not exist or is not readable."
  (when (and (stringp file) (file-readable-p file))
    (with-temp-buffer
      (insert-file-contents file)
      (condition-case nil
          (progn
            (goto-char (point-min))
            (check-parens)
            t)
        (error nil)))))


;; Tasks

(task "generate"
      :doc "Tangle dotfiles"
      :action (lambda ()
                (dolist (org-file org-files)
                  (ent-log* "- tangle %s" org-file)
                  (org-babel-tangle-file (expand-file-name org-file ent-project-home)))))


(task "verify-init"
      :doc "Check init.el file"
      :action (lambda ()
                (insert  (if (file-parens-balanced-p
                              (expand-file-name "init.el"
                                                (file-name-as-directory (file-name-concat ent-project-home "pkgs" "emacs"))))
                             "init file ok\n"
                           "init file with syntax error\n"))))


(task "lock"
      :doc "Generate emacs lock file"
      :action (concat "cd " ent-project-home "pkgs/emacs; nix run .#lock --impure -L"))


(task "check-emacs"
      :doc "Check generated emacs-config"
      :deps "generate verify-init lock"
      :action (concat  "cd "
                       ent-project-home
                       "pkgs/emacs; nix --show-trace run .#emacs-config -- --init-directory=. --debug-init"))

(task "update-inputs"
      :doc "Update flakes inputs"
      :deps "generate"
      :action "nix flake update")

(task "news"
      :doc "Read home-manager news"
      :action "home-manager news --flake . | cat")


(task "update-home"
      :doc "Run home-manager to generate a new version of home config"
      :deps "generate"
      :action "update-home")


(task "update-system"
      :doc "Run nix build to generate a new version of system config"
      :deps "generate"
      :action "update-system")

(task "nix-clean"
      :doc "Garbage collect in the nix repository"
      :action "df -h / && echo ' ' && nix-collect-garbage && echo ' ' && df -h /")


(provide '.ent)
;;; .ent.el ends here

;; Local Variables:
;; no-byte-compile: t
;; no-update-autoloads: t
;; End:
