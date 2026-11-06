# TX2 — Fondos de ventana animados y batiseñal

Ítem 4 (texturas) · 5 de noviembre de 2026.

**Rama:** `feature/texturas`. **Depende de:** ninguna. **Estado actual:** Prototipo en la rama, sin integrar a `main`; se ejecuta según el plan de Notion («4- Plan de implementación TEXTURAS»). **Decisiones vinculadas:** D16.

## Objetivo
Que lo que se ve por las ventanas se mueva, sin tocar el panorama aprobado (`exteriores-v3.png`).

## Alcance
Animaciones de presentación en `Backdrop`, por ambiente, según D16. Incluye la batiseñal cuando el jefe es El Gótico (3A). Con "Reducir movimiento" o velocidad 0 se ve el cuadro fijo de hoy. El azar de las animaciones es aparte.

## Criterios de aceptación
- Cada ambiente muestra la animación elegida y vuelve al cuadro fijo sin movimiento.
- No cambia semilla, guardado ni puntuación; el ambiente "cierre" no cambia.
- Rendimiento aceptable en GL Compatibility (remolinos con shader, no por píxel en GDScript).
- Suite sin fallos y capturas en `test-results/`.

## Fuera de alcance
Cambiar el dibujo de los exteriores; animar la mesa o el salón.
