# La Semilla: jefe final (contrato)

Ficha: [21-la-semilla](pasos/21-la-semilla.md) · Decisión: [D19](pasos/DECISIONES.md) · Diseño y plan en Notion: [2. Boss final: La Semilla](https://app.notion.com/p/422c28142b55807f8c72f79c1a366033) y su [plan de implementación](https://app.notion.com/p/422c28142b558089aaeccc27942b4245) · Bocetos aprobados: A1, B1 y la terminal C2 + C3 ([página de bocetos](https://claude.ai/artifact/STaKxRNLXYcharXhvkVpVz)).

## Qué es

La Semilla es el **encuentro 22**, el último de la campaña: va después del guardián del cielo (cualquiera de los tres). El rival es el número de la semilla de la jugada.

## Reglas (motor)

| Tema | Regla | Dónde |
| --- | --- | --- |
| Lugar | El nivel 7 tiene cuatro encuentros: rival 1, rival 2, guardián y La Semilla (`kind: "seed"`, id `la_semilla`). Los niveles 1 a 6 no cambian. | `Campaign.encounters(level, chosen, last)` |
| Objetivo | Objetivo del guardián × 1,5, redondeado una sola vez (0,5 hacia arriba). Dato provisional (D07/D11). | `Campaign.SEED_TARGET_MULTIPLIER`, `seed_target()` |
| Manos y tiradas | Las de siempre: 2 manos, 3 tiradas, 5 dados. | — |
| Poder | **Uno solo** durante todo el encuentro, sorteado entre los poderes de los jefes que tocaron en la jugada (los siete, guardián incluido). El generador sale de `semilla + "la_semilla"`: no toca el azar de la jugada, da siempre lo mismo para la misma semilla y no se vuelve a sortear al cargar. | `Campaign.seed_rule()`, `Game._advance_encounter()` |
| Poder en juego | La Semilla cuenta como jefe (`is_boss()`): su poder entra por el mismo contexto que el de cualquier jefe, así que la previsión coincide con la anotación. `is_seed()` la distingue. | `BossRules.has_power()` |
| Derrota | Se pierde la jugada, como con cualquier jefe. | — |
| Victoria | Fase `won` con los 22 encuentros superados. | `Game.close_encounter()` |

### La mano con el maletín

Vencido el guardián, la tienda de esa visita es la mano con el maletín (`Game.is_seed_shop_visit()`):

- Muestra **un solo ítem por sección** (el primero de cada una) y los cuatro son **regalo**: se cobran $0 (`shop_gifts`, ids de oferta). El precio guardado en la oferta no cambia.
- No hay renovación por sección. Hay un **restock** completo (`restock_seed_shop()`): cuesta siempre **$5** (`Campaign.SEED_SHOP_RESTOCK_PRICE`, sin descuentos ni renovaciones gratis de monedas), trae otra tanda de un ítem por sección y **lo nuevo ya no es gratis**. Desde el 25/11/2026 son cinco secciones (se sumó la moneda de un uso), así que la mano regala cinco ítems.
- «Seguir sin tienda» también lleva a La Semilla (sin regalos).

## Semilla elegida

Una jugada que no empieza con una semilla nueva al azar (hoy: «Reintentar misma semilla» al perder) queda marcada (`Game.seeded`) y al terminar **no suma nada** a la partida guardada: ni jugadas, ni victorias, ni nivel, ni logros, ni monedas. La marca viaja en el guardado de «Continuar partida».

El menú todavía no tiene un campo para ingresar una semilla a mano (quedó sin confirmar).

## Presentación

| Momento | Qué se ve | Dónde |
| --- | --- | --- |
| Toda la jugada | La semilla chica arriba a la izquierda, sobre la libreta, con la letra de 5×7 del juego, tenue pero legible (`SEMILLA 2847193650`). No sale en el tutorial ni en la tienda. | `seed_display.gd` («small») |
| Vence al guardián | El guardián **no muere todavía** y el bar **no se agrieta**: aparece el cobro «GUARDIÁN VENCIDO». | etapa `beaten` |
| Mano con el maletín | El bar intacto, con el guardián todavía en el cielo. | etapa `beaten` |
| Deja la mano | **A1**: muere el guardián. Tiembla, le crecen grietas de luz, destella y se parte en 24 pedazos que vuelan y caen; salen rayos blancos semitransparentes desde adentro. Enseguida, **B1**: grietas desde el techo, bloques de madera y revoque que caen y levantan polvo al llegar a la mesa, el negro baja de arriba hacia abajo y asoma la Matrix. La luz se escapa por donde estaba el guardián. | `seed_finale.gd` (`death`, después `collapse`) |
| La Semilla | **C2 + C3**: la semilla chica viaja al centro mientras crece y cada número gira hasta fijarse; espera y sube a su lugar arriba. Terminal verde con esquinas marcadas, cursor que parpadea, fallas de imagen y, cada tanto, un número que se «bugea» un cuadro. Fondo negro con columnas de letras (sobre todo números y latinas, algo de katakana y armenias) que suben y bajan; quedan la mesa, el termo, el mate y el vaso. Tocar la semilla muestra su poder. | `seed_display.gd` («terminal»), etapa `matrix` |
| Gana | **Sin cartel.** Tiembla todo, la mesa se parte en seis franjas que caen (con la libreta, los botones, el mate, el termo y el vaso), la Matrix deja de correr (cada columna se queda sin letras, como si se terminara la línea de código) y los números de la semilla se apagan parpadeando. Esta animación **no se puede omitir**. Solos aparecen los créditos provisionales; con «Continuar» o a los 8 segundos, las **recompensas** (todavía sin definir) y de ahí la vuelta al inicio. Sin movimiento, directo a los créditos. | `seed_finale.gd` (`ending`), `main.gd` (`render_credits`, `render_rewards`) |

- Mientras corre una animación la mesa no se puede tocar. **La primera vez se ve entera**; desde la segunda aparece «Omitir animación». La marca se guarda en la partida guardada (`seed_finale_seen`, clave opcional que no cambia la versión; sin partida, vale para la sesión).
- Sin movimiento (o velocidad 0) no hay animaciones: se pasa directo a cada estado quieto.
- La muerte del guardián (decisión del autor del 24/11) pasa al salir de la tienda, no al vencerlo. Al volver con «Continuar partida» a la mano con el maletín, el guardián sigue vivo y muere al salir.
- Sin sonido todavía (D10).
- Todo el azar de la presentación es visual: sale de la semilla y del tiempo, nunca del azar de la jugada.

## Arte

Generado por código (`py -3.13 tools/art/make_semilla.py`) en `assets/art/pixel-v3/semilla/`: `glifos-v1.png`, `escombros-v1.png` y `guardianes-muerte-v1.png` (los guardianes se toman sin tocar su dibujo). Ver `ART-PROMPTS.md`.

## Guardado

- Versión 10 de `SaveStore` (migración `seed_v10`): suma `shop_gifts` y `seeded` y, si la jugada está en el nivel 7 con tres encuentros, agrega La Semilla. Idempotente; no toca semilla, azar, plata, inventario ni ofertas.
- El validador acepta `kind: "seed"` solo como cuarto y último encuentro, exige que el poder sea el sorteado y rechaza regalos fuera de la mano con el maletín.

## Pruebas

`tests/la_semilla_tests.gd` (reglas, guardado, interfaz) y revisión visual `tests/la_semilla_review.gd` (con GPU) en `test-results/la-semilla/`.

## Pendiente

Premio al ganar, contenido de los créditos, música y efectos (D10), objetivo final (D07/D11), campo para ingresar semilla a mano (sin confirmar) y sesión humana de juego.

**25/11/2026:** si La Semilla sorteó el poder de Don Cebador (`thermos_theft`), solo anula los stickers: el termo no se mueve de la mesa (`Game.thermos_stolen()` es falso en La Semilla). Tras vencer al guardián se entra directo a la mano con el maletín (tienda obligatoria después de cada jefe).
