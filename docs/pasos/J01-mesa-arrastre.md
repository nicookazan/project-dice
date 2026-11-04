# J01 — Vaso, arrastre y Reservar (M1)

Etapa de jugabilidad e interactividad · 4 de noviembre de 2026.

**Rama:** `feature/mesa-arrastre`. **Depende de:** J00 (preparación). **Estado actual:** Pendiente. **Decisiones vinculadas:** D14.

## Objetivo
Que soltar un dado sobre el vaso, el termo o la tela libre lo mande al vaso, y que la tela izquierda coincida con su borde dorado.

## Fuente y alcance normativo
Plan de implementación en Notion (https://app.notion.com/p/40ec28142b55812da30cda3d6044f8b1) y bocetos aprobados por el autor (https://claude.ai/artifact/D74dybtbt4w1z4TfQn9zs9). Los valores de estilo salen de los bocetos y pueden ajustarse al verlos dentro del juego. Reglas comunes: la previsión coincide con la anotación; animaciones con azar aparte (nunca tocan semilla, estado ni guardado); respetan "Reducir movimiento" y la velocidad elegida; no dejan el juego trabado y se limpian al cambiar de pantalla; dados protegidos intactos.

## Trabajo a realizar
1. Reenviar el arrastre desde `InspectCup` (`render_table()`) y `InspectThermos` (`finish_render()`) a la zona `cup` con `set_drag_forwarding`, sin perder el clic.
2. Nuevo `scripts/felt_layout.gd` con el borde dorado de la tela izquierda: arriba y=316, abajo y=652, derecha x=694, izquierda `x = 392 - 0,1692 × (y - 340)`.
3. Zona izquierda con la forma de la tela (hoy es el rectángulo 366,324,325,330 y deja afuera la esquina inferior izquierda).
4. "Reservar": polígono `Color(0.46, 0.025, 0.10, 0.62)`, sin recuadro, palabra centrada; solo mientras se arrastra un dado de la mesa. El dado sigue armando grupo (decisión D14-1).
5. Brillo dorado del vaso (`assets/art/pixel-v3/vaso-brillo-v3.png`) en `Rect2(1264, 410, 176, 220)`: crece al acercarse el dado, se apaga al alejarse.
6. Dado que entra: cae por la boca y queda detrás de `vaso-frente-v3.png` (solo presentación).
7. Corregir `show_options()`: "Armar grupos arrastrando" pisa el texto de abajo.

## Criterios de aceptación
- Soltar sobre el vaso, el termo y la tela libre manda el dado al vaso.
- El clic en el vaso sigue funcionando.
- Soltar en la esquina inferior izquierda se acepta.
- Soltar en un lugar inválido no cambia el estado y el dado vuelve.
- Con "Armar grupos arrastrando" apagado, la tela izquierda no ofrece Reservar.
- Suite completa sin fallos y revisión en el juego con capturas en `test-results/`.

## Fuera de alcance
T4 (vendedor enojado), monedas, tutorial, La Semilla, pantallas nuevas y balance.
