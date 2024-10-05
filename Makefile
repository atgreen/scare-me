scare-me: *.asd *.lisp Makefile version.sexp
	sbcl --dynamic-space-size 2560 --eval "(require 'asdf)" --eval "(progn (push (uiop:getcwd) asdf:*central-registry*) (asdf:make :scare-me) (sb-ext:quit))"

clean:
	-rm -rf scare-me systems *~
