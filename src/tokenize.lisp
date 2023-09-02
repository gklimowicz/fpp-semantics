(defun tokenize (stream)
  "Convert the characters in `stream' into Fortran tokens"
  (loop with state = :start
        for ch = (read-char stream nil nil)
        while (neq state :end)
        do (write-char ch)
        (case ch)))
