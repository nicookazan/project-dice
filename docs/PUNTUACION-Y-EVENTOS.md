# Cálculo y eventos — contrato del paso 02

Implementado el 25 de octubre de 2026. Una consulta de puntuación describe lo que ocurriría sin ejecutar efectos que muten estado, gastar objetos ni consumir azar.

## Cálculo compartido

Game.preview() consulta Rules.score(). Game.score_hand() obtiene esa misma previsión, comprueba valid y acredita total una sola vez. El cálculo no escribe en los dados, grupos, monedas ni contadores.

Rules.validate_groups() rechaza selecciones vacías, índices inexistentes/no enteros, IDs duplicados dentro o entre grupos, resultados sin tirar e identidades incoherentes. La categoría debe coincidir con exactamente los dados seleccionados. Los sobrantes se agregan al final como un único grupo sin combinación; no se detectan pares automáticamente entre ellos.

Un cálculo inválido devuelve valid=false, errors con la explicación, total/raw_total=0 y rows vacío. No acredita historia, puntos ni un evento de mano anotada.

## Etapas y extensiones acotadas

1. resolve_die: número visible + aportes de puntos propios; después factores propios del dado.
2. resolve_group: base + valores de caras + mejoras de puntos.
3. Multiplicador del grupo: multiplicador inicial + sumas; después producto de factores.
4. Resultado original del grupo; copias finales = original × (1 + cantidad de copias).
5. finish_score: sumar todos los grupos con sus decimales y redondear una sola vez, con 0,5 hacia arriba.

Cada aporte explícito tiene source y amount. Los auxiliares aritméticos reciben contribuciones ya calculadas; reciben también los aportes puros calculados de las gemas desde el paso 07.

En el cierre original del paso 02 se aplicaban solo las monedas de la demo. Desde el paso 03 también se aplican mejoras globales y locales; desde el 04, acero y cobre. Sus ganancias se resuelven fuera de la previsión y solo se leen al puntuar. Desde el 05, fuego/agua/electricidad se evalúan en el cálculo puro según cara y grupo, sin hooks ni contadores. Desde el 06, tierra/viento ganan acumulación por mano en el evento de relanzamiento y solo se leen al puntuar. Desde el 07, las cuatro gemas aportan factores propios, sumas/factores del multiplicador y copias finales mediante cálculo puro. Desde el 09, los stickers aportan puntos de grupo y sumas a su multiplicador antes de rubí, según nivel y datos explícitos. El catálogo final sigue pendiente de D02. Desde el 08, la rotura se resuelve fuera de la previsión, después de acreditar. Desde el 10, Coins define las ocho monedas y Rules consulta sus aportes; las vistas de IDs provienen de instancias del inventario. Consumir opera fuera de la previsión, con contexto válido y sin gastar mano/tirada.

## Resultado de una mano

| Campo | Significado |
|---|---|
| valid / errors | Validez y motivos de rechazo |
| rows | Filas separadas por grupo y sobrantes |
| raw_total | Suma sin redondear de los resultados de grupos |
| total | Entero acreditable después del único redondeo |
| served | Si la mano conserva servida |

## Fila de grupo para la libreta

Se conservan category, ids, base, dice, added, multiplier y total, usados por la interfaz anterior.

| Campo adicional | Significado |
|---|---|
| category_base / served_bonus | Base ordinaria y bono de servida, separados |
| die_rows | Desglose por dado |
| subtotal | base + dice + added |
| multiplier_base | Multiplicador inicial, hoy 1 |
| multiplier_additions | Aportes aditivos con origen |
| multiplier_sum | Inicial más sumas, antes de factores |
| multiplier_factors | Factores con origen |
| original_total | Subtotal × multiplicador resuelto, antes de copias |
| copies / copy_count | Fuentes y cantidad total de copias |
| total | Resultado final del grupo sin redondear |

Cada die_row contiene id, number, face_index, base_points, point_additions, point_factors, before_factors y points. number conserva la identidad de combinación/paridad; points es el aporte de puntuación.

Fuentes actuales: coin:even, coin:odd, coin:full/straight/generala/poker y consumable:boost. La UI traduce esos IDs a nombres de monedas y muestra el aporte de cada dado. Devuelve y utiliza copias profundas para que editar un resultado no cambie los datos originales.

Ejemplos comprobados: trío de seises 28 + par de doses 9 = 37; doble par 2-2-5-5 + sobrante 6 = 35; dos pares separados + ese sobrante = 30; generala servida de seises = 130, sin victoria automática.

Fixtures: (2+1)×1,5 = 4,5; dos factores ×1,5 dan ×2,25; dos copias de un grupo de 100 dan 300; dos grupos de 10,25 suman 20,5 y acreditan 21. La transición real de anotación también se prueba con ese resultado fraccionario.

## Eventos de acciones efectivas

Game.events conserva el registro del encuentro actual. Cada evento es un diccionario separado:

- sequence: número creciente dentro de la partida.
- type: initial_roll, reroll, hand_scored o encounter_closed.
- rival y hand: contexto en que ocurrió.
- payload: datos separados del estado vivo.

| Tipo | Momento y contenido |
|---|---|
| initial_roll | Tras resolver la primera tirada de cada mano; rolled_ids, kept_ids, results y roll_number |
| reroll | Tras resolver un relanzamiento efectivo; las mismas listas, incluidos como conservados los dados agrupados |
| hand_scored | Después de fijar last_score, puntos, historial y fase de resultado; score completo y accumulated |
| encounter_closed | Después de cobrar y cambiar la fase; points, target, reward, cash_before y cash_after |

results registra id, face_index y number de cada dado lanzado. Mover dados, armar grupos, consultar la libreta o intentar lanzar un vaso vacío no emite una tirada. Repetir anotar/cerrar tampoco emite eventos.

El registro se vacía al empezar otro encuentro; sequence continúa para evitar IDs repetidos en la partida. Nueva partida reinicia ambos. Game.snapshot() copia también eventos y secuencia sin compartir payloads.

## Lugar de efectos posteriores

_after_roll(event) se llama una vez después del lanzamiento efectivo, con resultados y presupuesto ya actualizados. El paso 04 ya resuelve allí acero/cobre solo si el evento es reroll; el 06 también resuelve allí tierra/viento con sus propios contadores de mano.

_after_hand_scored(event) se llama una vez después de acreditar puntos e historial, antes de evaluar la derrota por manos agotadas. Desde el paso 08 resuelve allí una comprobación por carcasa intacta en combinación, protegida por breakage_by_hand; el de tirada aplica acero/cobre y tierra/viento desde los pasos 04 y 06.

Los hooks reciben una copia del evento. Cambiar su payload no puede reescribir el resultado acreditado, historial o registro original; los futuros efectos deberán modificar explícitamente el estado correspondiente.

No hay callbacks durante la previsión, ni bus genérico de efectos, ni un motor de catálogo anticipado. _after_roll ya aplica metales y elementos de mano; _after_hand_scored aplica la rotura después del crédito. Reparación se resuelve en su propia fase después del cobro, sin recalcular historia ni recompensas.

Desde el paso 13, la libreta usa texto ajustado y desplazable, con decimales íntegros y el mismo cálculo puro para la selección. Las fichas no ejecutan hooks ni consumen azar.

## Evidencia

242 comprobaciones aprobadas: las 173 anteriores y 69 nuevas. tests/scoring_event_tests.gd cubre aritmética, desglose, validación, pureza y orden/idempotencia de eventos. tests/support/observed_game.gd es exclusivo de pruebas.

test-results/tests.json contiene scoring_events_demo con resultados de aritmética y una secuencia de eventos. La captura test-results/desglose-puntos.png fue revisada: full servido de 122 con las contribuciones de los cinco dados y sus monedas.
