# Mesa limpia — 28 de octubre de 2026

Se quitaron de las tres zonas de juego los títulos FORMADOS, RESERVADOS y VASO, las instrucciones de grupos, la explicación de reserva, el contador del vaso y el botón visible «Ver vaso». La ficha se abre pulsando el propio vaso, con indicación al pasar el cursor y foco de teclado. Los dados, los grupos ya armados y los controles de juego conservan su comportamiento.

El vaso de la mesa ahora está de pie. Recurso integrado: `assets/art/environment-v2/vaso-cuero-negro-mesa-v2.png`. Se conserva la versión anterior. El fondo consume únicamente la región del vaso, sin sustituir el resto del escenario.

Validación: captura real de Godot en `test-results/mesa-sin-textos-vaso-parado.png`, apertura de la ficha al pulsar el vaso y suite existente: 2133 comprobaciones, cero fallos.

## Dados dentro del vaso y tirada desparramada

Los dados cuya zona es `cup` ya no generan controles visibles en la mesa, tanto antes de la primera tirada como al devolverlos al vaso. Al tirar, los dados sueltos aparecen en el paño central con posiciones irregulares y giros de 7 a 22 grados. Cada dado tiene un área de caída separada para evitar superposiciones. Los grupos armados conservan su distribución organizada.

La variación usa un generador visual independiente, derivado de la semilla y de la última tirada de cada dado. Seleccionar, inspeccionar o redibujar no mueve los dados ni consume azar del juego. Los dados conservados tampoco se desplazan al relanzar otros. La distribución se reconstruye con el historial guardado.

Capturas reales: `test-results/dados-dentro-del-vaso.png`, `test-results/dados-desparramados.png` y `test-results/dado-devuelto-al-vaso.png`. Se agregaron comprobaciones de ocultación, aparición, giros, estabilidad al seleccionar y relanzamiento selectivo a las pruebas de interfaz. Suite actual: 2139 comprobaciones, cero fallos.

## Animación de lanzamiento

Al pulsar TIRAR o espacio, los dados relanzados salen de la boca del vaso uno tras otro, describen un arco, giran y rebotan antes de asentarse en sus posiciones dispersas. La duración es de 0,85 segundos en velocidad normal y 0,48 en rápida. Los dados conservados no se animan. Movimiento reducido y velocidad «Sin animación» muestran directamente el resultado.

Un control transparente bloquea el puntero durante el lanzamiento; los comandos de juego y el teclado también quedan bloqueados hasta que termina. El resultado se calcula una sola vez antes de animarse; la animación no modifica el estado, el guardado ni el generador aleatorio. Redibujar la pantalla cancela la animación y restaura los controles de forma segura.

Revisión reproducible: `tests/throw_review.gd` guarda treinta fotogramas reales en `test-results/lanzamiento/`. Vista animada: `test-results/lanzamiento.gif`. Pruebas de interfaz verifican trayectoria intermedia, giro, aterrizaje, bloqueo de entrada, relanzamiento selectivo, cancelación, velocidades y equivalencia de resultados. Suite tras integrar la animación: 2151 comprobaciones, cero fallos.

## Prompt original del vaso

Edición con Imagegen integrada, usando `vaso-cuero-negro-mesa-v1.png` como referencia y destino de edición. Prompt completo:

> Use case: precise-object-edit. Edit target: attached pixel-art game background. Change ONLY the black leather dice cup in the rightmost burgundy mat section: stand it UPRIGHT on its flat bottom, opening facing UP, vertical cylindrical body, slightly tapered bottom, black leather with the same gold stitched seams, green felt inside visible as an ellipse at the top. It must be standing stably, NOT lying on its side, not tilted. Preserve pixel-art style, material and lighting. Cup footprint in the logical 1440x900 image coordinates: within x1160..1365, y345..550, leaving area below y560 empty for dice. Erase previous sideways cup and its shadow and reconstruct matching red felt. Keep every other object, border, mat, background, room, notebook, hand absolutely unchanged, and preserve exact framing/aspect ratio. No text, letters, numbers, dice or UI. This is a production background replacement, so align all surrounding pixels to the source.
