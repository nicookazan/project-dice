# J08 — Vuelo del sticker (T1)

Etapa de jugabilidad e interactividad · 4 de noviembre de 2026.

**Rama:** `feature/sticker-vuelo`. **Depende de:** J00. **Estado actual:** Implementado; a la espera de la prueba del autor en el juego. **Decisiones vinculadas:** D14.

## Objetivo
Animar la compra de stickers: vuelo hasta el termo y aviso cuando es repetido.

## Fuente y alcance normativo
Plan de implementación en Notion (https://app.notion.com/p/40ec28142b55812da30cda3d6044f8b1) y bocetos aprobados por el autor (https://claude.ai/artifact/D74dybtbt4w1z4TfQn9zs9). Los valores de estilo salen de los bocetos y pueden ajustarse al verlos dentro del juego. Reglas comunes: la previsión coincide con la anotación; animaciones con azar aparte (nunca tocan semilla, estado ni guardado); respetan "Reducir movimiento" y la velocidad elegida; no dejan el juego trabado y se limpian al cambiar de pantalla; dados protegidos intactos.

## Trabajo a realizar
1. Sticker suelto nuevo: vuela desde la oferta hasta su lugar en el termo y se pega con destellos, sin oscurecer la pantalla.
2. Sticker suelto repetido: sin vuelo, con el aviso "Trío · Nivel 1 → 2".
3. Paquete: solo vuela lo nuevo; lo repetido se desvanece en su lugar (paquetes de dos y de elegir uno).

## Criterios de aceptación
- La compra ya está guardada antes de animar.
- Omitir la animación deja el termo correcto.
- Un paquete con uno de cada tipo se ve bien.
- Suite completa sin fallos y revisión en el juego con capturas en `test-results/`.

## Fuera de alcance
T4 (vendedor enojado), monedas, tutorial, La Semilla, pantallas nuevas y balance.
