; Sticky-scroll context for (System)Verilog. Overrides (no `; extends`) the
; query nvim-treesitter-context ships for `systemverilog`, which lacks the
; enclosing `module` header, functions/tasks and generate blocks.

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
