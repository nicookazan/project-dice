# TX4 — Metales nuevos en el juego

Ítem 4 (texturas) · 7 de noviembre de 2026.

**Rama:** `feature/metales-juego`. **Depende de:** TX3. **Estado actual:** Completado el 07/11/2026; mecánicas provisionales. **Decisiones vinculadas:** D16 (puntos 4 y 4b).

## Objetivo
Que hierro oxidado, cobre oxidado y oro se compren y se jueguen con las mecánicas de los metales actuales. **No se inventa ninguna regla nueva.**

## Alcance
- Tabla única `Materials.TABLE`: cada metal indica su nombre, su cuerpo y de qué metal toma la mecánica (`base`). Hierro oxidado → acero, cobre oxidado → cobre, oro → acero.
- `materials.gd` resuelve cada metal por su base, con las mismas ganancias; previsión y anotación no cambian.
- Listas fijas ampliadas: `game.gd`, `shop.gd`, `validation_profile.gd`, `boss_rules.gd`, `save_validator.gd`, `coins.gd`.
- Los jefes que suspenden metales y la moneda que premia dados de metal tratan a cada metal nuevo como su base.
- Guardado: se amplía la lista de materiales válidos. El formato no cambia; no hace falta migrar.
- Interfaz: ficha del dado, inspección, recibos y el nombre «Hierro» salen de la tabla.

## Criterios de aceptación
- Se compran y puntúan en una partida normal; cada metal da lo mismo que su base.
- Previsión y anotación coinciden; las partidas viejas cargan; un metal nuevo se guarda y vuelve igual.

## Fuera de alcance
Mecánicas propias de los oxidados y del oro (las define el autor; si cambian el guardado llevan su migración); balance de precios y pesos (ítem 7).
