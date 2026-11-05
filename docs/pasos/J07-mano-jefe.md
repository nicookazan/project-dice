# J07 — Mano del jefe (M7)

Etapa de jugabilidad e interactividad · 4 de noviembre de 2026.

**Rama:** `feature/mano-jefe`. **Depende de:** J05. **Estado actual:** Pendiente. **Decisiones vinculadas:** D14.

## Objetivo
Que la mano del fondo juegue piedra, papel o tijera al clic, y que cada encuentro muestre la mano que corresponde.

## Fuente y alcance normativo
Plan de implementación en Notion (https://app.notion.com/p/40ec28142b55812da30cda3d6044f8b1) y bocetos aprobados por el autor (https://claude.ai/artifact/D74dybtbt4w1z4TfQn9zs9). Los valores de estilo salen de los bocetos y pueden ajustarse al verlos dentro del juego. Reglas comunes: la previsión coincide con la anotación; animaciones con azar aparte (nunca tocan semilla, estado ni guardado); respetan "Reducir movimiento" y la velocidad elegida; no dejan el juego trabado y se limpian al cambiar de pantalla; dados protegidos intactos.

## Trabajo a realizar
1. En `backdrop.gd::configure()` quitar la condición de actor para `hand_row`: los rivales usan la mano de su jefe (`boss_id` ya llega en el perfil).
2. Generar puño, papel y tijera para las 18 manos desde su propio dibujo; el puño se revisa jefe por jefe. **Se aprueba la hoja completa antes de seguir** (el puño aún no fue aprobado explícitamente).
3. Animación: tres golpes con el puño y la jugada final; vuelve a tamborilear. Azar aparte, como `loose_die_pose()`.
4. Clic: en jefes y rivales juega; en guardianes sigue `inspect_boss_hand`. El poder del jefe sigue en la libreta y al pasar el mouse.
5. Revisar otros poderes que usan la mano (termo robado de Don Cebador).

## Criterios de aceptación
- Mano correcta en rivales, jefe y Dios.
- El gesto no consume azar de la partida.
- Repetir el clic no rompe nada.
- Suite completa sin fallos y revisión en el juego con capturas en `test-results/`.

## Fuera de alcance
T4 (vendedor enojado), monedas, tutorial, La Semilla, pantallas nuevas y balance.
