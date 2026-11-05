# MON1 — Bocetos y arte de monedas

Etapa de monedas · 5 de noviembre de 2026.

**Rama:** `feature/monedas-arte`. **Depende de:** MON0. **Estado actual:** Sin empezar. **Decisiones vinculadas:** D10, D15.

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
