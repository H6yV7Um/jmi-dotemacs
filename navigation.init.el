;;; navigation.init.el -- Navigation and movement in Emacs

;;; Commentary:
;;; This configures a bunch of stuff I use for getting around my Emacs
;;; instance, including windmove (using a custom set of bindings) and
;;; projectile.  Also included is a bare helm config here, which I'll
;;; populate later on as I get used to using helm

;;; Code:

;; Helm:
(use-package helm-config
  :config
  (global-set-key (kbd "C-c h") 'helm-mini))

;; Side-effect: We use a bunch of Textmate-like bindings, so use
;; textmate-mode
(use-package textmate
  :config
  (textmate-mode)
  (define-key *textmate-mode-map* [(super /)] 'comment-or-uncomment-region-or-line))

;; Projectile
(use-package projectile
  :config
  (projectile-mode)

  (defun projectile-bind-cmd-t ()
    (define-key *textmate-mode-map* [(super t)] 'projectile-find-file))
  (add-hook 'textmate-mode-hook 'projectile-bind-cmd-t)
  (global-set-key [(super o)] 'projectile-switch-project))

(use-package helm-projectile
  :config
  (helm-projectile-toggle 0))

;; Window move via cmd-shift-arrow
(global-set-key [(super shift left)]  'windmove-left)
(global-set-key [(super shift right)] 'windmove-right)
(global-set-key [(super shift up)]    'windmove-up)
(global-set-key [(super shift down)]  'windmove-down)

;; Use Emacs session management
(use-package session
  :config
  (add-to-list 'session-globals-exclude 'org-mark-ring)
  :init (session-initialize))


;;; navigation.init.el ends here
