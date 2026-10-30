# 02 — Cálculo de puntos y eventos sin efectos secundarios

Versión 1 · 25 de octubre de 2026.

**Entrega:** Motor de reglas. **Estado actual:** Completado y probado el 25 de octubre de 2026.

**Depende de:** [01 — Estado persistente de partida y dados](01-estado-dados.md). **Decisiones vinculadas:** Ninguna bloqueante. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [02 en Notion](https://app.notion.com/p/404c28142b5581b8a58df21f7d4124d3?pvs=204).

Preparar un cálculo único y explicable que sirva para la previsión y la anotación, con eventos claros para conservar, relanzar y terminar una mano.

## Fuente y alcance normativo
PRD IA §4–6 y §13; PRD-PROTOTIPO §6 y reglas posteriores de gemas. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Adaptar Rules.score al estado persistente sin cambiar las bases ya vigentes.
2. Separar identidad del resultado, puntos propios, base de categoría, sumas al multiplicador, factores y copias finales.
3. Devolver un desglose por grupo y por dado con origen de cada aporte. Mantener decimales internos; redondear una sola vez el total de mano con 0,5 hacia arriba.
4. Establecer eventos de juego: primera tirada, relanzamiento efectivo con lista de lanzados/conservados, mano anotada y encuentro cerrado. Mover dados no es lanzar.
5. La consulta de previsión debe ser pura: sin aumentar contadores, gastar objetos, consumir azar ni comprobar roturas.
6. Anotar acredita una sola vez; los eventos posteriores ocurren después de fijar la puntuación. Preparar el lugar de ejecución de roturas para el paso 08.
7. Mantener validaciones de grupos: selección exacta, sin repetir IDs, sin reusar un dado; sobrantes en un único grupo.
8. Evitar un sistema genérico de efectos excesivo: resolver los puntos de extensión necesarios para el catálogo conocido.

## Criterios de aceptación
- Un trío de seises da 28; par de doses da 9; juntos dan 37.
- Doble par 2-2-5-5 y sobrante 6 da 35; dos pares separados y el mismo sobrante da 30.
- Generala servida de seises da 130, sin victoria automática.
- Relanzar solo un sobrante elimina servida de todos los grupos de la mano.
- Veinte consultas de previsión dejan estado y RNG intactos y coinciden con la anotación.
- Fixture de factores: multiplicador base 2, aporte +1 y factor ×1,5 da 4,5; dos grupos de 10,25 suman 20,5 y se acreditan 21, sin redondearlos antes.
- Repetir anotar no vuelve a sumar ni disparar eventos.

## Áreas de código y entrega
scripts/rules.gd, transiciones de scripts/game.gd y tests/run_tests.gd. Documentar el contrato del desglose para la libreta del paso 13.

## Fuera de alcance
Los factores de prueba no agregan objetos al catálogo. Los bonos históricos de varios tríos no habilitan más de cinco dados.

## Cierre del paso

Implementado y probado: **242 comprobaciones aprobadas, cero fallos** (173 anteriores y 69 nuevas).

- Rules.score valida la selección exacta y devuelve un desglose por dado, categoría, sumas, factores y copias.
- resolve_die, resolve_group y finish_score separan las operaciones y conservan decimales; solo el total de mano se redondea.
- Los eventos registran tiradas iniciales, relanzamientos efectivos, anotaciones y cierres. Sus hooks posteriores no se ejecutan al consultar la previsión.
- Anotar/cerrar son idempotentes; los efectos posteriores reciben los puntos e historial ya acreditados.
- La libreta muestra contribuciones por dado y moneda, sin truncar decimales.
- Código: scripts/rules.gd, scripts/game.gd y scripts/main.gd.
- Pruebas: tests/scoring_event_tests.gd, tests/support/observed_game.gd, tests/run_tests.gd y tests/visual_review.gd.
- Contrato para pasos 13/15: [PUNTUACION-Y-EVENTOS.md](../PUNTUACION-Y-EVENTOS.md).
- Informe: scoring_events_demo en test-results/tests.json. Revisión visual: test-results/desglose-puntos.png.
- No se agregaron objetos ni poderes nuevos al catálogo; factores/copias fuera de las monedas actuales se prueban con fixtures.

Paso recomendado siguiente: 03. El 10 también tiene sus dependencias técnicas completas; el 09 conserva su decisión pendiente D02.

