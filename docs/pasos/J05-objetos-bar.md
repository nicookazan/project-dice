# J05 — Objetos del bar (M4)

Etapa de jugabilidad e interactividad · 4 de noviembre de 2026.

**Rama:** `feature/objetos-bar`. **Depende de:** J04. **Estado actual:** Pendiente. **Decisiones vinculadas:** D14.

## Objetivo
Objetos del fondo que reaccionan al clic con una animación, y señal de borde dorado en lo interactuable.

## Fuente y alcance normativo
Plan de implementación en Notion (https://app.notion.com/p/40ec28142b55812da30cda3d6044f8b1) y bocetos aprobados por el autor (https://claude.ai/artifact/D74dybtbt4w1z4TfQn9zs9). Los valores de estilo salen de los bocetos y pueden ajustarse al verlos dentro del juego. Reglas comunes: la previsión coincide con la anotación; animaciones con azar aparte (nunca tocan semilla, estado ni guardado); respetan "Reducir movimiento" y la velocidad elegida; no dejan el juego trabado y se limpian al cambiar de pantalla; dados protegidos intactos.

## Trabajo a realizar
1. Nuevo `scripts/bar_props.gd`: zona clickeable, borde dorado `#ffe078` al pasar el mouse y animación que vuelve al estado inicial. Lo reusan el vaso y la mano.
2. Sifón: chorro largo que baja al vaso de al lado y lo llena con espuma (boquilla 399,229; vaso entre x=410 y x=415).
3. Bandera: ondulación por filas sobre el dibujo exacto de `texturas.bandera` (evita el error blanco).
4. Termo: sube, cruza por arriba del mate y se inclina 68° con centro en (966, 426); durante la animación no acepta otro clic. Se quita la ventana de detalle salvo termo robado.
5. Movimiento reducido: sin animación.

## Criterios de aceptación
- Cada objeto vuelve a su estado, se puede repetir el clic y cambiar de pantalla en el medio.
- Estado de partida y azar quedan iguales.
- Suite completa sin fallos y revisión en el juego con capturas en `test-results/`.

## Fuera de alcance
T4 (vendedor enojado), monedas, tutorial, La Semilla, pantallas nuevas y balance.
