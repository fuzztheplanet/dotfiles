;;; sensitive-minor-mode.el --- No backups for sensitive files  -*- lexical-binding: t -*-

;; Taken from anirudhsasikumar.net/blog/2005.01.21.html <3
;; Updated to the keyword form of `define-minor-mode'.

;;; Code:

;;;###autoload
(define-minor-mode sensitive-minor-mode
  "For sensitive files like password lists.
It disables backup creation and auto-saving in the current buffer.
With no argument, this command toggles the mode.  Non-null prefix
argument turns on the mode.  Null prefix argument turns off the mode."
  :init-value nil
  :lighter " Sensitive"
  :keymap nil
  (if sensitive-minor-mode
      (progn
        ;; disable backups
        (setq-local backup-inhibited t)
        ;; disable auto-save
        (when auto-save-default
          (auto-save-mode -1)))
    ;; restore to default values
    (kill-local-variable 'backup-inhibited)
    (when auto-save-default
      (auto-save-mode 1))))

(provide 'sensitive-minor-mode)
;;; sensitive-minor-mode.el ends here
