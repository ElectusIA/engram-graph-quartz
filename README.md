# engram-graph-quartz (Electus)

Publica la **memoria engram** de un dominio como un **sitio web con grafo navegable**
(Quartz), self-host en Dokploy. Issue `JAngelLM/electus-platform#49`.

## Principio: un grafo por dominio

Un grafo = un server engram-cloud = sus proyectos = su dominio. La misma imagen se
despliega N veces (una app Dokploy por dominio), parametrizada por env. Así el grafo del
**ecosistema Electus (desarrollo)** y el del **multiagente (cerebro n8n)** quedan
separados y sin contaminarse.

| App Dokploy | Dominio | Server | Proyectos |
|---|---|---|---|
| `engram-grafo` | `grafo.electusia.com` | `engram.electusia.com` (dev) | `electus-platform electus electus-core electus-core-api electus-wpp electus-voice` |
| `engram-grafo-multiagente` | `grafo-multiagente.electusia.com` | `memoria-multiagente.electusia.com` | `electus-multiagente-n8n` + clientes-bots |

## Cómo funciona

Un contenedor que, al arrancar (runtime), corre `build-and-serve.sh`:
1. **Slate limpio** (`rm -rf /data`): el grafo contiene SOLO sus `ENGRAM_PROJECTS`.
2. **Pull** de esos proyectos desde el server engram-cloud del dominio (3 pases: el
   import dependency-safe avanza pese a relaciones legacy huérfanas).
3. **`engram obsidian-export`** → vault Markdown.
4. **Quartz build** → sitio estático con grafo, backlinks y búsqueda.
5. **nginx** sirve el sitio en `:8080`. Auto-regen cada 12 h.

Los tokens llegan por **env de Dokploy** (nunca en la imagen).

## Envs (en Dokploy, por app)

| Env | Ejemplo |
|---|---|
| `ENGRAM_SERVER` | `https://engram.electusia.com` |
| `ENGRAM_TOKEN` | token con acceso a los proyectos del dominio |
| `ENGRAM_PROJECTS` | lista separada por espacios de proyectos a incluir |
| `SITE_TITLE` | `Memoria — Electus Platform (desarrollo)` |

Solo Electus (dev + multiagente). Quipux tiene su propio engram y no se publica aquí.

## Notas

- Quartz pineado a `v4.5.2` (`master` viene roto: `Could not resolve ../../.quartz/plugins`).
- El sitio es espejo de solo lectura; se regenera desde el server, no se edita.
- Regenerar ahora = redeploy de la app (o esperar el ciclo de 12 h).
- Dominio nuevo ⇒ el operador crea el registro DNS `A → 2.25.68.253`; el cert Let's
  Encrypt se emite solo tras el primer acceso (si el DNS ya resolvía).
