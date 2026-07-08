# frozen_string_literal: true

# Harness-agnostic configuration for the Nota knowledge base.
#
# These three values are the ONLY harness-specific surface in the MCP server.
# They are driven by environment variables, set by each harness's generated config:
#
#   NOTA_USER_DIR    — where user data lives (frameworks, best-practices/, private.db)
#   NOTA_CMD_PREFIX  — how to reference skills in user-facing strings.
#                      Non-empty (e.g. "/nota:") → "#{prefix}#{skill}" (Claude Code slash).
#                      Empty → "the #{skill} skill" (opencode, model-invoked, no slash).
#   NOTA_GITHUB_REPO — the GitHub repo (owner/name) hosting knowledge.db releases.
#
# Defaults assume the Claude Code target (the incumbent), so the server keeps
# working unchanged for existing installs when env vars are not set.

module NotaKnowledgeBase
  module Config
    module_function

    def user_dir
      ENV["NOTA_USER_DIR"] || File.join(Dir.home, ".config", "nota")
    end

    def cmd_prefix
      ENV["NOTA_CMD_PREFIX"] || "/nota:"
    end

    # Reference a skill in a user-facing string, adapting to the harness convention.
    #   Claude Code ("/nota:") → "/nota:setup"
    #   opencode      ("")      → "the setup skill"
    def cmd_ref(skill)
      prefix = cmd_prefix
      prefix.empty? ? "the #{skill} skill" : "#{prefix}#{skill}"
    end

    def github_repo
      ENV["NOTA_GITHUB_REPO"] || "javier-sy/nota-plugin"
    end
  end
end
