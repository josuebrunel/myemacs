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
(color-theme-euphoria)

;;LOADING PYTHON DJANGO TOOLS
(add-to-list 'load-path "~/.emacs.d/python-django/")
(require 'python-django)

;;LOADING RUBY ENHANCED MODE
(add-to-list 'load-path "~/.emacs.d/enhanced-ruby-mode")
;;(add-hook 'enh-ruby-mode-hook 'robe-mode)
;;(add-hook 'enh-ruby-mode-hook 'yard-mode)
(autoload 'enh-ruby-mode "enh-ruby-mode" "Major mode for ruby files" t)
(add-to-list 'auto-mode-alist '("\\.rb$" . enh-ruby-mode))
(add-to-list 'interpreter-mode-alist '("ruby" . enh-ruby-mode))

;;LOADING GO-MODE
(add-to-list 'load-path "~/.emacs.d/go-mode/")
(require 'go-mode-load)

;;AUTO INSERT
