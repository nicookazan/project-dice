# 13 — Mesa, libreta, inspección y tienda jugable

Versión 1 · 25 de octubre de 2026.

**Entrega:** Nivel jugable. **Estado actual:** Implementado y probado el 26 de octubre de 2026; dependencia 12 completada y D08 resuelta. Interfaz revisada a 1280×800 y 1440×900; datos comerciales de otras familias conservan decisiones pendientes.

**Depende de:** [12 — Compras, selección de objetivos y reemplazos](12-compras-aplicacion.md). **Decisiones vinculadas:** D08 resuelta: selección de carcasas con costo total, implementada en 08. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [13 en Notion](https://app.notion.com/p/404c28142b5581cea7a4e13f8b817aec?pvs=204).

Hacer utilizables y comprensibles los sistemas implementados, conservando la estética y disposición aprobadas.

## Fuente y alcance normativo
PRD IA §13–16; PRD-PROTOTIPO distribución de tienda y carcasa resquebrajada. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Mantener libreta al margen izquierdo, grupos a la izquierda de la mesa, reserva al centro y vaso a la derecha. Distinguir selección, grupo editable y bloqueado con texto/símbolo además del color.
2. Mostrar combinación válida de la selección y su puntuación sin elegir automáticamente la distribución de dados.
3. Adaptar la libreta al nuevo desglose: decimales en subtotales/multiplicadores, total redondeado al final; lápiz para previsión y azul para anotado. El formato actual entero de main.gd debe revisarse.
4. Ficha de dado: seis caras y probabilidades, material/carcasa/elemento, rotura, mejoras globales/locales y contadores de mano/encuentro. No confundir el número visible con los puntos.
5. Ficha de vaso: cuero actual y stickers; ficha de moneda: efecto, duración y contexto.
6. Distribuir tienda: monedas arriba izquierda; componentes arriba derecha; vaso reservado abajo izquierda; números/caras abajo centro; sticker+pack abajo derecha.
7. Un botón Renovar por sección con el mismo precio vigente; mostrar saldo, precio y efecto antes de confirmar.
8. Mostrar selección de dado/cara, packs y reparación conforme a D08, con cancelación clara y errores legibles.
9. Revisar ratón, arrastre y controles alternativos. Evitar que superposiciones o animaciones permitan acciones repetidas.

## Criterios de aceptación
- Capturas de mesa normal, grupos bloqueados, carcasa rota, detalle con ×4,5, tienda llena/vacía, selección de cara y ambos packs.
- La libreta no trunca a 4 un multiplicador 4,5 ni redondea grupos antes de sumar.
- Comprar una pieza identifica sin ambigüedad el dado que cambiará.
- Las cinco zonas comerciales permanecen legibles a 1280×800 y en la resolución lógica actual.
- Con textos largos, botones y precios no se superponen; reducir animaciones no cambia reglas.
- Ayuda explica doble par, servida, sobrantes y bloqueo con ejemplos.

## Entregable
UI conectada a operaciones reales, capturas revisadas y prueba de un flujo completo de compra/anotación. Los íconos provisionales se identifican como tales.

## Fuera de alcance
Rediseño total del arte, ocho fondos nuevos o catálogo artístico definitivo; se reutilizan recursos existentes.

## Cierre del paso
938 comprobaciones aprobadas, cero fallos: 898 anteriores y 40 nuevas. Mesa/tienda/fichas en scripts/main.gd; marcas y clic derecho en scripts/die.gd; validación de arrastre en scripts/drop_zone.gd. Pruebas en tests/interface_tests.gd y runner; capturas mediante tests/interface_review.gd.

Se verificaron selección con previsión pura, prohibición del jefe, marcas SEL/EDITABLE/FIJO/R, seis caras y probabilidades, puntos separados del número, capas/contadores, fichas desplazables, modales, ratón/teclado, cinco zonas simultáneas sin superposición, renovación compartida, multiplicador 4,5, ambos packs y un flujo real de compra/anotación con 130 puntos iguales a la previsión.

Capturas revisadas a 1280×800 y 1440×900 en test-results con prefijos de resolución: mesa-estados, ficha-dado, ficha-vaso, ficha-moneda, detalle-decimal, tienda-cinco-zonas, tienda-vacia, seleccion-cara, pack-elegir y pack-recibir. Informe interface_demo en test-results/tests.json. Ver [contrato y evidencia](../INTERFAZ-E-INSPECCION.md).

D08 sigue resuelta; D01/D02/D04 siguen pendientes para ofertas comerciales normales de otras familias. Los fixtures completos no son balance aprobado. Siguiente recomendado: 14, menú y recorrido, con dependencias técnicas completas y D05 de presentación pendiente.

