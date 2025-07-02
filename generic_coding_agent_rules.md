---
description: Project-wide coding, testing, and agent directives for Justin’s Rails-first full-stack projects.
globs:
alwaysApply: true
---
# Agent Behavior (Cursor)
- When the user asks why “why”, first explain your reasoning, then propose the fix; introspection prevents repeats.
- Be your own harshest critic - after you think you're done, review and _re-review_ your work. Will this actually behave correctly? Did you forget anything? What can you do to avoid the shame of being called out for being wrong? How could you improve things to impress the user?
- Replace each TODO in-place; do not break existing delegation boundaries.
- Plan before every function call, reflect after, and continue until the task is complete.
- Apply safe, obvious improvements without waiting for confirmation.

# Philosophy
- Optimize for clarity over cleverness; symmetry and readability beat premature abstraction.
- Default to Omakase Rails; move complex subclass logic to POROs under `app/lib/`.
- Never leave descriptive comments; instead extract a self-explaining method and reserve comments for TODO or truly surprising intent.
- Break multi-step work into first-class invocable units with precise names and sealed APIs.
- Avoid early returns; prefer `&.` / `?.` → simple `if`/`else` → single explicit return; guard clauses excepted.
- Any class doing >1 job must delegate: e.g., `Syndicator#call` depends on `InitUpload`, `UploadImage`, `PublishPost`.
- Inline throw-away locals; do not stockpile variables used once.
- Code confidently: do not rescue exceptions based on a fear of something going wrong. Run the code and let that determine what branches are necessary

# Ruby Style
- Follow StandardRB: double-quoted strings, tight hash literals, `proc { with_spaces }`.
- Always wrap assignments inside conditionals: `if (foo = ...)`.
- Leading dots on multi-line chains; ragged-edge alignment.
- `{}` for value blocks, `do…end` for side-effects.
- Omit `# frozen_string_literal: true`.
- Use dedicated Structs over OpenStruct when the return shape is known - explicit contracts beat dynamic flexibility
- Name methods for their return value/outcome, not their implementation details: `request_upload_url` not `start_resumable_upload`
- Trust framework conventions: let HTTParty convert hashes to JSON automatically rather than manual `.to_json`

# Ruby Style - SINGLE RETURN MANDATE
- **NEVER use early returns except for guard clauses** - use nested if/else with single implicit return
- If you're tempted to use early returns, extract smaller methods or use `&.` / `?.`
- Exception: One-line guard clauses only: `return Result.failure(:blank) if (foo = fetch).blank?`
- If a method feels too nested, it's doing too much - delegate to private methods or other classes if the work is sufficiently distinct/complex

# Ruby Feature POROs
- Every PORO that implements a feature should EITHER delegate to other POROs or implement logic, but never both. If it needs to do two things it should be a delegator to two other POROs that you should create
- When a PORO that implements feature functionality has a dependency on another PORO, instantiate it to an instance variable in a no-arg constructor
- Pattern: `def initialize; @dependency = DependencyClass.new; end`
- This allows for consistent dependency injection and cleaner testing
- Each PORO should instantiate its own dependencies rather than receiving them as parameters
- Dependencies should be stored as instance variables for reuse across method calls

# Rails Controllers
- Controllers are "escape hatches" — handle only basic flow control, never business logic.
- Extract all multi-step logic to dedicated POROs; controllers should branch on return values (usually a result struct if more than a true/false).

# JavaScript/TypeScript Style
- Follow StandardJS: single quotes; space before call parens.
- Use Stimulus + importmaps; favor Hotwire Turbo.

# Web style / CSS
- Style exclusively with Tailwind 4 utilities. When no utilities exist, use arbitrary variants. If that's impossible, then use a tyle tag. Never define custom classes in CSS files.
- I often use custom colors and spacing Refer to [application.css](mdc:app/assets/tailwind/application.css) and [tailwind.config.js](mdc:config/tailwind.config.js) for names of colors

# Architecture & Patterns
- For multi-step business logic, create a delegator PORO:
  - no-arg `initialize`
  - single public entry (e.g., `#call`)
  - helpers live in a same-name sub-folder.
- Write expression-based methods—return a single expression, don’t mutate locals.
- Centralize shared HTTP clients before reusing endpoints.
- Reuse existing constants; never hard-code full URLs.
- Mirror existing naming, structure, and abstraction level when extending code.
- Pass work units as arguments; avoid mutable instance state.
- Prefer <20-LOC home-grown code over adding new gems.
- Switch to keyword args when positional params exceed three.

# Testing
- Use Minitest (or TLDR) with Arrange – Act – Assert separated by a blank line.
- System tests: Capybara + Playwright; always use waiting finders.
- Use Mocktail for doubles; only mock the direct collaborators of the subject.
- No loops or meta-programming in tests; build the subject in `setup`.

