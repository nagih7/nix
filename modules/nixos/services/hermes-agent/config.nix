{ pkgs, ... }:

{
  services.hermes-agent = {
    enable = true;

    config = {
      model = {
        default = "gpt-5.1-codex-mini";
        provider = "openai-codex";
      };
      terminal = {
        backend = "local";
        timeout = 180;
        lifetime_seconds = 300;
      };
      agent = {
        max_turns = 60;
        reasoning_effort = "low";
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
        memory_char_limit = 2200;
        nudge_interval = 10;
      };
      compression = {
        enabled = true;
        threshold = 0.85;
        summary_model = "gpt-5.1-codex-mini";
      };
      toolsets = [ "all" ];
    };

    # ── Workspace documents (inline or file paths) ──
    documents = {
      "SOUL.md" = ''
        # SOUL.md
        You are a sharp, pragmatic AI assistant.
      '';
      "AGENTS.md" = ''
        # AGENTS.md
        Read SOUL.md first. Then help the user.
      '';
      "USER.md" = ''
        # USER.md
        Name: Your Human
      '';
      # Or reference a file:
      # "SOUL.md" = ./documents/SOUL.md;
    };

    # ── Declarative skills (phase 1) ──
    # skills = {
    #   bundled.enable = true;
    #   optional = [
    #     "creative/blender-mcp"
    #   ];
    #   custom = {
    #     repo-watch = {
    #       category = "research";
    #       source = ./skills/repo-watch;
    #     };
    #   };
    # };

    # ── MCP servers ──
    mcpServers = {
      context7 = {
        command = "npx";
        args = [ "-y" "@upstash/context7-mcp@latest" ];
      };
    };

    # ── Extra tools on PATH ──
    extraPackages = with pkgs; [ jq ripgrep curl ];
  };
}
