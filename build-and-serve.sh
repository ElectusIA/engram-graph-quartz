#!/usr/bin/env bash
# Pipeline en RUNTIME: trae la memoria de los servers engram-cloud de Electus,
# la exporta a Markdown y compila el sitio Quartz (grafo web). Luego nginx sirve.
# Los tokens llegan por env (Dokploy secrets) — nunca quedan en la imagen.
set -uo pipefail

export ENGRAM_DATA_DIR=/data
export ENGRAM_CLOUD_AUTOSYNC=0
mkdir -p /data /vault

pull () { # $1=server $2=token ; resto=proyectos
  local server="$1" token="$2"; shift 2
  ENGRAM_CLOUD_TOKEN="$token" engram cloud config --server "$server" >/dev/null 2>&1
  for p in "$@"; do
    ENGRAM_CLOUD_TOKEN="$token" engram cloud enroll "$p" >/dev/null 2>&1
    ENGRAM_CLOUD_TOKEN="$token" engram sync --cloud --import --project "$p" >/dev/null 2>&1 \
      && echo "  ok $p" || echo "  WARN $p (sin datos o error)"
  done
}

echo "[1/4] pull DEV ($ENGRAM_DEV_SERVER)"
pull "$ENGRAM_DEV_SERVER" "$ENGRAM_DEV_TOKEN" electus-platform electus electus-core electus-core-api electus-wpp electus-voice

echo "[2/4] pull MULTIAGENTE ($ENGRAM_MULTI_SERVER)"
pull "$ENGRAM_MULTI_SERVER" "$ENGRAM_MULTI_TOKEN" \
  electus-multiagente-n8n electus-multiagente-repo glosz maletaroja ocasojean \
  santorinniesthetic raptor roundtrip jaketiendaelectronica diferentecoleccionsegunnumero pruebanuevosmodelos

echo "[3/4] obsidian-export -> markdown"
engram obsidian-export --vault /vault --graph-config force >/dev/null 2>&1 || true
STAMP="$(engram stats 2>/dev/null | tr -d '\r' | head -1)"

echo "[4/4] quartz build"
rm -rf /quartz/content
cp -r /vault/engram /quartz/content
cat > /quartz/content/index.md <<EOF
---
title: "Memoria del ecosistema Electus"
---
Grafo navegable de la memoria persistente (engram) del ecosistema Electus: desarrollo + multiagente.
Espejo de solo lectura, regenerado desde los servers engram-cloud. Usa el grafo (esquina) y la búsqueda.
EOF
cd /quartz && npx quartz build --output /site 2>&1 | tail -5

echo "== sirviendo /site =="
exec nginx -g 'daemon off;'
