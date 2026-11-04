# Plan de implementación — monedas nuevas (primera tanda)

Catálogo y reglas: [MONEDAS-NUEVAS.md](MONEDAS-NUEVAS.md) (47 pasivas nuevas C07–C51, 7 de un uso U01–U08). Es la **primera tanda**: la arquitectura tiene que permitir sumar más monedas escribiendo datos, no código nuevo en `rules.gd`/`game.gd`.

Estado: plan, sin código. Convención del proyecto: una fase por vez, cada fase en `feature/<nombre>` con PR contra `main`, suite verde antes de cerrar, resultado y límites registrados en `ESTADO.md` y en el contrato del sistema.

## 1. Cómo funciona hoy (lo que condiciona el plan)

| Pieza | Hoy | Problema para las monedas nuevas |
|---|---|---|
| `Rules.score(dice, groups, passives, boost: bool, served, …)` | Pura; recibe solo ids de monedas y un bool de impulso | No ve estado de mano (tiradas usadas, mano 1 o 2), plata, stickers equipados, ni estado propio de cada moneda |
| `Coins` | Tabla `METADATA` + `DATA` con `effect` string; ramas a mano en `rules.gd` (`point_additions`, bucle de `category`) | Con ~55 monedas, una rama por moneda es inmantenible |
| `coin_inventory` | `equipped` / `consumables` con `state: {}` por instancia (hoy vacío) | Ya sirve para progreso (C18, C48–C51) pero nadie lo siembra ni lo valida |
| Capacidad | `shared_capacity` 5 y `consumable_capacity` 1 fijas; `save_validator` exige exactamente esos valores | Las monedas de ranura (C43/C44) exigen capacidad derivada |
| Plata | `can_afford` y `Purchases.prepare` exigen `cash >= 0` y `cash >= precio` | La moneda de oro (C19) necesita saldo negativo |
| Tiradas | `start_hand` fija `rolls_left = 3`; `roll()` siempre descuenta | C20 (+1 permanente) y relanzo libre (C27/U08) |
| Servida | `served = rolls_made == 1` | Sirve tal cual para C36 |
| Tienda | `Shop.generate` elige monedas con peso uniforme, sin rareza; `numbers` ya tiene sorteo por rareza en dos pasos | Reusar ese patrón para monedas |
| Rotura de gemas | `_after_hand_scored` sortea con `Gems.RISKS`; reparación en `Gems.repair_quote` | C46/C47/U07 |
| Categorías | `Rules.category(values)` solo mira los valores; escalera = `12345`, `23456`, `34561` | C25/C26/C28 cambian qué es una combinación |
| Guardado | v6, `save_validator` valida inventario, `shop_tables`, dados | Todo lo nuevo necesita v7 con migración |
| Arte | `coin_art.gd` indexa un atlas 4×2 con ocho ids | 55 monedas sin ilustración |
| Jefes | `BossRules.suspended(ctx, "coin", id)` | Cada efecto nuevo debe respetarlo |

## 2. Decisiones de diseño que fijo para poder arrancar

Son defaults míos; cualquiera se cambia con datos o una línea. Las marcadas **(confirmar)** conviene que las valides antes de la fase que las usa.

1. **Mult de mano = mult de cada grupo con combinación.** Las monedas "+1 mult" generales (C17, C36, C39, C40, C41, C50) suman a cada grupo que sea una combinación, nunca al grupo de sobrantes (igual que cobre y viento hoy). Con 2 grupos (trío + par) el beneficio se aplica dos veces. **(confirmar)**
2. **Puntos de mano = fila plana aparte.** Las monedas "+X puntos" sin condición de dado ni combinación (C18, C37, C38, C42, C49) se anotan en una fila propia que no se multiplica, como la fila DEBUG de `preview()`. Los puntos por dado y por combinación sí entran al grupo y se multiplican. **(confirmar)**
3. **C22–C24:** los puntos (+1) cuentan en los cinco dados; el mult (+0,5) solo en dados que están dentro de una combinación (sobrantes no).
4. **C41:** cuenta todas las equipadas, incluida ella misma.
5. **Escalera de 4 (C25):** sets válidos `1234`, `2345`, `3456` y, por la regla del 6→1 que ya existe, `4561`. Base 20 y bono de servida 25, como la escalera normal. El quinto dado va a sobrantes. **(confirmar)**
6. **Comodín (C26):** solo el dado con resultado 1. Para formar y puntuar toma el número que maximiza el puntaje de la mano; en caso de empate, el menor. Cada grupo guarda la asignación `die_id → número` para que previsión y anotación coincidan y para que sobrevivan al guardado. El número imitado se usa para todo (puntos del dado, mejoras globales, pares/impares, monedas por número). **(confirmar)**
7. **C18:** el estado es `strength` (40 inicial) y `grace` (verdadero hasta la primera tirada posterior a la compra). Resta `len(rolled_ids)` en cada tirada; la tirada con `grace` no resta y lo apaga. Suspendida por jefe: no aporta ni se desgasta.
8. **Monedas que crecen:** el contador avanza al cerrar el evento (C48 al ganar un encuentro, C49 al anotar una mano, C50 al anotar, C51 al ganar un jefe) y rinde desde el siguiente. La previsión nunca modifica el estado. Un jefe que las suspende no frena el contador (contrato de `cooldown_can_advance`).
9. **Descuento (C45):** −20 % sobre ofertas y renovaciones, redondeo al entero más cercano (0,5 hacia arriba): 4→3, 6→5, 9→7, 14→11. **(confirmar)**
10. **Renovación gratis (C21/U06):** hay un contador de renovaciones gratis por visita; la gratis no incrementa el precio de esa sección.
11. **Crédito (C19):** `cash` puede llegar a −10 con la moneda equipada. Aplica a compras y renovaciones de tienda y a reparaciones. Vender con saldo negativo está permitido (paga 1). La deuda no tiene intereses; el interés de cierre de encuentro se calcula con `max(cash, 0)` como hoy.
12. **Ranuras (C43/C44):** la capacidad se calcula (`base + bonos de equipadas`). No se puede vender una moneda de ranura si la capacidad resultante quedaría por debajo de lo ocupado.
13. **U07 Reparar gema:** solo en la fase `repair`; una de las gemas elegidas (la de mayor costo) se repara sin costo. Con C47 el resto cuesta la mitad (redondeo hacia arriba).
14. **C46:** la marca `shell_saved` vive en el dado; se reinicia si se compra otra gema para ese dado. El sorteo de rotura se consume siempre (misma secuencia de azar con o sin la moneda).
15. **Impulsos:** el bool `boost` pasa a una lista de impulsos activos. U01 conserva el id `boost` y cambia a 1 y 4; U03 y U04 son 2/5 y 3/6. Pueden acumularse varios en un encuentro.
16. **Tienda:** el sorteo es por etapas como el de números: tipo (pasiva/un uso) → rareza → moneda uniforme. Tipo 75/25 y rarezas de [MONEDAS-NUEVAS.md](MONEDAS-NUEVAS.md), todo en `shop_tables`. Si una etapa queda sin candidatas se renormaliza.
17. **Arte provisional:** hasta que el autor apruebe bocetos, las monedas sin ilustración usan una moneda en blanco del atlas con su abreviatura en texto, claramente provisional. No se inventa pixel art nuevo sin bocetos aprobados.

## 3. Arquitectura propuesta

**`scripts/coin_effects.gd` (nuevo, puro, sin estado propio).** Evalúa efectos declarativos. Cada moneda en `Coins.DATA` pasa a tener una lista `effects`, por ejemplo:

```
"par_mult":   {"effects": [{"kind": "category_mult",   "categories": ["Par"], "amount": 1}]},
"gastada":    {"effects": [{"kind": "hand_points_state", "key": "strength"}]},
"metal":      {"effects": [{"kind": "die_points_if", "filter": {"material": ["steel","copper"]}, "amount": 1},
                           {"kind": "die_mult_if",   "filter": {"material": ["steel","copper"]}, "amount": 0.5}]},
```

Familias de `kind` (unas 12 cubren las 55 monedas): `category_mult`, `category_points`, `die_points_if`, `die_mult_if`, `flat_group_mult`, `hand_mult_if` (condición de tirada/mano), `hand_points`, `scaled_mult` (stickers, equipadas, plata), `state_mult`/`state_points`, `rule` (straight4, wildcard1, pair_as_two_pair, free_single_reroll), `economy` (credit, discount, free_renewal, capacity, extra_rolls) y `gem` (save_first_break, repair_discount). Las monedas actuales se migran a esta tabla sin cambiar su resultado ni sus `source` (`coin:full`, etc.) para que sigan pasando los tests.

**Contexto de moneda.** `Rules.score(...)` gana un parámetro final `coin_context: Dictionary = {}` (compatible hacia atrás): `{hand, rolls_made, rolls_left, cash, equipped (instancias con state), sticker_levels, impulses, double_mult}`. Los fixtures que llaman a `score` sin contexto siguen funcionando. `Game.coin_context()` lo arma; `preview()` y `score_hand()` lo comparten, de modo que previsión y anotación sean idénticas por construcción.

**Instancias.** `Coins.instance(id, serial)` siembra `state` desde `Coins.initial_state(id)` (C18: `{strength: 40, grace: true}`; C48–C51: contadores en 0). `Purchases.prepare` usa esa función.

**Reglas que cambian combinaciones.** `Rules.category(values, rules := {})` y `Rules.validate_groups(dice, groups, rules)` reciben el conjunto de reglas activas (`straight4`, `wildcard`, `pair_as_two_pair`). Sin monedas el resultado es exactamente el de hoy.

## 4. Fases

Orden por dependencias y riesgo. Cada fase deja el juego jugable y la suite en verde.

### Fase 0 — Línea de base
- Correr la suite completa y confirmar el número real de comprobaciones (el `ESTADO.md` dice 2198; no confiar).
- Crear `feature/monedas-nucleo`.
- Cerrar las decisiones marcadas **(confirmar)** que afectan a la fase 1 y 2 (puntos 1, 2, 3).

### Fase 1 — Núcleo data-driven (sin monedas nuevas)
**Hace:** `coin_effects.gd`; `effects` en las ocho monedas actuales; `coin_context`; `Coins.initial_state`; campo `rarity`/`family` en el catálogo; capacidad derivada; guardado v7 con migración (impulsos como lista, capacidad calculada, `state` validado por moneda); `Shop` con sorteo por tipo y rareza (las ocho existentes quedan Común, precios 4/2 sin cambios).
**Criterio de cierre:** las 2198 comprobaciones actuales pasan sin editar ninguna aserción de puntuación; el sorteo de tienda con semilla fija ofrece lo mismo que antes cuando el catálogo es el de hoy (comprobar con un caso dorado).
**Riesgo:** medio. Es un refactor de `rules.gd`/`coins.gd`. Se protege con casos dorados de puntuación generados antes de tocar nada.

### Fase 2 — Monedas de puntuación sin estado
**Monedas:** C07–C09 (mult por combinación), C10–C16 (puntos por combinación), C17 (+1 mult), C22–C24 (metal/elementales/gemas), C29–C35 (por número), U01/U03/U04 (impulsos), U05 (doble mult).
**Detalle:** el doble mult de U05 es un flag de mano (`double_mult`) que se limpia al anotar; entra como factor ×2 en cada grupo con combinación.
**Pruebas:** una aserción de puntaje exacto por moneda con dados controlados (`Fixture.set_values`); coincidencia previsión = anotación; duplicados no permitidos; jefe que suspende la moneda; migración de un guardado v6 con impulso activo.
**Riesgo:** bajo.

### Fase 3 — Monedas de tirada y de mano
**Monedas:** C20 (+1 tirada), C36–C38 (ritmo), C39 (segunda mano), C40–C42 (stickers, equipadas, interés), C27 y U08 (relanzo libre de un dado).
**Detalle:** `start_hand` calcula `rolls_left = 3 + extra`. `roll()` con un único dado en el vaso y relanzo libre disponible no descuenta tirada pero sí incrementa `rolls_made` (deja de ser servida). El relanzo libre pasivo se reinicia cada mano; el de un uso es una ficha consumible.
**Pruebas:** C37/C38 con 0, 1 y 2 tiradas sobrantes; la interacción de U02 con C20; relanzo libre no descuenta pero gasta efectos de material/elemento (se dispara `_after_roll` igual).
**Riesgo:** medio (toca `roll()`).

### Fase 4 — Monedas con estado
**Monedas:** C18 (Moneda gastada), C48–C51 (Veterana, Acumulada, Racha, Cazajefes).
**Detalle:** engancharse a `_after_roll`, `score_hand` y `close_encounter`. Rotura de C18 al llegar a 0: se quita de `equipped`, se registra un evento y se muestra un aviso. La ficha de inspección muestra el estado (`28 / 40`, `+2,5 mult acumulado`). El validador exige `state` con forma correcta y rangos.
**Pruebas:** recorrer una campaña corta con semilla, guardando y restaurando entre manos y comprobando que el estado y el azar son idénticos; vender y recomprar reinicia; la tirada gratis de C18 se da una sola vez.
**Riesgo:** medio-alto (guardado y migración).

### Fase 5 — Economía y tienda
**Monedas:** C19 (oro), C21/U06 (renovación gratis), C45 (descuento), C43/C44 (ranuras), rareza y probabilidades reales en la tienda.
**Detalle:** `Game.can_afford` y `Purchases.prepare` reciben el límite de crédito; la interfaz muestra la plata negativa. La tienda muestra el precio con descuento y la rareza. La interfaz de monedas equipadas y de venta usa la capacidad derivada (hoy dibuja 5 fijas).
**Pruebas:** comprar hasta −10 y no más; vender la moneda de oro a 1; reroll gratis una vez; renovación pagada incrementa solo su sección; capacidad con C43 y venta bloqueada si sobran monedas; distribución de rarezas con 20 000 sorteos dentro de tolerancia.
**Riesgo:** medio (UI de la tienda).

### Fase 6 — Gemas
**Monedas:** C46 (Gema templada), C47 (Joyero), U07 (Reparar gema).
**Detalle:** `shell_saved` en el dado (con migración); `Gems.repair_quote` recibe descuento y reparación gratis; U07 se usa en la fase `repair`.
**Pruebas:** el sorteo de rotura consume el mismo azar con y sin C46; vender y recomprar C46 no renueva la protección; reemplazar la gema reinicia la marca.
**Riesgo:** bajo-medio.

### Fase 7 — Cambios de regla
**Monedas:** C25 (escalera de 4), C28 (par como doble par, experimental), C26 (comodín).
**Detalle:** `Rules.category` y `validate_groups` con reglas; `form_group`, la ayuda de combinaciones al pasar el mouse y la previsión usan el mismo conjunto. Para el comodín: resolutor de asignación determinista, `assigned` por grupo guardado en el snapshot, y brillo visual en el dado 1 cuando está en uso.
**Pruebas:** escalera de 4 con y sin moneda (sin ella no es combinación); el 5.º dado puntúa como sobrante; comodín en trío/póker/generala/full con 1 a 5 unos; empates; que el guardado reproduzca la misma asignación; que la previsión siempre iguale a la anotación en 500 manos aleatorias con semilla.
**Riesgo:** alto. Va última y cada moneda en su propio commit para poder revertir una sola.

### Fase 8 — Arte e interfaz (en paralelo desde la fase 2)
Pista separada, sin tocar `rules.gd`/`game.gd`: atlas de monedas ampliado, `coin_art.gd` por tabla, ficha de inspección con rareza y estado, brillo del comodín. **Aprobación del autor antes de integrar:** bocetos en una página de Artifact con PNG, uno por familia. Mientras tanto rige la moneda en blanco con abreviatura (decisión 17).

### Fase 9 — Simulación de balance
`tests/coin_balance_sim.gd` (headless): bot que arma el mejor agrupamiento con `Rules`, juega campañas por semilla con y sin cada moneda y mide aporte por mano, tasa de superar objetivos y efecto de combinaciones. Salida en `test-results/coin-balance.json` y tabla en el catálogo. Aquí se ajustan rarezas, precios y valores. **No reemplaza una sesión humana de juego** (D11 sigue pendiente).

## 5. Mapa moneda → fase

| Fase | Monedas |
|---|---|
| 1 | (núcleo) C01–C06, U01–U02 migradas |
| 2 | C07–C17, C22–C24, C29–C35, U01 (1 y 4), U03, U04, U05 |
| 3 | C20, C27, C36–C42, U08 |
| 4 | C18, C48–C51 |
| 5 | C19, C21, C43–C45, U06 |
| 6 | C46, C47, U07 |
| 7 | C25, C26, C28 |

## 6. Pruebas transversales (cada fase)
- Aserción de puntaje exacto por moneda con dados controlados y desglose de fuentes (`source`).
- Previsión = anotación, siempre.
- Reproducibilidad por semilla y exactitud tras guardar y continuar (ningún efecto re-sortea al cargar).
- Redondeo único al total de mano, con medios.
- Jefe que suspende cada moneda: sin poder y sin desgaste.
- Migración v6 → v7 sin sobrescribir archivos inválidos.
- Ajustar las aserciones que dicen "ocho monedas" en `coin_tests.gd`.

## 7. Documentación que acompaña cada fase
- Contrato por sistema: actualizar [MONEDAS-E-INVENTARIO.md](MONEDAS-E-INVENTARIO.md) y [MONEDAS-NUEVAS.md](MONEDAS-NUEVAS.md) (estado "implementada" por moneda), más [TIENDA-POR-SECCIONES.md](TIENDA-POR-SECCIONES.md), [GEMAS.md](GEMAS.md) y [PUNTUACION-Y-EVENTOS.md](PUNTUACION-Y-EVENTOS.md) donde correspondan.
- `ESTADO.md`: resultado, número de comprobaciones y límites.
- Aviso al usuario de cada cambio de alcance: el tablero de Notion se actualiza a mano o con el conector.

## 8. Riesgos principales
1. **Refactor de la fase 1** puede cambiar puntajes sin querer. Mitigación: casos dorados previos.
2. **Comodín** (previsión exacta, guardado, interfaz). Mitigación: última fase, aislada, con fuzz de previsión.
3. **Guardado v7** con estado por moneda. Mitigación: validación por forma y tests de ida y vuelta.
4. **Cantidad de arte** sin aprobar. Mitigación: moneda en blanco provisional y bocetos por familia.
5. **Capacidad y efecto de monedas "gratuitas"** (C43, C19, C20) pueden romper la economía; se miden en la fase 9 y empiezan con rareza alta.
