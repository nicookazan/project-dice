# MON1 — Bocetos y arte de monedas

Etapa de monedas · 5 de noviembre de 2026.

**Rama:** `feature/monedas-arte`. **Depende de:** MON0. **Estado actual:** Completado (suite: 3543 comprobaciones, cero fallos). **Decisiones vinculadas:** D10, D15.

**Resultado:** bocetos aprobados por el autor el 5 de noviembre de 2026 e integrados tal cual. En vez de extender `make_coins.gd`, las monedas nuevas salen de `tools/art/make_coins_nuevas.gd` hacia una hoja aparte (`coins-nuevas-v3.png`, 6 × 3): así `coins-v3.png` queda intacto por construcción, y la prueba lo verifica por hash. `scripts/coin_art.gd` elige la hoja según el id. Los ids (`NEW_IDS`) son los que usarán MON3 a MON8: `extra_hand`, `reserve_roll`, `collector`, `level_veteran`, `served`, `leftovers`, `reroll_all`, `mult_plus2`, `points_bag`, `flip_die`, `two_rolls`, `boss_shield`, `quick_cash`, `visit_discount`, `repair_all`, `even_boost`, `pack_small`, `pack_large`.

**Pendiente de decidir:** el borde por rareza solo cumple en las monedas nuevas; las 8 originales no lo siguen. Tres bocetos quedaron más flojos (Cobrador, Reparar todas, Impulso par) y el autor los aprobó así.

## Objetivo
Dibujar las 16 monedas nuevas y los 2 paquetes, con aprobación del autor antes de integrarlos.

## Trabajo a realizar
1. Bocetos de 32 × 32 px: 16 monedas y paquete chico y grande. Se publican en una página para aprobarlos. No se integra nada antes.
2. Extender `tools/art/make_coins.gd`. Las 8 monedas actuales quedan idénticas, píxel por píxel.
3. `scripts/coin_art.gd` hoy divide la hoja en 2 filas fijas: calcular filas según la cantidad y sumar los ids a `IDS`.
4. Icono cerrado del paquete, sin mostrar lo que trae.
5. Procedencia en `ART-PROMPTS.md`.

## Criterios de aceptación
- Las 8 celdas actuales no cambian y cada moneda nueva toma su celda.
- Las monedas sin arte siguen mostrando su abreviatura.
- Suite completa sin fallos.

## Fuera de alcance
Arte de las 43 monedas que hoy ya son provisionales.
