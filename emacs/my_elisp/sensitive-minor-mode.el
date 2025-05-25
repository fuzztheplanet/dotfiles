;; Taken from anirudhsasikumar.net/blog/2005.01.21.html <3
(provide 'sensitive-minor-mode)

(define-minor-mode sensitive-minor-mode
  "For sensitive files like password lists. It disables backup creation and auto-saving.
   With no argument, this command toggles the mode.
   Non-null prefix argument turns on the mode.
   Null prefix argument turns off the mode."

  ;; The initial value
  nil
  ;; The indicator for the modee line
  " Sensitive"
  ;; The minor mode bindings
  nil
  (if (symbol-value sensitive-minor-mode)
      (progn
	;; disable backups
	(set (make-local-variable 'backup-inhibited) t)
	;; disable auto-save
	(if auto-save-default
	  (auto-save-mode -1)))
    ; restore to default values
    (kill-local-variable 'backup-inhibited)
    (if auto-save-default
	(auto-save-mode 1))))

    

  
