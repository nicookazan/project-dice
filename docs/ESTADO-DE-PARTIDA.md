# Estado de partida y dados — contrato del paso 01

Implementado el 25 de octubre de 2026 y ampliado hasta 15. El estado se conserva en memoria y se persiste/restaura mediante el [contrato versionado v1](GUARDADO-Y-CONTINUAR.md), incluyendo decisiones de reparación/pack, guardas y RNG int64 exactos. La suite actual tiene 1083 comprobaciones aprobadas.

Ampliación del paso 02: snapshot incluye events y event_sequence; el registro se vacía por encuentro y su secuencia se reinicia por partida. El cálculo devuelve validación y desglose por dado/grupo. Ver [PUNTUACION-Y-EVENTOS.md](PUNTUACION-Y-EVENTOS.md).

Ampliación del paso 03: las mejoras numéricas globales/locales ya se aplican a los puntos del número obtenido y existen operaciones para acumularlas y cambiar una cara. La venta se conecta en 11–12. Ver [MEJORAS-NUMERICAS.md](MEJORAS-NUMERICAS.md).

Ampliación del paso 04: encounter_effects.steel_points y copper_multiplier ya tienen efecto. Los relanzamientos actualizan sus ganancias y el siguiente rival las reinicia; la tirada inicial de otra mano las conserva. Ver [METALES.md](METALES.md).

Ampliación del paso 05: element activa fuego/agua/electricidad durante el cálculo puro, sin contadores ni consumo. Persiste durante la partida. Ver [ELEMENTOS-CONDICIONALES.md](ELEMENTOS-CONDICIONALES.md).

Ampliación del paso 06: hand_effects.earth_points y wind_multiplier acumulan durante relanzamientos efectivos. Se borran cada mano mientras acero/cobre conservan su duración de encuentro. Ver [ELEMENTOS-DE-MANO.md](ELEMENTOS-DE-MANO.md).

Ampliación del paso 07: shell activa los cuatro poderes de gemas durante el cálculo; shell_broken suspende solo su poder. Desde el paso 08 se sortean después de acreditar la mano. Ver [GEMAS.md](GEMAS.md).

Ampliación del paso 08: snapshot incluye breakage_by_hand y repair_resolution para no repetir riesgo/cobro/reparación. La fase repair ocurre tras cobrar y antes de reward/won. Ver [ROTURA-Y-REPARACION.md](ROTURA-Y-REPARACION.md).

Ampliación del paso 09: cup.stickers guarda niveles; sticker_catalog conserva datos explícitos o null para balance pendiente. Snapshot incluye sticker_offers, sticker_offer_sequence y pending_sticker_pack. La elección pagada usa fase sticker_choice y bloquea salir de tienda hasta resolverla. Ver [STICKERS-Y-PAQUETES.md](STICKERS-Y-PAQUETES.md).

Ampliación del paso 10: coin_inventory y coin_instance_sequence son datos autoritativos de ejemplares. passives/consumable conservan vistas de IDs; snapshot copia instancias y estado. Ver [MONEDAS-E-INVENTARIO.md](MONEDAS-E-INVENTARIO.md).

Ampliación del paso 11: shop_state guarda slots identificados por sección; shop_tables y shop_offer_sequence forman parte del snapshot junto a RNG y costo compartido. offers es una vista de IDs de monedas para fixtures. Ver [TIENDA-POR-SECCIONES.md](TIENDA-POR-SECCIONES.md).

Ampliación del paso 12: pending_purchase conserva oferta capturada y objetivo; purchase_receipts y last_purchase_result registran commits. purchase_target bloquea acciones ajenas. Los packs de stock real usan pending_sticker_pack con origen shop. Ver [COMPRAS-Y-OBJETIVOS.md](COMPRAS-Y-OBJETIVOS.md).

## Identidad y propiedad de los datos

Game crea exactamente cinco dados al iniciar una partida mediante DiceState.create_dice(). Cada dado tiene un ID entero de 0 a 4, igual a su posición fija en el arreglo. Durante esa partida no se eliminan, reemplazan ni reordenan los dados. Los grupos y los controles existentes siguen usando ese ID/posición.

Los constructores crean arreglos y diccionarios nuevos para cada dado y partida. No se comparten caras, mejoras, contadores, stickers ni mapas globales entre dados o partidas.

## Datos de cada dado

| Campo | Significado | Duración |
|---|---|---|
| id | Identidad estable, 0–4 | Partida |
| faces | Seis posiciones de cara, iniciales 1–6 | Partida |
| material | Material inicial "basic" | Partida |
| shell | Carcasa; vacío si no hay | Partida |
| shell_broken | Estado resquebrajado de la carcasa | Partida |
| element | Elemento; vacío si no hay | Partida |
| encounter_effects | Acumulaciones de encuentro por origen; vacío al empezar rival | Encuentro |
| hand_effects | Acumulaciones de mano por origen; vacío al empezar mano | Mano |
| face_index | Posición sorteada de 0 a 5; −1 antes de lanzar | Mano |
| value | Número de la cara obtenida; 0 antes de lanzar | Mano |
| zone | "cup" o "reserve"; pertenencia a grupo en Game.groups | Mano |

Los poderes utilizan campos propios dentro de encounter_effects o hand_effects. El paso 04 ya aplica steel_points y copper_multiplier por encuentro; desde el paso 06 también aplica earth_points y wind_multiplier de mano. En el cierre original del paso 01 estos campos solo se almacenaban.

El lanzamiento sortea una posición de cara y obtiene value de faces[face_index]. Con caras básicas conserva los resultados y consumo de RNG de la demo anterior. Las operaciones de cambio de cara y la puntuación de mejoras numéricas están implementadas desde el paso 03; las compras se conectan en 11–12.

## Datos de partida

- global_points: mapa por número, con claves de texto, independiente de los dados.
- cup: material inicial "leather" y mapa stickers vacío. No se duplica por dado ni por cara.
- cash conserva la plata; coin_inventory guarda instancias equipadas/de un uso, con capacidad 5/1. passives y consumable son vistas de compatibilidad del inventario, no un segundo estado.
- run_seed y el estado del generador determinan la secuencia de azar.

Los grupos contienen IDs de los mismos cinco dados. La selección visual permanece en main.gd y se limpia con las acciones de interfaz existentes; no es un segundo inventario.

## Reinicios

| Operación | Qué se reinicia | Qué se conserva |
|---|---|---|
| start_hand | Grupos, resultados, posición de cara, zonas, contadores de mano y presupuesto de tres tiradas | Dados e IDs, caras, mejoras, componentes, roturas, acumulaciones de encuentro, plata e inventario |
| _start_encounter, al salir de tienda | Puntos, mano a 1, boost, historial, último cálculo, cobro/ofertas anteriores, precio de renovación, contadores de encuentro; después comienza la mano | Los mismos cinco dados, atributos de partida, mejoras globales, vaso, plata y monedas |
| restart | Toda la partida, con cinco dados nuevos básicos y estado inicial | Solo la semilla indicada si se solicita reintentar |

Una carcasa rota nunca reduce la cantidad de dados. La nueva mano conserva la referencia al mismo dado; una nueva partida crea datos completamente independientes, incluso de referencias antiguas.

## Copia de estado en memoria

Game.snapshot() devuelve un diccionario separado mediante copia profunda. Incluye progreso, dados, grupos, mejoras, vaso, inventario, ofertas, historial, cobro, mensaje y los enteros run_seed/rng_state. No incluye nodos de interfaz ni el objeto RNG.

Consultar o modificar la copia no altera el juego ni consume números aleatorios. La previsión sigue usando el mismo cálculo de la demo y no modifica esos datos.

Para el paso 15: mantener enteros del RNG con precisión exacta al codificar; validar IDs y referencias al cargar; definir versión, ubicación, escritura y recuperación antes de implementar archivos. El snapshot no constituye todavía un contrato de archivo ni ofrece restore.

## Constructor de estados de prueba

tests/support/game_fixture.gd crea resultados controlados y aplica cinco valores a los dados existentes sin reemplazarlos. No se carga desde el juego normal. Los ejemplos históricos de tres, cuatro u ocho dados se limitan a Rules.score, sin cambiar el conjunto de una partida.

La demostración de tests/state_tests.gd recorre dos manos reales, cobro, tienda y siguiente rival:

1. Modifica la segunda cara del dado 0 a 4 y registra mejoras/componentes que se activan según los pasos implementados.
2. Primera mano: trío de seises + par de doses, más +6 de acero y +5 de fuego = 48.
3. Segunda mano con los mismos dados: generala no servida de seises, más +6 de acero y +5 de fuego = 91; acumulado 139.
4. Entra a otro rival: conserva caras, mejoras, carcasa rota, material y elemento; reinicia acumulaciones temporales.

La evidencia está en state_demo dentro de test-results/tests.json. En el cierre del paso 01 se aprobaron 173 comprobaciones. Al cierre del paso 04 ese fixture acreditaba 43 y 86 (129) por el acero. Desde el paso 05 acredita 48 y 91 (139), al activarse también el fuego almacenado; la suite completa tiene 978 comprobaciones aprobadas tras el paso 14. El menú y anuncio inicial son fases explícitas de sesión; el recorrido se consulta sin modificar el estado. Las fichas y la previsión de selección leen este estado sin modificarlo. El sticker del fixture usa datos neutros explícitos, sin convertirlos en balance. El fixture declina la reparación de su carcasa previamente rota antes de ir a tienda.
