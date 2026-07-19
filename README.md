# engram-graph-quartz (Electus)

Publica la **memoria del ecosistema Electus** (engram) como un **sitio web con grafo navegable**
(Quartz), self-host en Dokploy. Issue `JAngelLM/electus-platform#49`.

## Cómo funciona

Un contenedor que, al arrancar (runtime), corre el pipeline `build-and-serve.sh`:
1. **Pull** de los proyectos de Electus desde los dos servers engram-cloud (dev + multiagente)
   a un SQLite local del contenedor.
2. **`engram obsidian-export`** → vault Markdown.
3. **Quartz build** → sitio estático con grafo, backlinks y búsqueda.
4. **nginx** sirve el sitio en `:8080`.

Los tokens llegan por **env de Dokploy** (nunca en la imagen). Regenerar = reiniciar/redeploy
el servicio (o un schedule que lo reinicie cada N horas).

## Envs (en Dokploy)

| Env | Valor |
|---|---|
| `ENGRAM_DEV_SERVER` | `https://engram.electusia.com` |
| `ENGRAM_DEV_TOKEN` | token con acceso a los proyectos dev |
| `ENGRAM_MULTI_SERVER` | `https://memoria-multiagente.electusia.com` |
| `ENGRAM_MULTI_TOKEN` | token con acceso a los proyectos del multiagente |

Solo Electus (dev + multiagente). Quipux tiene su propio engram y no se publica aquí.

## Provisional / notas

- Quartz es pre-1.0 y el vault de engram usa wikilinks + frontmatter, compatibles con Quartz.
- El sitio es espejo de solo lectura; se regenera desde los servers, no se edita.
