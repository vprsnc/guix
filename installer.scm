;; The nonguix installer, adjusted for hosts blocked from Russia:
;; substitutes from bordeaux and nonguix only (no ci.guix.gnu.org), and
;; the nonguix channel in /etc/guix/channels.scm from its GitHub mirror.
;;
;;   guix system image --image-type=iso9660 -L ~/src/nonguix installer.scm

(use-modules (gnu)
             (guix channels)
             (nongnu system install))

(define (nonguix-from-github ch)
  (if (eq? (channel-name ch) 'nonguix)
      (channel (inherit ch) (url "https://github.com/nonguix/nonguix"))
      ch))

(operating-system
  (inherit installation-os-nonfree)
  (services
   (modify-services (operating-system-user-services installation-os-nonfree)
     (guix-service-type
      config => (guix-configuration
                 (inherit config)
                 (channels
                  (map nonguix-from-github
                       (guix-configuration-channels config)))
                 (substitute-urls
                  '("https://bordeaux.guix.gnu.org"
                    "https://substitutes.nonguix.org")))))))
