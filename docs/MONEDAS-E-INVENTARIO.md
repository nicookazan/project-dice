# Monedas iniciales e inventario — contrato del paso 10

Implementado y probado el 26 de octubre de 2026. Se conservan las ocho monedas existentes; D03 permanece pendiente para monedas nuevas, activas, rarezas, habilitadoras de duplicados y economía futura. No se introducen poderes nuevos.

## Definiciones e instancias

Coins.catalog y definition devuelven copias con id, code, name, type, scope, trigger, duration, effect, amount, price, resale, description y use_contexts. Los IDs usados por la demo y el arte se mantienen: full, straight, generala, poker, even, odd, boost y roll. Los códigos de diseño correspondientes son C01–C06 y U01–U02.

| Código | Efecto | Duración/alcance |
|---|---|---|
| C01–C04 | +1 al multiplicador de full/escalera/generala/póker | Su categoría mientras está equipada |
| C05–C06 | +2 puntos por cara par/impar | Puntos propios, incluidos sobrantes |
| U01 | +3 por cara 1 o 3 | Resto del encuentro, incluida otra mano |
| U02 | +1 oportunidad de tirar | Solo la mano actual |

La paridad usa el número visible, sin confundirlo con sus puntos mejorados. Esmeralda duplica los aportes propios aplicables; los incrementos de categoría suman antes de rubí. Rules consulta magnitudes del catálogo y conserva las fuentes del desglose.

coin_inventory es el estado autoritativo: equipped y consumables son listas de instancias con instance_id, coin_id y state independiente. shared_capacity inicia en 5 para el espacio compartido por pasivas/activas; consumable_capacity inicia en 1. No hay activas en el catálogo actual. No se comparten diccionarios de estado entre ejemplares ni se incrustan definiciones mutables en las instancias.

coin_instance_sequence asigna identidad a cada adquisición sin recrear los ejemplares existentes. passives y consumable siguen como vistas de IDs compatibles con puntuación, interfaz y fixtures. Asignarlas explícitamente construye instancias; modificar una copia de passives no cambia el inventario. Las operaciones de juego trabajan sobre coin_inventory.

snapshot conserva inventario y secuencia mediante copia profunda, además de las vistas antiguas. El futuro guardado debe restaurar el inventario autoritativo; no reconstruirlo después desde las vistas. Los ejemplares se conservan entre manos/rivales y nueva partida limpia inventario, secuencia y boost.

## Contextos y transacciones

Coins.can_use consulta use_contexts por definición. U01 y U02 solo admiten play, antes de anotar, incluso antes de tirar o con el presupuesto agotado. Usarlas no consume una mano, una tirada ni azar. La instancia se retira una sola vez; un segundo clic no produce efectos. Tienda, elección de pack, reparación, resultado de mano, victoria y derrota rechazan su uso sin consumo.

U01 afecta grupos bloqueados y sobrantes sin alterar caras, miembros ni manos históricas. Persiste durante la segunda mano y termina al cerrar el encuentro o perder. U02 antes de la primera tirada deja cuatro oportunidades; otra mano vuelve a tres. Las monedas gastadas no reaparecen.

Coins.can_store valida tipo, capacidad y ausencia de duplicados equipados. Comprar exige tienda, oferta conocida no vacía, saldo y espacio antes de cobrar o crear una instancia; no desplaza objetos automáticamente. Una ranura de un uso ocupada impide guardar otra moneda. Una compra vacía su oferta y no puede repetirse. Vender retira solo el ejemplar indicado y paga una vez. La venta por tipo es inequívoca mientras los duplicados sigan prohibidos.

Precios iniciales heredados 4/2, reventa 2/1 y selección uniforme por tipo conservan carácter provisional. La tienda usa definiciones y validación de capacidad/contexto; el generador conserva la exclusión de pasivas poseídas hasta que exista habilitadora. Ninguna moneda desconocida se interpreta como una tirada extra.

## Evidencia y límites

Al cierre del paso 10: **795 comprobaciones aprobadas, cero fallos:** 722 anteriores y 73 nuevas. tests/coin_tests.gd cubre catálogo, aislamiento de definiciones/instancias, snapshots, identidad, capacidad, duplicados, dinero, compras/ventas únicas, ocho efectos, paridad mejorada, U01 bloqueado e histórico, duraciones y ventanas de uso. tests/run_tests.gd comprueba inspección, compra con espacio disponible y uso inicial desde la interfaz real. Informe coins_demo en test-results/tests.json; para repetir: Probar.cmd.

Capturas revisadas: test-results/monedas-inventario.png, moneda-inspeccion.png y monedas-limites-tienda.png. Implementación en scripts/coins.gd, scripts/game.gd, scripts/rules.gd y scripts/main.gd. Capturas mediante tests/visual_review.gd.

No se implementan cooldowns, rescates, duplicados habilitados ni recompensas permanentes. D03 conserva el catálogo futuro. La tienda por secciones se incorporó en 11, con cuatro ofertas de monedas mixtas sin garantizar una de cada tipo. Sus datos comerciales mantienen D01/D02/D04 pendientes. Ver [contrato](TIENDA-POR-SECCIONES.md).

## Actualización: arquitectura data-driven (primera tanda de monedas nuevas)

El catálogo ya no se limita a ocho monedas. `Coins.DATA` (scripts/coins.gd) tiene 51 pasivas (C01–C51) y 8 de un uso (U01–U08); cada fila declara `code`, `name`, `description`, `rarity`, `family` y una lista `effects`. `scripts/coin_effects.gd` (puro, sin estado ni azar) evalúa esos efectos: `category_mult`, `category_points`, `die_points_if`, `die_mult_if`, `flat_group_mult`, `cond_mult`, `scaled_mult`, `state_mult`, `hand_points`, `rule`, `slots`, `credit`, `discount`, `free_renewals`, `extra_rolls`, `gem` y los de un uso. Precio y reventa se derivan de la rareza (pasivas 4/6/9/14 con reventa 2/3/4/7; un uso 2/3/5 con reventa 1/1/2) salvo que la fila los fije (C19: 10/1). **Sumar una moneda es escribir una fila.**

- `Rules.score(..., boss_context, coin_context)`: el contexto (`hand`, `rolls_made`, `rolls_left`, `cash`, `equipped_count`, `sticker_total`, `states`, `double_mult`) lo arma `Game.coin_context()` y lo comparten previsión y anotación. Sin contexto el resultado es el de siempre.
- Instancias: `Coins.instance` siembra `state` con `Coins.initial_state` (C18: `strength` 40 y `grace`; C48–C51: contadores en 0). El validador exige la misma forma de `state`.
- Capacidad calculada: `Coins.capacity` (5 + bonos de C43; 1 + bonos de C44). `shared_capacity` y `consumable_capacity` se guardan pero el validador exige que coincidan con el cálculo. No se vende una moneda de ranura si sobrarían monedas.
- Las monedas de un uso admiten más de una ranura (C44); la interfaz dibuja todas.
- Ventanas de uso: `play` (U01–U05, U08), `shop` (U06), `repair` (U07).
- Arte provisional: las monedas fuera del atlas de ocho se dibujan como moneda tintada por rareza con su abreviatura (`Coins.SHORT`).

## Etapa de monedas (noviembre de 2026)

Catálogo vigente: 75 monedas, 57 pasivas (C01–C57) y 18 de un uso (U01–U18). Todo vive en filas de `scripts/coins.gd`; el detalle de cada paso está en [MONEDAS-NUEVAS.md](MONEDAS-NUEVAS.md).
- Ventanas de uso nuevas: `play` también para U09–U15 y U18; `shop` para U16; `repair` para U17.
- Fila con `once_per_run` (U14): aparece una sola vez por partida (`once_coins_seen`). Moneda de un uso que pide un dado (U12): `Coins.targeted`.
- Paquete de monedas: `Coins.can_replace` decide los reemplazos al elegir del paquete; la que sale paga su reventa.
- Duraciones nuevas en la ficha de moneda: "Inmediata" (U15) y "Visita actual a la tienda" (U16).
- Suspensión por jefe: una moneda suspendida no da manos, tiradas ni plata; el Escudo de jefe (U14) las devuelve durante la mano protegida.
