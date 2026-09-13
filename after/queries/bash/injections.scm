;; extends

; Injected languages in heredocs (shebang, file redirect, or heredoc delimiter)
((heredoc_redirect
  (heredoc_body) @injection.content)
  (#shebang-inject! @injection.content))
