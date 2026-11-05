# MON3 — Pasivas nuevas

Etapa de monedas · 5 de noviembre de 2026.

**Rama:** `feature/monedas-pasivas`. **Depende de:** MON1, MON2. **Estado actual:** Completado (suite: 3645 comprobaciones, cero fallos). **Decisiones vinculadas:** D15 (punto 12).

## Objetivo
Agregar cinco pasivas nuevas, todas Raras.

## Trabajo a realizar
1. **C53 Tirada de reserva:** efecto `extra_rolls_first`, aplicado en `start_hand()` si es la mano 1.
2. **C54 Cobrador:** efecto `encounter_cash`, con fila propia en el cobro de `close_encounter()`. El validador la acepta sin exigirla a guardados viejos.
3. **C55 Veterano de nivel:** `scaled_mult` con `level_index + 1` en el contexto.
4. **C56 Servida:** solo datos, `cond_mult` con `first_roll` y +2.
5. **C57 Sobrantes:** `hand_points` por dado en "Sin combinación", calculado en `Rules.score`. El dado abducido no cuenta.
6. Usar `_active_passives()` en tiradas y plata, y corregir C20, que hoy da la tirada aunque esté suspendida.

## Criterios de aceptación
- Previsión igual a anotación para cada moneda, también en las filas de jugadas posibles.
- Servida se acumula con Primera tirada: +3 mult.
- Veterano de nivel da +0,25 en el nivel 1 y +1,75 en el nivel 7.
- Sobrantes da 0 con los 5 dados en combinación y cuenta el quinto dado con Escaleras de 4.
- Tirada de reserva solo aplica en la primera mano y se integra con Tiradas sin usar.
- Una moneda suspendida no aporta.
- Suite completa sin fallos; `tests/coin_batch_tests.gd` ajustado al nuevo total.
