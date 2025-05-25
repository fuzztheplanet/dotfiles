;; Load custom configs
(if (file-readable-p (concat user-emacs-directory "skywhi.org"))
    (org-babel-load-file (concat user-emacs-directory "skywhi.org")))

(if (file-readable-p "~/org/perso/conf.org")
    (org-babel-load-file "~/org/perso/conf.org"))

(if (file-readable-p "~/org/work/conf.org")
    (org-babel-load-file "~/org/work/conf.org"))

(put 'downcase-region 'disabled nil)
