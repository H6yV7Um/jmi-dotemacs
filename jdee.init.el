;; JDEE initializations

(require 'jde)

;; bsh-jar
(setq bsh-jar "/usr/share/java/bsh.jar")

;; Plugins
(setq jde-plugins-directory "~/elisp/jde-plugins")

;; Project context switching settings
(setq jde-project-context-switching-enabled-p t)

(defun jars-in-below-directory (directory)
  "List the .jar files in DIRECTORY and in its sub-directories."
  ;; Although the function will be used non-interactively,
  ;; it will be easier to test if we make it interactive.
  ;; The directory will have a name such as
  ;;  "/usr/local/share/emacs/21.0.100/lisp/"
  (interactive "DDirectory name: ")
  (let (jar-files-list
        (current-directory-list
         (directory-files-and-attributes directory t)))
    ;; while we are in the current directory
    (while current-directory-list
      (cond
       ;; check to see whether filename ends in `.jar'
       ;; and if so, append its name to a list.
       ((equal ".jar" (substring (car (car current-directory-list)) -4))
        (setq jar-files-list
              (cons (car (car current-directory-list)) jar-files-list)))
       ;; check whether filename is that of a directory
       ((eq t (car (cdr (car current-directory-list))))
        ;; decide whether to skip or recurse
        (if
            (equal "."
                   (substring (car (car current-directory-list)) -1))
            ;; then do nothing since filename is that of
            ;;   current directory or parent, "." or ".."
            ()
          ;; else descend into the directory and repeat the process
          (setq jar-files-list
                (append
                 (jars-in-below-directory
                  (car (car current-directory-list)))
                 jar-files-list)))))
      ;; move to the next filename in the list; this also
      ;; shortens the list so the while loop eventually comes to an end
      (setq current-directory-list (cdr current-directory-list)))
    ;; return the filenames
    jar-files-list))

(defun jde-find-dired (dir regexp)
  "Find java files in DIR containing a regexp REGEXP and start Dired on output.
The command run (after changing into DIR) is

    find . -type f -and -name \\*.java -exec grep -s -e REGEXP {} \\\; -ls

Thus ARG can also contain additional grep options."
  (interactive "DJde-find-dired (directory): \nsJde-find-dired (grep regexp): ")
  (find-dired dir
              (concat "-type f -and -name \\*.java -exec grep " find-grep-options " -e "
                      (shell-quote-argument regexp)
                      " {} \\\; ")))


(require 'font-lock)
;; FIXME temp hack to get a little better java 1.5 support
(let* ((java-keywords
        (eval-when-compile
          (regexp-opt
           '("catch" "do" "else" "super" "this" "finally" "for" "if"
             ;; Anders Lindgren <****> says these have gone.
             ;; "cast" "byvalue" "future" "generic" "operator" "var"
             ;; "inner" "outer" "rest"
             "implements" "extends" "throws" "instanceof" "new"
             "interface" "return" "switch" "throw" "try" "while"))))
       ;;
       ;; Classes immediately followed by an object name.
       (java-type-names
        `(mapconcat 'identity
                    (cons
                     ,(eval-when-compile
                        (regexp-opt '("boolean" "char" "byte" "short" "int" "long"
                                      "float" "double" "void")))
                     java-font-lock-extra-types)
                    "\\|"))
       (java-type-names-depth `(regexp-opt-depth ,java-type-names))
       ;;
       ;; These are eventually followed by an object name.
       (java-type-specs
        (eval-when-compile
          (regexp-opt
           '("abstract" "const" "final" "synchronized" "transient" "static"
             ;; Anders Lindgren <****> says this has gone.
             ;; "threadsafe"
             "volatile" "public" "private" "protected" "native"
             ;; Carl Manning <caroma@ai.mit.edu> says this is new.
             "strictfp"))))
       )

  (setq java-font-lock-keywords-3
        (append
         (list
          ;; support static import statements
          '("\\<\\(import\\)\\>\\s-+\\(static\\)\\s-+\\(\\sw+\\)"
            (1 font-lock-keyword-face)
            (2 font-lock-keyword-face)
            (3 (if (equal (char-after (match-end 0)) ?\.)
                   'jde-java-font-lock-package-face
                 'font-lock-type-face))
            ("\\=\\.\\(\\sw+\\)" nil nil
             (1 (if (and (equal (char-after (match-end 0)) ?\.)
                         (not (equal (char-after (+ (match-end 0) 1)) ?\*)))
                    'jde-java-font-lock-package-face
                  'font-lock-type-face))))
          )

         java-font-lock-keywords-2

         ;;
         ;; More complicated regexps for more complete highlighting for types.
         ;; We still have to fontify type specifiers individually, as Java is hairy.
         (list
          ;;
          ;; Fontify class names with ellipses
          `(eval .
                 (cons (concat "\\<\\(" ,java-type-names "\\)\\>\\.\\.\\.[^.]")
                       '(1 font-lock-type-face)))
          ;;
          ;; Fontify random types immediately followed by an item or items.
          `(eval .
                 (list (concat "\\<\\(\\(?:" ,java-type-names "\\)"
                               "\\(?:\\(?:<.*>\\)\\|\\>\\)\\(?:\\.\\.\\.\\)?\\)"
                               "\\([ \t]*\\[[ \t]*\\]\\)*"
                               "\\([ \t]*\\sw\\)")
                       ;; Fontify each declaration item.
                       (list 'font-lock-match-c-style-declaration-item-and-skip-to-next
                             ;; Start and finish with point after the type specifier.
                             (list 'goto-char (list 'match-beginning
                                                    (+ ,java-type-names-depth 3)))
                             (list 'goto-char (list 'match-beginning
                                                    (+ ,java-type-names-depth 3)))
                             ;; Fontify as a variable or function name.
                             '(1 (if (match-beginning 2)
                                     font-lock-function-name-face
                                   font-lock-variable-name-face)))))
          ;;
          ;; Fontify those that are eventually followed by an item or items.
          (list (concat "\\<\\(" java-type-specs "\\)\\>"
                        "\\([ \t]+\\sw+\\>"
                        "\\([ \t]*\\[[ \t]*\\]\\)*"
                        "\\)*")
                ;; Fontify each declaration item.
                '(font-lock-match-c-style-declaration-item-and-skip-to-next
                  ;; Start with point after all type specifiers.
                  (goto-char (or (match-beginning 5) (match-end 1)))
                  ;; Finish with point after first type specifier.
                  (goto-char (match-end 1))
                  ;; Fontify as a variable or function name.
                  (1 (if (match-beginning 2)
                         font-lock-function-name-face
                       font-lock-variable-name-face))))))))

