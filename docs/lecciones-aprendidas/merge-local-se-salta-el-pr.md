---
fecha: 2026-08-02
contexto: Cierre del Módulo 1 y del sistema de lecciones aprendidas
categoria: proceso
severidad: media
estado: resuelto
---

# Fusionar en local produce el mismo árbol, pero destruye el punto de revisión

## Síntoma

Ninguno visible. El Módulo 1 quedó integrado en `main`, todos los ficheros en su sitio, `verify.sh`
en verde. El resultado en el árbol de trabajo era **exactamente** el que habría producido el flujo
correcto.

Lo que faltaba no estaba en los ficheros: faltaba el PR.

## Causa raíz

Fusioné la rama del Módulo 1 a `main` con `git merge --no-ff` en local, y presenté esa vía como la
recomendada. El flujo canónico es otro:

```text
rama local → push → PR → revisión → merge en el servidor → pull a local
```

Dos suposiciones equivocadas se sumaron:

1. **Que no había remoto.** Lo había: el repositorio ya existía y tenía dos ramas publicadas. No lo
   comprobé antes de proponer, porque `git remote -v` no formaba parte de mi rutina al planificar.
2. **Que "integrar en `main`" y "hacer merge" eran lo mismo.** En un repo sin remoto lo son. En
   cuanto hay servidor, el merge deja de ser una operación sobre ficheros y pasa a ser el momento en
   que algo se declara aprobado.

Lo que se pierde al saltárselo no es código, es **el registro**: el diff revisado, la ejecución de
la CI, la conversación y la constancia de quién aprobó qué. En un proyecto cuyo producto es
precisamente la trazabilidad, ese registro no es ceremonia — es parte del entregable.

## Cómo se detectó

No lo detecté yo. Lo detectó el usuario preguntando *"¿pero no debo hacer push primero y luego el PR
y merge?"* después de que yo diera el trabajo por cerrado.

La comprobación que habría bastado, antes de proponer cualquier estrategia de integración:

```bash
git remote -v          # ¿hay servidor?
git branch -r          # ¿qué hay publicado ya?
```

**La técnica generalizable**: antes de decidir cómo se integra el trabajo, averiguar si el
repositorio tiene servidor. La respuesta cambia por completo cuál es la operación correcta, y cuesta
dos comandos.

## Resolución

El merge local nunca llegó a publicarse, así que fue reversible por completo:

1. `git reset --hard origin/main` — `main` vuelve a su punto publicado. El commit de merge era la
   unión de dos commits alcanzables desde otras referencias, así que no se perdió contenido.
2. `git rebase --onto <rama-m1> <merge> <rama-lecciones>` — la rama de lecciones había nacido del
   `main` ya fusionado y arrastraba ese merge; el rebase lo elimina y deja sus commits limpios.
3. PR #1 y PR #2, revisados y fusionados en GitHub por el usuario.

Efecto colateral del paso 2, que merece su propia atención: el rebase reescribió los commits propios
y dejó **huérfano** un hash citado dentro de otra ficha. Seguía resolviendo en local por el reflog,
pero no pertenecía a la rama y nunca habría llegado al servidor. Corregido en `f31c52c`.

## Guardarraíl

**Exención parcial, justificada.** No hay causa técnica que un test del repositorio pueda detectar:
la decisión de fusionar en local la toma una persona antes de que exista código que comprobar.

Pero existe un guardarraíl real, y está en el servidor, no en el repo: **protección de rama sobre
`main` en GitHub**, exigiendo pull request. Con ella activada, un push directo a `main` es rechazado
por el propio servidor y la lección deja de depender de que alguien la recuerde.

Está **pendiente de activar**. Es configuración de GitHub, no código, y por eso queda fuera de
`verify.sh`.

Mientras tanto, la regla vive en la memoria del asistente y en `CLAUDE.md`: push, PR y merge los
ejecuta siempre el usuario.

## Lección transferible

Cuando dos caminos producen el mismo estado final, no son equivalentes si uno de ellos genera un
artefacto que el otro no. El merge local y el merge vía PR dejan el mismo árbol de ficheros; solo
uno deja constancia de que alguien lo revisó.

Y el corolario incómodo: **la ausencia de un registro no se nota**. Un fallo de código se manifiesta;
un control que nadie ejerció tiene exactamente el mismo aspecto que uno que sí se ejerció, hasta que
alguien pide la prueba. Por eso los controles de proceso conviene imponerlos desde el sistema —
protección de rama, revisión obligatoria— y no confiarlos a la disciplina.
