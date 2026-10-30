# Tienda: integración artística de la referencia

## Venta por arrastre y balanceo más marcado — 30/10/2026

Las monedas propias del inventario inferior se pueden arrastrar. Mientras se sostiene una, aparece una capa bordó transparente sobre los cuatro compartimentos del maletín, con «Vender: $2» para pasivas o «Vender: $1» para consumibles. El objeto que se lleva queda por encima de esa capa. Se retiraron los botones de venta que estaban debajo de cada moneda; pulsar la moneda conserva su inspección.

Soltar sobre la capa vende únicamente esa instancia y acredita su reventa real una sola vez. Soltar en el lugar original o fuera del maletín cancela el arrastre y restaura la moneda sin cambiar saldo, inventario, ofertas ni RNG. No se pueden vender ofertas ajenas ni vender durante compras pendientes. Los datos del arrastre identifican la instancia; el precio sale del catálogo y no del contenido del gesto.

Dados y monedas comparten `scripts/drag_sway.gd`: rotación más marcada, amortiguación y un pequeño retraso de posición para sentir la inercia al mover el mouse. Reducir movimiento y Sin animación anulan ambos efectos.

Verificación: **2215 comprobaciones, cero fallos**. `tests/coin_drag_tests.gd` cubre devolución, venta única, instancias antiguas, importes reales, contexto y movimiento reducido. `tests/coin_drag_review.gd` realiza arrastres nativos y verifica la capa, retorno al origen, venta de pasiva/consumible y cancelación fuera del maletín a 1440×900 y 1280×800. También se repitió la revisión de arrastre de dados, sin errores.

## Monedas únicas e inventario inferior — 30/10/2026

Las ofertas de monedas pasivas se sortean sin reposición por identidad: una misma moneda no ocupa dos ranuras y las equipadas quedan excluidas. Se eliminan del conjunto todas las entradas del mismo identificador, incluso si las tablas lo repiten con otros pesos. Las monedas de un uso siguen pudiendo repetirse. Si una tabla solo tiene una pasiva elegible, se ofrece una sola vez y los otros espacios quedan vacíos.

Al continuar una partida anterior se limpian los duplicados y las ofertas de pasivas ya equipadas; se conservan la primera oferta válida, el saldo y el RNG. No se sortean reemplazos. Comprar desde un stock histórico duplicado también retira las copias restantes de esa pasiva.

En la tienda, las monedas del jugador y sus controles de venta pasan a la franja azul inferior, a la derecha de los dados. La moneda de un uso tiene su sector a la derecha. El botón de avanzar al siguiente rival/nivel ocupa el antiguo panel de monedas arriba a la derecha. Abandonar queda debajo de ese botón, antes de Menú/Opciones/Recorrido. Se conservan inspección, descripciones y venta exacta.

Pruebas: inventarios únicos en 64 semillas, tabla de una sola pasiva, exclusión de equipadas, repetición permitida de consumibles, compra desde stock viejo, restauración sin cargos ni azar y ubicación de los controles. Revisión visual de inventario lleno, deuda, ofertas y compras a 1440×900 y 1280×800.

## Termo plateado de pie a la izquierda — 30/10/2026

El termo deja la franja azul y se coloca de pie abajo a la izquierda, según el montaje del usuario. Reutiliza la tapa negra, pico rojo y cuerpo plateado del arte de la partida (`mesa-libreta-frontal-v1.png`), con siluetas que excluyen el fondo. El metal limpio se prolonga en la parte que el vaso tapa en la imagen original; el asa se completa sin arrastrar píxeles del mate. Los stickers conservan sus marcas provisionales y sus niveles, ahora en dos columnas sobre el cuerpo del termo.

Los dados siguen en la franja azul. «Abandonar partida» ocupa el espacio liberado a su derecha, antes del botón de continuar. El área de inspección acompaña al termo a su nueva ubicación. Compras, aumentos de nivel y guardado se conservan. Verificación: **2167 comprobaciones, cero fallos**, revisión visual a 1440×900 y 1280×800.

## Dados y termo en la franja azul — 30/10/2026

Los cinco dados del jugador se muestran en la franja azul inferior, entre Abandonar y el termo. Se retiró su antiguo panel de la izquierda. Conservan sus materiales, puntos, inspección y descripción al pasar el mouse.

El termo usa por ahora un placeholder horizontal de cuerpo verde, metal y tapa negra, dibujado con formas pixeladas en `scripts/shop_thermos.gd`. Ocupa el espacio junto a los dados. Se eliminó el botón «Ver termo»: tocar el propio termo abre la ficha.

El dibujo recibe una copia de los stickers reales del jugador cada vez que se actualiza la tienda. Cada categoría tiene una marca provisional y su nivel. Comprar uno lo pega inmediatamente; comprarlo otra vez aumenta el nivel de la misma marca. Admite las seis categorías a la vez y un termo sin stickers no inventa ninguno. El guardado ya conserva esos niveles.

Verificación: **2167 comprobaciones, cero fallos**. Incluye los cinco dados dentro del pie, compra real con aparición inmediata del sticker y actualización al nivel 2. Capturas de termo vacío, compra y seis stickers en `test-results/<resolución>-tienda-hover-*.png`.

## Correcciones de descripciones y costos por zona — 30/10/2026

Los botones sin descripción ya no generan recuadros vacíos. Las ofertas activan la descripción solo sobre la ilustración; el precio y los huecos del compartimento no la activan. Objetos, inventario y flechas de renovación usan un panel fijo a la izquierda (posición lógica 30,400), independiente de dónde entra el mouse. Conserva aparición inmediata, textura bordó, borde rectangular y letra pixelada. El panel ignora el mouse y se oculta al salir o abrir una confirmación.

Cada zona tiene ahora su contador de renovación: empieza en $1 y aumenta únicamente al renovar esa zona. Por ejemplo, componentes $1 → $2 mientras monedas, números y stickers continúan en $1. La nueva visita reinicia los cuatro contadores. Se guardan y restauran por separado.

Formato de guardado v4: migra v1–v3 sin cambiar plata, inventario, ofertas ni RNG. Los guardados históricos no registraban qué zona se había renovado; al migrarlos, los cuatro nuevos contadores comienzan en $1. El archivo anterior se conserva como respaldo al guardar.

Verificación: **2164 comprobaciones, cero fallos**. Incluye renovación independiente, recarga exacta, migración v3 y rechazo de descripciones vacías. Revisión con mouse sobre menú sin texto, objeto, precio, hueco y retry; posición fija comprobada a 1440×900 y 1280×800.

## Descripción instantánea y marco rectangular — 30/10/2026

Se eliminó la espera de los tooltips (`gui/timers/tooltip_delay_sec=0.0`). Aparecen en el siguiente cuadro al entrar con el mouse, sin mantenerlo quieto durante un temporizador.

El recuadro conserva la textura bordó del interior del maletín, pero la toma de una región limpia. `scripts/tooltip_frame.gd` dibuja un marco dorado rectangular independiente: no incluye el canto negro ni los bordes en perspectiva del recurso original. Se conserva la tipografía pixelada y el ajuste del texto.

La revisión visual captura ahora directamente después de los cuadros de procesamiento y dibujo, sin la espera de 1.3 segundos anterior. Verificada a 1280×800 y 1440×900.

## Renovación junto al nombre de cada zona — 30/10/2026

Los cuatro botones inferiores de renovación se sustituyeron por una flecha circular dorada junto a cada encabezado del maletín. El icono usa trazos escalonados acordes al pixel art; muestra costo y alcance al pasar el mouse. Cada botón conserva la renovación de su propia sección, el costo compartido creciente y el bloqueo cuando no alcanza el saldo o hay una compra pendiente. El encabezado y su flecha quedan centrados como conjunto.

Las comprobaciones de interfaz ahora encuentran cada botón por su zona y verifican el precio en la descripción. Se conserva la regresión de renovación aislada, cobro y actualización del costo compartido.

## Descripciones al pasar el mouse — 30/10/2026

Las ofertas muestran únicamente la ilustración centrada y un precio pulsable. Se quitaron los nombres, el precio duplicado, el texto «Comprar» y los botones de consulta «?». Los efectos, alcance global/local, niveles y riesgos se leen al pasar el mouse por el objeto o su precio, también cuando la compra está deshabilitada.

Las descripciones usan paño bordó y borde dorado extraídos del maletín, texto crema con fuente monoespaciada sin suavizado y salto de línea automático. Godot ubica el recuadro dentro de la pantalla y lo retira al salir. Los dados y las monedas del inventario también muestran sus efectos al pasar el mouse; la ficha detallada sigue disponible.

`scripts/item_tooltip.gd` comparte el estilo entre botones, ofertas y dados. El centrado de los dados ofrecidos ahora considera su escala real. No se generan recursos gráficos nuevos ni se cambian las reglas comerciales.

Validación: **2156 comprobaciones, cero fallos**, incluidas descripción sin cobro/azar, ausencia de «?», precio único y compras conservadas. `tests/shop_hover_review.gd` revisa el mouse real, el precio en deuda y las descripciones a 1440×900 y 1280×800; capturas `test-results/<resolución>-tienda-hover-*.png`.

## Actualización del 30/10/2026: vendedor con maletín

La tienda ahora muestra a un vendedor de traje inspirado en las dos fotos del usuario, con el mismo pixel art del club. Presenta un maletín de cuero negro con interior bordó y herrajes dorados. Sus cuatro compartimentos contienen las ofertas reales de números/caras, componentes, monedas y stickers. Todas entran a la vista; no es necesario alternar capas.

El fondo de la mesa, paño de juego, libreta, vaso y figuras superiores ya no se dibuja en la tienda. Los dados del jugador y sus monedas se consultan en paneles de inventario separados. Se conservan venta, inspección, termo, compras con objetivo, paquetes, renovación por sección y continuación.

Arte: `assets/art/shop-salesman-v1.png`, generado con Imagegen integrada. Prompt y procedencia: `assets/art/shop-salesman-prompts-v1.md`. Se conserva el arte anterior como recurso histórico y fuente de los marcos de interfaz.

Verificación: **2155 comprobaciones, cero fallos**. Revisión visual de ofertas, inventario lleno, deuda, confirmación, paquete, vendido y alto contraste a 1440×900 y 1280×800; sin errores de ejecución. Capturas en `test-results/<resolución>-tienda-estilo-*.png`.

La descripción siguiente documenta la versión anterior.

27 de octubre de 2026. Pedido del usuario: cambiar la tienda ahora para acercarla al estilo artístico de la imagen suministrada. La referencia queda conservada en `docs/referencias/tienda-estilo.png`.

## Cambio integrado

**Dirección posterior del autor:** los dados siguen el [maestro frontal marfil](DISENO-MAESTRO-DADOS.md). Las antiguas carcasas son ahora materiales de los puntos: sus ilustraciones de tienda deben mostrar puntos de gema sobre el mismo cuerpo, no cubos enteros de gema. El atlas isométrico integrado queda como versión histórica pendiente de sustituir; no define el diseño futuro. Este cambio documentado no modifica las transacciones actuales.

La tienda tiene un paño bordó con cuatro sectores bordados en oro: números/caras y componentes arriba, monedas y stickers abajo. Libreta y vaso a la izquierda; inventario, venta e inspección de monedas arriba a la derecha; dinero y capacidad en carteles separados. Cartel grande TIENDA, marcos de pixel art, tipografía monoespaciada sin suavizado, precios destacados y ofertas ilustradas. Confirmación de objetivo y elección de paquetes usan el mismo marco.

Se conserva el club, mate, mano y nube recuperados. Del nuevo fondo se utiliza la mesa desde la altura 278; el sector superior de la imagen nueva no sustituye la mano original. Las ilustraciones no determinan el resultado de dados ni efectos. Una oferta de cambio de cara dibuja dinámicamente el número que se vende, aunque el atlas incluya un dado decorativo.

Los textos y controles son reales: comprar, consultar efecto con ?, seleccionar dado/cara, confirmar/cancelar, elegir paquete, vender y renovar por sección. La descripción completa sigue disponible antes de pagar. El inventario muestra las monedas equipadas; un botón separado vende cada una y otro permite inspeccionarla. Se mantienen cuatro ofertas de monedas, dos de cada otra sección, capacidad fija actual y precios/renovación ya existentes. La imagen de referencia no reintroduce compra de capacidad, cambios de tamaño del conjunto ni renovación global.

## Recursos y procedencia

| Archivo | Procedencia y uso |
|---|---|
| `assets/art/shop-table-v1.png` | Generación integrada con Imagegen, usando la referencia del usuario y el club existente como dirección artística. Mesa de tienda y marcos sin textos ni precios. Se reutilizan regiones para los marcos nativos de Godot. |
| `assets/art/shop-items-v1.png` | Atlas transparente generado con Imagegen a partir de la referencia del usuario; 4×4, materiales, carcasas, elementos, paquetes, stickers y medallón numérico. Alpha conservado. |
| `assets/art/coins-v2.png` | Atlas existente reutilizado; no se modificó. |
| `assets/art/club-table-v2.png` | Club, mate y mano/nube existentes conservados; no se modificó. |
| `assets/art/ivory-die-front-v4.png` | Dados reales del jugador y representación exacta de ofertas de cara. |
| `assets/art/shop-art-prompts-v1.md` | Prompts completos y referencias de las dos generaciones; herramienta integrada, sin CLI/API externa. |

Los nuevos archivos fueron copiados al proyecto desde el directorio de resultados de Imagegen, conservando sus originales. Las ilustraciones se consumen como regiones de textura; no contienen datos comerciales. `scripts/shop_art.gd`, `backdrop.gd` y `main.gd` integran arte y controles.

## Verificación

**2025 comprobaciones, cero fallos**: regresión completa previa más ocho comprobaciones de la tienda nueva. Cubren consulta sin cargo/azar, bloqueo de compras tras la ficha, venta exacta de una moneda, dibujo de cara con número correcto, confirmación de cambio de cara y salida de tienda en deuda.

`tests/shop_style_review.gd` produjo siete capturas por resolución a 1280×800 y 1440×900: ofertas, inventario lleno, deuda, confirmación, paquete, vendido y contraste. Revisadas con renderizado real; sin errores. `test-results/<resolución>-tienda-estilo-*.png`; informe `shop_style_demo` en `test-results/tests.json`.

Los ejemplos visuales usan datos de laboratorio explícitos para mostrar ofertas y estados; no agregan recursos a las partidas normales. La regresión natural mantiene las rutas/semillas previas. Las pruebas seleccionan compras dentro de su sección, ya que el mismo precio puede aparecer en números y monedas.

La tienda ya está implementada y disponible al abrir `Jugar.cmd` y ganar el primer encuentro. Las capturas no equivalen a aprobación artística del autor. Las variantes de jefes, exteriores y Dios siguen pendientes dentro del pase artístico del paso 19.
