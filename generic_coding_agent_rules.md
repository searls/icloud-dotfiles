---
description: Project-wide coding, testing, and agent directives for Justin’s Rails-first full-stack projects.
globs:
alwaysApply: true
---

# Agent Behavior
- The work is NEVER done until the tests pass. Never tell the user you're finished with something if there are tests and you haven't run them.
- When the user asks why “why”, first explain your reasoning, then propose the fix; introspection prevents repeats.
- Be your own harshest critic - after you think you're done, review and _re-review_ your work. Will this actually behave correctly? Did you forget anything? What can you do to avoid the shame of being called out for being wrong? How could you improve things to impress the user?
- Replace each TODO in-place; do not break existing delegation boundaries.
- Plan before every function call, reflect after, and continue until the task is complete.
- Apply safe, obvious improvements without waiting for confirmation.

# Philosophy
- Optimize for clarity over cleverness; symmetry and readability beat premature abstraction.
- Be extremely vigilant of duplication and dead code. I like codebases so clean I can eat off them
- Default to Omakase Rails; move complex subclass logic to POROs under `app/lib/`.
- I'm a "One script/ to rule them all" kind of guy, so if there's a `script/test` that's the thing you should run to know if tests are passing. If there's not one and there is more than one command to run, then create a good script/test that tests everything.
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
- In general save class methods for exceptions where `new` isn't getting the job done (this happens but maybe only 5% of the time)
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
- Name POROs verb-first and the primary method should repeat the verb. (e.g. `InvitesUser#invite` NOT `InviteUser#call`)
- When a PORO that implements feature functionality has a dependency on another PORO, instantiate it to an instance variable in a no-arg constructor
- Pattern: `def initialize; @dependency = DependencyClass.new; end`
- In general, POROs should have a single public method
- POROs that have a complex return or a potential failure case should return either a Outcome (that answers success? and has an optional error attr) or a Result (basically same as an outcome but with some sort of data). So if the PORO has a side effect return an outcome (command-query separation means it shouldn't have a meaningful return) and if it returns a value but has a potential failure case, return a Result. These can be inline structs but they're simple/repeatable enough that it's probably worth creating a result.rb / outcome.rb and reusing them for conventionality
- This allows for consistent dependency injection and cleaner testing
- Each PORO should instantiate its own dependencies rather than receiving them as parameters
- Dependencies should be stored as instance variables for reuse across method calls

# Rails Controllers and Models
- EVERY controller that's authenticated, when possible query for data based on the current_user's relationship to that data (e.g. `current_user.posts.find_by(id: params[:id])`, NOT `Post.find_by(params[:id])`) so as not to risk exposing other users' data
- Controllers are "escape hatches" — handle only basic flow control, never business logic. Pull that business logic into POROs organized nicely in app/lib
- Never write custom initializers or attr methods to controllers, models, or other Rails sub-classes. Treat them like DSL-configuration for calling class methods you can only call from them
- If you want to add a method to a model and it's not elucidating an attribute to be easier for callers to consume and it's not a validation, basically always create some other PORO that's got that responsibility. Models should never implement features.
- Extract all multi-step logic to dedicated POROs; controllers should branch on return values (usually an Outcome or Result if more than a true/false).
- NEVER write Rails controller tests. They were deprecated over a decade ago. Write integration tests when you want to call through the stack

# Rails views
- Extract common building blocks into partials
- Improve reuse by NEVER referencing instance variables in partials; improve caching by passing in as much state as possible as opposed to calling global helper methods from inside partials

# JavaScript/TypeScript Style
- Follow StandardJS: single quotes; space before call parens.
- Use Stimulus + importmaps; favor Hotwire Turbo.

# Tailwind / CSS
- Style exclusively with Tailwind 4 utilities. When no utilities exist, use arbitrary variants. If that's impossible, then use a tyle tag. Never define custom classes in CSS files.
- It's imperative with Tailwind that you extract into partials or components anything that represents a repeatable building block. Otherwise we'll end up duplicating a mess of classes and make it very hard to maintain
- I often use custom colors and spacing Refer to [application.css](mdc:app/assets/tailwind/application.css) and [tailwind.config.js](mdc:config/tailwind.config.js) for names of colors (in particular I like -accent, -info, -success, -danger, -warn variants of border/text/background etc)
- Fix visual issues by actually navigating through the app and taking screenshots (see "Playwright MCP Tool Usage" below)
- Never get into situations where you want to use safelists or regex for Tailwind classes -- full class names should be written literally and not interpolated dynamically so that the JIT can do its work. Rely on constants, dictionaries, helpers, flow control that contain the full set of spelled-out classes

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
- When running system tests, always set CI=true so it runs headlessly
- For writing tests of posse_party that integrate with platforms, read @claude/docs/writing_integration_tests.md and work with the user since you need their participation

# Playwright MCP Tool Usage

- You have a playwright MCP tool that lets you interact with the app yourself
- Set the headless attribute and the viewport size in playwright-mcp-config.json
- Some apps will have a TestController for local dev; inspect it to see if it might offer functionality you need. If you look at rails routes, it may be able to override session variables or allow you to introspect mail deliveries to, for example, login via email
- When working on a visual aspect of a website:
  - Navigate to the page and scroll to the point of interest
  - Take a screenshot
  - Visually inspect the screenshot — DON'T ASSUME it looks right—verify!

## Quick Playwright Login for POSSE Party

If you're asked to log in to posse_party app:

1. Enter "searls@gmail.com" in the email field and submit
2. Open a new tab to http://localhost:3000/test/latest_email to see the login code
3. Click the link in the email
