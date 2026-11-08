# TX9 — Las 75 monedas en ficha esmaltada

Ítem 4 (texturas) · 7 de noviembre de 2026.

**Rama:** `feature/monedas-esmalte`. **Depende de:** Ninguna. **Estado actual:** Hecho el 07/11/2026 (PR abierto, sin mergear); falta la aprobación del autor en el juego. **Decisiones vinculadas:** D17.

## Objetivo
Que todas las monedas tengan dibujo propio en el mismo estilo: aro por rareza y esmalte por familia.

## Alcance
- Generador `tools/art/make_coins_v4.py`: una sola hoja `pixel-v3/coins-v4.png` con las 75 monedas y los dos paquetes (celdas de 32×32). Rareza y familia se leen de `coins.gd`.
- `coin_art.gd` usa la hoja nueva por id; desaparece la ficha provisional con abreviatura.
- Las 51 que eran provisionales y las 24 que ya tenían dibujo pasan al mismo estilo. C48 Veterana y C49 Acumulada siguen los diseños del autor.
- El tamaño en pantalla no cambia.

## Criterios de aceptación
- Cada id de `coins.gd` tiene celda; ninguna moneda cae en la ficha provisional.
- Los paquetes se ven igual que hoy.

## Fuera de alcance
Cambios de efectos, precios o rarezas.
