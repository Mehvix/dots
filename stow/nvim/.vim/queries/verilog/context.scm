; Sticky-scroll context for (System)Verilog — the parser language is `verilog`
; but nvim-treesitter-context ships its query under `systemverilog/`, so that
; query is never found (it looks up by parser lang). This file supplies one for
; `verilog` and, crucially, pins the enclosing `module` header.

(module_declaration) @context

(function_declaration) @context

(task_declaration) @context

(always_construct) @context

(initial_construct) @context

(conditional_statement) @context

(loop_statement) @context

(conditional_generate_construct) @context

(if_generate_construct) @context

(loop_generate_construct) @context

(generate_region) @context

(hierarchical_instance) @context
