# 06 — Tierra y viento con duración por mano

Versión 1 · 25 de octubre de 2026.

**Entrega:** Motor de reglas. **Estado actual:** Completado y probado el 26 de octubre de 2026; dependencias 04 y 05 completadas.

**Depende de:** [04 — Acero y cobre con duración por encuentro](04-metales.md), [05 — Fuego, agua y electricidad](05-elementos-condicionales.md). **Decisiones vinculadas:** Ninguna bloqueante. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [06 en Notion](https://app.notion.com/p/404c28142b55811cbfe4fb145757ee27?pvs=204).

Añadir acumulaciones de mano sin mezclarlas con las acumulaciones de encuentro de acero y cobre.

## Fuente y alcance normativo
PRD-PROTOTIPO: tierra y viento, disparadores y reinicios. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Tierra activa si al menos un dado se relanza y ella permanece en mesa. Añade +2 puntos por cada otro dado conservado junto a ella, incluidos agrupados y sueltos.
2. No contar al propio dado de tierra ni a los relanzados. Conservar solo tierra y relanzar cuatro produce ganancia 0.
3. Acumular tierra durante la mano. Relanzar el propio dado borra toda su acumulación de tierra; la mano siguiente también la reinicia.
4. Tierra aplica lo acumulado también en sobrantes.
5. Viento suma +0,5 al multiplicador por cada relanzamiento propio. Primera tirada no cuenta.
6. Reiniciar viento cada mano; aplicarlo solo en combinaciones desde par.
7. Mantener independientes los campos de material y elemento. Un mismo dado puede tener acero+tierra o cobre+viento.

## Criterios de aceptación
- Tierra y tres otros dados conservados, quinto relanzado: tierra gana +6.
- Tierra y un compañero conservados: +2; repetir aumenta a +4.
- Enviar y retirar dados sin lanzar no gana nada; intentar tirar el vaso vacío tampoco.
- Acero+tierra, junto a otros tres conservados: gana +3 de acero y +6 de tierra en ese relanzamiento.
- Al empezar otra mano del mismo encuentro se conserva acero y se borra tierra.
- Cobre+viento tras dos relanzamientos propios aporta +1 de cada fuente; al iniciar otra mano queda solo +1 del cobre.
- Viento sobrante no multiplica; tierra sobrante sí suma sus puntos.

## Entregable
Eventos integrados y pruebas con mezcla de familias y límites de duración. El desglose distingue ambos orígenes.

## Fuera de alcance
No generalizar que todos los efectos se reinician juntos ni agregar una bonificación de sinergia por combinarlos.

## Cierre del paso
524 comprobaciones aprobadas, cero fallos: 470 anteriores y 54 nuevas. Eventos y contadores en scripts/elements.gd y scripts/game.gd; cálculo/desglose en scripts/rules.gd y scripts/main.gd. Pruebas en tests/hand_element_tests.gd, tests/element_tests.gd y tests/run_tests.gd; capturas mediante tests/visual_review.gd.

Se verificaron conservación agrupada/suelta, tierra sola, reinicio propio, viento acumulativo, tiradas rechazadas/extra, composición con materiales y mejoras, independencia entre mano/encuentro, previsión pura y anotación única. La demostración combina acero+tierra y cobre+viento: mano 64; siguiente mano sin nuevos relanzamientos 43, conservando solo metales. Capturas revisadas: test-results/elementos-mano.png, tierra-acero.png, viento-cobre.png y reinicio-elementos-mano.png.

Ver [contrato y evidencia](../ELEMENTOS-DE-MANO.md). Sin decisiones bloqueantes nuevas. Poderes de gemas en 07 y compras en 12. El paso 07 tiene ahora completas sus dependencias.

