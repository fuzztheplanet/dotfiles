;; org-archive-subtree-hierarchical.el
;;
;; version 0.2
;; modified from https://lists.gnu.org/archive/html/emacs-orgmode/2014-08/msg00109.html
;; modified from https://stackoverflow.com/a/35475878/259187

;; In orgmode
;; * A
;; ** AA
;; *** AAA
;; ** AB
;; *** ABA
;; Archiving AA will remove the subtree from the original file and create
;; it like that in archive target:

;; * AA
;; ** AAA

;; And this give you
;; * A
;; ** AA
;; *** AAA
;;
;; Install file to your include path and include in your init file with:
;;
;;  (require 'org-archive-subtree-hierarchical)
;;  (setq org-archive-default-command 'org-archive-subtree-hierarchical)
;;
(provide 'org-archive-subtree-hierarchical)
;; (require 'org-archive)

;; (defun org-archive-subtree-hierarchical--line-content-as-string ()
;;   "Returns the content of the current line as a string"
;;   (save-excursion
;;     (beginning-of-line)
;;     (buffer-substring-no-properties
;;      (line-beginning-position) (line-end-position))))

;; (defun org-archive-subtree-hierarchical--org-child-list ()
;;   "This function returns all children of a heading as a list. "
;;   (interactive)
;;   (save-excursion
;;     ;; this only works with org-version > 8.0, since in previous
;;     ;; org-mode versions the function (org-outline-level) returns
;;     ;; gargabe when the point is not on a heading.
;;     (if (= (org-outline-level) 0)
;;  (outline-next-visible-heading 1)
;;       (org-goto-first-child))
;;     (let ((child-list (list (org-archive-subtree-hierarchical--line-content-as-string))))
;;       (while (org-goto-sibling)
;;  (setq child-list (cons (org-archive-subtree-hierarchical--line-content-as-string) child-list)))
;;       child-list)))

;; (defun org-archive-subtree-hierarchical--org-struct-subtree ()
;;   "This function returns the tree structure in which a subtree
;; belongs as a list."
;;   (interactive)
;;   (let ((archive-tree nil))
;;     (save-excursion
;;       (while (org-up-heading-safe)
;;  (let ((heading
;;         (buffer-substring-no-properties
;;      (line-beginning-position) (line-end-position))))
;;    (if (eq archive-tree nil)
;;        (setq archive-tree (list heading))
;;      (setq archive-tree (cons heading archive-tree))))))
;;     archive-tree))

;; (defun org-archive-subtree-hierarchical ()
;;   "This function archives a subtree hierarchical"
;;   (interactive)
;;   (let ((org-tree (org-archive-subtree-hierarchical--org-struct-subtree))
;;  (this-buffer (current-buffer))
;;  (file (abbreviate-file-name
;;         (or (buffer-file-name (buffer-base-buffer))
;;         (error "No file associated to buffer")))))
;;     (save-excursion
;;       (setq location org-archive-location
;;      afile (car (org-archive--compute-location
;;                 (or (org-entry-get nil "ARCHIVE" 'inherit) location)))
;;      ;; heading (org-extract-archive-heading location)
;;      infile-p (equal file (abbreviate-file-name (or afile ""))))
;;       (unless afile
;;  (error "Invalid `org-archive-location'"))
;;       (if (> (length afile) 0)
;;    (setq newfile-p (not (file-exists-p afile))
;;      visiting (find-buffer-visiting afile)
;;      buffer (or visiting (find-file-noselect afile)))
;;  (setq buffer (current-buffer)))
;;       (unless buffer
;;  (error "Cannot access file \"%s\"" afile))
;;       (org-cut-subtree)
;;       (set-buffer buffer)
;;       (org-mode)
;;       (goto-char (point-min))
;;       (while (not (equal org-tree nil))
;;  (let ((child-list (org-archive-subtree-hierarchical--org-child-list)))
;;    (if (member (car org-tree) child-list)
;;        (progn
;;      (search-forward (car org-tree) nil t)
;;      (setq org-tree (cdr org-tree)))
;;      (progn
;;        (goto-char (point-max))
;;        (newline)
;;        (org-insert-struct org-tree)
;;        (setq org-tree nil)))))
;;       (newline)
;;       (org-yank)
;;       (when (not (eq this-buffer buffer))
;;  (save-buffer))
;;       (message "Subtree archived %s"
;;         (concat "in file: " (abbreviate-file-name afile))))))

;; (defun org-insert-struct (struct)
;;   "TODO"
;;   (interactive)
;;   (when struct
;;     (insert (car struct))
;;     (newline)
;;     (org-insert-struct (cdr struct))))

;; (defun org-archive-subtree ()
;;   (org-archive-subtree-hierarchical)
;;   )



(require 'dash)

(defadvice org-archive-subtree (around fix-hierarchy activate)
  (let* ((fix-archive-p (and (not current-prefix-arg)
                             (not (use-region-p))))
         (afile  (car (org-archive--compute-location
               (or (org-entry-get nil "ARCHIVE" 'inherit) org-archive-location))))
         (buffer (or (find-buffer-visiting afile) (find-file-noselect afile))))
    ad-do-it
    (when fix-archive-p
      (with-current-buffer buffer
        (goto-char (point-max))
        (while (org-up-heading-safe))
        (let* ((olpath (org-entry-get (point) "ARCHIVE_OLPATH"))
               (path (and olpath (split-string olpath "/")))
               (level 1)
               tree-text)
          (when olpath
            (org-mark-subtree)
            (setq tree-text (buffer-substring (region-beginning) (region-end)))
            (let (this-command) (org-cut-subtree))
            (goto-char (point-min))
            (save-restriction
              (widen)
              (-each path
                (lambda (heading)
                  (if (re-search-forward
                       (rx-to-string
                        `(: bol (repeat ,level "*") (1+ " ") ,heading)) nil t)
                      (org-narrow-to-subtree)
                    (goto-char (point-max))
                    (unless (looking-at "^")
                      (insert "\n"))
                    (insert (make-string level ?*)
                            " "
                            heading
                            "\n"))
                  (cl-incf level)))
              (widen)
              (org-end-of-subtree t t)
              (org-paste-subtree level tree-text))))))))
