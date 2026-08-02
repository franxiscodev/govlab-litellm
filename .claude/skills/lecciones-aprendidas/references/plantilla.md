# Plantilla de ficha

Copiar el bloque de abajo a `docs/lecciones-aprendidas/<patron-en-kebab-case>.md` y rellenar.
Los valores válidos de cada campo están en [SKILL.md](../SKILL.md) §4.

Borrar las líneas en cursiva: son indicaciones, no contenido.

---

```markdown
---
fecha: AAAA-MM-DD
contexto: <qué se estaba haciendo — en un proyecto con roadmap, el módulo>
categoria: infraestructura | datos | seguridad | proceso | herramientas | documentacion
severidad: alta | media | baja
estado: resuelto | mitigado | abierto
---

# <Título en una línea: el patrón, no el incidente>

## Síntoma

*Qué se vio, tal cual se vio, antes de saber la causa. Incluir la salida real de comandos o los
mensajes de error literales — es lo que hace la ficha buscable cuando el patrón reaparezca.*

## Causa raíz

*Por qué ocurría en realidad. Si el síntoma apuntaba a otro sitio, decir explícitamente hacia dónde
apuntaba y por qué despistaba.*

## Cómo se detectó

*La técnica de diagnóstico, que es lo reutilizable. Qué comando, qué comprobación o qué pregunta
reveló la verdad. Esta sección existe aparte de la causa raíz porque el método vale más que el
hallazgo concreto.*

## Resolución

*El arreglo, con enlace al commit por su hash corto.*

## Guardarraíl

*El test o comprobación que hace fallar el sistema si esto reaparece, con ruta relativa al fichero
y confirmación de que se verificó fallando antes del arreglo.*

*Si no hay guardarraíl, esta sección debe justificar por qué no lo hay. Solo vale para fichas sin
causa técnica, y hay que haber descartado antes las opciones baratas.*

## Lección transferible

*Una o dos frases que puedan leerse sin conocer el proyecto. Es la parte que sobrevive al stack, al
lenguaje y a la empresa — y la que sirve como material docente.*
```

---

## Notas de redacción

- **Título**: nombra el patrón. `Un health check verde no prueba que el servicio haga su trabajo`
  es útil dentro de tres módulos; `Fallo de Redis en el M1` no.
- **Síntoma antes que causa**: el orden importa. Quien lea la ficha en el futuro llegará con el
  síntoma en la mano, no con la causa.
- **Sin secretos**: describir la forma del dato, nunca el dato.
- **Patrón que reaparece**: no crear una ficha nueva. Añadir a la existente una sección
  `## Reaparición — AAAA-MM-DD` con el caso nuevo.
