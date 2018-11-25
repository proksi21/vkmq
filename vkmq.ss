;;; -*- Gerbil -*-
;;; VK CallbackAPI Message Queue
;;; Author - Pavel Rodzevich aka proksi21

(import :std/net/httpd
        :std/net/address
        :std/net/request
        :std/net/uri
        :std/text/json
        :std/text/utf8
        :std/sugar
        :std/getopt
        :std/misc/channel
	:std/misc/sync
        :gerbil/gambit/threads)

(export main)

(def mq (make-channel))
(def tokens (make-sync-hash (hash)))

(def (run address)
  (let (httpd (start-http-server! address mux: (make-default-http-mux default-handler)))
    (http-register-handler httpd "/" root-handler)
    (http-register-handler httpd "/vkmq" vkmq-handler)
    (thread-join! httpd)))

;; /
(def (root-handler req res)
  (let ((request-hash (read-json (open-input-string (utf8->string (http-request-body req))))))
    (cond
      ((equal? (hash-get request-hash 'type) "confirmation")
        (http-response-write res 200 [["Content-Type" . "text/plain"]] (sync-hash-get tokens "confirm-token")))
      ((equal? (hash-get request-hash 'type) "message_new")
        (http-response-write res 200 [["Content-Type" . "text/plain"]] "ok")
        (let ((reply (json-object->string request-hash)))
          (displayln reply)
          (channel-put mq reply))))))

;; /vkmq
(def (vkmq-handler req res)
  (let (token (hash-get (list->hash-table (form-url-decode (http-request-params req))) "token"))
    (cond
      ((equal? token (sync-hash-get tokens "secret-token"))
        (http-response-write res 200 [["Content-Type" . "application/json"]] (channel-try-get mq)))
      (else
        (http-response-write res 404 [["Content-Type" . "text/plain"]] "these aren't the droids you are looking for.")))))

;; default
(def (default-handler req res)
  (http-response-write res 404 [["Content-Type" . "text/plain"]] "these aren't the droids you are looking for."))

(def (main . args)
  (def gopt (getopt (option 'address "-a" "--address"
                            help: "server address"
                            default: "178.62.204.208:80")
                    (option 'secret "-s" "--secret"
                            help: "secret token for vkmq"
                            default: "SUPER_SECRET")
                    (option 'token "-c" "--confirm-token"
                            help: "string to return to vk (confirmation)"
                            default: "a1s2d3")))

  (def opt (getopt-parse gopt args))
  (sync-hash-put! tokens "confirm-token" (hash-get opt 'token))
  (sync-hash-put! tokens "secret-token" (hash-get opt 'secret))
  
  (try (run (hash-get opt 'address))
    (catch (getopt-error? exn)
      (getopt-display-help exn "hellod" (current-error-port))
      (exit 1))))
