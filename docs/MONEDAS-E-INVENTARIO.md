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
