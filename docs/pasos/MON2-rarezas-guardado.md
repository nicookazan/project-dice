# MON2 — Rarezas y guardado v9

Etapa de monedas · 5 de noviembre de 2026.

**Rama:** `feature/monedas-rarezas`. **Depende de:** MON0. **Estado actual:** Completado (suite: 3481 comprobaciones, cero fallos). **Decisiones vinculadas:** D15.

## Objetivo
Aplicar los 10 cambios de rareza y dejar el guardado listo para el resto de la etapa.

## Trabajo a realizar
1. **Rara → Común:** C16 Puntos de generala, C22 Dados de metal, C23 Dados elementales, C24 Gemas, C35 Seises.
2. **Común → Rara:** C21 Renovación gratis, C37 Tiradas sin usar, C38 Última tirada, C39 Segunda mano, C42 Interés.
3. Subir `SaveStore.VERSION` de 8 a 9 y corregir `CLAUDE.md`, que todavía dice v7.
4. Campos nuevos, todos juntos: `hand_mult_bonus`, `hand_points_bonus`, `visit_discount`, `boss_shield_active`, `once_coins_seen`, `pending_coin_pack`.
5. Migración `coins_v9`: rellena lo que falta y reconstruye `shop_tables.coins` con el catálogo vigente. No toca semilla, azar, plata, inventario ni ofertas ya generadas.

## Criterios de aceptación
- Un guardado v8 migra sin cambiar el progreso, y migrar dos veces da lo mismo.
- Rarezas, precios y reventas coinciden con la tabla del plan.
- Suite completa sin fallos.

## Límites
Las ofertas ya generadas conservan su precio hasta renovarse; la reventa cambia de inmediato. Un guardado v9 hecho entre pasos no recibe las monedas agregadas después: para probar cada paso, usar partida nueva. Los guardados v8 toman el catálogo al cargar.
