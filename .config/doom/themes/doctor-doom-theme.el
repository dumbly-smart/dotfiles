;;; doctor-doom-theme.el --- Doctor Doom theme -*- lexical-binding: t; no-byte-compile: t; -*-

(require 'doom-themes)

(defgroup doctor-doom-theme nil
  "A dark steel-and-Latverian-green theme for Doom Emacs."
  :group 'doom-themes)

(defcustom doctor-doom-padded-modeline 5
  "Padding for the armored modeline."
  :group 'doctor-doom-theme
  :type '(choice integer boolean))

(def-doom-theme doctor-doom
  "Doctor Doom's steel armor, green cloak, and Latverian gold."

  ;; name       default      256        16
  ((bg         '("#0b0e0c"  "#0b0e0c"  "black"))
   (fg         '("#d4d7d0"  "#d4d7d0"  "white"))
   (bg-alt     '("#111713"  "#111713"  "black"))
   (fg-alt     '("#8f9991"  "#8f9991"  "brightblack"))

   (base0      '("#070907"  "#070907"  "black"))
   (base1      '("#0e120f"  "#0e120f"  "black"))
   (base2      '("#151c17"  "#151c17"  "black"))
   (base3      '("#202a23"  "#202a23"  "brightblack"))
   (base4      '("#354139"  "#354139"  "brightblack"))
   (base5      '("#58625b"  "#58625b"  "brightblack"))
   (base6      '("#7d867f"  "#7d867f"  "brightblack"))
   (base7      '("#aab0ab"  "#aab0ab"  "white"))
   (base8      '("#eef0eb"  "#eef0eb"  "brightwhite"))

   (grey       base6)
   (red        '("#b44a50"  "#b44a50"  "red"))
   (orange     '("#c17a4b"  "#c17a4b"  "brightred"))
   (yellow     '("#d0af63"  "#d0af63"  "yellow"))
   (green      '("#83a36b"  "#83a36b"  "green"))
   (blue       '("#78969a"  "#78969a"  "blue"))
   (dark-blue  '("#57767b"  "#57767b"  "blue"))
   (teal       '("#65937c"  "#65937c"  "cyan"))
   (magenta    '("#a2788c"  "#a2788c"  "magenta"))
   (violet     '("#8b82a3"  "#8b82a3"  "brightmagenta"))
   (cyan       '("#8eb4aa"  "#8eb4aa"  "brightcyan"))
   (dark-cyan  '("#56796f"  "#56796f"  "cyan"))

   (highlight      green)
   (vertical-bar   base3)
   (selection      dark-cyan)
   (builtin        cyan)
   (comments       base6)
   (doc-comments   base7)
   (constants      yellow)
   (functions      green)
   (keywords       red)
   (methods        cyan)
   (operators      base7)
   (type           teal)
   (strings        yellow)
   (variables      fg)
   (numbers        orange)
   (region         selection)
   (error          red)
   (warning        yellow)
   (success        green)
   (vc-modified    yellow)
   (vc-added       green)
   (vc-deleted     red)

   (modeline-bg     "#1b2920")
   (modeline-bg-alt "#101511")
   (modeline-fg     base8)
   (modeline-fg-alt base6)
   (-modeline-pad
    (when doctor-doom-padded-modeline
      (if (integerp doctor-doom-padded-modeline) doctor-doom-padded-modeline 5))))

  ((default :background bg :foreground fg)
   (cursor :background green)
   (fringe :background bg :foreground base4)
   (hl-line :background base2)
   ((line-number &override) :foreground base4 :background bg)
   ((line-number-current-line &override) :foreground green :background base2 :weight 'bold)
   (region :background base4 :foreground base8 :distant-foreground base8)
   (vertical-border :foreground base3)
   (window-divider :foreground base3)
   (window-divider-first-pixel :foreground base3)
   (window-divider-last-pixel :foreground base3)

   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-alt :foreground modeline-fg-alt
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-alt)))
   (doom-modeline-bar :background green)
   (doom-modeline-buffer-file :foreground base8 :weight 'bold)
   (doom-modeline-buffer-path :foreground teal)
   (doom-modeline-buffer-major-mode :foreground green)

   (font-lock-comment-face :foreground comments :slant 'italic)
   (font-lock-doc-face :foreground doc-comments :slant 'italic)
   (show-paren-match :foreground base0 :background green :weight 'bold)
   (show-paren-mismatch :foreground base8 :background red :weight 'bold)
   (link :foreground cyan :underline t)

   (org-level-1 :foreground green :weight 'bold :height 1.28)
   (org-level-2 :foreground cyan :weight 'bold :height 1.18)
   (org-level-3 :foreground yellow :weight 'bold :height 1.10)
   (org-level-4 :foreground teal :weight 'semi-bold)
   (org-todo :foreground red :weight 'bold)
   (org-done :foreground green :weight 'bold)
   (org-block :background base1)
   (org-block-begin-line :foreground base6 :background base2)

   (vertico-current :background base3 :foreground base8 :weight 'bold)
   (corfu-current :background base3 :foreground base8 :weight 'bold)
   (treemacs-root-face :foreground green :weight 'bold :height 1.1)
   (+dashboard-banner :foreground green :weight 'bold)
   (+dashboard-menu-title :foreground green :weight 'bold)
   (+dashboard-menu-desc :foreground base7)
   (+dashboard-footer :foreground red)))

;;; doctor-doom-theme.el ends here
