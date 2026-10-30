# Monedas y grupos por arrastre

30/10/2026.

Durante los encuentros se dibujan solamente las monedas equipadas y la moneda de un uso disponible. No hay recuadros, nombres sobre las monedas ni paneles para ranuras vacías. La inspección, descripción, uso y marca de suspensión por jefe se conservan.

## Usar la opción

Activá **Armar grupos arrastrando** junto a la zona izquierda de la mesa o desde Opciones. La preferencia queda guardada aparte de la partida. Las preferencias anteriores conservan el modo de clic hasta que se active esta opción.

1. Tirás los dados.
2. Al pasar el mouse por uno, se muestran las combinaciones posibles con los dados disponibles y se resaltan sus compañeros. La ayuda respeta las prohibiciones del jefe y excluye dados ya agrupados o dentro del vaso.
3. Arrastrás los dados hacia el sector izquierdo. Quedan en una fila de borrador y el botón **Armar grupo** se habilita cuando los dados forman una combinación válida.
4. Pulsás **Armar grupo** para confirmar. Para quitar un dado del borrador, arrastralo de vuelta a la reserva. También puede ir al vaso si quedan tiradas.

Con la opción activa, un clic ya no añade dados al borrador. La selección exacta del borrador se conserva en el estado de interfaz ya existente; preparar una combinación no cambia resultados, puntuación, grupos ni RNG. Confirmar usa las mismas reglas de grupos que antes. Al desactivar la opción se limpia el borrador y vuelve la selección por clic.

Durante el arrastre, el dado gira suavemente según el movimiento del mouse y se estabiliza mediante un resorte amortiguado. Es un efecto visual; no afecta caras ni sorteos. Se desactiva con Reducir movimiento o Sin animación. Soltar en un lugar inválido devuelve la apariencia original sin modificar la partida.

Actualización posterior del 30/10/2026: el balanceo ahora tiene mayor amplitud y una pequeña inercia de posición para que se perciba mejor el movimiento. El mismo efecto se comparte con las monedas que se arrastran para vender en la tienda. [Venta por arrastre](TIENDA-ESTILO.md).

## Verificación

`tests/drag_group_tests.gd` cubre combinaciones sin mutación, prohibiciones del jefe, clic desactivado, borrador exacto, devolución, confirmación, estados bloqueados, monedas sin paneles y estabilización del balanceo. `tests/drag_group_review.gd` realiza arrastres con eventos reales de mouse, comprueba la formación del par y un destino inválido, y captura el resultado a 1440×900 y 1280×800. Las preferencias nuevas y antiguas se verifican en `tests/presentation_tests.gd`.

Resultado final: **2198 comprobaciones, cero fallos**. Arrastre con mouse verificado en ambas resoluciones, sin errores de ejecución.
