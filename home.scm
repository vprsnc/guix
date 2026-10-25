;; Guix Home: packages, dotfiles and user daemons.
;;
;;   guix home reconfigure ~/dotfiles/home.scm
;;
;; If reconfigure fails with "unknown package", run `guix search <name>`
;; and fix or drop that line.

(use-modules (gnu home)
             (gnu home services)
             (gnu home services desktop)
             (gnu home services gnupg)
             (gnu home services shells)
             (gnu home services shepherd)
             (gnu home services sound)
             (gnu home services syncthing)
             (gnu packages)
             (gnu services)
             (guix gexp))

;;; Packages

(define %emacs-packages
  '("emacs"
    ;; also in system.scm (for the LightDM session), but ~/.exwm can only
    ;; (require 'exwm) if it is on the home profile's EMACSLOADPATH
    "emacs-exwm"
    ;; ui
    "emacs-modus-themes" "emacs-ef-themes" "emacs-doric-themes"
    "emacs-mood-line" "emacs-all-the-icons"   ;breadcrumb: :vc
    "emacs-hide-mode-line" "emacs-visual-fill-column"
    ;; completion & editing
    "emacs-vertico" "emacs-marginalia" "emacs-consult" "emacs-corfu"
    "emacs-crux" "emacs-general" "emacs-modalka" "emacs-expand-region"
    "emacs-multiple-cursors" "emacs-move-text" "emacs-paredit"
    "emacs-smartparens" "emacs-rainbow-delimiters" "emacs-treesit-auto"
    ;; files & projects
    "emacs-dired-hacks"                     ;dired-hide-dotfiles: :vc
    "emacs-all-the-icons-dired" "emacs-projectile" "emacs-magit"
    "emacs-envrc" "emacs-bash-completion"   ;ghostel: :vc in config.org
    ;; org & notes
    "emacs-org-contrib" "emacs-org-superstar" "emacs-org-present"
    "emacs-org-roam" "emacs-org-pomodoro" "emacs-denote"
    "emacs-denote-journal"
    ;; guix
    "emacs-guix" "emacs-geiser" "emacs-geiser-guile"
    ;; dev
    "emacs-ess" "emacs-polymode" "emacs-poly-r" "emacs-polymode-markdown"
    "emacs-markdown-mode" "emacs-clojure-mode" "emacs-cider"
    "emacs-flycheck" "emacs-flycheck-clj-kondo" "emacs-docker"
    "emacs-yaml-mode" "emacs-web-mode" "emacs-restclient"
    "emacs-simple-httpd" "emacs-csv-mode"
    ;; reading
    "emacs-pdf-tools" "emacs-djvu" "emacs-nov"
    "emacs-fb2-reader"
    ;; ai
    "emacs-gptel" "emacs-agent-shell"
    ;; misc
    "emacs-password-store" "emacs-pass" "emacs-pinentry"
    "emacs-mentor" "emacs-telega"
    "mu"))

(define %tree-sitter-grammars
  '("tree-sitter-bash" "tree-sitter-python" "tree-sitter-clojure"
    "tree-sitter-r" "tree-sitter-json" "tree-sitter-html"
    "tree-sitter-css" "tree-sitter-javascript" "tree-sitter-markdown"))

(define %tools
  '("git" "mpv" "imagemagick" "qutebrowser"
    "uv" "python" "node"                ;node: Claude Code and squint (npm)
    ;; clojure; babashka, clj-kondo and clojure-lsp come from nonguix
    "openjdk:jdk" "clojure-tools" "babashka" "clj-kondo" "clojure-lsp"
    "ripgrep" "fd" "direnv" "password-store" "gnupg" "isync"
    "rust" "rust:cargo" "gcc-toolchain"  ;jieba builds its module with cargo
    "wireplumber" "brightnessctl" "xinput"
    "font-fira-code" "font-google-noto" "font-google-noto-sans-cjk"
    "font-google-noto-emoji"))

;;; Emacs: tangle emacs/config.org at build time

(define %emacs-config
  (computed-file
   "emacs-config"
   (with-imported-modules '((guix build utils))
     #~(begin
         (use-modules (guix build utils))
         (mkdir-p #$output)
         (chdir #$output)
         (copy-file #$(local-file "emacs/config.org") "config.org")
         (invoke #$(file-append (specification->package "emacs-minimal")
                                "/bin/emacs")
                 "--batch"
                 "--eval" "(require 'ob-tangle)"
                 "--eval" "(org-babel-tangle-file \"config.org\")")))))

;;; Mail: mbsync config; mu4e (emacs/config.org) runs it and sends mail

(define %mail-address "YOU@riseup.net")  ;PLACEHOLDER

(define %mbsyncrc
  (mixed-text-file "mbsyncrc" "\
IMAPAccount riseup
Host mail.riseup.net
User " %mail-address "
PassCmd \"pass show mail.riseup.net | head -n 1\"
TLSType IMAPS
CertificateFile /etc/ssl/certs/ca-certificates.crt

IMAPStore riseup-remote
Account riseup

MaildirStore riseup-local
SubFolders Verbatim
Path ~/Mail/riseup/
Inbox ~/Mail/riseup/INBOX

Channel riseup
Far :riseup-remote:
Near :riseup-local:
Patterns *
Create Both
Expunge Both
SyncState *
"))

;;; kmonad

(define %kmonad-service
  (shepherd-service
   (provision '(kmonad))
   (documentation "Home-row mods for the built-in ThinkPad keyboard.")
   (start #~(make-forkexec-constructor
             (list #$(file-append (specification->package "kmonad")
                                  "/bin/kmonad")
                   #$(local-file "kmonad/thinkpad.kbd"))
             #:log-file (string-append (or (getenv "XDG_STATE_HOME")
                                           (string-append (getenv "HOME")
                                                          "/.local/state"))
                                       "/log/kmonad.log")))
   (stop #~(make-kill-destructor))
   (respawn? #t)))

;;; Home

(home-environment
 (packages (specifications->packages
            (append %emacs-packages %tree-sitter-grammars %tools)))

 (services
  (list
   (service home-bash-service-type)

   (simple-service 'environment home-environment-variables-service-type
                   `(("EDITOR" . "emacsclient")
                     ("VISUAL" . "emacsclient")
                     ;; `npm install -g` goes to ~/.local
                     ("NPM_CONFIG_PREFIX" . "$HOME/.local")
                     ("PATH" . "$HOME/.local/bin:$PATH")
                     ;; uv's downloaded Pythons expect an FHS system;
                     ;; use the Guix one instead.
                     ("UV_PYTHON_DOWNLOADS" . "never")
                     ("UV_PYTHON_PREFERENCE" . "only-system")))

   (service home-xdg-configuration-files-service-type
            `(("emacs/early-init.el" ,(file-append %emacs-config "/early-init.el"))
              ("emacs/init.el" ,(file-append %emacs-config "/init.el"))
              ;; ("emacs/cyrillic-dvorak.el" ,(local-file "emacs/cyrillic-dvorak.el"))
              ("mpv/mpv.conf" ,(plain-file "mpv.conf" "\
hwdec=auto
save-position-on-quit=yes
"))
              ("git/config" ,(plain-file "gitconfig" "\
[user]
	name = YOUR NAME
	email = heavypresence@riseup.net
[init]
	defaultBranch = main
"))))

   (service home-files-service-type
            `((".exwm" ,(file-append %emacs-config "/exwm.el"))
              (".mbsyncrc" ,%mbsyncrc)))

   ;; Every passphrase prompt (pass, mbsync, git, gpg in a shell) goes to
   ;; the Emacs minibuffer via pinentry.el; falls back to the terminal
   ;; when Emacs isn't running. The long cache lets mbsync reuse it.
   (service home-gpg-agent-service-type
            (home-gpg-agent-configuration
             (pinentry-program
              (file-append (specification->package "pinentry-emacs")
                           "/bin/pinentry-emacs"))
             (default-cache-ttl 28800)
             (max-cache-ttl 28800)
             (extra-content "allow-emacs-pinentry\n")))

   (service home-dbus-service-type)
   (service home-pipewire-service-type)
   (service home-syncthing-service-type)
   (simple-service 'kmonad home-shepherd-service-type
                   (list %kmonad-service)))))
