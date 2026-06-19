;; extends

; apply lua syntax highlighting to properties named "extraLuaConfig"
(binding_set
  (binding
    attrpath: (attrpath) @_attribute
    expression: [
      (_ (string_fragment) @injection.content)
      (apply_expression argument: (_ (string_fragment) @injection.content))
    ])
  (#set! injection.language "lua")
  (#match? @_attribute "(^|\\.)extraLuaConfig")
)

; home.file.*.text
(binding
  attrpath: (_) @_path (#hmts-path? @_path "home" "file" ".*" "text")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#hmts-inject! @_path)
  (#set! injection.combined)
)

; xdg.configFile.*.text
(binding
  attrpath: (_) @_path (#hmts-path? @_path "xdg" "configFile" ".*" "text")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#hmts-inject! @_path)
  (#set! injection.combined)
)

; Strings with shebang expressions:
;   ''
;   #! /bin/lang
;   ''
(
  (indented_string_expression
    (string_fragment) @injection.language (#lua-match? @injection.language "^%s*#!")
  ) @injection.content
  (#gsub! @injection.language ".*#!.*env (%S+).*" "%1")
  (#gsub! @injection.language ".*#!%s*%S*/(%S+).*" "%1")
  (#set! injection.include-children)
  (#set! injection.combined)
)

; Explicit annotations in comments:
;   /* lang */ ''script''
; or:
;   # lang
;   ''script''
((comment) @injection.language
  .
  (_ (string_fragment) @injection.content)
  (#gsub! @injection.language "[/*#%s]" "")
  (#set! injection.combined)
)

; Fish
(binding
  attrpath: (_) @_path (#hmts-path? @_path "programs" "fish" "((interactive|login)S|s)hellInit$")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "fish")
  (#set! injection.combined)
)

(binding
  attrpath: (_) @_path (#hmts-path? @_path "programs" "fish" "(shellAliases|shellAbbrs|functions)" ".*" "body")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "fish")
  (#set! injection.combined)
)

(binding
  attrpath: (_) @_path (#hmts-path? @_path "programs" "fish" "(shellAliases|shellAbbrs|functions)" ".*")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "fish")
  (#set! injection.combined)
)

; Bash
(binding
  attrpath: (_) @_path (#hmts-path? @_path "programs" "bash" "(init|logout|profile|bashrc)Extra$")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "bash")
  (#set! injection.combined)
)

; Zsh
(binding
  attrpath: (_) @_path
  (#hmts-path? @_path "programs" "zsh" "(completionInit|envExtra|initContent|loginExtra|logoutExtra|profileExtra)$")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "bash")
  (#set! injection.combined)
)

; oh-my-zsh
(binding
  attrpath: (_) @_path
  (#hmts-path? @_path "programs" "zsh" "oh-my-zsh" "extraConfig$")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "bash")
  (#set! injection.combined)
)

; Firefox and its forks
(binding
  attrpath: (_) @_path (#hmts-path? @_path "programs" "(firefox|floorp|librewolf|thunderbird)" "profiles" ".*" "userC(hrome|ontent)")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "css")
  (#set! injection.combined)
)

; Polkit
(binding
  attrpath: (_) @_path (#hmts-path? @_path "security" "polkit" "extraConfig")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "javascript")
  (#set! injection.combined)
)

; Wezterm
(binding
  attrpath: (_) @_path (#hmts-path? @_path "programs" "wezterm" "extraConfig")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "lua")
  (#set! injection.combined)
)

; Waybar
(binding
  attrpath: (_) @_path (#hmts-path? @_path "programs" "waybar" "style")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "css")
  (#set! injection.combined)
)

; Fontconfig
(binding
  attrpath: (_) @_path (#hmts-path? @_path "fonts" "fontconfig" "localConf")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "xml")
  (#set! injection.combined)
)

(binding
  attrpath: (_) @_path (#hmts-path? @_path "fonts" "fontconfig" "configFile" ".*" "text")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "xml")
  (#set! injection.combined)
)

; SSH
(binding
  attrpath: (_) @_path (#hmts-path? @_path "(services|programs|boot)" "(openssh|ssh|initrd)" ".*" "extraConfig")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "ssh_config")
  (#set! injection.combined)
)

; Nginx
(binding
  attrpath: (_) @_path (#hmts-path? @_path "services" "nginx" "(((events|stream|(prep|app)end)C|c)onfig|((append|common)H|h)ttpConfig)")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "nginx")
  (#set! injection.combined)
)

; Bash for Nix derivations and shells (shellHook, preBuild, etc.)
(binding
  attrpath: (attrpath) @_attribute
  expression: [
    (indented_string_expression (string_fragment) @injection.content)
    (string_expression (string_fragment) @injection.content)
    (apply_expression argument: (indented_string_expression (string_fragment) @injection.content))
    (apply_expression argument: (string_expression (string_fragment) @injection.content))
  ]
  (#match? @_attribute "(^|\\.)(shellHook|(pre|post)?(Hook|Patch|Configure|Build|Check|Install|Fixup|InstallCheck|Start|Stop)|(patch|configure|build|check|install|fixup|installCheck)Phase|script|activationScript)$")
  (#set! injection.language "bash")
  (#set! injection.combined)
)

; Home Manager Activation Scripts
(binding
  attrpath: (_) @_path (#hmts-path? @_path "home" "activation" ".*")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "bash")
  (#set! injection.combined)
)

; Nushell
(binding
  attrpath: (_) @_path (#hmts-path? @_path "programs" "nushell" "(extraEnv|extraConfig|extraLogin)$")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "nu")
  (#set! injection.combined)
)

; Yazi
(binding
  attrpath: (_) @_path (#hmts-path? @_path "programs" "yazi" "initLua$")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "lua")
  (#set! injection.combined)
)

; xarchiverrc (INI format)
(binding
  attrpath: (_) @_path (#hmts-path? @_path "(home|xdg)" "(file|configFile)" ".*xarchiverrc$" "text")
  expression: [
    (_ (string_fragment) @injection.content)
    (apply_expression argument: (_ (string_fragment) @injection.content))
  ]
  (#set! injection.language "ini")
  (#set! injection.combined)
)
