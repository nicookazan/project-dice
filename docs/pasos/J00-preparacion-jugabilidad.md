# J00 — Preparación de la etapa de jugabilidad

Etapa de jugabilidad e interactividad · 4 de noviembre de 2026.

**Rama:** `feature/jugabilidad-preparacion`. **Estado actual:** Completado (ver `ESTADO.md`).

## Objetivo
Dejar listo el terreno de J01–J08 sin cambiar el comportamiento del juego.

## Trabajo realizado
1. Suite base corrida antes de tocar nada.
2. Fichas J01–J08 y decisiones D14.
3. Generadores de los bocetos pasados a `tools/art/bocetos-jugabilidad/` (`anim.py` consolidado con solo lo aprobado, `capture.gd`, `verify_drop.gd`, `stills.py`); reproducen byte a byte los GIF y PNG aprobados. Se corren con `py anim.py <tarea>` desde esa carpeta; las capturas salen de `capture.gd` a `test-results/bocetos/`.
4. Sprites del vaso: `tools/art/make_vaso_jugabilidad.py` genera `vaso-brillo-v3.png` y `vaso-frente-v3.png` (sin IA de imagen, sin tocar `vaso-v3.png`).
5. El chorro del sifón, la bandera ondulada y las poses de la mano se hacen en J05 y J07, junto con el código que las usa; no se generan acá.

## Plan completo
https://app.notion.com/p/40ec28142b55812da30cda3d6044f8b1
