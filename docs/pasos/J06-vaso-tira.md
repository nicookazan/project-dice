# J06 — Vaso que tira (M6)

Etapa de jugabilidad e interactividad · 4 de noviembre de 2026.

**Rama:** `feature/vaso-tira`. **Depende de:** J01, J05. **Estado actual:** Pendiente. **Decisiones vinculadas:** D14.

## Objetivo
Que clic en el vaso o el botón TIRAR hagan la tirada con la animación aprobada (versión A).

## Fuente y alcance normativo
Plan de implementación en Notion (https://app.notion.com/p/40ec28142b55812da30cda3d6044f8b1) y bocetos aprobados por el autor (https://claude.ai/artifact/D74dybtbt4w1z4TfQn9zs9). Los valores de estilo salen de los bocetos y pueden ajustarse al verlos dentro del juego. Reglas comunes: la previsión coincide con la anotación; animaciones con azar aparte (nunca tocan semilla, estado ni guardado); respetan "Reducir movimiento" y la velocidad elegida; no dejan el juego trabado y se limpian al cambiar de pantalla; dados protegidos intactos.

## Trabajo a realizar
1. Clic en el vaso llama a `act(game.roll)`. El botón TIRAR usa la misma animación.
2. Sacudida con los dados detrás de la pared, sube a (1230, 372), se inclina 118° y vuelve. Los dados parten de la boca rotada (88 px del centro) y terminan en los lugares de `loose_die_pose()`.
3. Vaso dibujado aparte durante la animación (hoy es parte del fondo).
4. Movimiento reducido o velocidad 0: tirada directa. Confirmar jugando que ~3 s no se haga pesado frente a los 0,85 s actuales.

## Criterios de aceptación
- Misma semilla, mismo resultado con clic o botón.
- No se puede tirar dos veces durante la animación.
- Dados retenidos no se mueven; si se relanzan pocos, solo salen esos.
- Suite completa sin fallos y revisión en el juego con capturas en `test-results/`.

## Fuera de alcance
T4 (vendedor enojado), monedas, tutorial, La Semilla, pantallas nuevas y balance.
