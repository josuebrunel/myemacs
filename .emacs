

(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 ;;'(default ((t (:inherit nil :stipple nil :background "#234f32" :foreground "white" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 98 :width normal :foundry "unknown" :family "Monaco"))))
)

(set-default-font "Monaco 12")

(global-linum-mode 1) ;; Display line numbers in margin

(load-file "~/.emacs.d/emacs-for-python-master/epy-init.el")

;;LOADING COLOR-THEME
(add-to-list 'load-path "~/.emacs.d/color-theme/")
(require 'color-theme)
(color-theme-initialize)
(color-theme-calm-forest) ;; my current color-theme

;;LOADING PYTHON DJANGO TOOLS
(add-to-list 'load-path "~/.emacs.d/python-django/")
(require 'python-django)

;;LOADING GO-MODE
(add-to-list 'load-path "~/.emacs.d/go-mode/")
(require 'go-mode-load)

;;AUTO INSERT

