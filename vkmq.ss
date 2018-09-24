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
        :gerbil/gambit/threads)

(export main)

(def mq (make-channel))
(def secret-token "asdf")
(def confirm-token "asdf")

(def (run address)
  (let (httpd (start-http-server!
	       address
	       mux: (make-default-http-mux default-handler)))
    (http-register-handler httpd "/" root-handler)
    (http-register-handler httpd "/vkmq" vkmq-handler)
    (thread-join! httpd)))

;; /
(def (root-handler req res)
  (let ((request-hash
	 (read-json
	  (open-input-string
	   (utf8->string (http-request-body req))))))
    (cond
     ((equal? (hash-get request-hash 'type) "confirmation")
      (http-response-write res 200 [["Content-Type" . "text/plain"]]
	    confirm-token))
     ((equal? (hash-get request-hash 'type) "message_new")
      (http-response-write res 200 [["Content-Type" . "text/plain"]]
        "ok")
      (let* ((user
	            (hash-ref (hash-ref request-hash 'object) 'from_id))
	         (msg
	            (hash-ref (hash-ref request-hash 'object) 'text))
	         (reply
	            (json-object->string
	                (list->hash-table
		                [[(number->string user) . msg]]))))
	    (displayln reply)
	    (channel-put mq reply))))))

;; /vkmq
(def (vkmq-handler req res)
  (cond
   ((equal? (http-request-params req) secret-token)
    (http-response-write res 200 [["Content-Type" . "application/json"]]
      (channel-try-get mq)))
   (else
    (http-response-write res 404 [["Content-Type" . "text/plain"]]
      "these aren't the droids you are looking for.\n"))))

;; default
(def (default-handler req res)
  (http-response-write res 404 '(("Content-Type" . "text/plain"))
    "these aren't the droids you are looking for.\n"))

(def (main . args)
  (def gopt
    (getopt 
        (option 'address "-a" "--address"
            help: "server address"
            default: "178.62.204.208:80")
	    (option 'secret "-s" "--secret"
		    help: "secret token for vkmq"
		    default: "SUPER_SECRET")
	    (option 'token "-c" "--confirm-token"
		    help: "string to return to vk (confirmation)"
		    default: "a1s2d3")))

  (def opt (getopt-parse gopt args))
  (set! confirm-token (hash-get opt 'token))
  (set! secret-token (hash-get opt 'secret))
  
  (try
   (run (hash-get opt 'address))
   (catch (getopt-error? exn)
     (getopt-display-help exn "hellod" (current-error-port))
     (exit 1))))