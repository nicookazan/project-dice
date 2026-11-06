# TX1 — Elementos de los dados más grandes

Ítem 4 (texturas) · 5 de noviembre de 2026.

**Rama:** `feature/texturas`. **Depende de:** ninguna. **Estado actual:** Prototipo en la rama, sin integrar a `main`; se ejecuta según el plan de Notion («4- Plan de implementación TEXTURAS»). **Decisiones vinculadas:** D16.

## Objetivo
Que las marcas de fuego, agua, electricidad, tierra y viento se lean mejor: hoy son de 2 a 4 px.

## Alcance
La opción A elegida: marcas grandes (hasta 34 px de alto) que se quedan sobre el borde del dado, con un máximo de 3 px afuera, sin tapar los puntos. Se generan en `tools/art/bocetos-texturas/make_bocetos_dados.py` y se dibujan en `Die.draw_element_edges()` desde `assets/art/pixel-v3/elementos-v3.png`.

## Criterios de aceptación
- Los cinco elementos se ven más grandes y no tapan ningún punto del 1 al 6.
- Los dados protegidos (`PROTEGIDOS.sha256`) no cambian.
- Mesa, tienda y arrastre muestran lo mismo; una suspensión del jefe sigue marcando "S".
- Suite sin fallos y captura en `test-results/`.

## Fuera de alcance
Animar los elementos; la opción B (aura fuera del dado).
