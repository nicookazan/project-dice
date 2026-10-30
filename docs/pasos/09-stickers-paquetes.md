# 09 — Stickers por categoría y paquetes

Versión 1 · 25 de octubre de 2026.

**Entrega:** Nivel jugable. **Estado actual:** Modelo, operaciones y pruebas completados el 26 de octubre de 2026. Dependencia 02 completada; catálogo final pendiente de D02. Integración comercial y panel de paquetes conservan 11–13.

**Depende de:** [02 — Cálculo de puntos y eventos sin efectos secundarios](02-puntuacion-eventos.md). **Decisiones vinculadas:** D02. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [09 en Notion](https://app.notion.com/p/404c28142b5581f79625cffeafdcaff2?pvs=204).

Modelar mejoras de categoría y resolver ambos tipos de paquete sin duplicar stickers ni aplicar los descartados.

## Fuente y alcance normativo
PRD IA §8 y §10 packs; PRD-PROTOTIPO tienda y doble par. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Guardar un nivel por tipo de sticker y un catálogo de efectos por nivel. Par y sin combinación comparten tipo; otras categorías usan su alcance.
2. Primera compra incorpora el sticker; recompra aumenta un nivel, sin límite diseñado ni nuevo espacio ocupado.
3. Mantener el mismo precio base por tipo al recomprar; la recompra depende de que vuelva a aparecer, no de un botón de subir nivel libre.
4. Resolver packs de elegir uno entre tres distintos y packs de recibir dos distintos. El tipo se informa antes de cobrar.
5. Permitir stickers ya poseídos dentro de packs; si se reciben aumentan nivel. Descartados no tienen efecto.
6. Aplicar sus puntos y multiplicadores solo a la categoría correspondiente antes de factores como rubí.
7. Datos de balance editables, con valores ausentes identificados. D02 fija incrementos por categoría, precios y si habrá sticker de doble par; no asumir duplicación universal ni un incremento idéntico para todos.
8. Representar la elección pendiente de un pack como estado explícito para el guardado.

## Criterios de aceptación
- Dos compras del mismo tipo dejan un registro de nivel 2.
- Sticker de trío no mejora el par de la misma mano.
- El tipo compartido afecta par y sobrantes.
- Elegir un sticker poseído entre tres solo aumenta ese tipo; los otros dos no se modifican.
- Recibir dos distintos poseídos aumenta una vez cada uno.
- Un pack nunca contiene dos copias del mismo tipo, aunque haya tipos poseídos.
- La elección no vuelve a cobrar ni vuelve a sortear al abrir su panel.
- Usar multiplicadores explícitos de fixture permite probar el orden sin convertirlos en balance aprobado.

## Entregable
Modelo, operaciones y pruebas; catálogo final bloqueado por D02. Integración comercial en 11–12 y visual en 13.

## Fuera de alcance
No inventar un sticker ni bono de servida para doble par; no implementar bonos de categorías repetidas que requieran más de cinco dados.

## Cierre del paso
722 comprobaciones aprobadas, cero fallos: 666 anteriores y 56 nuevas. Modelo/validación en scripts/stickers.gd; estado, ofertas explícitas y transacciones en scripts/game.gd; puntuación/desglose en scripts/rules.gd y scripts/main.gd. Pruebas en tests/sticker_tests.gd, tests/run_tests.gd y fixture histórico de estado; capturas mediante tests/visual_review.gd.

Se verificaron niveles sin duplicar registros, precios constantes por tipo, alcance compartido, categorías aisladas, composición antes de rubí, paquetes con tipos distintos/poseídos, elecciones sin aplicar descartados, pago único, rechazo atómico y snapshots con elección pendiente. Informe stickers_demo en test-results/tests.json. Capturas revisadas: test-results/stickers-categorias.png y sticker-desglose.png. Ejemplo de prueba: trío 68 + par 9 = 77.

Ver [contrato y evidencia](../STICKERS-Y-PAQUETES.md). D02 sigue pendiente: los valores de prueba no son balance aprobado; datos ausentes se identifican explícitamente. Ofertas reales en 11–12 y panel de elección en 13. Siguiente recomendado: 10.

