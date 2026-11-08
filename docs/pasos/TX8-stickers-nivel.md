# TX8 — Stickers por nivel (calcomanía y medallón)

Ítem 4 (texturas) · 7 de noviembre de 2026.

**Rama:** `feature/stickers-nivel`. **Depende de:** Ninguna. **Estado actual:** En curso (PR abierto, sin mergear). **Decisiones vinculadas:** D17.

## Objetivo
Que los seis stickers se vean como el resto del juego: calcomanía brillante hasta el nivel 9 y medallón dorado desde el nivel 10, con el dado modelo del autor.

## Alcance
- Generador `tools/art/make_stickers_v4.py`: hojas grande (52×52) y chica (19×19) en estilo A y B, y la hoja girada del termo en cada estilo.
- `sticker_art.gd` elige el estilo con `style_for_level(level)`; el umbral es la constante `GOLD_FROM_LEVEL = 10`.
- Se pasa el nivel a quienes dibujan stickers: termo (mesa y tienda), oferta, álbum, vuelo y revelado.
- En tienda y álbum el sticker se dibuja a 104 px (52 × 2), sin estirar.

## Criterios de aceptación
- Nivel 9 dibuja A y nivel 10 dibuja B en todas las vistas.
- Las zonas de clic y los lugares del termo (`THERMOS_SPOTS`) no se mueven.
- Suite sin fallos y capturas en `test-results/`.

## Fuera de alcance
Animación propia del salto al nivel 10; cambios de reglas o de guardado.
