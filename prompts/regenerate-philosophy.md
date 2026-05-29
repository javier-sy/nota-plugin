# Prompt: Regenerate musadsl-philosophy.md

## Objective

Regenerate the file `rules/musadsl-philosophy.md` — the MusaDSL design philosophy document that is always loaded in the LLM context when the Nota plugin is active.

## What this file is for

`musadsl-philosophy.md` is the **conceptual layer** of the Nota plugin. It captures *why* each abstraction exists and *when* it is the right choice — not what the API can do, but how to think and compose with MusaDSL idiomatically.

Its purpose is to ensure that every skill (`/nota:code`, `/nota:explain`, `/nota:think`, etc.) makes idiomatic choices naturally — reaching for the right tool because it understands the design intent, not because an explicit rule matched a specific case.

It complements `musadsl-reference.md` (which answers "what" and "how") by answering "why" and "when."

## Sources to read

Read ALL of the following before writing. Do not skip any file.

### Primary: musa-dsl documentation

```
MusaDSL/musa-dsl/README.md                              — architecture overview, design goals
MusaDSL/musa-dsl/docs/README.md                        — documentation map
MusaDSL/musa-dsl/docs/subsystems/series.md             — series design and patterns
MusaDSL/musa-dsl/docs/subsystems/sequencer.md          — temporal engine design
MusaDSL/musa-dsl/docs/subsystems/neumas.md             — notation layer
MusaDSL/musa-dsl/docs/subsystems/datasets.md           — GDV/PDV separation rationale
MusaDSL/musa-dsl/docs/subsystems/generative.md         — generative tools and their roles
MusaDSL/musa-dsl/docs/subsystems/transport.md          — clock/transport design
MusaDSL/musa-dsl/docs/subsystems/transcription.md      — output bridge design
MusaDSL/musa-dsl/docs/examples/sequencer-dsl-voices.md — idiomatic usage example
MusaDSL/musa-dsl/docs/examples/neuma-notation.md       — idiomatic usage example
```

### Primary: Ruby source code (design comments and architecture)

Focus on module-level and class-level documentation comments, not method implementations. The relevant files are:

```
MusaDSL/musa-dsl/lib/musa-dsl/series/base-series.rb       — prototype/instance design intent
MusaDSL/musa-dsl/lib/musa-dsl/series/main-serie-constructors.rb  — constructor philosophy
MusaDSL/musa-dsl/lib/musa-dsl/series/main-serie-operations.rb    — operation design
MusaDSL/musa-dsl/lib/musa-dsl/datasets.rb                 — dataset hierarchy rationale
MusaDSL/musa-dsl/lib/musa-dsl/sequencer.rb                — sequencer role
MusaDSL/musa-dsl/lib/musa-dsl/generative.rb               — generative tools overview
```

### Secondary: demo projects (idiomatic patterns)

Read the READMEs of these demos to understand how the framework is intended to be used in practice:

```
MusaDSL/musadsl-demo/demo-02/README.md   — Series Explorer
MusaDSL/musadsl-demo/demo-03/README.md   — Canon (buffered series)
MusaDSL/musadsl-demo/demo-04/README.md   — Neumas
MusaDSL/musadsl-demo/demo-05/README.md   — Markov
MusaDSL/musadsl-demo/demo-17/README.md   — Event Architecture
MusaDSL/musadsl-demo/demo-19/README.md   — Advanced Series
MusaDSL/musadsl-demo/demo-22/README.md   — Multi-Phase
```

## Output requirements

### Format

Write a single markdown file: `rules/musadsl-philosophy.md`

### Content principles

1. **Intent over description** — Every section must answer "why does this exist" or "when is this the right choice." Do not describe what the API does (that belongs in `musadsl-reference.md`).

2. **Directive, not tutorial** — Write in the imperative. "Reach for Series when…", "Never collapse GDV to PDV before…", "Keep musical decisions out of the sequencer." Avoid narrative explanations.

3. **Idiomatic use tables** — For the most important abstractions (especially Series), include a table mapping musical needs to the idiomatic tool or pattern. These tables are the highest-value content for guiding LLM choices.

4. **No API signatures** — Do not list method signatures, parameter names, or full examples. Minimal code snippets only where they illustrate a conceptual point that prose cannot. Full API is in `musadsl-reference.md`.

5. **Accuracy over completeness** — Only assert design intent you can verify from the sources. If something is unclear from the sources, omit it rather than speculate.

### Structure

Follow this section order:

1. Title + one-sentence description of the document's purpose
2. Core principle: audio-engine independence, GDV/PDV separation
3. Series as the native type for sequences (most important section — include the "when to reach for" table)
4. Prototype/instance design intent
5. Sequencer as temporal engine, not musical logic
6. Generative tools: their roles and when each is appropriate
7. Neumas: notation at the GDV layer, base_duration convention
8. Events (on/launch): macro structure vs note-level events
9. Rational for time values

### Size target

~120-160 lines. Dense and directive. This document is always in LLM context — every line costs tokens on every skill invocation. Cut anything that doesn't directly guide tool choice or prevent a common mistake.

### What NOT to include

- Method signatures or parameter lists (that's `musadsl-reference.md`)
- Installation or setup instructions
- Plugin instructions (how to use Nota skills)
- Version history
- Praise or marketing language about the framework

## Process

1. Read all primary sources in parallel
2. Read demo READMEs to identify recurring idiomatic patterns
3. For each section, answer: what design decision does this capture, and what mistake does it prevent?
4. Write the complete `rules/musadsl-philosophy.md`
5. After writing, verify: does every section answer "why" or "when"? Remove or rewrite any section that only answers "what."
