# Rotura y reparación — contrato del paso 08

**Cambio de representación — 27 de octubre de 2026:** las antiguas carcasas son ahora materiales de los puntos del dado. Se conservan el riesgo, la pérdida temporal de poder, los costos, la selección y la deuda. El daño debe representarse en los puntos mejorados, sin agrietar el cuerpo ni eliminar puntos de la cara. Las referencias históricas a carcasa y claves `shell` siguen identificando esta familia. [Diseño maestro vigente](DISENO-MAESTRO-DADOS.md).

Implementado y probado el 26 de octubre de 2026. Se conservan siempre los mismos cinco dados. La rotura solo suspende el poder de la carcasa; no borra números, caras, mejoras, material ni elemento.

## Riesgo después del puntaje

| Gema | Riesgo por mano elegible | Costo de reparación |
|---|---|---|
| Esmeralda | 10% | $2 |
| Rubí | 20% | $3 |
| Zafiro | 30% | $4 |
| Diamante | 50% | $5 |

Game._after_hand_scored comprueba carcasas conocidas intactas que puntuaron en combinación, después de acreditar puntos, historial y evento, y antes de evaluar derrota. Cada dado elegible consume una única llamada a rng.randf; rompe si draw < risk. Las copias de diamante no producen comprobaciones extra. Carcasas rotas y sobrantes no sortean. No hay usos seguros ni rotura al agrupar, reservar, relanzar o consultar la previsión.

La gema aporta íntegramente a la mano recién anotada aunque se rompa después. El cálculo acreditado y el historial no se recalculan. En la siguiente mano su poder está suspendido hasta reparar. Los otros componentes siguen funcionando.

breakage_by_hand guarda por número de mano las comprobaciones con ID, carcasa, sorteo, umbral y resultado, incluso un arreglo vacío si no había elegibles. La marca se establece antes de comprobar, evitando repetir el hook. score_hand también protege contra doble anotación. La secuencia no agrega eventos de mano ni activaciones por cada copia.

## Cobro y resolución opcional

close_encounter acredita una sola recompensa y calcula los intereses sobre el saldo anterior; una deuda genera cero intereses. Si quedan carcasas resquebrajadas conocidas, pasa a phase="repair". repair_resolution conserva status, available_ids, selected_ids, cost, cash_after_reward y next_phase. Después de resolver añade cash_after. El destino es reward para encuentros normales y won para el último jefe.

Game.repair_quote(ids) es puro y devuelve valid, cost, items y error. Rechaza IDs no enteros, repetidos, fuera de rango, carcasas intactas y carcasas desconocidas. Cada item separa ID, gema y precio. No consume azar ni cobra.

Game.resolve_repairs(ids) solo acepta una oferta pendiente después del cobro. Valida la selección completa antes de modificar datos, quita el costo exacto aunque deje deuda y limpia únicamente shell_broken de los IDs elegidos. Una lista vacía declina gratis y conserva todas las roturas. La resolución se cierra una sola vez; otro clic no cobra, no repara ni entrega recompensa adicional. No se puede jugar otra mano ni ir a tienda mientras está pendiente. Sin carcasas rotas continúa directamente.

La siguiente recompensa se suma al saldo con deuda normalmente. El siguiente rival limpia las marcas del encuentro pero conserva carcasas reparadas o rotas. Nueva partida limpia todo. snapshot devuelve copias profundas de ambas marcas: el futuro guardado del paso 15 deberá conservarlas para no repetir sorteos, cobros o reparaciones. No se implementa restauración en disco en este paso.

## Interfaz y decisión D08

El usuario eligió en este chat el 26 de octubre de 2026: «Elegir carcasas; mostrar costo total». La pantalla presenta casillas por dado/gema/precio, costo total y saldo resultante, con confirmación o continuación sin reparar. Se informa que admite deuda. Tras el último jefe se usa la misma selección antes de mostrar la victoria final. D08 queda resuelta; los pasos 13–14 integrarán esta interacción al recorrido completo.

## Evidencia y límites

**666 comprobaciones aprobadas, cero fallos:** 581 anteriores y 85 nuevas. tests/repair_tests.gd fuerza sorteos por debajo, en y por encima de cada umbral; no usa pruebas estadísticas. tests/support/breakage_game.gd inyecta valores solo desde pruebas y verifica que ya se acreditó la mano al sortear. Se cubren copias, sobrantes, derrota, repetición de hooks/clics, identidad, costos, validación atómica, deuda, declinación, último jefe, persistencia y recuperación de poderes.

tests/run_tests.gd comprueba selección, total, confirmación con deuda y declinación final en la interfaz real. tests/gem_tests.gd ahora espera exactamente cinco sorteos de riesgo para sus cinco gemas, sin multiplicarlos por las copias. El observador de eventos llama al hook real; el fixture histórico de estado declina su carcasa rota antes de ir a tienda.

Informe: repairs_demo en test-results/tests.json. Para repetir: Probar.cmd. Capturas revisadas: test-results/reparacion-seleccion.png y reparacion-cobrada.png. El ejemplo cobra $12 sobre saldo −$20, queda en −$8 y repara esmeralda+diamante por $7, terminando en −$15.

Implementación en scripts/game.gd, scripts/gems.gd y scripts/main.gd. Capturas mediante tests/visual_review.gd. La compra de componentes llega en 12; el inicio normal todavía tiene cinco dados básicos. Guardado en disco y campaña completa conservan sus pasos.
