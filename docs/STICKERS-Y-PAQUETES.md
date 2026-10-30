> Actualización del 28/10/2026: siempre mate con termo; stickers sobre el termo; exteriores ilustrados según el PRD; gemas brillantes. Sustituye las referencias históricas a cerveza, stickers en vaso y puntos opacos. Ver docs/CAMBIOS-VISUALES-2026-10-28.md.

# Stickers y paquetes — contrato del paso 09

Motor implementado y probado el 26 de octubre de 2026. D02 sigue pendiente para incrementos, precios, probabilidades y posible sticker de doble par. Este paso usa datos explícitos de prueba; no habilita nuevas ofertas en la tienda normal. Generación comercial en 11, conexión de compras en 12 y elección visual de paquetes en 13.

## Propiedad, catálogo y cálculo

cup.stickers contiene un único nivel entero positivo por tipo. La primera adquisición crea nivel 1 y cada adquisición posterior incrementa el mismo registro, sin un límite de diseño ni otro espacio de inventario. Los niveles duran la partida y se conservan entre manos y rivales.

| Tipo | Categorías |
|---|---|
| pair_loose | Par y Sin combinación |
| trio | Trío |
| straight | Escalera |
| full | Full |
| poker | Póker |
| generala | Generala |

Doble par mantiene base 15 y no recibe el tipo compartido. No se inventa un sticker ni bono de servida. No se agregan nuevos bonos de categorías repetidas que requieran más de cinco dados.

Game.sticker_catalog separa por tipo points_per_level, multiplier_per_level y price. El evaluador multiplica los incrementos explícitos por el nivel; cada categoría puede tener magnitudes distintas. El catálogo de inicio usa null para los valores pendientes: Stickers.missing los identifica, no los convierte en cero ni en ×2. Los fixtures son exclusivos de tests/sticker_tests.gd. Un nivel poseído con datos ausentes/inválidos hace inválido el cálculo; no se ignora silenciosamente. El fixture histórico de persistencia usa un catálogo neutro explícito para conservar su demostración de 48 + 91.

El aporte de puntos pertenece al grupo, después de los puntos propios y antes del multiplicador. Esmeralda no duplica este aporte de categoría. El incremento de multiplicador suma con cobre, viento, zafiro y monedas antes de rubí; diamante copia el resultado final. La base de categoría y servida conservan sus reglas. La previsión es pura, conserva decimales y se redondea una vez al final. La libreta muestra sticker, nivel, puntos y origen del multiplicador.

## Ofertas y operaciones internas

Stickers.offer valida single (un tipo), choose_one (tres tipos distintos) y receive_two (dos tipos distintos). Los contenidos y precio llegan explícitos desde el futuro generador; aquí no se inventan probabilidades ni se sortean nuevas ofertas. Los tipos poseídos siguen siendo elegibles. Un individual exige el precio base del tipo y no lo encarece por nivel.

Game.register_sticker_offer registra contenidos ya definidos solo en tienda y devuelve un ID único por partida. No es un botón de subir nivel: cada oferta se consume una sola vez. inspect_sticker_offer devuelve una copia con tipo, opciones, precio y recibo de compra antes de cobrar. buy_sticker_offer valida todo antes de descontar, exige saldo suficiente y protege contra doble clic.

- single aplica una mejora al tipo ofrecido.
- receive_two aplica una mejora a cada tipo distinto, de forma atómica.
- choose_one cobra una sola vez y entra en phase="sticker_choice", sin aplicar candidatos todavía. pending_sticker_pack guarda offer_id, kind, items y paid. choose_sticker aplica exclusivamente el elegido, registra selected en el recibo y vuelve a tienda. Las otras dos opciones no se aplican.

Mientras hay elección pendiente se bloquean nuevas compras, renovación y salida de tienda. Consultar/reabrir la oferta no cobra, no cambia opciones ni consume azar. Una elección inválida o repetida no aplica nada. Los snapshots separan niveles, catálogo, ofertas, secuencia y elección pendiente para el futuro guardado; no se implementa restauración en disco. Otro rival limpia ofertas anteriores y conserva niveles; nueva partida reinicia todo.

## Evidencia y límites

**722 comprobaciones aprobadas, cero fallos:** 666 anteriores y 56 nuevas. tests/sticker_tests.gd verifica balance ausente/inválido, niveles, precios constantes, categorías, compartido, doble par excluido, composición, redondeo, pureza, adquisiciones únicas, ambos paquetes, candidatos poseídos, descartados, duplicados, saldo insuficiente y copias de estado. tests/run_tests.gd comprueba la libreta real. Informe: stickers_demo en test-results/tests.json; para repetir: Probar.cmd.

Ejemplo exclusivo de prueba: trío nivel 2 con +3 puntos y +0,5 al multiplicador por nivel da (10+18+6)×2 = 68; un par ajeno conserva 9; mano 77. Otro fixture combina sticker, cobre, viento y rubí: 17×(1+0,5+1+0,5)×1,5 = 76,5. Ninguno de estos incrementos o precios constituye balance aprobado.

Capturas revisadas: test-results/stickers-categorias.png y sticker-desglose.png, mediante tests/visual_review.gd. Implementación en scripts/stickers.gd, scripts/game.gd, scripts/rules.gd y scripts/main.gd. Desde el paso 12, los paquetes se integran al stock real y al panel provisional de elección con cierre/reapertura; la integración visual completa conserva el 13 y los datos comerciales normales siguen pendientes.

