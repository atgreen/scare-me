(asdf:defsystem #:scare-me
  :description "Transform RHEL Insights reports into tomorrows headlines!"
  :author "Anthony Green <green@redhat.com>"
  :license "MIT"
  :version (:read-file-form "version.sexp")
  :serial t
  :components ((:file "package")
               (:file "unix-opts")
               (:file "scare-me"))
  :depends-on (:completions :str :cl-json :njson :njson/cl-json :3bmd :with-user-abort)
  :build-operation "program-op"
  :build-pathname "scare-me"
  :entry-point "scare-me:main")

#+sb-core-compression
(defmethod asdf:perform ((o asdf:image-op) (c asdf:system))
  (uiop:dump-image (asdf:output-file o c) :executable t :compression t))
