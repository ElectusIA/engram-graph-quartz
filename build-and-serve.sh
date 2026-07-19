#!/usr/bin/env bash
# Pipeline en RUNTIME: trae la memoria de los servers engram-cloud de Electus,
# la exporta a Markdown y compila el sitio Quartz (grafo web). Luego nginx sirve.
# Los tokens llegan por env (Dokploy secrets) — nunca quedan en la imagen.
set -uo pipefail

export ENGRAM_DATA_DIR=/data
export ENGRAM_CLOUD_AUTOSYNC=0
mkdir -p /data /vault

pull () { # $1=server $2=token ; resto=proyectos
  # IMPORTANTE: usar SOLO env vars (ENGRAM_CLOUD_SERVER). `engram cloud config` escribe un
  # cloud.json con token vacío que el path de import prioriza -> 401. (gotcha real, #49)
  local server="$1" token="$2"; shift 2
  export ENGRAM_CLOUD_SERVER="$server" ENGRAM_CLOUD_TOKEN="$token"
  for p in "$@"; do
    engram cloud enroll "$p" >/dev/null 2>&1
    # import dependency-safe puede quedar parcial en datos legacy con relaciones huérfanas;
    # trae la mayoría de observaciones, suficiente para el grafo.
    engram sync --cloud --import --project "$p" >/dev/null 2>&1 \
      && echo "  ok $p" || echo "  parcial/skip $p"
  done
}

regen () { # pipeline completo: pull -> export -> quartz build
echo "[1/4] pull DEV ($ENGRAM_DEV_SERVER)"
pull "$ENGRAM_DEV_SERVER" "$ENGRAM_DEV_TOKEN" electus-platform electus electus-core electus-core-api electus-wpp electus-voice

echo "[2/4] pull MULTIAGENTE ($ENGRAM_MULTI_SERVER)"
pull "$ENGRAM_MULTI_SERVER" "$ENGRAM_MULTI_TOKEN" \
  electus-multiagente-n8n electus-multiagente-repo glosz maletaroja ocasojean \
  santorinniesthetic raptor roundtrip jaketiendaelectronica diferentecoleccionsegunnumero pruebanuevosmodelos

echo "[3/4] obsidian-export -> markdown"
engram obsidian-export --vault /vault --graph-config force >/dev/null 2>&1 || true

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
}

# --- primer build, luego servir y auto-regenerar cada 12h ---
regen
echo "== sirviendo /site (nginx) =="
nginx -g 'daemon off;' &
while true; do
  sleep 43200
  echo "== auto-regen ($(date -u)) =="
  regen && nginx -s reload || echo "regen fallo, se conserva el sitio anterior"
done
