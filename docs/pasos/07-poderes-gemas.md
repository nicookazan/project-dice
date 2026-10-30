# 07 — Poderes de esmeralda, rubí, zafiro y diamante

Versión 1 · 25 de octubre de 2026.

**Entrega:** Motor de reglas. **Estado actual:** Completado y probado el 26 de octubre de 2026; dependencias 02, 04, 05 y 06 completadas.

**Depende de:** [02 — Cálculo de puntos y eventos sin efectos secundarios](02-puntuacion-eventos.md), [04 — Acero y cobre con duración por encuentro](04-metales.md), [05 — Fuego, agua y electricidad](05-elementos-condicionales.md), [06 — Tierra y viento con duración por mano](06-elementos-acumulativos.md). **Decisiones vinculadas:** Ninguna bloqueante. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [07 en Notion](https://app.notion.com/p/404c28142b55813292e0c13163041011?pvs=204).

Resolver los cuatro poderes de carcasa en el orden aprobado y hacer visibles sus aportes.

## Fuente y alcance normativo
PRD-PROTOTIPO: carcasas de vidrio y gemas; PRD IA §6 sumas antes de productos. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Activar gemas únicamente si la carcasa está intacta y el dado puntúa en combinación desde par; sobrantes nunca activan.
2. Esmeralda multiplica ×2 todos los puntos propios de ese dado, incluyendo mejoras y bonos de material, elemento y monedas. No multiplica la base ni otros dados.
3. Zafiro suma +2 al multiplicador del grupo por carcasa intacta.
4. Rubí aplica ×1,5 al multiplicador después de todas las sumas. Varios rubíes multiplican sus factores.
5. Diamante añade una copia del resultado final de su grupo por cada diamante: original × (1+n), sin resolver de nuevo poderes ni activar eventos.
6. Devolver el cálculo completo con campos suficientes para explicar aportes y factores; mantener decimales hasta el total final de mano.
7. Usar un indicador de carcasa resquebrajada que el paso 08 administrará; desde este paso, un fixture roto no activa su poder.

## Criterios de aceptación
- Esmeralda con cara 4, mejora +3 y fuego +5 aporta (4+3+5)×2 = 24.
- Dos rubíes generan factor 2,25; dos zafiros aportan +4.
- Fixture de grupo: subtotal 20, multiplicador inicial 1, un zafiro y un rubí → 20×(1+2)×1,5 = 90.
- Dos diamantes sobre grupo cuyo resultado antes de copias sea 100 dan 300, no 400.
- Carcasa rota o dado sobrante no aporta ni factor, ni suma, ni copia.
- Cobre/viento se suman antes de rubí; diamante copia el resultado que ya contiene esmeralda y rubí.
- La previsión permanece sin efectos secundarios.

## Entregable y demostración
Pruebas de cada gema y de combinaciones de tres familias. Incluir un ejemplo con resultado fraccionario que obligue a redondear al final.

## Fuera de alcance
No hacer sorteos de rotura todavía; no aplicar riesgo al formar grupos, reservar o consultar la libreta.

## Cierre del paso
581 comprobaciones aprobadas, cero fallos: 524 anteriores y 57 nuevas. Poderes puros en scripts/gems.gd; integración y desglose en scripts/rules.gd y scripts/main.gd. Pruebas en tests/gem_tests.gd, tests/run_tests.gd y tests/element_tests.gd; capturas mediante tests/visual_review.gd.

Se verificaron cada gema, categorías, carcasas rotas/sobrantes, composición con números/metales/elementos/monedas, sumas antes de productos, copias sin recursión, redondeo final y previsión sin mutaciones ni consumo del azar. Demostración mixta: subtotal 129 × multiplicador 7,5 × tres resultados = 2902,5, acreditable 2903. Capturas revisadas: test-results/gemas.png, gemas-desglose.png y gema-resquebrajada.png.

Ver [contrato y evidencia](../GEMAS.md). Sin decisiones bloqueantes nuevas. Rotura/reparación en 08; compras en 12. El paso 08 tiene completas sus dependencias técnicas; D08 sigue vinculada a la interacción de reparación en 13–14.

