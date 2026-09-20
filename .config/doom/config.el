;;; config.el -*- lexical-binding: t; -*-

;; Doctor Doom: Latverian green, steel, and gold. Plain JetBrains Mono has
;; native hinting; symbols stay on their dedicated Nerd Font face.
(setq doom-theme 'doctor-doom
      doom-font (font-spec :family "JetBrains Mono" :size 16 :weight 'medium)
      doom-big-font (font-spec :family "JetBrains Mono" :size 24 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "Noto Sans" :size 17)
      doom-serif-font (font-spec :family "Noto Serif" :size 17)
      doom-symbol-font (font-spec :family "Symbols Nerd Font Mono" :size 16)
      display-line-numbers-type 'relative
      confirm-kill-emacs nil
      fancy-splash-image nil
      +dashboard-banner-vertical-padding '(1 . 2))

(setq-default line-spacing 0.08)

(defun xtrmn8/doctor-doom-banner ()
  "Return a hooded, riveted Doctor Doom mask for Doom's dashboard."
  (propertize
   (string-join
    '("                    .-=================-."
      "                 .-'                     '-."
      "               .'          .-------.          '."
      "              /          .'  _____  '.          \\"
      "             /          / .-'     '-. \\          \\"
      "            ;          / /  o     o  \\ \\          ;"
      "            |         | | .---------. | |         |"
      "            |         | ||  [==] [==] || |         |"
      "            |         | ||      ^     || |         |"
      "            |         | ||     /|\\    || |         |"
      "            |         | ||    /_|_\\   || |         |"
      "            |         | ||   ._____.   || |         |"
      "            |         | ||   |||||||   || |         |"
      "            ;          \\||___|||||||___||/          ;"
      "             \\           \\_________/           /"
      "              '.        .-'         '-.        .'"
      "                '-.__.-'               '-.__.-'"
      "                   /_____________________\\"
      "                       DOCTOR  DOOM"
      "                  SOVEREIGN OF LATVERIA")
    "\n")
   'face '+dashboard-banner))

(setq +dashboard-ascii-banner-fn #'xtrmn8/doctor-doom-banner)

;; Fast escape from insert/replace state. Doom excludes terminals and sidebars,
;; so the chord never steals input from a shell.
(after! evil-escape
  (setq evil-escape-key-sequence "jk"
        evil-escape-delay 0.20))

;; Keep notes in one predictable place and record when tasks are completed.
(setq org-directory (expand-file-name "~/org/")
      org-agenda-files (list org-directory)
      org-log-done 'time)

;; ~/.git belongs to an unrelated home-directory setup. Ignore it when
;; Projectile searches upward so nested repositories remain independent.
(after! projectile
  (setq projectile-project-root-files-bottom-up
        (remove ".git" projectile-project-root-files-bottom-up)))

(after! org
  (setq org-hide-emphasis-markers t
        org-startup-indented t
        org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "WAIT(w@)" "|"
                                      "DONE(d!)" "CANCELLED(c@)"))))

;; These are intentionally memorable entry points for the included tutorial.
(map! :leader
      (:prefix ("o" . "open")
       :desc "Doom Emacs guide" "G" (cmd! (find-file "~/DOOM_EMACS_GUIDE.md"))
       :desc "Doom practice" "P" (cmd! (find-file "~/org/doom-practice.org"))))

;; High-frequency controls. C-h/j/k/l changes panes without a C-w prefix;
;; Alt plus the same directions resizes the current pane.
(map! :niv "C-h" #'evil-window-left
      :niv "C-j" #'evil-window-down
      :niv "C-k" #'evil-window-up
      :niv "C-l" #'evil-window-right
      :nv  "M-h" #'evil-window-decrease-width
      :nv  "M-j" #'evil-window-increase-height
      :nv  "M-k" #'evil-window-decrease-height
      :nv  "M-l" #'evil-window-increase-width
      :niv "C-s" #'save-buffer)

;; SPC ; is the speed layer: one stable prefix for the commands used all day.
(map! :leader
      (:prefix (";" . "speed")
       :desc "Command palette"       ";" #'execute-extended-command
       :desc "Project file"          "f" #'projectile-find-file
       :desc "Project search"        "/" #'+vertico/project-search
       :desc "Switch buffer"         "b" #'consult-buffer
       :desc "Save buffer"           "s" #'save-buffer
       :desc "Save all buffers"      "S" #'save-some-buffers
       :desc "Kill buffer"           "k" #'kill-current-buffer
       :desc "Jump anywhere"         "j" #'avy-goto-char-timer
       :desc "Git status"            "g" #'magit-status
       :desc "Terminal popup"        "t" #'+vterm/toggle
       :desc "Project tree"          "e" #'+treemacs/toggle
       :desc "Definition"            "d" #'xref-find-definitions
       :desc "References"            "D" #'xref-find-references
       :desc "Code action"           "a" #'eglot-code-actions
       :desc "Rename symbol"         "r" #'eglot-rename
       :desc "Diagnostics"           "x" #'flycheck-list-errors
       :desc "Compile project"       "c" #'projectile-compile-project
       :desc "Test project"          "T" #'projectile-test-project
       :desc "Practice workbook"     "p" (cmd! (find-file "~/org/doom-practice.org"))
       :desc "Edit Doom config"      "E" (cmd! (find-file (expand-file-name "config.el" doom-user-dir)))
       :desc "Speed key reference"   "?" (cmd! (find-file "~/DOOM_SPEED_KEYS.md"))))
