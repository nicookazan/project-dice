# Acero y cobre — contrato del paso 04

Implementado el 26 de octubre de 2026. Los nombres acero/cobre son provisionales. Sus efectos ya se resuelven con las tiradas y el cálculo normales; su compra se conectará en los pasos 11–12.

## Datos y duración

- material="steel": encounter_effects.steel_points almacena puntos propios acumulados.
- material="copper": encounter_effects.copper_multiplier almacena sumas al multiplicador del grupo.
- Ausencia de la clave equivale a cero. No se guardan ganancias por número o por cara.
- Los contadores duran todo el encuentro y no se borran al empezar otra mano.
- Game._start_encounter() los reinicia al entrar al próximo rival. Conserva el material, las caras y las mejoras numéricas.
- Nueva partida devuelve los cinco dados básicos y elimina las acumulaciones.

No se implementa todavía una operación comercial de cambio de material ni nuevas familias.

## Disparador único

Game._after_roll(event) llama a Materials.after_reroll() únicamente para eventos reroll efectivos. Utiliza las listas rolled_ids y kept_ids generadas antes de resolver la tirada.

Una tirada inicial de cualquier mano no es un relanzamiento: no gana cobre, no gana acero y no borra el acero acumulado en otra mano. Mover dados, consultar la libreta, agruparlos, vaciar el vaso o intentar lanzar sin presupuesto no activa los metales.

Los efectos no consumen números aleatorios ni disparan eventos extra. Los métodos de consulta no aplican ganancias. El observador de pruebas llama al hook real de Game antes de registrar lo observado.

## Acero

En cada relanzamiento de otros dados donde permanece en mesa, suma +3 puntos propios una sola vez. Conservarlo suelto o en grupo cuenta. Relanzar uno o cuatro compañeros produce el mismo +3.

Relanzar el propio acero pone su steel_points en cero. Enviarlo al vaso sin lanzar no borra nada. No se limpian otras claves de encounter_effects, contadores de mano, caras, mejoras globales/locales, carcasa, rotura ni elemento.

Los puntos acumulados se suman también en sobrantes. Un 4 con +6 de acero aporta 10. Si además tiene +3 global y +12 local al 4, aporta 25. Su número sigue siendo 4 para combinaciones y paridad.

Un grupo bloqueado conserva sus miembros y su categoría; sus dados de acero pueden seguir acumulando puntos al conservarse mientras se relanzan otros dados.

## Cobre

Cada relanzamiento del propio dado suma +0,5 a su copper_multiplier. Relanzarlo otra vez aumenta el valor, no lo borra. Conservarlo mientras se relanzan otros no produce ganancias.

La acumulación se añade al multiplicador de su propio grupo solo en combinaciones desde par. No se aplica al grupo sin combinación, pero dejarlo allí no borra su valor para otra mano.

Los aportes de varios cobres se suman entre sí y con las monedas de categoría antes de factores. Dos cobres con +0,5 cada uno y una moneda Full +1 dan multiplicador 1 + 0,5 + 0,5 + 1 = 3. Un factor posterior de prueba ×1,5 lo lleva a 4,5.

## Desglose e inspección

Materials.steel_points() y copper_multiplier() leen el acumulado aplicable al material actual, sin mutaciones. Materials.inspect() devuelve datos separados con:

- id/name: identidad y nombre legible.
- duration: encounter.
- points / multiplier_addition: poder ganado y consultable.
- gain / trigger: magnitud por activación y disparador.
- applies_to_leftovers / resets_on_own_reroll: diferencias entre acero y cobre.

Rules.score añade material:steel:ID a los puntos propios y material:copper:ID a las sumas al multiplicador del grupo. No extiende sus efectos a otros grupos ni al bono histórico de repetición.

La libreta presenta cada origen con el material y número del dado. Los tooltips conservan las instrucciones del dado y agregan acumulación, disparador y duración. El dado básico sigue usando su ayuda normal.

## Ejemplos verificados

Con resultados controlados 4-4-2-2-6:

1. Dos aceros forman el primer par; dos cobres se relanzan una vez y forman el segundo.
2. Cada acero gana +3: su par da 5 + 4 + 4 + 3 + 3 = 19.
3. Cada cobre gana +0,5: su par da (5 + 2 + 2) × (1 + 0,5 + 0,5) = 18.
4. Sobra un 6: total 43.
5. Relanzar solo el sobrante vuelve a dar +3 a cada acero; el par pasa a 25. El cobre conservado no aumenta: con el mismo sobrante 6, la mano da 49.

Otra prueba con +3 global y +12 local al 4:

- Primera mano con un acero de +6 y cobre de +1: par 74 más sobrantes 6 = 80.
- La segunda mano conserva esos contadores en su tirada inicial. Un nuevo relanzamiento del cobre deja acero +9 y cobre +1,5: par 100 más sobrantes 6 = 106.
- Acumulado 186; el siguiente rival comienza con ambos metales en cero y las mejoras numéricas conservadas.

Al cierre del paso 04, el antiguo fixture de estado del paso 01 acreditaba 43 y 86 (129) porque sus +6 de acero almacenados ya tenían efecto. Desde el paso 05 acredita 48 y 91 (139), al activar también su fuego. No se borró esa interacción para conservar resultados históricos de una etapa sin poderes.

## Evidencia y límites

391 comprobaciones aprobadas: 328 anteriores y 63 nuevas. Informe test-results/tests.json, campo materials_demo. tests/material_tests.gd cubre disparadores, acumulación, reinicios, mezcla con números/monedas, pureza, bloqueo, snapshots y crédito.

Capturas revisadas: test-results/metales.png, acero.png y cobre.png. La UI también se prueba con un par acero/cobre de 24 puntos y multiplicador 1,5.

Los estados controlados solo se crean desde tests; la partida normal sigue empezando con cinco dados básicos. Fuego/agua/electricidad se incorporaron en el paso 05; tierra/viento se incorporaron en el 06 con contadores independientes de mano. Los poderes de gemas se incorporaron en el 07; rotura, compra de materiales y sinergias especiales siguen en sus pasos.

## Metales nuevos (TX3 y TX4, 07/11/2026)

El nombre «Hierro» reemplaza a «Acero» en toda la interfaz; el id interno sigue siendo `steel`, así que los guardados no migran. Se suman `rust_iron` (hierro oxidado), `rust_copper` (cobre oxidado) y `gold` (oro), definidos en la tabla `Materials.TABLE`, donde cada metal indica su nombre, su cuerpo del shader y su **metal base**.

**Mecánicas provisionales (decisión del autor, 06/11/2026):** hierro oxidado funciona como hierro, cobre oxidado como cobre y oro como hierro. Mismos puntos, mismos reinicios, mismos contadores (`steel_points` y `copper_multiplier`), que se guardan por base. Para los jefes que suspenden metales y para la moneda «Dados de metal» (C22) cada metal nuevo cuenta como su base o como metal, respectivamente. Los dados oxidados se compran ya oxidados: el óxido no avanza en la partida.

**Tienda y guardado:** los cinco metales entran a las ofertas de componentes con el mismo precio y peso que su base (tabla provisional hasta el ítem 7). El guardado solo amplía la lista de materiales válidos; el formato no cambia y las partidas viejas cargan.

**Pendiente del autor:** mecánicas propias de los oxidados y del oro. La del oro («da dinero si no se usa para hacer puntos») necesita definir qué significa «no se usa», porque hoy los sobrantes suman puntos. Si cambian el formato del guardado, llevan su migración. Arte: [TX3](pasos/TX3-metales-arte.md); código: [TX4](pasos/TX4-metales-juego.md).
