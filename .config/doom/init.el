;;; init.el -*- lexical-binding: t; -*-

(doom! :completion
       (corfu +orderless)
       vertico

       :ui
       doom
       dashboard
       hl-todo
       indent-guides
       modeline
       ophints
       (popup +defaults)
       treemacs
       (vc-gutter +pretty)
       vi-tilde-fringe
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       snippets
       (whitespace +guess +trim)
       word-wrap

       :emacs
       dired
       electric
       ibuffer
       tramp
       undo
       vc

       :term
       eshell
       vterm

       :checkers
       syntax

       :tools
       editorconfig
       (eval +overlay)
       lookup
       (lsp +eglot)
       magit
       make
       tree-sitter

       :os
       tty

       :lang
       (cc +lsp +tree-sitter)
       data
       emacs-lisp
       (go +lsp +tree-sitter)
       json
       (javascript +lsp +tree-sitter)
       markdown
       org
       (python +lsp +pyright +tree-sitter)
       (rust +lsp +tree-sitter)
       sh
       web
       yaml

       :config
       (default +bindings +smartparens))
