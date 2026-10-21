;; Minimal Guix System for the ThinkPad X1.
;; Only hardware, login and root-level bits live here; everything else
;; is in home.scm.
;;
;;   sudo guix system reconfigure ~/dotfiles/system.scm

(use-modules (gnu)
             (nongnu packages linux)
             (nongnu system linux-initrd))
(use-service-modules desktop linux pm xorg)
(use-package-modules emacs-xyz haskell-apps linux)

(define %user "george")                 ;CHECK

;; Applies to the console, GRUB (LUKS passphrase!) and X.
(define %keyboard-layout
  (keyboard-layout "us" "dvorak"))      ;CHECK

(operating-system
  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware))

  ;; Copy these three from the installer's /etc/config.scm.
  (host-name "x1")
  (timezone "Europe/Nicosia")
  (locale "en_US.utf8")
  (keyboard-layout %keyboard-layout)

  (bootloader (bootloader-configuration
               (bootloader grub-efi-bootloader)
               (targets '("/boot/efi"))
               (keyboard-layout %keyboard-layout)))

  ;; REPLACE: copy mapped-devices, file-systems and swap-devices
  ;; verbatim from the installer's /etc/config.scm.
  (mapped-devices
   (list (mapped-device
          (source (uuid "00000000-0000-0000-0000-000000000000"))
          (target "cryptroot")
          (type luks-device-mapping))))

  (file-systems
   (cons* (file-system
            (mount-point "/")
            (device "/dev/mapper/cryptroot")
            (type "ext4")
            (dependencies mapped-devices))
          (file-system
            (mount-point "/boot/efi")
            (device (uuid "0000-0000" 'fat32))
            (type "vfat"))
          %base-file-systems))

  ;; kmonad reads /dev/input (input) and writes /dev/uinput (uinput).
  (groups (cons (user-group (name "uinput") (system? #t))
                %base-groups))

  (users (cons (user-account
                (name %user)
                (group "users")
                (home-directory (string-append "/home/" %user))
                (supplementary-groups
                 '("wheel" "netdev" "audio" "video" "input" "uinput")))
               %base-user-accounts))

  ;; emacs-exwm installs the "EXWM" session that GDM offers.
  (packages (cons emacs-exwm %base-packages))

  (services
   (append
    (list (service tlp-service-type)
          (service thermald-service-type)
          (service kernel-module-loader-service-type '("uinput"))
          (udev-rules-service 'kmonad kmonad)
          (udev-rules-service 'brightnessctl brightnessctl)
          (set-xorg-configuration
           (xorg-configuration
            (keyboard-layout %keyboard-layout))))
    (modify-services %desktop-services
      (guix-service-type
       config => (guix-configuration
                  (inherit config)
                  (substitute-urls
                   (cons "https://substitutes.nonguix.org"
                         %default-substitute-urls))
                  (authorized-keys
                   (cons (plain-file "nonguix.pub"
                                     "(public-key (ecc (curve Ed25519) (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))")
                         %default-authorized-guix-keys))))))))
