; extends

; `@function.builtin` gives it the same highlight as `print`
((identifier) @function.builtin
  (#any-of? @function.builtin "Chainsaw")
  (#set! priority 128))
