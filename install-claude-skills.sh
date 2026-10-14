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

# Consigne globale : interview automatique sur les vraies décisions
if ! grep -q "INTERVIEW-AUTO" "$DEST/CLAUDE.md" 2>/dev/null; then
cat >> "$DEST/CLAUDE.md" <<'MD'
<!-- INTERVIEW-AUTO -->
## Interview avant les décisions importantes
Quand je lance un projet (perso, cours, pro), une fonctionnalité, ou que je dois prendre
une décision qui engage du temps, de l'argent ou un choix difficile à défaire :
- Utilise la skill `interview-me` AVANT de proposer une solution ou d'écrire du code.
- Une seule question à la fois, la plus utile d'abord, en proposant ta recommandation.
- Arrête-toi dès que tu as compris l'objectif, le public, les contraintes et le critère
  de réussite (en général 3 à 6 questions), puis résume ce que tu as compris.
- Pour un projet de code, enchaîne ensuite : spec-driven-development, puis
  planning-and-task-breakdown, puis code en mode ponytail.

Ne fais PAS d'interview pour les questions simples ou factuelles (une recette, une
définition, une commande, un petit bug évident) : réponds directement.
Si je dis « pas d'interview » ou « fonce », réponds directement.
MD
fi

echo "Skills installées dans $DEST/skills : $(ls "$DEST/skills" | wc -l)"
