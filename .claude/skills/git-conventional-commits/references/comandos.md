# Cheat sheet de Git

## Estados de un archivo

- **Untracked**: nuevo, Git aún no lo rastrea.
- **Modified**: modificado pero no añadido al staging area.
- **Staged**: preparado para el próximo commit.
- **Committed**: guardado en el historial local.

## Configuración e inicialización

```bash
git init                                        # inicializar repositorio local
git clone <url>                                 # clonar repositorio remoto
git config --global user.name "Nombre"
git config --global user.email "correo@ejemplo.com"
git config --list                               # ver configuración efectiva
```

## Inspección y estado

```bash
git status                      # estado del working tree y del staging area
git status --short              # versión compacta
git diff                        # cambios aún no preparados
git diff --staged               # cambios ya preparados
git log --oneline --graph --all # historial gráfico resumido
git log -p <archivo>            # historial con diffs de un archivo
git show <hash>                 # detalle de un commit
```

## Staging y commits

```bash
git add <archivo>               # preparar un archivo concreto (preferido)
git add .                       # preparar todo el directorio actual
git add -p                      # preparar por fragmentos (ideal para commits atómicos)
git restore --staged <archivo>  # sacar del staging sin perder cambios
git restore <archivo>           # descartar cambios locales (DESTRUCTIVO)
git commit -m "mensaje"
git commit --amend -m "mensaje" # rehacer el último commit (solo sin push previo)
```

## Ramas

```bash
git branch                      # listar ramas locales
git branch -a                   # incluir ramas remotas
git branch --show-current       # rama actual
git switch -c <rama>            # crear y cambiar (equivale a checkout -b)
git switch <rama>               # cambiar de rama
git merge <rama>                # fusionar <rama> en la actual
git branch -d <rama>            # borrar rama ya fusionada
```

## Sincronización remota

```bash
git remote -v                   # remotos vinculados
git fetch                       # descargar sin fusionar
git pull origin <rama>          # descargar e integrar
git push origin <rama>          # subir commits
git push -u origin <rama>       # subir y establecer upstream la primera vez
```

## Guardar trabajo temporal

```bash
git stash                       # guardar cambios sin commitear
git stash list
git stash pop                   # recuperar el último stash
```

## Comandos que requieren confirmación del usuario

Destructivos o que reescriben historia — nunca ejecutar sin pedirlo explícitamente:

```bash
git reset --hard <ref>
git push --force / --force-with-lease
git rebase <rama>
git clean -fd
git branch -D <rama>
```
