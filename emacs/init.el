;;; init.el --- Load the literate configuration  -*- lexical-binding: t -*-

;; The real configuration lives in skywhi.org. It is tangled into the cache
;; directory (not next to the .org file, which is inside the dotfiles
;; repository) and only re-tangled when the .org file is newer.

(require 'org)

(defvar skw/tangle-dir
  (expand-file-name "emacs/" (or (getenv "XDG_CACHE_HOME") "~/.cache"))
  "Where tangled configuration files are written.")

(defun skw/load-org-config (org-file)
  "Tangle ORG-FILE into `skw/tangle-dir' if needed, then load it.
Blocks use `:tangle yes', which always tangles next to the .org file, so
the .org is first copied into `skw/tangle-dir' and tangled there."
  (when (file-readable-p org-file)
    (let* ((base (file-name-base org-file))
           (org-copy (expand-file-name (concat base ".org") skw/tangle-dir))
           (el-file (expand-file-name (concat base ".el") skw/tangle-dir)))
      (make-directory skw/tangle-dir t)
      (when (file-newer-than-file-p org-file el-file)
        (copy-file org-file org-copy t)
        (org-babel-tangle-file org-copy el-file "emacs-lisp"))
      (load-file el-file))))

(skw/load-org-config (expand-file-name "skywhi.org" user-emacs-directory))

;; Optional per-machine overlays. They live outside the dotfiles repository
;; and may rely on `load-file-name' (via `skw/get-file-directory'), so they
;; are tangled in place, next to their .org file.
(dolist (overlay '("~/org/perso/conf.org" "~/org/work/conf.org"))
  (when (file-readable-p overlay)
    (org-babel-load-file overlay)))

;;; init.el ends here
