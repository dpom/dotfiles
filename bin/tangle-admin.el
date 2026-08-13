(require 'org)

;; Don't ask when evaluating code blocks
(setq org-confirm-babel-evaluate nil)


(let* ((bin-path (file-name-directory (directory-file-name (if load-file-name load-file-name buffer-file-name))))
       (admin-path (file-name-directory (directory-file-name bin-path)))
       (org-files (directory-files admin-path nil "\\.\\(org\\|txt\\)$")))
  (message "admin path: %s" admin-path)
  (dolist (org-file org-files)
    (unless (member (file-name-sans-extension org-file) '("README" "Notebook"))
      (message "\n\033[1;32mGenerating %s\033[0m\n" org-file)
      (org-babel-tangle-file (expand-file-name org-file admin-path)))))
