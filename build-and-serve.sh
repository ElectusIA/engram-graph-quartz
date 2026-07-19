#!/usr/bin/env bash
# Grafo web de UN dominio de memoria engram (parametrizable). Un grafo = un server = sus
# proyectos. Pipeline runtime: pull -> obsidian-export -> quartz build -> nginx. Auto-regen 12h.
# Tokens y lista de proyectos por env (Dokploy) — nunca en la imagen.
#   ENGRAM_SERVER   URL del server engram-cloud del dominio
#   ENGRAM_TOKEN    token con acceso a los proyectos
#   ENGRAM_PROJECTS lista separada por espacios de proyectos a incluir
#   SITE_TITLE      título del sitio
set -uo pipefail
export ENGRAM_DATA_DIR=/data ENGRAM_CLOUD_AUTOSYNC=0
export ENGRAM_SERVER="${ENGRAM_SERVER:?falta ENGRAM_SERVER}" ENGRAM_TOKEN="${ENGRAM_TOKEN:?falta ENGRAM_TOKEN}"
export ENGRAM_CLOUD_SERVER="$ENGRAM_SERVER" ENGRAM_CLOUD_TOKEN="$ENGRAM_TOKEN"

regen () {
  mkdir -p /data /vault
  echo "[1/3] pull ($ENGRAM_SERVER)"
  for p in $ENGRAM_PROJECTS; do
    engram cloud enroll "$p" >/dev/null 2>&1
    engram sync --cloud --import --project "$p" >/dev/null 2>&1 && echo "  ok $p" || echo "  parcial/skip $p"
  done
  echo "[2/3] obsidian-export"
  engram obsidian-export --vault /vault --graph-config force >/dev/null 2>&1 || true
  echo "[3/3] quartz build"
  rm -rf /quartz/content; mkdir -p /quartz/content
  [ -d /vault/engram ] && cp -r /vault/engram/. /quartz/content/
  cat > /quartz/content/index.md <<EOF
---
title: "${SITE_TITLE:-Memoria Electus}"
---
Grafo navegable de la memoria persistente (engram). Espejo de solo lectura regenerado desde
el server engram-cloud. Usa el grafo (esquina inferior) y la búsqueda (Ctrl+K).
EOF
  cd /quartz && npx quartz build --output /site 2>&1 | tail -3
}

regen
echo "== sirviendo /site (nginx) =="
nginx -g 'daemon off;' &
while true; do
  sleep 43200
  echo "== auto-regen ($(date -u)) =="
  regen && nginx -s reload || echo "regen falló; se conserva el sitio anterior"
done
