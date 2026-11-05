# MON0 — Preparación de la etapa de monedas

Etapa de monedas (ítem 5 de los pendientes posteriores al paso 20) · 5 de noviembre de 2026.

**Rama:** `feature/monedas-preparacion`. **Estado actual:** Completado. **Decisiones vinculadas:** D15.

## Objetivo
Dejar listo el terreno de MON1–MON9 sin cambiar el comportamiento del juego.

## Trabajo realizado
1. Suite base corrida antes de tocar nada: 3452 comprobaciones, cero fallos.
2. Fichas MON0–MON9 sumadas al índice.
3. Decisiones confirmadas por el autor, registradas en D15.

## Plan completo
https://app.notion.com/p/40fc28142b5580f78431fc36d9e1f587

## Reglas comunes de la etapa
- La previsión coincide con la anotación: todo efecto pasa por `Rules.score` y `Game.coin_context()`.
- El azar es reproducible por semilla y exacto tras guardar y continuar.
- Mirar, inspeccionar o cerrar paneles no consume azar ni cambia ofertas.
- Precios, pesos y cantidades viven en tablas y son provisionales hasta el ítem 7.
- Nunca se sobrescribe un guardado inválido.
- Los dados protegidos no se tocan. Arte nuevo: generador en `tools/art/` y procedencia en `ART-PROMPTS.md`.
