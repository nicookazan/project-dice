# TX10 — Elementos animados en la cara de arriba

Ítem 4 (texturas) · 7 de noviembre de 2026.

**Rama:** `feature/elementos-arriba`. **Depende de:** TX1. **Estado actual:** En curso (PR abierto, sin mergear). **Decisiones vinculadas:** D17.

## Objetivo
Que cada elemento se vea como un emblema pintado en perspectiva sobre la cara de arriba del dado, con una animación leve.

## Alcance
- Generador `tools/art/make_elementos_v4.py`: hoja `pixel-v3/elementos-v4.png`, 5 elementos × 12 cuadros, solo la franja de arriba del dado.
- `Die.draw_element_edges()` dibuja el cuadro que corresponde (120 ms por cuadro, ajustado por la velocidad), con una fase por dado que sale de su lugar en la mano.
- «Reducir movimiento» o velocidad cero → primer cuadro fijo; «Reducir destellos» → el rayo no pasa por su tono más claro.
- Se quitan las marcas laterales de TX1 y su hoja.

## Criterios de aceptación
- El emblema no tapa ningún punto del 1 al 6.
- La animación no consume azar de la partida ni toca el guardado.
- Los dados protegidos no cambian.

## Fuera de alcance
Cambios de reglas de los elementos.
