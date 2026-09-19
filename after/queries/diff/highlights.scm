;; extends

;; Tree-sitter Highlights for Diff & Patch files
;; High-priority styling to make additions and deletions unmistakable.

;; Bold styling for the leading + in added lines
(addition
  "+" @diff.plus.sign
  (#set! priority 125))

;; Bold styling for the leading - in deleted lines
(deletion
  "-" @diff.minus.sign
  (#set! priority 125))

;; Prominent styling for hunk location headers (@@ -1,5 +1,5 @@)
(location) @diff.location
(location
  "@@" @diff.location
  (#set! priority 110))
