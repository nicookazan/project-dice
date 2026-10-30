# Mate, termo, exteriores y gemas brillantes

Decisión del usuario del 28 de octubre de 2026. Sustituye las indicaciones históricas de cerveza, stickers sobre el vaso y gemas mates.

- Siempre hay mate y termo en los siete ambientes disponibles, también en tienda. La cerveza de las láminas históricas del PRD no es una instrucción vigente.
- Los stickers poseídos se dibujan sobre el cuerpo del termo; tocarlo o elegir **Ver termo** muestra niveles y efectos. El vaso sigue sirviendo para relanzar dados y tiene su propia ficha.
- Los seis exteriores ilustrados muestran barrio diurno, atardecer, barrio nocturno, galaxia con planetas, agujero negro con disco luminoso y cielo con nubes y arquitectura dorada. Las ventanas miran a partes de un mismo panorama. El cierre conserva ventanas opacas.
- Rubí, zafiro, esmeralda y diamante recuperan colores intensos, facetas y reflejos blancos estáticos inspirados en la imagen adjunta. Los puntos negros conservan su apariencia. No hay destellos animados.

## Recursos y referencias

`assets/art/environment-v2/exteriores-v2.png`: atlas nuevo de seis paisajes, generado con Imagegen integrado. `termo-v1.png`: termo con transparencia, generado con la misma herramienta. Los prompts completos están en [PROMPTS.md](../assets/art/environment-v2/PROMPTS.md).

`escenarios-1-4.png` y `escenarios-5-8.png`: referencias recuperadas del PRD de Notion. Se consultan como evidencia visual; la cerveza y el antiguo infierno que contienen no se incorporan al juego.

`assets/art/dice-master-v1/puntos-gema-brillantes-referencia.png`: copia exacta de la nueva referencia adjunta por el usuario.

Las facetas de las gemas se dibujan en Godot sobre las posiciones reales de cada punto del atlas existente. `dice_art.gd` obtiene y almacena sus límites; `die.gd` dibuja una paleta de píxeles por gema. Esto conserva las seis caras, la separación de los puntos, el cuerpo marfil, selección, arrastre y marcas de daño/suspensión en mesa, tienda y galería.

## Compatibilidad y revisión

El guardado v3 conserva la clave interna histórica `cup.stickers` para abrir partidas existentes. Es solo compatibilidad de datos: la presentación y ficha pertenecen al termo. Puntuación, compras, niveles, efectos y azar se conservan.

Capturas reales de Godot: `test-results/1440x900-dados-brillantes-*.png`, `test-results/1280x800-dados-brillantes-*.png` y `test-results/1280x800-presentacion-*.png`. La escena de revisión equipa stickers y gemas de laboratorio; no los regala en partidas normales. La revisión técnica no sustituye la valoración artística del usuario.

## Verificación del cambio visual del 28/10/2026

Suite completa: **2125 comprobaciones, cero fallos**. Incluye 24 comprobaciones nuevas de cantidad exacta y separación de los puntos brillantes en las cuatro gemas. Revisadas capturas reales de mesa, galería, termo/stickers, daño y tienda a 1280×800 y 1440×900; los siete ambientes a 1280×800. Revisión de presentación sin fallos de opciones, movimiento reducido, audio o invariantes de partida.
