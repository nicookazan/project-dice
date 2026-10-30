# Tierra y viento — contrato del paso 06

Implementado y probado el 26 de octubre de 2026. Los elementos permanecen equipados durante la partida, pero sus ganancias duran solo la mano. Son pasivos y no consumen usos. Sus valores iniciales de prueba son +2 y +0,5, ajustables durante el balance.

## Disparador y almacenamiento

Game._after_roll llama a Elements.after_reroll exclusivamente después de un relanzamiento efectivo, con rolled_ids y kept_ids del evento. La primera tirada de cada mano no cuenta. Mover dados, agruparlos, consultar la libreta, tirar el vaso vacío o lanzar sin presupuesto no produce ganancias. Una tirada extra efectiva sigue la misma regla.

- Tierra (`element="earth"`): si permanece en mesa, suma 2 × (cantidad de conservados − 1) a `hand_effects.earth_points`. Cuenta compañeros agrupados y sueltos, excluye al propio dado y a los relanzados. Conservar solo tierra da cero. Relanzar la propia tierra borra únicamente ese bono.
- Viento (`element="wind"`): cada relanzamiento propio suma +0,5 a `hand_effects.wind_multiplier`. Conservarlo no gana ni borra poder; volver a relanzarlo acumula.

Elements.earth_points y wind_multiplier son consultas puras; solo leen la clave si coincide el elemento equipado. La ausencia de clave equivale a cero. No usan azar ni generan eventos adicionales. Ninguna regla altera mejoras numéricas, caras, carcasa o contadores de la otra familia.

## Puntuación y desglose

Tierra suma puntos propios tanto en combinaciones como en sobrantes, antes de futuros factores propios. Viento se añade al multiplicador de su grupo solo en combinaciones desde par, junto a cobre y monedas, antes de futuros factores. Dejarlo en sobrantes conserva su acumulación, pero no la aplica. No hay un bono especial por combinar familias.

Los orígenes `element:earth:ID` y `element:wind:ID` se distinguen de `material:steel:ID` y `material:copper:ID`. La libreta muestra condición, acumulación y aplicación; los tooltips explican el disparador y los reinicios. La previsión no modifica dados, grupos, contadores, eventos ni azar. La anotación acredita exactamente ese cálculo una vez.

## Reinicios independientes

| Transición | Tierra/viento | Acero/cobre | Equipo |
|---|---|---|---|
| Relanzar una tierra | Borra solo su tierra | Aplica la regla propia del material | Conservado |
| Otra mano del mismo rival | Ambos a cero | Conservan acumulación | Conservado |
| Otro rival | Ambos a cero | Ambos a cero | Conservado |
| Nueva partida | Ambos a cero | Ambos a cero | Cinco dados básicos |

Se utiliza el reinicio por mano existente de DiceState; no se introduce un borrado conjunto de todos los efectos.

## Demostración y evidencia

Con 4-4-2-2-6, un acero+tierra en el primer par y cobre+viento en el segundo: relanzar solo el cobre/viento dos veces da acero +6, tierra +12, cobre +1 y viento +1. Primer par: 5 + 4 + 4 + 6 + 12 = 31. Segundo: (5 + 2 + 2) × (1 + 1 + 1) = 27. Sobrante 6: mano **64**.

La mano siguiente borra tierra/viento y conserva acero +6/cobre +1. Con los mismos grupos y sin otro relanzamiento da 19 + 18 + 6 = **43**. Con un nuevo relanzamiento del cobre/viento, los contadores quedan acero +9/tierra +6/cobre +1,5/viento +0,5; el recorrido automático deja tierra como sobrante y acredita **56**.

Al cierre del paso 06: **524 comprobaciones aprobadas, cero fallos:** 470 anteriores y 54 nuevas. Informe `hand_elements_demo` en test-results/tests.json. tests/hand_element_tests.gd cubre disparadores, tamaños de conservación, varios elementos, tirada extra, composición, ámbitos, reinicios, pureza, consumo exacto del azar, eventos y anotación. tests/run_tests.gd comprueba la interfaz real. Para repetir: Probar.cmd.

Capturas revisadas: test-results/elementos-mano.png, tierra-acero.png, viento-cobre.png y reinicio-elementos-mano.png, generadas por tests/visual_review.gd. Implementación: scripts/elements.gd, scripts/game.gd, scripts/rules.gd y scripts/main.gd. tests/element_tests.gd reconoce ahora el catálogo inicial de cinco elementos.

Sin decisiones bloqueantes nuevas. Los poderes de gemas se incorporaron en el 07 y las compras corresponden al 12; la partida normal sigue comenzando con cinco dados básicos. Los estados controlados se limitan a pruebas.
