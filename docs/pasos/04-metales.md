# 04 — Acero y cobre con duración por encuentro

Versión 1 · 25 de octubre de 2026.

**Entrega:** Motor de reglas. **Estado actual:** Completado y probado el 26 de octubre de 2026.

**Depende de:** [02 — Cálculo de puntos y eventos sin efectos secundarios](02-puntuacion-eventos.md), [03 — Mejoras globales, locales y cambios de cara](03-numeros-caras.md). **Decisiones vinculadas:** Ninguna bloqueante. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [04 en Notion](https://app.notion.com/p/404c28142b5581cc9f22e62f8da2d86f?pvs=204).

Incorporar los dos materiales confirmados respetando sus disparadores, duración y alcance.

## Fuente y alcance normativo
PRD-PROTOTIPO: nuevas definiciones de metales. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Acero: por cada relanzamiento efectivo de otros dados, si permanece en mesa, añadir +3 puntos propios una sola vez, independientemente de cuántos otros se relancen.
2. Permitir activación conservado suelto o agrupado. Ni enviarlo al vaso ni retirarlo activa poder.
3. Acero conserva su acumulación entre manos del encuentro; relanzarlo borra solo esa acumulación. La primera tirada de otra mano no se trata como relanzamiento.
4. Cobre: cada relanzamiento propio suma +0,5 al multiplicador de su grupo. Dura el encuentro y nuevos relanzamientos suman, no reinician.
5. Cobre solo aplica en combinaciones desde par; en sobrantes no multiplica, pero conserva lo acumulado para una mano posterior.
6. Reiniciar ambos materiales al cambiar de rival; conservar caras y mejoras numéricas.
7. Incorporar sus aportes al desglose y datos consultables por la futura ficha del dado.

## Criterios de aceptación
- Conservar un acero y relanzar uno o cuatro dados produce +3 en ambos casos.
- Conservarlo dos relanzamientos produce +6; mover los otros sin lanzar produce 0.
- Al empezar la siguiente mano mantiene +6, aunque todos se lancen por primera vez.
- Relanzar ese acero lo devuelve a acumulación 0, sin quitar una mejora local.
- Cobre relanzado dos veces acumula +1; nuevo rival lo reinicia.
- Acero 4 con +6 conservado como sobrante aporta 10; cobre sobrante no añade su multiplicador.
- Los grupos bloqueados se benefician de conservar acero sin permitir cambiar sus miembros.

## Entregable
Materiales aplicados a estados de prueba y soportados por el motor normal, con pruebas de transiciones. Los nombres acero/cobre siguen siendo provisionales.

## Fuera de alcance
Compra de materiales, reacción especial con electricidad y nuevas variantes de metal.

## Cierre del paso

Implementado y probado: **391 comprobaciones aprobadas, cero fallos** (328 anteriores + 63 nuevas).

- Acero gana +3 una vez por relanzamiento ajeno; funciona suelto, agrupado y en sobrantes. Relanzarlo borra solo su ganancia.
- Cobre gana +0,5 por relanzamiento propio; sus sumas se aplican solo en combinaciones desde par.
- Ambas acumulaciones duran el encuentro; una nueva mano y su tirada inicial las conservan, el siguiente rival las reinicia.
- Aportes separados por dado/material en libreta y datos de inspección, con tooltips de regla y duración.
- Código: scripts/materials.gd, game.gd, rules.gd, main.gd y die.gd.
- Pruebas: tests/material_tests.gd, fixtures, observador, suite e imágenes controladas.
- Contrato: [METALES.md](../METALES.md).
- Evidencia: materials_demo en test-results/tests.json y capturas revisadas metales.png, acero.png y cobre.png.
- El fixture histórico con +6 de acero ahora puntúa 43 y 86, reflejando el poder implementado; los demás criterios de persistencia se conservan.

Sin decisiones de diseño nuevas. La compra de materiales sigue en 11–12; elementos, carcasas y sinergias no se adelantan.

Siguiente recomendado: 05. El 10 continúa disponible; el 06 aún depende del 05.

