# 01 — Estado persistente de partida y dados

Versión 1 · 25 de octubre de 2026.

**Entrega:** Motor de reglas. **Estado actual:** Completado y probado el 25 de octubre de 2026.

**Depende de:** [00 — Base recuperada y reglas vigentes](00-base-verificada.md). **Decisiones vinculadas:** Ninguna bloqueante. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [01 en Notion](https://app.notion.com/p/404c28142b558193b702f1400b22d114?pvs=204).

Que cada uno de los cinco dados conserve su identidad, caras, mejoras y componentes durante la partida, separando lo que se reinicia por mano o encuentro.

## Fuente y alcance normativo
PRD-PROTOTIPO: cinco dados fijos y tres espacios independientes; PRD IA §7. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Punto de partida antes de este paso
scripts/game.gd reinicia el arreglo de dados en start_hand(); hoy cada dado solo guarda value y zone. Ampliar este modelo es la primera dependencia real.

## Trabajo a realizar
1. Definir una identidad estable para cada uno de los cinco dados y seis posiciones de cara. Guardar el número de cada cara por separado del valor que aporta.
2. Separar estado permanente de la partida (caras, mejoras locales, material, carcasa, rotura y elemento), estado de encuentro y estado de mano.
3. Guardar las mejoras globales por número y el vaso de cuero en el estado de partida, sin copiarlas a cada cara.
4. Mantener grupos, selección, vaso y reserva referenciados a dados válidos. Conservar la regla de bloqueo al enviar al vaso.
5. Hacer explícitos los reinicios: nueva mano libera grupos y resultados; nuevo encuentro borra acumulaciones de encuentro; nueva partida borra todas las mejoras propias de la partida.
6. Adaptar roll, start_hand, restart y leave_shop, preservando la demo y su semilla. Proponer estructuras pequeñas serializables, sin atar las reglas a nodos visuales.
7. Añadir un constructor de estados de prueba; datos controlados solo en pruebas, no regalos durante la partida.

## Criterios de aceptación
- Cambiar la cara 2 por 4 y registrar una mejora local no se pierde al empezar la segunda mano ni otro rival.
- Nueva partida devuelve cinco dados con caras 1–6, sin efectos y sin referencias compartidas entre dados.
- Modificar un dado no cambia los otros cuatro.
- Los cinco dados se mantienen incluso cuando una futura carcasa esté rota.
- Las 132 comprobaciones de referencia siguen pasando o se adaptan solo por representación, conservando la expectativa funcional.
- Crear el estado y copiarlo para consultar la previsión no altera el generador aleatorio.

## Entregable y demostración
Modelo integrado en game.gd o módulos de dominio pequeños; pruebas de reinicios y un ejemplo controlado de dos manos. Registrar el esquema y los campos a persistir para el paso 15.

## Fuera de alcance
Todavía no aplicar poderes, vender dados, aumentar su cantidad ni guardar archivos de partida.

## Cierre del paso

Implementado y probado: **173 comprobaciones aprobadas, cero fallos**. Se conservan las 132 anteriores y se añaden 41 de identidad, aislamiento, reinicios, RNG y copia profunda.

- Código: scripts/dice_state.gd y scripts/game.gd.
- Pruebas: tests/support/game_fixture.gd, tests/state_tests.gd y adaptación de tests/run_tests.gd.
- Contrato y campos para el paso 15: [ESTADO-DE-PARTIDA.md](../ESTADO-DE-PARTIDA.md).
- Demostración: state_demo en test-results/tests.json, con dos manos de 37 y 80 puntos y transición al siguiente rival.
- Se conserva la selección/bloqueo de grupos y los cinco dados, incluida una carcasa rota.
- Los poderes y la puntuación de las mejoras almacenadas siguen en los pasos posteriores. El guardado en disco corresponde al 15.
- No fue necesario resolver decisiones de diseño nuevas.

El paso 02 queda disponible. Los demás conservan sus dependencias.

