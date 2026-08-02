---
name: git-conventional-commits
description: Flujo de trabajo Git con Conventional Commits — usar al crear commits, ramas, sincronizar con el remoto o revisar el historial. Se activa con "commit", "commitear", "crear rama", "branch", "push", "pull", "merge", "changelog", "conventional commits", "guardar cambios en git".
---

# Git y Conventional Commits

Guía operativa para trabajar con Git generando un historial limpio, atómico y apto para changelogs automáticos y versionado semántico.

Esta skill cubre el **contenido del mensaje** de commit.

## Reglas no negociables

1. **Nunca `git push --force`** sobre ramas compartidas (`main`, `master`, `develop`). Si hace falta reescribir historia publicada, avisar al usuario y esperar confirmación explícita.
2. **Nunca commitear directamente en `main`/`master`** una funcionalidad o corrección. Crear primero una rama de trabajo.
3. **Siempre inspeccionar antes de commitear**: `git status` y `git diff` para no incluir temporales, logs, `.env` ni credenciales.
4. **Atomicidad**: un commit = un cambio lógico. No mezclar refactor masivo con fix de bug.
5. **Verificar el formato Conventional Commits** antes de confirmar el mensaje.

## Flujo estándar

```bash
# 1. Estado actual
git status
git branch --show-current

# 2. Rama de trabajo (si estamos en main/master)
git checkout -b feature/nombre-descriptivo-kebab-case

# 3. Revisar lo que se va a incluir
git diff
git add <archivos-concretos>   # preferible a `git add .`
git diff --staged

# 4. Commit
git commit -m "tipo(scope): descripción en imperativo"

# 5. Sincronizar
git pull origin main
git push origin <rama-actual>
```

## Formato del mensaje

```text
<tipo>[scope opcional]: <descripción breve en imperativo>

[cuerpo opcional con el porqué del cambio]

[pie: BREAKING CHANGE: ... / Closes #123]
```

- Descripción en **imperativo** y minúscula: "añadir", "corregir", "actualizar" — nunca "añadido"/"corregido".
- Sin punto final. Idealmente ≤ 72 caracteres la primera línea.
- El `scope` es el módulo o área afectada: `auth`, `api`, `readme`, `database`.

### Tipos permitidos

| Tipo | Cuándo usarlo |
|---|---|
| `feat` | Nueva funcionalidad para el usuario |
| `fix` | Corrección de un bug |
| `docs` | Solo documentación (README, comentarios) |
| `style` | Formato, espacios, punto y coma — sin cambio de significado |
| `refactor` | Reestructuración sin corregir bugs ni añadir features |
| `perf` | Mejora de rendimiento |
| `test` | Añadir o corregir pruebas |
| `build` | Sistema de compilación o dependencias (npm, maven, gradle) |
| `ci` | Configuración de CI/CD (GitHub Actions, GitLab CI) |
| `chore` | Mantenimiento general que no toca código fuente ni pruebas |

### Ejemplos

```bash
git commit -m "feat(auth): implementar inicio de sesión con token JWT"
git commit -m "fix(api): solucionar error 500 al enviar datos vacíos en el formulario"
git commit -m "docs(readme): añadir instrucciones de instalación local"
```

Breaking change (el `!` y/o el pie son obligatorios):

```bash
git commit -m "feat(database)!: cambiar esquema de usuarios

BREAKING CHANGE: la estructura de la tabla de usuarios ha cambiado y requiere migración."
```

## Nombres de rama

- `feature/agregar-filtro-busqueda` — nueva funcionalidad
- `fix/error-login-nulo` — corrección de bug
- `hotfix/caida-pagos-produccion` — urgencia sobre producción
- Siempre kebab-case, derivadas de `main` (o `develop` si el proyecto la usa).

## Situaciones concretas

**Conflictos en `pull`/`merge`**: no resolver a ciegas. Listar los archivos en conflicto (`git status`), mostrar al usuario las secciones enfrentadas y proponer una resolución que preserve la intención de ambos lados. Confirmar antes de `git add` de los archivos resueltos.

**Corregir el último commit** (solo si aún **no** se ha hecho push): `git commit --amend -m "nuevo mensaje"`.

**Repositorio sin inicializar**: ofrecer `git init` en vez de asumirlo.

**Muchos cambios dispares en el working tree**: proponer dividirlos en varios commits con `git add` selectivo, no empaquetar todo junto.

## Referencia de comandos

Ver [references/comandos.md](references/comandos.md) para el cheat sheet completo (configuración, inspección, ramas, remotos).
