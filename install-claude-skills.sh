#!/usr/bin/env bash
# Installe les skills ponytail, OmniRoute, graphify et agent-skills dans ~/.claude
# (niveau utilisateur : disponibles dans tous les projets).
set -euo pipefail
DEST="${CLAUDE_HOME:-$HOME/.claude}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$DEST/skills" "$DEST/references" "$DEST/agents"

clone() { git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$1.git" "$TMP/$2" && git -C "$TMP/$2" sparse-checkout set "${@:3}"; }

clone addyosmani/agent-skills agent-skills skills references agents
cp -r "$TMP"/agent-skills/skills/* "$DEST/skills/"
cp "$TMP"/agent-skills/references/*.md "$DEST/references/"
cp "$TMP"/agent-skills/agents/*.md "$DEST/agents/"

clone dietrichgebert/ponytail ponytail skills
cp -r "$TMP"/ponytail/skills/ponytail* "$DEST/skills/"

clone diegosouzapw/OmniRoute omniroute skills
for d in "$TMP"/omniroute/skills/*/; do
  [ "$(basename "$d")" = ponytail ] || cp -r "$d" "$DEST/skills/"
done

clone Graphify-Labs/graphify graphify graphify/skills/claude
git -C "$TMP/graphify" sparse-checkout add --no-cone /graphify/skill.md >/dev/null 2>&1 || true
mkdir -p "$DEST/skills/graphify"
cp "$TMP/graphify/graphify/skill.md" "$DEST/skills/graphify/SKILL.md"
cp -r "$TMP/graphify/graphify/skills/claude/references" "$DEST/skills/graphify/"

# CLI requis par la skill graphify (optionnel, ne bloque pas si absent)
command -v graphify >/dev/null || pip install -q graphifyy 2>/dev/null || pipx install graphifyy 2>/dev/null || true

echo "Skills installées dans $DEST/skills : $(ls "$DEST/skills" | wc -l)"
