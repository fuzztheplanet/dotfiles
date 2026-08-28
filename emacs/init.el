;;; init.el --- Load the literate configuration  -*- lexical-binding: t -*-

;; The real configuration lives in skywhi.org. Its blocks are tangled into the
;; cache directory (a file-level `header-args' property in the .org sets the
;; target, so nothing is written next to the .org inside the dotfiles
;; repository), byte-compiled, and only re-tangled when the .org is newer.
;; Byte-compiling makes native compilation kick in and lets `auto-compile'
;; keep the .elc fresh.

(require 'ob-tangle)
(require 'bytecomp)

(defvar skw/d-cache
  (expand-file-name "emacs/" (or (getenv "XDG_CACHE_HOME") "~/.cache"))
  "Directory holding every piece of Emacs state (packages, history, …).")

(defun skw/load-org-config (org-file)
  "Tangle ORG-FILE into `skw/d-cache' and byte-compile it if needed, then load it."
  (when (file-readable-p org-file)
    (let* ((el-file (expand-file-name
                     (concat (file-name-base org-file) ".el") skw/d-cache))
           (elc-file (byte-compile-dest-file el-file)))
      (make-directory skw/d-cache t)
      (when (file-newer-than-file-p org-file el-file)
        (org-babel-tangle-file org-file nil "emacs-lisp"))
      (when (file-newer-than-file-p el-file elc-file)
        (byte-compile-file el-file))
      (load (file-name-sans-extension el-file)))))

(skw/load-org-config (expand-file-name "skywhi.org" user-emacs-directory))

;; Optional per-machine overlays. They live outside the dotfiles repository
;; and may rely on `load-file-name' (via `skw/get-file-directory'), so they
;; are tangled in place, next to their .org file.
(dolist (overlay '("~/org/perso/conf.org" "~/org/work/conf.org"))
  (when (file-readable-p overlay)
    (org-babel-load-file overlay)))

;;; init.el ends here
