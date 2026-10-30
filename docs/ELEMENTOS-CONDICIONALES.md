# Fuego, agua y electricidad — contrato del paso 05

Implementado y probado el 26 de octubre de 2026. Los tres elementos son pasivos, duran la partida y no consumen usos. Coexisten con material, carcasa y mejoras numéricas en el mismo dado. Su compra se conecta en el paso 12; los estados de demostración son exclusivos de pruebas.

## Reglas y cálculo

| Elemento | Condición | Aporte propio |
|---|---|---|
| fire / Fuego | Cara 4, 5 o 6 en una combinación desde par | +5 |
| water / Agua | Cara 1, 2 o 3 en una combinación desde par | +5 |
| electricity / Electricidad | Cada otro dado con el mismo número dentro del grupo | +3 por coincidencia |

Las condiciones leen el número de la cara, sin mejoras de puntos. Electricidad excluye al propio dado y los otros grupos; los sobrantes constituyen un único grupo donde sí funciona. Fuego y agua quedan inactivos en sobrantes. No se forman combinaciones automáticamente.

Elements.catalog() y definition() devuelven copias separadas. Elements.evaluate(die, dice, ids, category) recibe un grupo previamente validado por Rules y devuelve metadatos nuevos: identidad, condición, duración, active, points, matches, reason y source. Un elemento vacío o desconocido no produce efecto. No escribe estado, usa azar ni genera eventos.

Rules.score incorpora una sola contribución element:TIPO:ID a los puntos propios, junto a mejoras numéricas, acero y monedas aplicables. Se suma antes de factores propios y del multiplicador del grupo. La base de categoría y los compañeros no reciben el aporte. Desde el paso 07 la esmeralda equipada aplica su ×2 real después de estas sumas; ver [GEMAS.md](GEMAS.md).

La previsión y la anotación usan el mismo cálculo. Relanzar o consultar repetidamente no acumula ganancias de estos elementos. El campo element persiste entre manos y encuentros; nueva partida lo devuelve a vacío. No se agregan contadores ni hooks.

## Inspección y demostración

Cada die_row incluye element_effect aun cuando esté inactivo. La libreta muestra el origen del aporte y su condición cumplida o motivo de inactividad. El tooltip del dado indica condición, permanencia y ausencia de consumo.

Capturas revisadas: test-results/elementos.png, fuego-agua.png y electricidad.png. El estado controlado combina un acero/fuego 4 con +3 global, +12 local y +3 de acero: aporta 27; su compañero agua 4 aporta 7 y explica su inactividad. El par da 39. Otro grupo combina electricidad, agua y cobre: subtotal 27 × 1,5 = 40,5. Total de mano 79,5, acreditable 80 tras un único redondeo.

## Evidencia y límites

Al cierre del paso 05: 470 comprobaciones aprobadas, cero fallos: 391 anteriores y 79 nuevas. tests/element_tests.gd cubre todas las caras, categorías, coincidencias entre grupos/sobrantes, composición, persistencia, ausencia de acumulación, pureza y consumo exacto de azar. La suite también prueba el desglose real de la interfaz. Informe: elements_demo en test-results/tests.json. Para repetir: Probar.cmd.

Archivos de implementación: scripts/elements.gd, scripts/rules.gd y scripts/main.gd. Pruebas: tests/element_tests.gd, tests/run_tests.gd, tests/state_tests.gd y tests/visual_review.gd. El fixture histórico de estado ahora acredita 48 + 91 = 139 porque su fuego almacenado ya está activo, además del acero.

Tierra/viento se implementaron en el paso 06; ver [su contrato](ELEMENTOS-DE-MANO.md). El catálogo compartido contiene ahora los cinco elementos iniciales. Los poderes de gemas se incorporaron en el 07. Su fixture equipado ahora aporta 54 puntos propios y par 66; la captura del paso 05 sin carcasa conserva el ejemplo 27/39. Reacciones entre familias y compras siguen en sus fichas. El inicio normal conserva los cinco dados básicos.
