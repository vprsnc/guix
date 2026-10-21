;; Copy to ~/.config/guix/channels.scm, then `guix pull`.
;; nonguix provides the full Linux kernel and firmware (the X1's Intel
;; Wi-Fi does not work with linux-libre).
;;
;; GitLab is blocked from Russia; this is nonguix's own GitHub mirror.
;; Safe from any mirror: `guix pull' checks the signed commits against
;; the introduction below.
(cons* (channel
        (name 'nonguix)
        (url "https://github.com/nonguix/nonguix")
        (introduction
         (make-channel-introduction
          "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
          (openpgp-fingerprint
           "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
       %default-channels)
