#!/usr/bin/env bash
set -euo pipefail

# Skill-evidence session runner.
#   RED   = scratch config, Superpowers absent   -> baseline evidence
#   GREEN = scratch config, working-tree plugin  -> verification evidence
# Design: docs/heyi-sp/specs/2026-07-02-skill-evidence-and-style-design.md
# Transcripts are only ever produced by this script; never hand-write one.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EVIDENCE_ROOT="$REPO_ROOT/docs/heyi-sp/evidence"
SCRATCH_ROOT="${SKILL_EVIDENCE_SCRATCH:-$HOME/.cache/skill-evidence-scratch}"
TODAY="$(date +%F)"

usage() {
  cat >&2 <<'USAGE'
Usage:
  run-skill-evidence.sh preflight <claude|codex> <red|green>
  run-skill-evidence.sh run <claude|codex> <red|green> <skill> <scenario-slug> <prompt-file>

RED   = scratch config, plugin absent (baseline)
GREEN = scratch config with the working-tree plugin loaded (verification)
The transcript's repo-relative path is printed on the last stdout line.
USAGE
  exit 2
}

note() { echo "[run-skill-evidence] $*" >&2; }

make_workspace() {
  local dir
  dir="$(mktemp -d "${TMPDIR:-/tmp}/skill-evidence-ws.XXXXXX")"
  git -C "$dir" init --quiet
  echo "# Scratch target repository for a skill-evidence session" > "$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" -c user.email=evidence@local -c user.name=evidence \
    commit --quiet -m "init scratch workspace"
  echo "$dir"
}

claude_env_dir() { # $1 = red|green
  local dir="$SCRATCH_ROOT/claude-$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    # Seed onboarding/user state so headless runs skip first-run prompts.
    if [[ -f "$HOME/.claude.json" ]]; then
      cp "$HOME/.claude.json" "$dir/.claude.json"
    fi
    # With a non-default CLAUDE_CONFIG_DIR, claude reads OAuth credentials
    # from $CLAUDE_CONFIG_DIR/.credentials.json (it does not fall back to
    # the macOS Keychain), so materialize them from the Keychain item.
    if security find-generic-password -s "Claude Code-credentials" -w >/dev/null 2>&1; then
      security find-generic-password -s "Claude Code-credentials" -w > "$dir/.credentials.json"
      chmod 600 "$dir/.credentials.json"
    fi
    # Deliberately no plugins/ and no settings.json: the scratch env must
    # not inherit installed plugins or user hooks.
  fi
  echo "$dir"
}

codex_env_dir() { # $1 = red|green
  local dir="$SCRATCH_ROOT/codex-$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    # Codex keeps credentials in CODEX_HOME; seed auth only. No config.toml:
    # the scratch env must not inherit plugin or marketplace configuration.
    if [[ -f "$HOME/.codex/auth.json" ]]; then
      cp "$HOME/.codex/auth.json" "$dir/auth.json"
    fi
  fi
  if [[ "$1" == "green" && ! -f "$dir/.superpowers-installed" ]]; then
    note "installing working-tree plugin into scratch CODEX_HOME"
    CODEX_HOME="$dir" codex plugin marketplace add "$REPO_ROOT" >&2
    CODEX_HOME="$dir" codex plugin add superpowers@superpowers-dev >&2
    touch "$dir/.superpowers-installed"
  fi
  echo "$dir"
}

verify_codex_green_load() { # $1 = CODEX_HOME dir; dies unless installed == working tree
  local installed
  installed="$(CODEX_HOME="$1" codex plugin list \
    | awk '$1 ~ /^superpowers@superpowers-dev/ {print $NF}')"
  if [[ -z "$installed" || ! -d "$installed/skills" ]]; then
    note "FATAL: cannot locate installed superpowers plugin path"
    exit 1
  fi
  if ! diff -r "$installed/skills" "$REPO_ROOT/skills" >/dev/null; then
    note "FATAL: installed plugin skills differ from working tree: $installed"
    note "Remove $1 and rerun to reinstall."
    exit 1
  fi
  echo "$installed"
}

harness_version() { # $1 = claude|codex
  case "$1" in
    claude) claude --version 2>/dev/null | head -1 ;;
    codex)  codex --version 2>/dev/null | head -1 ;;
  esac
}

run_session() { # $1 harness, $2 phase, $3 prompt-file, $4 transcript-path
  local harness="$1" phase="$2" prompt_file="$3" transcript="$4"
  local ws cfg load_note version
  ws="$(make_workspace)"
  version="$(harness_version "$harness")"

  if [[ "$harness" == "claude" ]]; then
    cfg="$(claude_env_dir "$phase")"
    if [[ "$phase" == "green" ]]; then
      load_note="--plugin-dir $REPO_ROOT (working tree loaded directly; no cache to drift)"
    else
      load_note="none (scratch CLAUDE_CONFIG_DIR, no plugins)"
    fi
  else
    cfg="$(codex_env_dir "$phase")"
    if [[ "$phase" == "green" ]]; then
      local installed
      installed="$(verify_codex_green_load "$cfg")"
      load_note="local marketplace install at $installed (diff -r against working tree: identical)"
    else
      load_note="none (scratch CODEX_HOME, auth seeded, no plugins)"
    fi
  fi

  mkdir -p "$(dirname "$transcript")"
  {
    echo "# Evidence transcript"
    echo
    echo "- Date: $TODAY"
    echo "- Harness: $version"
    echo "- Phase: $phase"
    echo "- Prompt file: $prompt_file"
    echo "- Workspace: scratch git repository (created by run-skill-evidence.sh)"
    echo "- Plugin load: $load_note"
    echo
    echo "## Prompt"
    echo
    echo '````text'
    cat "$prompt_file"
    echo '````'
    echo
    echo "## Session output"
    echo
    echo '````text'
  } > "$transcript"

  local rc=0
  if [[ "$harness" == "claude" ]]; then
    if [[ "$phase" == "green" ]]; then
      ( cd "$ws" && CLAUDE_CONFIG_DIR="$cfg" claude -p --output-format text \
          --plugin-dir "$REPO_ROOT" < "$prompt_file" ) >> "$transcript" 2>&1 || rc=$?
    else
      ( cd "$ws" && CLAUDE_CONFIG_DIR="$cfg" claude -p --output-format text \
          < "$prompt_file" ) >> "$transcript" 2>&1 || rc=$?
    fi
  else
    ( cd "$ws" && CODEX_HOME="$cfg" codex exec - < "$prompt_file" ) \
      >> "$transcript" 2>&1 || rc=$?
  fi
  {
    echo '````'
    echo
    echo "- Exit code: $rc"
  } >> "$transcript"
  if [[ "$rc" -ne 0 ]]; then
    note "session exited non-zero ($rc); recorded in transcript"
  fi
}

cmd="${1:-}"
case "$cmd" in
  preflight)
    [[ $# -eq 3 ]] || usage
    harness="$2"; phase="$3"
    prompt="$(mktemp "${TMPDIR:-/tmp}/skill-evidence-preflight.XXXXXX")"
    echo "Reply with exactly: PREFLIGHT OK" > "$prompt"
    out="$(mktemp "${TMPDIR:-/tmp}/skill-evidence-preflight-out.XXXXXX")"
    run_session "$harness" "$phase" "$prompt" "$out"
    # Check only the session-output section: the prompt echo earlier in the
    # transcript always contains the sentinel, which would mask a dead session.
    if awk '/^## Session output$/,0' "$out" | grep -q "PREFLIGHT OK"; then
      echo "PREFLIGHT OK ($harness $phase)"
    else
      note "preflight failed; transcript follows"
      cat "$out" >&2
      exit 1
    fi
    ;;
  run)
    [[ $# -eq 6 ]] || usage
    harness="$2"; phase="$3"; skill="$4"; slug="$5"; prompt_file="$6"
    [[ -f "$prompt_file" ]] || { note "prompt file not found: $prompt_file"; exit 1; }
    transcript="$EVIDENCE_ROOT/$skill/$TODAY-$slug-$harness-$phase.md"
    run_session "$harness" "$phase" "$prompt_file" "$transcript"
    echo "docs/heyi-sp/evidence/$skill/$TODAY-$slug-$harness-$phase.md"
    ;;
  *)
    usage
    ;;
esac
