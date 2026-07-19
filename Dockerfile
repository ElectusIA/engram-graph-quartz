# Grafo web de la memoria engram del ecosistema Electus (Quartz + engram) — issue platform#49.
# El pipeline (pull de los servers -> obsidian-export -> quartz build) corre en RUNTIME,
# así los tokens llegan por env de Dokploy y no quedan en capas de la imagen.
FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates nginx \
    && rm -rf /var/lib/apt/lists/*

# Binario engram (release oficial linux amd64) — para pull + obsidian-export
ARG ENGRAM_VERSION=1.19.0
RUN curl -fsSL "https://github.com/Gentleman-Programming/engram/releases/download/v${ENGRAM_VERSION}/engram_${ENGRAM_VERSION}_linux_amd64.tar.gz" \
      | tar xz -C /usr/local/bin engram && chmod +x /usr/local/bin/engram

# Quartz (generador del sitio con grafo) — deps instaladas en build
RUN git clone --depth 1 https://github.com/jackyzha0/quartz /quartz \
    && cd /quartz && npm ci

COPY nginx.conf /etc/nginx/nginx.conf
COPY build-and-serve.sh /usr/local/bin/build-and-serve.sh
RUN chmod +x /usr/local/bin/build-and-serve.sh && mkdir -p /site

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/build-and-serve.sh"]
