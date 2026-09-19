;; extends

;; Tree-sitter Language Injections for Diff & Patch files
;; Enables syntax highlighting for embedded languages based on file extensions.

;; Git diff: modified & added files
((block
  (new_file (filename) @injection.filename)
  (hunks
    (hunk
      (changes) @injection.content)+))
  (#gsub! @injection.filename "\t.*" "")
  (#gsub! @injection.filename "^[\"']" "")
  (#gsub! @injection.filename "[\"']$" "")
  (#not-match? @injection.filename "null$")
  (#set! injection.include-children))

;; Git diff: deleted files (new_file is /dev/null, so get filename from old_file)
((block
  (old_file (filename) @injection.filename)
  (new_file (filename) @_new (#match? @_new "null$"))
  (hunks
    (hunk
      (changes) @injection.content)+))
  (#gsub! @injection.filename "\t.*" "")
  (#gsub! @injection.filename "^[\"']" "")
  (#gsub! @injection.filename "[\"']$" "")
  (#not-match? @injection.filename "null$")
  (#set! injection.include-children))

;; Non-git unified diff: modified & added files (e.g., diff -u or plain patch)
((old_file)
 (new_file (filename) @injection.filename)
 [
   (context)
   (addition)
   (deletion)
 ]+ @injection.content
 (#gsub! @injection.filename "\t.*" "")
 (#gsub! @injection.filename "^[\"']" "")
 (#gsub! @injection.filename "[\"']$" "")
 (#not-match? @injection.filename "null$")
 (#set! injection.combined)
 (#set! injection.include-children))

;; Non-git unified diff: deleted files
((old_file (filename) @injection.filename)
 (new_file (filename) @_new (#match? @_new "null$"))
 [
   (context)
   (addition)
   (deletion)
 ]+ @injection.content
 (#gsub! @injection.filename "\t.*" "")
 (#gsub! @injection.filename "^[\"']" "")
 (#gsub! @injection.filename "[\"']$" "")
 (#not-match? @injection.filename "null$")
 (#set! injection.combined)
 (#set! injection.include-children))
