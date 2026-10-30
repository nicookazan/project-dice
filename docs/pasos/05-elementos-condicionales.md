# 05 — Fuego, agua y electricidad

Versión 1 · 25 de octubre de 2026.

**Entrega:** Motor de reglas. **Estado actual:** Completado y probado el 26 de octubre de 2026; dependencias 02 y 03 completadas.

**Depende de:** [02 — Cálculo de puntos y eventos sin efectos secundarios](02-puntuacion-eventos.md), [03 — Mejoras globales, locales y cambios de cara](03-numeros-caras.md). **Decisiones vinculadas:** Ninguna bloqueante. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [05 en Notion](https://app.notion.com/p/404c28142b55818390d6f75ac2d3344f?pvs=204).

Añadir los elementos cuyo poder depende del resultado y del grupo, sin contadores acumulativos.

## Fuente y alcance normativo
PRD-PROTOTIPO: tres espacios y definiciones de fuego, agua, electricidad. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Fuego: +5 puntos propios cuando el dado muestra 4, 5 o 6 y pertenece a una combinación válida desde par.
2. Agua: +5 puntos propios con 1, 2 o 3 y combinación desde par.
3. Electricidad: +3 puntos propios por cada otro dado de su mismo grupo que muestre igual número. No contarse a sí mismo ni contar otros grupos.
4. Tratar a los sobrantes como un único grupo: electricidad puede contar coincidencias entre ellos; fuego y agua no activan allí.
5. Permitir un elemento por dado junto a material y carcasa. Es pasivo, permanente durante la partida y no consume usos.
6. Añadir cada aporte una sola vez antes del eventual ×2 de esmeralda. Describir condición, aporte y por qué no se activó cuando corresponda.

## Criterios de aceptación
- Un 4 de fuego aporta 9 dentro de un par; suelto aporta 4 antes de otras mejoras.
- Un 3 de agua aporta 8 dentro de un trío; un 4 de agua no activa.
- Una mejora que convierte un 3 en 12 puntos no habilita fuego: se evalúa la cara 3.
- Un eléctrico en trío suma +6 a sus propios puntos; en generala suma +12.
- Dos 2 sin agrupar: cada eléctrico entre ellos cuenta al otro dentro de sobrantes.
- Un par de doses separado no cuenta coincidencias de un 2 situado en otro grupo.
- Consultar la previsión varias veces o relanzar no acumula un bono permanente de estos elementos.

## Entregable y demostración
Catálogo de tres efectos, cálculo y desglose. Probar un dado con mejora local y elemento para verificar composición; su aplicación por compra llega en 12.

## Fuera de alcance
Sin reacciones especiales entre familias, activación manual, nuevos elementos ni reglas de consumo.

## Cierre del paso
470 comprobaciones aprobadas, cero fallos: 391 anteriores y 79 nuevas. Catálogo y evaluación pura en scripts/elements.gd; integración en scripts/rules.gd y scripts/main.gd. Pruebas en tests/element_tests.gd, tests/run_tests.gd y tests/state_tests.gd; capturas mediante tests/visual_review.gd.

Se verificaron caras límite, categorías, electricidad entre grupos y sobrantes, composición con números/metales/monedas, persistencia, previsión sin mutaciones ni consumo de azar y anotación única. Capturas revisadas: test-results/elementos.png, fuego-agua.png y electricidad.png. Demostración: par 39 + trío 40,5 = 79,5, acreditable 80.

Ver [contrato y evidencia](../ELEMENTOS-CONDICIONALES.md). No hubo decisiones bloqueantes. La compra queda en 12 y el poder de esmeralda en 07. El paso 06 tiene ahora completas sus dependencias.

