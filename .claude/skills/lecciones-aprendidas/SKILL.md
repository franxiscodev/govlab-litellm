---
name: lecciones-aprendidas
description: Capturar conocimiento no obvio del proyecto en fichas temáticas — usar al cerrar un módulo, una feature o una sesión larga de depuración, cuando haya habido hallazgos que merezca la pena no olvidar. Se activa con "lección aprendida", "lecciones aprendidas", "incidencia", "postmortem", "documentar el fallo", "descubrimiento", "esto nos volverá a pasar", "no era lo que parecía", "registrar lo que aprendimos".
---

# Lecciones aprendidas

Método para convertir hallazgos, incidencias e imponderables en fichas reutilizables, en lugar de
dejarlos en mensajes de commit y en conversaciones que se pierden.

Una ficha responde a **qué aprendimos**; el commit que arregló el problema ya responde a **qué
cambiamos**. Son cosas distintas y viven en sitios distintos.

## Reglas no negociables

1. **Nunca proponer una ficha a mitad de una tarea.** Los hallazgos se anotan en silencio y se sigue
   trabajando.
2. **Nunca escribir una ficha sin confirmación explícita del usuario.** Ni siquiera cuando parezca
   evidente que la merece.
3. **Como mucho una propuesta por tarea.** Si la respuesta es que no, se acepta y no se insiste.
4. **Toda ficha con causa técnica necesita un guardarraíl**, y hay que comprobar que ese guardarraíl
   falla *antes* del arreglo.
5. **Ningún secreto, credencial, dato de cliente ni PII** dentro de una ficha.

---

## 1. Cuándo proponer — y cuándo callarse

Esta es la sección que decide si el sistema se usa o acaba ignorado. Interrumpir con "¿documentamos
esto?" cada vez que algo sorprende lo convierte en ruido.

### Momento

Solo al **cerrar una unidad de trabajo grande**: un módulo del roadmap, una feature con varios
commits, una sesión larga de depuración. Nunca durante.

### Umbral de relevancia

Hace falta al menos uno:

- Un hallazgo de severidad **alta** — llegó, o habría llegado, a producción.
- **Dos o más** hallazgos de severidad media acumulados en la misma tarea.
- Una decisión de arquitectura cuyo porqué no se deduce del código ni del historial.

Si nada alcanza el umbral, **no se dice nada**. El silencio es la respuesta correcta por defecto.

### Filtrar antes de listar

El umbral se aplica **a cada candidata por separado**, no al lote. Que la tarea haya generado un
hallazgo grave no autoriza a colar detrás los menores "ya que estamos".

Antes de escribir la propuesta, descartar todo lo que no supere el umbral **por sí solo**. Lo
descartado no se menciona, ni siquiera como nota al margen: mencionarlo es proponerlo.

Una lista de cuatro candidatas en la que solo una importa entrena al usuario a desconfiar de la
lista entera, y a partir de ahí el sistema deja de servir.

### Forma de la propuesta

Una lista de candidatas —**solo las que pasaron el filtro**—, una línea cada una, y esperar
respuesta:

```text
Cierro el Módulo 1. Tres hallazgos que creo que merecen ficha:

  1. Health check verde con Redis desconectado           (infraestructura, alta)
  2. LiteLLM_SpendTable no existe, es LiteLLM_SpendLogs   (datos, alta)
  3. os.environ/ solo vale dentro de config.yaml          (herramientas, media)

¿Las registro? Puedes decirme todas, algunas o ninguna.
```

El usuario puede aceptar todas, algunas o ninguna.

### Una propuesta abierta bloquea el avance

Si la respuesta **no se pronuncia sobre las candidatas** —cambia de tema, da una instrucción nueva,
responde a otra cosa de la misma sesión— la propuesta sigue **abierta**. No se interpreta como un sí
ni como un no.

En ese caso: **volver a preguntar antes de empezar la siguiente tarea**, en una línea y sin repetir
la lista entera.

```text
Antes de seguir: quedó sin responder si registro las 2 fichas que propuse. ¿Las hago?
```

Y solo entonces continuar. El motivo es que el material se degrada rápido: los detalles que hacen
útil una ficha —la salida exacta, el comando que reveló la causa, por qué despistaba el síntoma—
viven en el contexto de la sesión y se pierden al cambiar de tarea. Escrita al día siguiente, la
ficha ya es un resumen de memoria.

Esto **no contradice** la regla de una sola propuesta por tarea: la relanzada no es una propuesta
nueva, es la misma esperando respuesta. Si tras la relanzada tampoco hay pronunciamiento, se toma
como un no y se sigue sin volver a mencionarlo.

### Patrón que reaparece

Si un hallazgo nuevo encaja en una ficha existente, **se amplía esa ficha** con una entrada fechada
en lugar de crear una segunda. Dos fichas sobre el mismo patrón valen menos que una con dos casos.

---

## 2. Qué merece ficha

Basta con uno:

- La realidad contradijo a la documentación, oficial o propia.
- Un fallo tardó en diagnosticarse porque el síntoma apuntaba a otro sitio.
- Algo parecía correcto y no lo estaba: verde engañoso, test que no probaba nada.
- Se tomó una decisión no obvia cuyo porqué no se deduce del código.
- Un imponderable del entorno obligó a cambiar de enfoque.

**Y qué no**, para que el archivo siga siendo legible:

- Erratas, fallos triviales, cosas resueltas en un minuto.
- Lo que el historial de git ya cuenta bien por sí solo.
- Preferencias personales del usuario: eso es memoria, no lección de proyecto.

---

## 3. La regla del guardarraíl

Toda ficha con causa técnica debe terminar en un test, comprobación o aserción que haga fallar el
sistema si el problema reaparece. Hay que **verificar que ese guardarraíl falla antes del arreglo**:
un test que nunca ha fallado no demuestra nada.

Una lección sin guardarraíl es una anécdota.

La exención existe solo para fichas **sin causa técnica** — decisiones, imponderables de proceso — y
debe justificarse dentro de la propia ficha. Antes de invocarla, agotar las opciones baratas: un
`grep` sobre un fichero de configuración suele bastar y cuesta tres líneas.

---

## 4. Dónde viven y cómo se llaman

Ruta por defecto: **`docs/lecciones-aprendidas/`**.

Nombre en `kebab-case` **temático**, sin fecha (va en el frontmatter). El nombre describe el
**patrón**, no el incidente concreto:

| Bien | Mal | Por qué |
|---|---|---|
| `salud-aparente-vs-real.md` | `bug-redis-m1.md` | El patrón reaparecerá en otro módulo con otro servicio |
| `nombres-de-esquema-sin-verificar.md` | `tabla-spendtable.md` | El nombre concreto de la tabla es un detalle del caso |

### Frontmatter

| Campo | Valores |
|---|---|
| `fecha` | ISO `AAAA-MM-DD` |
| `contexto` | Texto libre que sitúa el hallazgo (en un proyecto con roadmap, el módulo) |
| `categoria` | `infraestructura` · `datos` · `seguridad` · `proceso` · `herramientas` · `documentacion` |
| `severidad` | `alta` (llegó o habría llegado a producción) · `media` (coste real de diagnóstico) · `baja` (detectado a tiempo, se documenta por el patrón) |
| `estado` | `resuelto` (arreglado y con guardarraíl) · `mitigado` (apaño temporal, falta el fondo) · `abierto` (documentado, sin resolver) |

Ver la plantilla completa en [references/plantilla.md](references/plantilla.md).

### Enlaces

- Al commit que resolvió el hallazgo, por su **hash corto**.
- Al fichero del guardarraíl, con **ruta relativa desde la carpeta de fichas**
  (p. ej. `../../ruta/al/script.sh`). Son los enlaces que más se rompen: comprobarlos.

---

## 5. Higiene

Nunca volcar en una ficha secretos, claves, tokens, datos de cliente ni PII. Si el incidente los
involucra, describir **la forma del dato, no el dato**: "una clave de 48 caracteres en base64", no
la clave.

---

## 6. Índice

Crear `README.md` en la carpeta a partir de la **tercera ficha**; por debajo se lee sola.

Tabla ordenada por fecha descendente, con columnas **Fecha · Ficha · Categoría · Severidad ·
Lección en una línea**. Esa última columna es la que da unidad de criterio: permite escanear todo el
aprendizaje del proyecto sin abrir un solo fichero.

Al añadir una ficha, añadir su fila.

---

## 7. Git

Cada ficha en su propio commit `docs(lecciones): …`, **separado del arreglo que la originó**.

```bash
git commit -m "docs(lecciones): registrar salud aparente frente a salud real"
```

Ver la skill [git-conventional-commits](../git-conventional-commits/SKILL.md) para el resto de
convenciones.

---

## 8. Estado y evolución

> **Esta skill está en pruebas.** Los criterios de abajo son una primera propuesta, no una norma
> asentada. Se corrigen en cuanto fallen en la práctica.

Cuando algo de esto ocurra, **decirlo en voz alta y proponer la mejora concreta** en lugar de
apañarlo en silencio:

- Un hallazgo real no encaja en ninguna `categoria`, `severidad` o `estado` existente.
- La plantilla se queda corta, o sobra una sección, para un caso concreto.
- El umbral de relevancia deja fuera algo que sí importaba.
- Aparecen propuestas de ficha en tareas pequeñas — **síntoma de umbral mal calibrado**.
- El momento de propuesta resulta ser el equivocado.
- Dos fichas acaban solapándose: la nomenclatura no separa bien los patrones.

Regla operativa:

> **Si hay que forzar la plantilla para que algo entre, el defecto es de la skill, no de la ficha.**

Cada mejora acordada se aplica en su propio commit `feat(skills)` o `fix(skills)`, de modo que la
evolución del criterio quede trazada igual que la del código.

### Criterios pendientes

Dudas abiertas que todavía no merecen regla fija:

- Si el índice debería autogenerarse desde el frontmatter cuando la carpeta crezca.
- Si conviene un campo `relacionadas:` para enlazar patrones recurrentes entre módulos.
- Si las fichas en estado `abierto` deberían caducar y forzar una revisión pasado un tiempo.
