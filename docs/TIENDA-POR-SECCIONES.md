# Tienda por secciones — contrato del paso 11

Modelo y generador implementados y probados el 26 de octubre de 2026. D01/D02/D04 siguen pendientes para precios, probabilidades y contenido comercial final. Las tablas completas de demostración son exclusivas de tests/shop_tests.gd. La partida normal genera monedas con economía provisional heredada y muestra las demás secciones sin ofertas hasta configurarlas.

## Stock identificado y distribución

| Sección | Espacios | Contenido permitido |
|---|---|---|
| coins | 4 | Monedas pasivas o de un uso, mezcladas sin cupo por tipo |
| components | 2 | Material, carcasa o elemento en cualquiera de los dos |
| numbers | 2 | Mejora global, local o cambio de cara, sin cupos por subtipo |
| stickers | 2 | Un individual y un paquete |
| cup | 0 | Lugar reservado, sin oferta ni renovación |

Game.shop_state es el stock autoritativo. Cada sección guarda slots y configured; una oferta tiene offer_id único por partida, kind, price y effect con datos concretos. Las ofertas numéricas incluyen rarity. El vacío es un diccionario vacío. shop_offer_sequence conserva IDs entre visitas y se reinicia al comenzar partida nueva. offers queda como vista de IDs de monedas para compatibilidad con fixtures; no representa un segundo stock.

Los paquetes resuelven una vez su tipo e items distintos al generar la oferta, mediante selección sin reemplazo dentro de su pool explícito. Los tipos poseídos siguen siendo elegibles. Renderizar, inspeccionar o cambiar de pestaña no cambia contenidos ni consume azar.

## Tablas y generación

Shop.default_tables contiene las ocho monedas actuales con pesos unitarios y precios provisionales; no fuerza una pasiva y un consumible. Las pasivas ya equipadas se excluyen y cada pasiva aparece como máximo una vez entre las ofertas. Los consumibles sí pueden repetirse. Si se agotan las pasivas elegibles y no hay consumibles en la tabla, los espacios restantes quedan vacíos. Esta política aplica la decisión del usuario del 30/10/2026.

Las otras secciones empiezan con tablas vacías, sin inventar precios ni pesos. Una tabla vacía deja slots vacíos y configured=false; renovar una sección así no cobra. Las tablas explícitas usan candidatos con kind, price, weight y effect. Se validan precios enteros no negativos, pesos positivos finitos y datos de cada familia. Carcasas requieren intact=true; números y magnitudes respetan sus contratos; stickers individuales respetan el precio configurado por tipo; packs necesitan suficientes tipos distintos definidos.

numeric_rarity_weights separa los pesos base de rareza del peso de cada candidato dentro de esa rareza. El generador no recibe nivel/rival: esas probabilidades no cambian automáticamente entre encuentros. Esta restricción no se extiende a componentes u otras familias. Los rangos locales, precios y pesos de las pruebas no son balance aprobado.

Shop.generate usa un generador temporal a partir de rng_state y devuelve sección, estado aleatorio y secuencia nuevos. Una configuración inválida no modifica el juego. La generación inicial prepara todas las secciones antes de confirmar estado, fase o RNG; incluso un error en una sección posterior conserva los sorteos anteriores sin aplicarlos.

## Visitas, renovación y compras

open_shop solo funciona desde reward y guarda las ofertas generadas. La generación inicial no puede usarse de nuevo para renovar gratis. refresh_shop(section) valida fase, sección, saldo y tabla antes de cobrar; cambia todos los slots de esa sección, incluidos vacíos, y conserva las otras secciones y el inventario comprado.

reroll_prices contiene un contador por sección: 1, 2, 3… Renovar aumenta únicamente el contador de esa sección. Cambiar pestaña o comprar no lo incrementa. Abrir una nueva visita reinicia los cuatro a 1. No hay renovación global ni del vaso. Saldo insuficiente o tabla inválida conserva dinero, ofertas, secuencia y RNG.

La compra normal de monedas consume únicamente su slot identificado. El botón conserva expected_offer_id, de modo que una confirmación vieja no compra otra oferta después de renovar. commit_shop_offer(section, id) es la frontera interna de stock para una compra ya validada: solo vacía el slot, sin cobrar ni aplicar efectos por sí misma. Desde el paso 12, las ofertas configuradas de todas las familias usan transacciones y selección de objetivos. Ver [compras y objetivos](COMPRAS-Y-OBJETIVOS.md). Los datos comerciales finales continúan pendientes.

## Interfaz y persistencia

Desde el paso 13, la tienda muestra simultáneamente las cinco zonas acordadas: monedas arriba izquierda, componentes arriba derecha, vaso reservado abajo izquierda, números/caras abajo centro y stickers abajo derecha; el costo propio de cada sección aparece al pasar el mouse sobre su flecha de renovación. Los espacios comprados muestran vendido. Los demás contenidos solo aparecen al cargar tablas explícitas de prueba. El vaso mantiene su reserva sin controles de compra.

snapshot incluye shop_tables, shop_state, shop_offer_sequence, reroll_prices y RNG, con copias profundas. La configuración sobrevive entre visitas; el stock se limpia al comenzar otro rival. La nueva partida vuelve a tablas provisionales iniciales y secuencia cero. El guardado/restauración en disco pertenece al 15.

## Evidencia y límites

Al cierre del paso 11: **848 comprobaciones aprobadas, cero fallos:** 795 anteriores y 53 nuevas. tests/shop_tests.gd verifica distribución, IDs, contenido de packs, cuatro monedas iguales por tipo, rareza numérica independiente de rival, aislamiento entre secciones, stock vacío/refill, compras reales de monedas, costo compartido, visitas, reproducibilidad, tablas inválidas, insuficiencia de saldo y confirmaciones obsoletas. tests/run_tests.gd comprueba pestañas, renovación seleccionada y renderizado sin azar. Informe shop_demo en test-results/tests.json; para repetir: Probar.cmd.

Capturas revisadas: test-results/tienda-monedas-cuatro.png, tienda-componentes.png, tienda-numeros.png y tienda-stickers.png. Implementación: scripts/shop.gd, scripts/game.gd y scripts/main.gd. Fixtures históricos ahora usan una vista de cuatro slots y fuerzan el consumible cuando prueban su ranura; no se conserva el antiguo cupo garantizado de dos ofertas.

No se habilitan compras de dados, vaso ni valores comerciales finales. Siguiente paso: 12, aplicación transaccional y selección de objetivos con ofertas almacenadas; D01/D02/D04 permanecen visibles.
