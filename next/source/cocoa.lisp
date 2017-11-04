;;;; cocoa.lisp --- cocoa helper functions & data

(in-package :interface)

(defparameter *window* nil)

(defmacro on-main-thread (&rest actions)
  `(ccl::call-in-event-process
     #'(lambda ()
         ,@actions)))

(defun ns-to-lisp-string (ns-str)
  (if (and (not (eql (%null-ptr) ns-str)) (plusp (#/length ns-str)))
    (ccl::%get-utf-8-cstring (#/UTF8String ns-str))
    ""))

(defclass next-window (ns:ns-window) ()
  (:metaclass ns:+ns-object))

(objc:defmethod (#/acceptsFirstResponder :<BOOL>) ((self next-window)) t)

(objc:defmethod (#/keyDown: :void) ((self next-window) event)
  (let* ((flags (#/modifierFlags event))
	 (character (ns-to-lisp-string (#/charactersIgnoringModifiers event))))
    (next:push-key-chord
     (> (logand flags #$NSControlKeyMask) 0)
     (> (logand flags #$NSAlternateKeyMask) 0)
     (> (logand flags #$NSCommandKeyMask) 0)
     character)
    (call-next-method event)))

(defun make-window ()
  (gui::assume-cocoa-thread)
  ;; Content rect for window, bounds rect for view.
  (ns:with-ns-rect (r 100.0 100.0 1024.0 768.0)
    (ccl::with-autorelease-pool 
      (let* ((window (make-instance
		      'next-window
		      :with-content-rect r
		      :style-mask (logior #$NSTitledWindowMask
					  #$NSClosableWindowMask
					  #$NSMiniaturizableWindowMask
					  #$NSResizableWindowMask)
		      :backing #$NSBackingStoreBuffered
		      :defer t)))
	(#/makeKeyAndOrderFront: window +null-ptr+)
	(setf *window* window)
	*window*))))

(defun initialize ()
  (on-main-thread
   (make-window)))

(defun start ())

(defun kill ()
  (quit))

(defun set-visible-view (view)
  (on-main-thread
   (#/setContentView: *window* view)))

(defun set-visible-view-window (view window)
  (on-main-thread
   (#/setContentView: window view)))

(defun make-web-view ()
  (on-main-thread
   (let ((view
	  (make-instance
	   'ns:web-view
	   :frame-name #@"frame"
	   :group-name #@"group")))
     view)))

(defun url-from-string (s)
  (ccl::with-autorelease-pool
    (#/retain (#/URLWithString: ns:ns-url (ccl::%make-nsstring (string s))))))

(defun web-view-set-url (view url)
  (on-main-thread
   (let* ((nsurl (url-from-string url))
	  (webframe (#/mainFrame view))
	  (request (#/requestWithURL: ns:ns-url-request nsurl)))
     (#/loadRequest: webframe request))))

(defun add-to-stack-layout ())
(defun delete-view (view))
(defun web-view-scroll-down ())
(defun web-view-scroll-up ())
(defun web-view-set-url-loaded-callback ())
(defun web-view-get-url ())
(defun make-minibuffer ())
(defun minibuffer-show ())
(defun minibuffer-hide ())
(defun minibuffer-get-input ())
(defun minibuffer-set-completion-function ())
