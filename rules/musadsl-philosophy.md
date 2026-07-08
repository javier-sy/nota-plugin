# MusaDSL Design Philosophy

This document captures the conceptual model and design intentions of MusaDSL. It answers *why* each abstraction exists and *when* it is the right choice — not what the API can do, but how to think with it.

## Core principle: model musical intent, not audio output

MusaDSL is audio-engine independent by design. It models *what music is* — scale degrees, proportional durations, dynamic markings, ornaments — not *what MIDI needs* — absolute pitches, durations in seconds, velocity integers. This separation is structural:

- **GDV** (Grade/Duration/Velocity) — musical intent: scale degree relative to a tonic, duration as a multiple of `base_duration`, velocity as a dynamic marking (`mf`, `f`, `pp`…)
- **PDV** (Pitch/Duration/Velocity) — MIDI realization: absolute pitch 0-127, duration in Rational bars, velocity 0-127
- **Transcription** — the bridge: expands ornaments, converts GDV to PDV, renders articulations

**Never collapse these layers prematurely.** A composition written in GDV works in any scale, any key, any transposition. A composition written in PDV is committed to one MIDI mapping. Write musical logic in GDV; let Transcription and `to_pdv(scale)` handle the rest.

## Series: the native type for sequences of values

When you need a sequence of any musical parameter — pitches, grades, durations, velocities, harmonic progressions, control values, anything that occurs in order over time — that sequence is a **Serie**.

Series are not a utility or convenience wrapper. They are MusaDSL's native type for sequential musical data:

- **Lazy**: defined without evaluating; supports infinite generators, deferred consumption, cost-free composition
- **Functional**: transform with `.map`, filter with `.select`/`.remove`, combine with `.with`/`H()`/`HC()`, join with `MERGE()`/`.after`
- **Composable**: a complex melodic line is a composition of simpler series operations, not an imperative list
- **Reusable**: prototype/instance pattern — define once, instantiate many times independently

**When to reach for Series:**

| Musical need | Series idiom |
|---|---|
| Sequence of any values | `S(v1, v2, v3, ...)` |
| Pitch + duration + velocity as a unit | `H(pitch: s1, duration: s2, velocity: s3)` |
| Cycling when series have unequal lengths | `HC(...)` — cycles all until common multiple |
| Retrograde / rotation / shuffle | `.reverse`, `.shift(n)`, `.randomize` |
| Transformation / transposition | `.map { \|v\| ... }` |
| Multiple voices on the same material | `.buffered` + independent `.buffer.i` per voice |
| Canon or round | `.buffered`, readers staggered by `wait` |
| Sequential phrases | `MERGE(phrase1, phrase2, phrase3)` |
| Constrained random sequence | `RND(values).remove { \|v, h\| v == h.last }` |
| Numeric contour | `FOR(from:, to:, step:)`, `SIN(steps:)`, `FIBO()`, `HARMO()` |

Before reaching for a Markov chain, an `every` loop, or hard-coded arrays, ask: is this a sequence of values that transforms or combines? If yes, that is a Serie.

## Prototype/instance: define once, consume independently

Every serie starts as a **prototype** — a definition, not yet consuming values. Call `.i` to create an **instance** — stateful, ready to consume. Multiple instances read the same prototype independently from the start:

```ruby
melody = S(60, 64, 67)  # prototype — defines the sequence
v1 = melody.i           # instance 1 — independent position pointer
v2 = melody.i           # instance 2 — starts from 60 again
```

For multiple voices that must progress through the **same** source in parallel (each reading at its own pace, never resetting):

```ruby
shared = S(60, 64, 67).buffered
reader1 = shared.buffer.i   # independent reader — tracks its own position
reader2 = shared.buffer.i   # independent reader — unaffected by reader1
```

Use `.buffered` for canon, rounds, and polyphonic material derived from a single melodic source.

## Sequencer: temporal engine, not musical logic

The sequencer decides **when** events happen. Musical decisions — what note, what pattern, what progression — live in series and generative tools. The sequencer schedules their delivery in time.

`at`, `wait`, `every`, `play`, `move` are scheduling primitives:

- `at position { }` — absolute bar position
- `wait duration { }` — relative to current position
- `every interval { }` — recurring at regular intervals
- `play serie { }` — consume a serie over time; each element's `:duration` drives the wait to the next
- `move from:, to:, duration:, every: { }` — animate a parameter continuously

**Keep musical decisions out of the sequencer blocks.** The block receives values from a serie or generator; it maps them to output (MIDI notes, CC, OSC). It does not generate the values.

Series constructors (`S()`, `H()`, `FOR()`, etc.) must be defined **outside** `sequencer.with` blocks — they are not available inside the DSL context.

## Generative tools: constrained decision-making

Generative tools operate upstream of series — they produce musical material within constraints:

- **Markov** — probabilistic: each state has weighted transitions. Use for stochastic sequences where you want to control tendencies and probabilities.
- **Variatio** — combinatorial: all Cartesian product combinations of parameter fields. Use for exhaustive exploration of a parameter space.
- **Rules** — L-system production: grow a structure by applying production rules, prune invalid branches. Use for grammar-like growth with structural constraints.
- **GenerativeGrammar** — formal grammar: compose sequences with `|` (alternative), `+` (sequence), `.repeat`. Use for rule-driven formal structures.
- **Darwin** — evolutionary: score candidates by features and dimensions, select the fittest. Use for fitness-driven selection from a candidate pool.

Generative tools are not substitutes for Series — they are upstream decision-makers. Their output (value arrays, candidate lists) typically feeds into Series or directly into `play`. A Markov chain produces a sequence of state values; those values become elements of a serie that `play` consumes.

## Neumas: musical notation at the GDV layer

Neumas encode musical events in compact text at the GDV layer — scale-relative, not pitch-absolute:

```
(grade duration velocity ornament)
(0 1 mf)        # grade 0, 1 × base_duration, mezzo-forte
(+2 1/2 f tr)   # relative +2, half a base_duration, forte, trill
(silence 2)     # silence for 2 × base_duration
```

Duration is a **multiple of `base_duration`**, not an abstract fraction of a beat. If `base_duration: 1/4r`, then `1` = quarter, `2` = half, `1/2` = eighth. This matters: neuma `1` does not mean "one quarter note" — it means "one base_duration unit."

Neumas always require a `NeumaDecoder` (needs a scale and `base_duration`). Ornaments additionally require a `Transcriptor` — without one they are silently discarded.

## Events: compositional form

The `on`/`launch` system is for **macro structure** — sections, transitions, form. Not for individual notes:

```ruby
on :verse do
  ctrl = play material, decoder: decoder, mode: :neumalang do |gdv| ... end
  ctrl.after { launch :chorus }   # fires only on natural completion
end
on :chorus do ... end
```

`on_stop` fires on **any** termination — use for cleanup (notes off, state reset).
`after` fires only on **natural** completion — use for section chaining.
A manual `.stop` triggers `on_stop` but **not** `after`. Never rely on `after` for cleanup.

## Rational for all time values

Musical time is rational. Use `1/4r`, `3/8r`, `1r` — never Float. The sequencer accumulates time in Rational internally; Float causes drift in long compositions and subtle timing errors in polyrhythmic structures.
