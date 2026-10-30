#!/bin/zsh
set -eu
PROJECT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
if command -v godot >/dev/null 2>&1; then
  exec godot --path "$PROJECT_DIR" "$@"
fi
for GODOT_BIN in "/Applications/Godot.app/Contents/MacOS/Godot" "$HOME/Applications/Godot.app/Contents/MacOS/Godot"; do
  if [ -x "$GODOT_BIN" ]; then
    exec "$GODOT_BIN" --path "$PROJECT_DIR" "$@"
  fi
done
printf '%s\n' 'No se encontró Godot. Abrí project.godot desde Godot 4.7.1, o instalá Godot.app en Aplicaciones.'
printf '%s' 'Presioná Enter para cerrar.'
read -r CLOSE_REPLY
