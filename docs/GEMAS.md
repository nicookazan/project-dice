# Poderes de gemas — contrato del paso 07

**Avance visual posterior:** caras 1–6 negras y de cuatro gemas mates integradas en mesa, libreta de tienda y ofertas; mismas claves/efectos. Galería sin equipamiento desde menú/Opciones. [Catálogo](CARAS-DE-DADOS.md), 2101 comprobaciones aprobadas, cero fallos. La migración completa de terminología histórica en todos los textos es independiente de esta integración de caras.

**Decisión posterior del autor — 27 de octubre de 2026:** la familia antes llamada carcasa pasa a representar el **material de los puntos**: negro base; esmeralda, rubí, zafiro y diamante para las mejoras existentes. Cambia la representación y terminología, no los efectos ni su riesgo/reparación. Esta familia no recubre ni recolorea el cuerpo. Las menciones históricas a carcasa y claves técnicas `shell`/`shell_broken` corresponden a esta misma familia. [Diseño maestro vigente](DISENO-MAESTRO-DADOS.md). Actualización de sprites/interfaz pendiente en 19.

Implementado y probado el 26 de octubre de 2026. Los cuatro poderes se evalúan sin modificar estado. Solo se activan cuando la carcasa está intacta y su dado pertenece a una combinación válida desde par. No se activan en sobrantes ni cuando shell_broken es verdadero.

## Orden y alcance

| Carcasa | Operación | Alcance |
|---|---|---|
| emerald / Esmeralda | ×2 después de sumar puntos propios | Solo su dado, incluidos mejoras, acero, elementos y monedas aplicables |
| sapphire / Zafiro | +2 al multiplicador | Su grupo |
| ruby / Rubí | ×1,5 después de todas las sumas al multiplicador | Su grupo; varios rubíes multiplican sus factores |
| diamond / Diamante | +1 copia del resultado original ya resuelto | Su grupo; total = original × (1 + cantidad de diamantes) |

La base de categoría y los compañeros no reciben el factor de esmeralda. Zafiros, cobre, viento y monedas suman antes de rubí. Diamante copia el resultado que ya contiene todos esos efectos y esmeralda; las copias no activan poderes, sorteos ni eventos adicionales y no se copian unas a otras.

Se preservan los decimales en dados y grupos. Rules.finish_score suma los resultados y redondea una sola vez, con 0,5 hacia arriba. Dos grupos de 10,5 y 13,5 más sobrante 3 acreditan 27, no 28.

## Datos e inspección

Gems.definition devuelve una copia de nombre, descripción y magnitud. Gems.evaluate recibe un dado y una categoría previamente validados por Rules y devuelve datos separados: active, reason, source y los cuatro aportes point_factor, multiplier_addition, multiplier_factor y copies, con valores neutros cuando está inactiva. Una carcasa vacía o desconocida no genera efectos.

Rules.score integra point_factors por dado y multiplier_additions, multiplier_factors y copies por grupo. Cada origen tiene formato shell:TIPO:ID. die_rows incluye shell_effect para explicar tanto activación como suspensión. La libreta identifica dado/gema, resultado original y copias. Los tooltips muestran poder, requisito y estado intacto/resquebrajado.

No se cambian los contadores de material o elemento, ni el azar, ni la identidad/cantidad de dados. Las carcasas permanecen equipadas entre manos y rivales; nueva partida crea cinco dados básicos. La anotación conserva el cálculo íntegro en historial y emite únicamente el evento de mano anotada existente.

## Ejemplos verificados

- Esmeralda con 4 +3 global +5 fuego: (4+3+5)×2 = 24. Su compañero con la mejora global aporta 7; par = 5+24+7 = 36.
- Dos rubíes dan factor 2,25; dos zafiros dan +4. Subtotal 20 con zafiro y rubí: 20×(1+2)×1,5 = 90.
- Dos diamantes sobre original 100 dan 300, nunca 400.
- Estado mixto con 4-4-2-2-2, acero/tierra/esmeralda, zafiro, cobre/viento/rubí y dos diamantes: el primer dado suma 39 y duplica a 78; subtotal 129. Multiplicador (1+2+1+1)×1,5 = 7,5. Original 967,5; con dos copias = 2902,5; acreditable **2903**.
- Marcar resquebrajada la esmeralda de ese estado conserva mejoras, acero y tierra: el dado aporta 39; la mano pasa a 2025.

## Evidencia y límites

Al cierre del paso 07: **581 comprobaciones aprobadas, cero fallos:** 524 anteriores y 57 nuevas. tests/gem_tests.gd cubre cada gema, categorías, suspensión, mezcla de tres familias, orden, decimales, aislamiento de metadatos, pureza, crédito único, historial y reinicios. tests/run_tests.gd comprueba desglose y tooltips de la interfaz real. Informe gems_demo en test-results/tests.json; para repetir: Probar.cmd.

Capturas revisadas: test-results/gemas.png, gemas-desglose.png y gema-resquebrajada.png. Implementación: scripts/gems.gd, scripts/rules.gd y scripts/main.gd; capturas mediante tests/visual_review.gd. El fixture de composición en tests/element_tests.gd ahora activa su esmeralda equipada: 54 puntos propios y par 66; con moneda Pares aporta 58.

Sin decisiones bloqueantes nuevas. Desde el paso 08 la rotura se sortea después de anotar; agrupar, reservar y prever siguen sin riesgo. Ver [rotura y reparación](ROTURA-Y-REPARACION.md). La compra llega en 12. El inicio normal conserva cinco dados básicos y los componentes se demuestran mediante estados controlados de pruebas.
