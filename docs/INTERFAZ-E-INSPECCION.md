# Interfaz e inspección — contrato del paso 13

Implementado y probado el 26 de octubre de 2026. Se conserva la estética del club y el arte existente. La mesa mantiene libreta a la izquierda, grupos junto a ella, reserva al centro y vaso a la derecha. No se introducen reglas ni valores de balance nuevos.

## Mesa y selección

La selección muestra categoría válida y puntos del grupo usando el mismo Rules.score que la previsión, incluidas sus mejoras y el estado de servida. No arma grupos ni reparte dados automáticamente. Armar grupo solo se habilita para una selección válida; la previsión también respeta la generala prohibida del jefe.

Los dados seleccionados muestran SEL además del borde de color. Los grupos indican EDITABLE o FIJO; una carcasa resquebrajada muestra R y una grieta además de su explicación en la ficha. La marca no cambia el número de la cara. Un dado agrupado permanece inspeccionable aunque no pueda seleccionarse o relanzarse.

La libreta conserva decimales en filas y multiplicadores, y redondea solo el total de mano. Ejemplo verificado: par de 76,5 con multiplicador 4,5 más sobrantes 15 da 91,5, acreditable 92. Se mantiene lápiz para previsión y lapicera azul al anotar.

## Fichas consultables

- Dado: seis posiciones de cara, frecuencia y probabilidad por número (incluidos números ausentes), resultado visible separado de sus puntos numéricos, mejoras globales/locales, material, carcasa, rotura/riesgo/reparación, elemento y acumulaciones de mano/encuentro.
- Vaso: cuero actual, cinco dados fijos y stickers con nivel y aporte de categoría cuando sus datos están definidos.
- Moneda: poder, código, tipo, duración, contexto permitido, precio y reventa.
- Libreta: cada dado y fuente de puntos, sumas, factores, resultado original y copias.

Los detalles usan RichTextLabel con ajuste de línea y desplazamiento dentro de un diálogo acotado. detail_text conserva el texto completo para pruebas e inspección; no se fuerza el tamaño del cuadro mediante una etiqueta de texto sin límites. Abrir, leer o cerrar fichas no modifica juego, historial ni RNG. El diálogo es exclusivo y los callbacks de botones y atajos ignoran acciones de juego mientras está visible.

## Cinco zonas de tienda simultáneas

| Posición | Zona |
|---|---|
| Arriba izquierda | Cuatro monedas |
| Arriba derecha | Dos componentes |
| Abajo izquierda | Vaso reservado, con ficha |
| Abajo centro | Dos números/caras |
| Abajo derecha | Sticker individual y paquete |

Cada sección comercial tiene su propio botón Renovar con el mismo costo compartido vigente. Saldo, efecto y precio se muestran antes de comprar. Se conservan stock almacenado, confirmación con objetivo, cancelación sin cargo, reparación selectiva y protección contra repeticiones. Las tarjetas limitan sus textos al área disponible y conservan la descripción completa en tooltip.

Los paneles del paso 12 siguen operativos. La elección de cara identifica dado, posición y número actual. El pack de elegir uno conserva el pago y opciones al cerrar/reabrir; el de recibir dos muestra un comprobante con los dos tipos y sus nuevos niveles. Los controles de continuación y renovación se bloquean durante elecciones pendientes.

Las ilustraciones actuales de monedas están identificadas como provisionales. Las ofertas normales siguen usando solo monedas mientras D01/D02/D04 conservan pendientes los datos comerciales de otras familias. La tienda llena de las capturas usa tablas explícitas de prueba; la interfaz no las convierte en balance aprobado.

## Ratón y controles alternativos

- Clic izquierdo selecciona dados; arrastre mueve entre vaso y reserva. Se rechazan datos de arrastre mal formados y un sexto dado.
- Clic derecho abre la ficha del dado. Inspeccionar permite consultar el único dado seleccionado; Ver vaso abre su ficha.
- 1–5 seleccionan los mismos cinco IDs; G agrupa, C envía al vaso, V reserva, espacio tira, I inspecciona y Esc limpia selección. F1 abre ayuda.
- Esc cancela una compra con objetivo aún sin confirmar. Tab/Enter conservan la navegación y activación de botones; el foco del dado tiene marca visible.

Los atajos no actúan durante fichas, elecciones, resultados o tienda salvo las acciones de consulta/cancelación correspondientes. Se ignoran repeticiones automáticas de teclas. No se añadieron animaciones que modifiquen o demoren reglas.

La ayuda explica doble par, servida, sobrantes, bloqueo, jefe, selección, marcas, compras y uso de monedas, con ejemplos.

## Evidencia y límites

**938 comprobaciones aprobadas, cero fallos:** 898 anteriores y 40 nuevas. tests/interface_tests.gd prueba fichas y probabilidades, pureza, modales, eventos de clic izquierdo/derecho a través del viewport, teclado, arrastre, zonas sin superposición, renovación compartida, decimal 4,5, ambos paquetes y un flujo compra → tirada → selección → agrupación → anotación que acredita 130, igual a la previsión. El runner anterior sigue verificando transacciones y reparación.

Informe interface_demo en test-results/tests.json. Para repetir: Probar.cmd. Capturas mediante tests/interface_review.gd a 1280×800 y 1440×900, con prefijos 1280x800- y 1440x900- en test-results: mesa-estados, ficha-dado, ficha-vaso, ficha-moneda, detalle-decimal, tienda-cinco-zonas, tienda-vacia, seleccion-cara, pack-elegir y pack-recibir. Se revisaron texto desplazable, cinco zonas, inventario completo, precios y separación de controles.

Implementación en scripts/main.gd, scripts/die.gd y scripts/drop_zone.gd. Las pruebas anteriores consultan ahora detail_text como texto de presentación completo. No se modificó el motor de puntuación ni el generador para completar esta ficha. Menú/recorrido en 14, guardado en disco en 15 y balance comercial siguen pendientes.
