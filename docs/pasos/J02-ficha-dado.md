# J02 — Ficha del dado (M2 y T2)

Etapa de jugabilidad e interactividad · 4 de noviembre de 2026.

**Rama:** `feature/ficha-dado`. **Depende de:** J01. **Estado actual:** Implementado; a la espera de la prueba del autor en el juego. **Decisiones vinculadas:** D14.

## Objetivo
Mostrar al pasar el mouse sobre un dado una ficha con material, gema, elemento, caras y "Vale N puntos".

## Fuente y alcance normativo
Plan de implementación en Notion (https://app.notion.com/p/40ec28142b55812da30cda3d6044f8b1) y bocetos aprobados por el autor (https://claude.ai/artifact/D74dybtbt4w1z4TfQn9zs9). Los valores de estilo salen de los bocetos y pueden ajustarse al verlos dentro del juego. Reglas comunes: la previsión coincide con la anotación; animaciones con azar aparte (nunca tocan semilla, estado ni guardado); respetan "Reducir movimiento" y la velocidad elegida; no dejan el juego trabado y se limpian al cambiar de pantalla; dados protegidos intactos.

## Trabajo a realizar
1. Nuevo `scripts/die_card.gd`; colores en una tabla dentro del script (ver Estilos aprobados en el plan).
2. Contenido opción A: material · gema · elemento en color; caras con la actual en dorado; "Vale N puntos" del mismo cálculo que la puntuación.
3. Casos: dado común, caras cambiadas, gema rota, material suspendido por el jefe y dado en el vaso.
4. Mesa: dentro de la tela izquierda, con el costado inclinado de `felt_layout.gd`. Tienda: arriba del dado (T2).
5. Reemplazar los textos de `die_hover_text` y `update_hover_description`; mantener el resaltado de combinaciones.
6. Inspeccionar explica material, gema y elemento con textos que ya existen en los datos.

## Criterios de aceptación
- "Vale N" coincide con la puntuación en cada caso.
- Pasar el mouse no cambia el estado.
- La ficha desaparece al arrastrar y al abrir una ventana.
- Suite completa sin fallos y revisión en el juego con capturas en `test-results/`.

## Fuera de alcance
T4 (vendedor enojado), monedas, tutorial, La Semilla, pantallas nuevas y balance.
