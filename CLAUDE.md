# CLAUDE.md — nota-plugin

## Project overview

Nota is a **harness-agnostic** algorithmic composition assistant for the [MusaDSL](https://musadsl.yeste.studio) framework. The source lives in `src/` and a generator (`scripts/generate.rb`) emits per-harness plugin output (`dist/claude-code/`, `dist/opencode/`) from a neutral `src/manifest.yml` + per-target templates in `targets/`.

It provides 10 interactive skills, a semantic search MCP server backed by sqlite-vec, and two knowledge databases (public `knowledge.db` + private `private.db`).

## Project structure

```
nota-plugin/                      # source repo (harness-agnostic)
├── src/                          # FUENTE agnóstica
│   ├── manifest.yml              #   Neutral descriptor: name, version, mcp, skills, instructions
│   ├── mcp_server/               #   Ruby MCP server (22 tools) — harness-agnostic
│   │   ├── config.rb             #     Config.user_dir / cmd_ref / github_repo (env-driven)
│   │   ├── server.rb             #     Tool definitions
│   │   ├── search.rb             #     Dual-DB semantic search
│   │   ├── chunker.rb            #     Source → JSONL chunks
│   │   ├── indexer.rb            #     Chunk + embed + store orchestrator
│   │   ├── embeddings.rb         #     Voyage AI integration
│   │   ├── db.rb                 #     sqlite-vec database management
│   │   ├── ensure_db.rb          #     Auto-download knowledge.db on session start
│   │   └── knowledge.db          #     Public knowledge base (gitignored, auto-downloaded)
│   ├── rules/                    #   Static reference (always in LLM context)
│   │   ├── musadsl-reference.md  #     Condensed API reference (~700 lines)
│   │   ├── best-practices.md     #     Condensed best practices (23 items)
│   │   ├── musadsl-philosophy.md
│   │   └── think-journal.md
│   ├── defaults/                 #   Default frameworks (analysis, inspiration)
│   ├── data/
│   │   └── best-practices/       #     Global best practice source files (23 .md)
│   └── skills/<name>/SKILL.md    #   10 skills in superset format with {{cmd:X}} placeholders
├── targets/                      # Per-harness generation templates
│   ├── claude-code.yml           #   → dist/claude-code/ (plugin.json, .mcp.json, hooks)
│   └── opencode.yml              #   → dist/opencode/ (package.json, index.ts, opencode.json)
├── scripts/
│   ├── generate.rb               #   Generator: src/ + targets/ → dist/<harness>/
│   └── templates/
│       └── opencode-index.ts     #   TS plugin wrapper template for opencode
├── prompts/                      # Regeneration prompts for maintainers
├── .claude-plugin/
│   └── marketplace.json          # Marketplace catalog (source → github ref claude-release)
├── .github/workflows/
│   ├── build-release.yml         # CI: build + release knowledge.db.gz
│   └── generate-dist.yml         # CI: generate dist/ → push claude-release + npm publish
├── Gemfile  Gemfile.lock         # Ruby deps: mcp, sqlite3, sqlite-vec (+ generator deps)
├── Makefile  .version  VERSION   # Build + version tooling
├── CLAUDE.md  README.md  LICENSE
└── dist/                         # Generated output (gitignored, CI-published)
    ├── claude-code/              #   → pushed to branch claude-release by CI
    └── opencode/                 #   → published as nota-plugin-for-opencode on npm
```

The MCP server is harness-agnostic: `src/mcp_server/config.rb` reads `NOTA_USER_DIR`, `NOTA_CMD_PREFIX`, `NOTA_GITHUB_REPO` from env, with Claude Code defaults. Each harness's generated config sets these env vars appropriately.

## Key files and their roles

| File | Role | When to update |
|------|------|----------------|
| `src/rules/musadsl-reference.md` | Condensed API reference, always in context | When musa-dsl source or demos change |
| `src/rules/best-practices.md` | Condensed best practices summary, always in context | When best practices are added/modified |
| `src/data/best-practices/*.md` | Full best practice source files (embeddable) | When extracting new patterns |
| `src/manifest.yml` | Neutral source of truth (name, version, skills, mcp, instructions) | When structure/version/skills change |
| `src/mcp_server/config.rb` | Harness-specific config surface (3 env vars) | When adding a new harness target |
| `targets/*.yml` | Per-harness generation templates | When a harness's output format changes |
| `scripts/generate.rb` | The generator itself | When generation logic changes |
| `.claude-plugin/marketplace.json` | Marketplace catalog (points at claude-release branch) | Every release |
| `README.md` | User-facing documentation | When features/counts change |
| `src/mcp_server/chunker.rb` | Defines what gets chunked and how | When adding new content types |

## Developer workflows

### When musa-dsl source code or documentation changes

The API reference and knowledge base may be outdated.

1. **Regenerate `src/rules/musadsl-reference.md`** — follow the prompt in `prompts/regenerate-reference.md`. This reads all docs and source code from `../musa-dsl/` and rewrites the reference. Target: ~400-700 lines, accuracy over brevity, code is authoritative over docs.

2. **Rebuild knowledge.db** — run `make build` (requires `VOYAGE_API_KEY`). This re-chunks all sources and re-embeds.

3. **Verify** — run `make verify-server` to confirm the MCP server starts.

### When musadsl-demo changes

Demos affect both the knowledge base (demo code + READMEs are chunked) and potentially the best practices and reference.

1. **Review best practices** — read the new/changed demo code, contrast against existing practices in `src/data/best-practices/`, propose additions or modifications.

2. **If best practices change** — follow the "When best practices change" workflow below.

3. **Update demo index** — the demo index table at the end of `src/rules/musadsl-reference.md` must list all demos. Regenerate the reference if demos were added/removed.

4. **Rebuild knowledge.db** — `make build`.

### When best practices change

Best practices live in three places that must stay in sync:

1. **Source files** — `src/data/best-practices/*.md` (one file per practice, full content with example and anti-pattern)
2. **Condensed summary** — `src/rules/best-practices.md` (numbered list, one line per practice, always in LLM context)
3. **Knowledge base** — embedded in `knowledge.db` as `kind: "best_practice"` chunks

When adding, modifying, or removing practices:

1. Create/edit/delete the source file in `src/data/best-practices/`
2. Update `src/rules/best-practices.md` to reflect the change (add/edit/remove the corresponding numbered item)
3. Update the count in `README.md` (search for "practices" — appears in the best-practices skill description and in the project structure)
4. Rebuild knowledge.db — `make build`

### When skills change

Skills live in `src/skills/<name>/SKILL.md` in **superset format** with `{{cmd:X}}` placeholders. The generator resolves `{{cmd:X}}` per target:
- `claude-code` → `/nota:X`
- `opencode` → `the X skill`

Frontmatter: `name`, `description`, `version` (all preserved in source; `version` is stripped for opencode by the generator). After editing skills, run `make generate` to regenerate `dist/`.

### When releasing a new version

Use `version.sh` from the ecosystem root (`MusaDSL/version.sh`):

```bash
# 1. Bump version (updates VERSION + manifest.yml + marketplace.json via POST_VERSION_COMMAND)
./version.sh new patch|minor|major nota-plugin

# 2. Update README.md if any user-facing counts or features changed (manual)

# 3. Build knowledge.db + generate + install locally for testing (requires VOYAGE_API_KEY)
export VOYAGE_API_KEY=<your-key>
./version.sh local nota-plugin

# 4. Publish: verify-server + tag + commit + push
./version.sh publish nota-plugin

# 5. CI generates dist/ and publishes (claude-release branch + npm) via generate-dist.yml
```

**Trigger knowledge.db release** — either:
- The CI workflow triggers automatically if `src/mcp_server/chunker.rb` or `src/mcp_server/embeddings.rb` changed
- Otherwise, manually trigger via GitHub Actions → "Build and Release Knowledge DB" → "Run workflow"
- Users auto-download the new knowledge.db on their next session (checked every 24h)

### CI/CD

Two workflows:

1. **`build-release.yml`** — builds and releases `knowledge.db.gz` as a GitHub Release. Triggered by `repository_dispatch` from source repos, manual dispatch, or push to main modifying `src/mcp_server/chunker.rb` or `src/mcp_server/embeddings.rb`.

2. **`generate-dist.yml`** — runs `make generate`, pushes `dist/claude-code/` to the `claude-release` orphan branch (via `peaceiris/actions-gh-pages`), and publishes `dist/opencode/` as `nota-plugin-for-opencode` on npm. Triggered by push to main modifying `src/`, `src/manifest.yml`, `targets/`, etc.

## Build commands

```bash
make setup          # Install Ruby gem dependencies
make chunks         # Generate JSONL chunks only (no API key needed)
make build          # Full build: chunks + embeddings + knowledge.db (requires VOYAGE_API_KEY)
make generate       # Generate dist/claude-code/ + dist/opencode/ from src/ + targets/
make package        # gzip knowledge.db for distribution
make verify-server  # Test MCP server responds to initialize
make status         # Show index status (chunk counts by kind)
make clean          # Remove knowledge.db, chunks, dist/, and generated artifacts
```

## Important conventions

- **Rational for all timing values** — `1/4r`, never `0.25` or `1/4` (which is integer 0 in Ruby)
- **Best practice format** — each `.md` file has: `# Title`, `## Description`, `## Example` (```ruby), `## Anti-pattern` (```ruby). Optional: `## Variant` sections.
- **Source repos are siblings** — the Makefile assumes all MusaDSL repos are cloned as siblings under `../` (e.g., `../musa-dsl/`, `../musadsl-demo/`)
- **Version lives in `src/manifest.yml`** — the generator propagates it to `plugin.json`, `package.json`, `VERSION`, `marketplace.json`. `./version.sh new` bumps `VERSION` and (via `POST_VERSION_COMMAND`) `manifest.yml` + `marketplace.json`.
- **knowledge.db is gitignored** — never commit it; it's distributed via GitHub Releases
- **dist/ is gitignored** — never commit it; CI generates and publishes it
- **Skills use `{{cmd:X}}` placeholders** — never hardcode `/nota:X` in skill source; the generator resolves per target
