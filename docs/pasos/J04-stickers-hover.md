# J04 — Stickers al pasar el mouse (M5 y T3)

Etapa de jugabilidad e interactividad · 4 de noviembre de 2026.

**Rama:** `feature/stickers-hover`. **Depende de:** J00. **Estado actual:** Implementado; a la espera de la prueba del autor en el juego. **Decisiones vinculadas:** D14.

## Objetivo
Ventanita con lo que aporta cada sticker del termo, en la mesa y en la tienda.

## Fuente y alcance normativo
Plan de implementación en Notion (https://app.notion.com/p/40ec28142b55812da30cda3d6044f8b1) y bocetos aprobados por el autor (https://claude.ai/artifact/D74dybtbt4w1z4TfQn9zs9). Los valores de estilo salen de los bocetos y pueden ajustarse al verlos dentro del juego. Reglas comunes: la previsión coincide con la anotación; animaciones con azar aparte (nunca tocan semilla, estado ni guardado); respetan "Reducir movimiento" y la velocidad elegida; no dejan el juego trabado y se limpian al cambiar de pantalla; dados protegidos intactos.

## Trabajo a realizar
1. Nuevo `scripts/sticker_tip.gd`. Zonas invisibles sobre cada sticker (termo de mesa origen 1203,168; tienda origen 65,525) usando `StickerArt.thermos_rect`.
2. Ventanita: "Jugada · Nivel N" y debajo "+X puntos · +Y mult." con totales de ese nivel. Mesa: a la izquierda del termo; tienda: a la derecha.
3. Termo robado: sin ventanitas mientras dure el jefe.

## Criterios de aceptación
- Los valores coinciden con la puntuación en cada nivel.
- Las zonas no bloquean soltar dados en el vaso.
- Suite completa sin fallos y revisión en el juego con capturas en `test-results/`.

## Fuera de alcance
T4 (vendedor enojado), monedas, tutorial, La Semilla, pantallas nuevas y balance.
