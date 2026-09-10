# Nota — source

Source of the Nota plugin: a MusaDSL composition assistant for AI coding assistants.
This repository builds it, tests it and publishes it. It is not where you install it from,
and it is not where it is documented.

- **What Nota is, how to install it and what it needs** — [nota.yeste.studio](https://nota.yeste.studio):
  [what it does](https://nota.yeste.studio/#about) ·
  [the skills](https://nota.yeste.studio/#skills) ·
  [requisites](https://nota.yeste.studio/#prerequisites) ·
  [install](https://nota.yeste.studio/#install) ·
  [troubleshooting](https://nota.yeste.studio/#troubleshooting)
- **Knowledge base releases and issue tracker** — [`javier-sy/nota`](https://github.com/javier-sy/nota)
- **Claude Code distribution** — [`javier-sy/claude-plugins`](https://github.com/javier-sy/claude-plugins),
  written by CI from `dist/claude-code/`

None of that is repeated below. What follows is what only this repository can say.

## Development

How the plugin is built, tested and published.

### Architecture

The plugin has three knowledge layers, and **it owns only one of them**.

1. **The framework's own conceptual layer**, read at session start from the
   **installed musa-dsl gem** — `docs/idioms.md` (the catalogue of idioms, indexed
   by symptom) and `docs/vocabulary.md` (every name the guides teach, on one
   page). Nota does not keep a copy: musa-dsl is where those documents can be
   falsified, by its own suite and its own doctest, and every copy of them that
   ever lived here drifted from the original. Requires the gem, and nothing
   else: there is no version floor. Each document is served if the installed gem
   has it and named if it does not — `docs/vocabulary.md` arrives in 0.49.1, so an
   older gem gets the idioms and is told the vocabulary is not in its version.
   A floor would be an assertion about musa-dsl's history kept inside Nota, which
   is the category of thing this whole layer exists to remove; what the plugin
   owes the reader is not a verdict on which releases are fit but an accurate
   statement of which one it read, and every response carries it.
2. **Semantic search** (MCP server + sqlite-vec + Voyage AI embeddings) — retrieves relevant docs, API, and code examples on demand
3. **Works catalog** — finds similar compositions from demos and private indexed works

What the plugin does carry in context is how the **assistant** behaves
(`rules/think-journal.md`, the frameworks in `defaults/`), which is its own
business and nobody else's.

Two separate databases:

- **`knowledge.db`** (public) — Documentation, API reference, demo code, and gem READMEs. Pre-built, automatically downloaded on session start from the releases of [`javier-sy/nota`](https://github.com/javier-sy/nota), which serves every harness. The CI workflow rebuilds it when source repos update.

- **`private.db`** (local, per-user) — User's indexed compositions and musical analyses. Stored at `~/.config/nota/private.db`, outside the plugin directory, persisting across updates. Never touched by CI or auto-updates.

When searching, the MCP server queries both databases and merges results by cosine distance. If `private.db` doesn't exist, searches use only the public knowledge base.

### MCP Tools (22)

| Tool | Purpose |
|------|---------|
| `search` | Semantic search across all knowledge (docs, API, demos, private works, analyses, best practices) |
| `api_reference` | Exact API reference lookup by module/method |
| `similar_works` | Find similar works and demo examples (includes private works and analyses) |
| `dependencies` | Dependency chain for a concept (what setup is needed) |
| `pattern` | Code pattern for a specific technique |
| `check_setup` | Check plugin status: API key, knowledge base, private works DB |
| `list_works` | List all indexed private works with chunk counts |
| `add_work` | Index a private composition work from a given path |
| `remove_work` | Remove a private work from the index by name (also removes associated analysis) |
| `index_status` | Show status of both knowledge databases (public and private) |
| `get_analysis_framework` | Get the current analysis framework (default or user-customized) |
| `save_analysis_framework` | Save a customized analysis framework |
| `reset_analysis_framework` | Reset the analysis framework to default |
| `add_analysis` | Store a composition analysis in the knowledge base |
| `get_inspiration_framework` | Get the current inspiration framework (default or user-customized) |
| `save_inspiration_framework` | Save a customized inspiration framework |
| `reset_inspiration_framework` | Reset the inspiration framework to default |
| `save_best_practice` | Save a best practice (private or global scope) |
| `list_best_practices` | List all user best practices with indexing status |
| `remove_best_practice` | Remove a user best practice by name |
| `get_best_practices_index` | Get the user's condensed best practices index |
| `save_best_practices_index` | Save the user's condensed best practices index |

### Building the public knowledge base

Prerequisites: all MusaDSL source repositories cloned as siblings of `nota/`, and `VOYAGE_API_KEY` with sufficient quota for embedding ~3000 chunks.

```bash
make chunks    # Generate chunks only (no API key needed, useful for inspection)
make build     # Full build: chunks + embeddings + knowledge.db (requires VOYAGE_API_KEY)
make package   # Package knowledge.db for release in javier-sy/nota
make status    # Check index status
make clean     # Remove all generated artifacts
```

### CI/CD

The CI workflow (`.github/workflows/build-release.yml`) builds the public knowledge base and releases it in [`javier-sy/nota`](https://github.com/javier-sy/nota) — the index serves every harness, so it does not live in this repository. It is triggered by:
- `repository_dispatch` events from the 7 source repositories (when they update)
- Manual workflow dispatch
- Pushes to main that modify the server code

The CI only rebuilds `knowledge.db` — it never touches `private.db`.

### Project Structure

```
nota/
├── .claude-plugin/          # Plugin metadata (plugin.json)
├── skills/
│   ├── hello/               # /nota:hello skill — welcome and capabilities overview
│   ├── explain/             # /nota:explain skill — MusaDSL concept explanations
│   ├── code/                # /nota:code skill — composition coding and modification
│   ├── think/               # /nota:think skill — creative ideation and brainstorming
│   ├── index/               # /nota:index skill — manage private works index
│   ├── analyze/             # /nota:analyze skill — structured composition analysis
│   ├── best-practices/      # /nota:best-practices skill — manage best practices
│   ├── analysis-framework/  # /nota:analysis-framework skill — manage analysis dimensions
│   ├── inspiration-framework/ # /nota:inspiration-framework skill — manage inspiration dimensions
│   └── setup/               # /nota:setup skill — configuration and troubleshooting
├── defaults/                # Default configuration files
│   ├── analysis-framework.md      # Default analysis framework (10 dimensions)
│   └── inspiration-framework.md   # Default inspiration framework (9 dimensions)
├── rules/                   # Always in context — assistant behaviour only
│   └── think-journal.md           # Persisting creative thinking
├── data/
│   ├── best-practices/      # The user's own practices (4 .md files); what
│   │                        #   describes musa-dsl itself lives in musa-dsl
│   └── chunks/              # Generated JSONL chunks + manifest
├── mcp_server/              # Ruby MCP server + sqlite-vec
│   ├── server.rb            # MCP tools (22 tools)
│   ├── search.rb            # Dual-DB search (knowledge.db + private.db)
│   ├── chunker.rb           # Source material → chunks
│   ├── indexer.rb           # Chunk + embed + store orchestrator
│   ├── embeddings.rb        # Voyage AI integration
│   ├── db.rb                # sqlite-vec database management
│   ├── ensure_db.rb         # Auto-download knowledge.db from releases
│   └── knowledge.db         # Public knowledge base (auto-downloaded)
├── hooks/                   # Session lifecycle hooks (musa-dsl docs into context)
├── .mcp.json                # MCP server configuration
├── Gemfile                  # Ruby dependencies
├── Makefile                 # Build targets (for maintainers)
└── .github/workflows/       # CI: build + release public knowledge DB
```

## Licence

Proprietary — see [LICENSE](LICENSE). Nota is free of charge and is not open source:
it is licensed to be used, not copied, changed or redistributed. What you compose with
it is yours, without condition.

MusaDSL itself is free software, LGPL-3.0-or-later, and is unaffected.

## Author

Javier Sánchez Yeste — [yeste.studio](https://yeste.studio)
