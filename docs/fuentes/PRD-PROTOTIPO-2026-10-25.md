> Actualización del 28/10/2026: siempre mate con termo; stickers sobre el termo; exteriores ilustrados según el PRD; gemas brillantes. Sustituye las referencias históricas a cerveza, stickers en vaso y puntos opacos. Ver docs/CAMBIOS-VISUALES-2026-10-28.md.

# Copia de referencia — PRD-PROTOTIPO

Fuente: https://app.notion.com/p/404c28142b5581679265d602cec7e69b?pvs=204
Recuperada el 25 de octubre de 2026. Contenido histórico y vigente mezclado; consultar ../REGLAS-VIGENTES.md para la implementación.

Here is the result of "fetch" for the Page with URL https://app.notion.com/p/404c28142b5581679265d602cec7e69b as of 2026-10-25T20:54:03.722Z:
<page url="https://app.notion.com/p/404c28142b5581679265d602cec7e69b" icon="🧪">
<ancestor-path></ancestor-path>
<properties>
{"title":"PRD-PROTOTIPO"}
</properties>
<iconMetadata>{"type":"emoji","emoji":"🧪"}</iconMetadata>
<content>
<callout icon="🧪" color="blue_bg">
<b>Documento exclusivo del prototipo.</b> Por instrucción del autor, las decisiones, pruebas y valores de este primer prototipo se registran aquí y no se añaden al PRD principal. Esta página documenta el alcance; no indica que exista código implementado.
</callout>

<b>Referencia de reglas y dirección visual:</b> <mention url="https://app.notion.com/p/3fec28142b55815c9f84c21402b73154" />.<br /><b>Convención:</b> CONFIRMADO = indicado por el autor o regla heredada expresamente identificada; PROPUESTA = recomendación para probar, ajustable y sin aprobación implícita.

<table-of-contents />

# 1. Objetivo

Comprobar si tirar, conservar dados, fijar grupos y construir sinergias con pocas monedas resulta claro y entretenido. Primero validar funcionamiento; después ajustar dificultad y economía.<br /><b>CONFIRMADO — motor:</b> Godot. Versión, lenguaje y configuración técnica todavía por elegir al iniciar la implementación.<br /><b>PROPUESTA de presentación:</b> aplicación 2D para PC, control con ratón y la distribución visual ya explorada: libreta al margen izquierdo, grupos a la izquierda de la mesa, reservados al centro y vaso a la derecha. Arte provisional legible; conservar la referencia de club argentino.

# 2. Contenido confirmado

## Nuevas definiciones para la versión hasta Dios: carcasas de vidrio y gemas

- <b>CONFIRMADO:</b> subtipos de carcasa rubí, zafiro, esmeralda y diamante, con cuatro efectos distintos y su propia combinación de poder y riesgo; no son cuatro escalones del mismo efecto. El porcentaje indica probabilidad de romper la carcasa, no de conservarla.
- <b>Valores iniciales confirmados para probar, ajustables durante el balance:</b> esmeralda 10% de rotura y reparación por 2 de plata; rubí 20% y reparación por 3; zafiro 30% y reparación por 4; diamante 50% y reparación por 5. Las probabilidades se aplican por dado intacto que puntúe en un grupo y por mano anotada. Estos valores sustituyen los ejemplos anteriores de 25%, 40%, 50% y 75%.
- <b>CONFIRMADO — activación por grupo:</b> el efecto de una gema intacta y su riesgo de rotura solo se aplican cuando su dado puntúa como parte de un grupo válido desde par en adelante. En «sin combinación» no aplica el poder de la gema ni existe riesgo de rotura; el dado aporta su valor y las mejoras numéricas que correspondan. Armar el grupo habilita el efecto en la previsión, pero no adelanta la comprobación de rotura: esta sigue ocurriendo después de anotar la mano.
- <b>CONFIRMADO — estado resquebrajado, aclaración vigente:</b> el dado pierde el poder de su carcasa/gema mientras está roto (por ejemplo, el efecto de rubí). Conserva los números de sus caras, los cambios de número y todas sus mejoras numéricas locales; las mejoras globales de la partida tampoco se pierden. Mantiene el color y la identidad del material, con textura resquebrajada. No se destruye. Esta aclaración reemplaza la interpretación anterior de conservar también el poder de la gema.
- <b>CONFIRMADO — momento de rotura:</b> después de anotar la mano, primero se aplica el efecto de la carcasa y se acreditan los puntos. Después se comprueba una sola vez por cada dado con carcasa que haya puntuado formando parte de un grupo. Formar o bloquear el grupo no dispara la comprobación. Los sobrantes de «sin combinación» no la disparan.
- <b>CONFIRMADO — sin usos seguros:</b> el riesgo comienza desde la primera mano en que el dado puntúa en un grupo.
- <b>CONFIRMADO — identidad del rubí:</b> aplica un factor que multiplica el multiplicador de su propio grupo, después de sumar los aportes aditivos a ese multiplicador. <b>Valor inicial confirmado para probar: ×1,5 por rubí</b>; ajustable durante el balance. La gema debe estar intacta y el dado debe pertenecer a un grupo; no afecta a otros grupos ni a «sin combinación».
- <b>CONFIRMADO — varios rubíes:</b> cada rubí intacto del grupo aplica su propio factor; los factores se multiplican entre sí. Con el valor de prueba confirmado de ×1,5 por dado, dos rubíes producen un factor conjunto de ×2,25.
- <b>CONFIRMADO — zafiro:</b> cada zafiro intacto suma <b>+2 al multiplicador de su propio grupo</b>, antes de aplicar los factores del rubí y de otras fuentes. Los aportes de varios zafiros se acumulan por suma: dos zafiros aportan +4. Requiere pertenecer a un grupo; no funciona en «sin combinación». Valor inicial de prueba, ajustable durante el balance.
- <b>CONFIRMADO — identidad de la esmeralda:</b> multiplica todos los puntos propios de ese dado antes de sumarlos al subtotal del grupo: número, mejoras numéricas y bonos propios de materiales, elementos y monedas. Ejemplo: (4 de cara + 3 de mejora numérica + 5 de fuego) ×2 = 24. No multiplica la base de categoría ni los puntos de los demás dados. <b>Factor inicial confirmado para probar: ×2</b>; un dado que aportaría 6 puntos pasa a aportar 12. Es ajustable durante el balance. Requiere carcasa intacta y que el dado puntúe en un grupo.
- <b>CONFIRMADO — diamante y acumulación:</b> cada diamante intacto añade una copia de la puntuación final de su propio grupo, calculada después de dados, mejoras, monedas y otras gemas, pero antes de las copias de diamante. No vuelve a ejecutar el cálculo ni activa otra vez efectos o comprobaciones de rotura. Con n diamantes, resultado del grupo = valor original × (1 + n). Ejemplo: un grupo de 100 con dos diamantes da 300, no 400. La rotura sigue comprobándose una vez por dado después de anotar la mano. Su probabilidad inicial de rotura confirmada es del 50%, con reparación por 5 de plata. Requiere carcasa intacta y pertenecer a un grupo.
- La rotura se comprueba después de puntuar, por lo que no quita el efecto ya acreditado en esa mano. Las reglas de riesgo, reparación y deuda están definidas para la primera prueba; sus valores son ajustables durante el balance.
- <b>CONFIRMADO — reparación opcional al cerrar un encuentro ganado:</b> primero se cobran las recompensas del encuentro; después se ofrece reparar las carcasas resquebrajadas y, si el jugador acepta, se descuenta el costo de la plata disponible. No se ofrece como reparación entre manos. El cobro automático obligatorio queda superado.
- <b>CONFIRMADO — deuda por reparación:</b> el jugador puede aceptar reparar aunque no le alcance la plata y quedar con saldo negativo. No se aplica derrota por esta elección. Las recompensas de los siguientes encuentros se suman al saldo y reducen la deuda normalmente. Si el saldo anterior al cobro es negativo, los intereses son cero: no se cobran intereses negativos ni cargos extra por deuda. Ejemplo: saldo −3 y recompensas de 8 dejan saldo 5, sin intereses ni recargos.

## Tres espacios por dado para la primera prueba; sinergias especiales diferidas

- <b>CONFIRMADO PARA LA PRIMERA PRUEBA — tres espacios independientes por dado:</b> un material, una carcasa de gema y un elemento pueden coexistir, por ejemplo acero + rubí + fuego. Esta decisión reemplaza el límite previo de dos capas. Es revisable al probar, por indicación del autor («por ahora sí, luego retocamos»). No implica que las tres capas sean obligatorias ni que estén equipadas desde el inicio.
- <b>CONFIRMADO — funcionamiento inicial sin sinergias especiales:</b> cada capa aporta su efecto normal y los efectos equipados coexisten según el orden de puntuación establecido. «Aditivo» se interpreta aquí como superposición de efectos independientes, sin crear bonos adicionales por emparejarlos; no transforma los factores multiplicativos ya definidos en sumas. No se implementan todavía superconducción ni otras reacciones especiales.
- <b>CONFIRMADO — elementos iniciales:</b> fuego, agua, tierra, viento y electricidad. Hielo fue un ejemplo anterior de posible interacción futura, no parte de esta selección inicial de cinco.
- <b>CONFIRMADO — fuego, valor inicial de prueba:</b> añade <b>+5 puntos propios</b> al dado si su resultado es 4, 5 o 6 y puntúa en una combinación válida desde par en adelante. Se evalúa el número de la cara, no su valor de puntos mejorado. Ejemplo sin otras mejoras: un 4 aporta 9 puntos al grupo. No aumenta el número usado para formar combinaciones, no potencia a los otros dados y no funciona en «sin combinación». Es un beneficio al puntuar, no una ganancia acumulativa por cada tirada. El valor +5 es ajustable durante el balance.
- <b>CONFIRMADO — agua, valor inicial de prueba:</b> añade +5 puntos propios si su dado muestra 1, 2 o 3 y puntúa en una combinación válida desde par en adelante. No funciona en «sin combinación». Se evalúa el número de la cara, no su valor de puntos mejorado, y no modifica la identidad del resultado. Es la contraparte del fuego; el +5 es ajustable durante el balance.
- <b>CONFIRMADO — disparador de tierra:</b> cuando se relanza efectivamente al menos un dado y el dado de tierra permanece en la mesa, gana poder según cuántos otros dados también permanezcan allí. No se cuenta a sí mismo ni cuenta los dados relanzados. Ejemplo con cinco dados: tierra y otros tres se conservan, y el quinto se relanza → cuentan tres dados para el aumento. Conservarlos puede incluir dados sueltos y dados en grupos. Mover dados sin lanzar no activa el efecto; no hay ganancia por no lanzar ninguno.
- <b>CONFIRMADO — tierra, valor inicial de prueba:</b> añade +2 puntos propios por cada otro dado conservado junto a él en cada activación válida. Ejemplo: se conservan tierra y otros tres, mientras se relanza el quinto → tierra gana +6 puntos propios. La ganancia se acumula solo durante la mano actual, se reinicia al empezar la siguiente y se borra completamente si se relanza ese dado de tierra. Esta pérdida afecta únicamente a la bonificación de tierra, no a sus números ni mejoras numéricas ni sustituye las reglas de otras capas. La ganancia también se aplica si termina puntuando en «sin combinación». El +2 es ajustable durante el balance. El aumento por cantidad de dados conservados diferencia tierra del acero, cuyo +3 se activa una vez por relanzamiento ajeno.
- <b>CONFIRMADO — viento, valor inicial de prueba:</b> cada relanzamiento efectivo del propio dado de viento añade +0,5 al multiplicador de su grupo, antes de aplicar factores multiplicativos. Se acumula solo durante la mano actual y se reinicia al comenzar la siguiente. Relanzarlo de nuevo incrementa la ganancia; la primera tirada de la mano no cuenta como relanzamiento. No aplica su multiplicador al grupo de «sin combinación»: requiere una combinación válida desde par en adelante. El +0,5 es ajustable durante el balance.
- <b>CONFIRMADO — electricidad, valor inicial de prueba:</b> suma +3 puntos propios por cada otro dado de su mismo grupo que muestre el mismo número que él. No se cuenta a sí mismo ni cuenta dados de otros grupos; importa el número de la cara, no sus puntos mejorados. Ejemplo: un dado eléctrico de un trío gana +6 puntos; en una generala gana +12. El beneficio pertenece a ese dado, no añade +3 a cada compañero. Es un efecto propio del elemento, no una sinergia especial entre capas. El +3 es ajustable durante el balance. También funciona en el conjunto único de «sin combinación»: cuenta los otros sobrantes con su mismo número. No requiere que el jugador haya formado un par u otra combinación con ellos.
- <b>Alcance y orden de cálculo confirmados:</b> viento requiere combinación desde par; electricidad también cuenta coincidencias entre sobrantes; esmeralda duplica todos los puntos propios, incluidos los bonos aplicables de otras fuentes. La esmeralda sigue requiriendo una combinación desde par para activar su propio efecto, como las demás gemas. Las identidades, valores iniciales y alcance de los cinco elementos están definidos para probar.
- <b>CONFIRMADO — activación elemental:</b> todos los poderes elementales de esta primera versión son pasivos; se activan automáticamente al cumplirse su condición. No requieren botones de activación manual.
- <b>CONFIRMADO — permanencia elemental:</b> el elemento aplicado permanece durante toda la partida hasta que el jugador lo reemplace. No consume usos ni desaparece por activarse. Esto define la permanencia de la capa, no la duración de eventuales bonificaciones acumuladas, que se definirá por efecto.
- <b>CONFIRMADO — una por familia:</b> cada dado admite como máximo un material, una carcasa y un elemento. No se permiten dos subtipos de la misma familia, como acero + cobre, rubí + diamante o fuego + agua.
- <b>Límite vigente:</b> hasta tres efectos equipados, uno por familia. No hay dos metales, dos carcasas ni dos elementos simultáneos en un mismo dado.
- <b>Futuro, fuera del alcance inicial:</b> analizar sinergias como electricidad con metal o fuego/tierra con gemas; no se presupone su alcance ni se diseñan sus reglas todavía, por decisión del autor.
- Estas definiciones corresponden al diseño de la versión hasta Dios; todavía no están implementadas en la demo.

## Nuevas definiciones para la versión hasta Dios: metales

- <b>CONFIRMADO — primer subtipo, nombre provisional «acero»:</b> gana +3 puntos propios por cada relanzamiento efectivo de otros dados en el que permanece en la mesa. Conservarlo suelto o dentro de un grupo cuenta. El beneficio corresponde a ese dado, no a todos los dados ni a la base de categoría. Enviar o retirar dados del vaso sin lanzarlos no activa la ganancia. <b>Duración confirmada:</b> lo acumulado dura todo el encuentro y se reinicia contra el siguiente rival. Si se relanza ese acero, pierde todos los puntos acumulados por este material y vuelve a su estado base; conserva sus caras y mejoras numéricas. La primera tirada de una nueva mano no cuenta como relanzamiento.
- <b>CONFIRMADO — segundo subtipo, nombre provisional «cobre»:</b> cada relanzamiento efectivo de ese dado añade <b>+0,5 al multiplicador de su grupo</b>, aplicado antes de factores como el del rubí. Los aportes acumulados duran todo el encuentro y se reinician contra el siguiente rival. Relanzarlo vuelve a incrementarlos, no los elimina. La primera tirada de cada mano no cuenta como relanzamiento ni añade +0,5. El valor es inicial para pruebas y ajustable durante el balance.
- <b>CONFIRMADO — acero en «sin combinación»:</b> conserva su aporte de puntos propios acumulados. Suma el número obtenido, las mejoras numéricas aplicables y los puntos ganados por conservar ese acero.
- <b>CONFIRMADO — cobre en «sin combinación»:</b> no aplica su aporte de multiplicador al grupo de sobrantes. Solo lo aplica si pertenece a una combinación válida desde par en adelante. Esto no borra lo acumulado durante el encuentro; únicamente limita dónde puede aplicarse.
- Los nombres acero y cobre son provisionales. Estas definiciones están en diseño; no implican implementación en la demo.

## Tienda ampliada hasta Dios: disposición confirmada

La nueva disposición reemplaza la propuesta anterior de separar carcasas/elementos y materiales en zonas simultáneas independientes. Hay cinco espacios visuales en la mesa, cuatro con ofertas y uno reservado para futuras mejoras del vaso.

- <b>Arriba izquierda — monedas:</b> hasta cuatro ofertas mezcladas al azar entre monedas normales y monedas de un uso, sin cantidades garantizadas por tipo. Las de un uso siguen usando su ranura aparte. Comprar deja vacío el espacio correspondiente hasta renovar esa sección o visitar otra tienda.
- <b>Arriba derecha — carcasas, elementos y materiales:</b> una sección con hasta dos ofertas. Cada espacio puede ofrecer cualquiera de las tres familias, permitiendo mezclas entre ambos espacios y sin tipo fijo por espacio ni por visita. Los materiales disponibles por ahora son los metales definidos. Al renovar esta sección se sortean nuevamente las dos ofertas, incluidos sus tipos: un espacio que ofrecía elemento puede pasar a material o carcasa, o volver a ofrecer elemento. No se han fijado probabilidades numéricas de aparición.
- <b>Abajo izquierda — mejoras del vaso por esta partida:</b> espacio reservado, sin ofertas ni acciones de compra por ahora, con el dibujo del vaso de dados actual. No implica volver a permitir más dados ni cambios de material del vaso.
- <b>Abajo centro — dados:</b> hasta dos ofertas de mejoras numéricas globales/locales o cambios de cara. No vende dados adicionales: se mantienen los cinco dados fijos.
- <b>Abajo derecha — stickers:</b> un lugar garantizado para un sticker individual y otro para un paquete de los tipos ya definidos: elegir uno entre tres stickers distintos o recibir dos stickers distintos. «Sticker fijo» se interpreta como el espacio individual garantizado; no se presupone que sea siempre la misma categoría.
- Las cuatro secciones con ofertas conservan su lugar en cada visita. En la sección superior derecha varían aleatoriamente las familias de sus dos ofertas, no la existencia ni la ubicación de la sección. El espacio reservado al vaso también permanece visible.
- <b>CONFIRMADO — renovación por sección:</b> «Renovar» reemplaza todas las ofertas de la sección elegida, tanto las que siguen a la venta como los espacios que quedaron vacíos al comprar. No modifica las ofertas de las demás secciones ni retira productos que el jugador ya compró y equipó/guardó. Se mantiene la progresión del costo compartida entre secciones y su reinicio en la siguiente visita, ya definidos.
- <b>CONFIRMADO — sustitución:</b> al comprar y aplicar un reemplazo de un componente ya equipado, el anterior se pierde sin devolución de plata ni reserva. Se conservan los otros componentes, los números de las caras y sus mejoras numéricas. Ejemplo confirmado: al sustituir rubí por zafiro en un dado de acero + rubí + fuego, se pierde el rubí y quedan acero + zafiro + fuego.
- <b>Terminología:</b> se nombrará directamente material, carcasa o elemento, evitando la abreviatura «capa» que causó confusión.
- <b>Dirección visual:</b> la imagen anotada del autor fija la distribución, no constituye arte final. Se conserva la estética del PRD y del juego actual: mesa del club, paño bordó, bordes dorados, objetos ilustrados y controles legibles.
- Esta organización corresponde a la versión ampliada hasta Dios y todavía no está implementada. La sección histórica «Tienda inicial confirmada» describe la demo de monedas implementada. No se redefinen precios sin una decisión específica.

## Catálogo inicial y alcance ya documentados

- Vaso común de cuero y cinco dados básicos con caras 1 a 6 como arranque heredado.
- <b>CONFIRMADO — versión ampliada hasta Dios (nivel 7):</b> cinco dados fijos durante toda la partida, sin compra de dados adicionales. Se conservan modificaciones de caras, mejoras y materiales. La ampliación de capacidad y el crecimiento del número de dados quedan fuera de esta versión.
- Con cinco dados siguen siendo válidos varios grupos en una misma mano, por ejemplo trío + par o dos pares y un sobrante. <b>CONFIRMADO — doble par:</b> categoría propia que usa exactamente cuatro dados, dos de un número y dos de otro distinto, por ejemplo 2-2-5-5. El quinto dado puede ir a «sin combinación». Se conserva la alternativa de formar dos grupos de par separados; cada dado puntúa una sola vez. <b>Base de doble par confirmada: 15 puntos</b>, más el valor de sus cuatro dados y las mejoras aplicables. Ejemplo: 2-2-5-5 aporta 15 + 2 + 2 + 5 + 5 = 29 antes de mejoras. Sus mejoras específicas y un eventual bono de servida siguen pendientes. Esta definición se incorpora a la versión hasta Dios; no implica que la categoría ya esté implementada en la demo. Los bonos por repetir categorías desde trío no son alcanzables con cinco dados bajo las reglas ordinarias; su definición previa queda como referencia histórica, no como requisito de esta versión.
- Seis monedas de mejora: cuatro por combinación y dos por paridad.
- Dos monedas de un uso.
- Jefe que prohíbe generala.<br /><b>PROPUESTA de recorte:</b> usar dados de material básico en esta primera prueba; materiales especiales, otros vasos y catálogo completo quedan para etapas posteriores. Las monedas elegidas no requieren activas con cooldown.

# 3. Monedas

Los nombres siguientes son identificadores funcionales, no nombres finales.

<table fit-page-width="true" header-row="true">
<tr>
<td>
ID
</td>
<td>
Moneda
</td>
<td>
Efecto confirmado por el autor
</td>
<td>
Tipo y efecto confirmados para la prueba
</td>
</tr>
<tr>
<td>
C01
</td>
<td>
Full
</td>
<td>
Aumenta el poder del full.
</td>
<td>
Pasiva: +1 al multiplicador de los grupos de su categoría; no de otras categorías ni del bono por repetición.
</td>
</tr>
<tr>
<td>
C02
</td>
<td>
Escalera
</td>
<td>
Aumenta el poder de la escalera.
</td>
<td>
Pasiva: +1 al multiplicador de los grupos de su categoría; no de otras categorías ni del bono por repetición.
</td>
</tr>
<tr>
<td>
C03
</td>
<td>
Generala
</td>
<td>
Aumenta el poder de la generala.
</td>
<td>
Pasiva: +1 al multiplicador de los grupos de su categoría; no de otras categorías ni del bono por repetición.
</td>
</tr>
<tr>
<td>
C04
</td>
<td>
Póker
</td>
<td>
Aumenta el poder del póker.
</td>
<td>
Pasiva: +1 al multiplicador de los grupos de su categoría; no de otras categorías ni del bono por repetición.
</td>
</tr>
<tr>
<td>
C05
</td>
<td>
Pares
</td>
<td>
Aumenta el poder de todos los números pares: 2, 4 y 6.
</td>
<td>
Pasiva: +2 puntos por cada dado de la paridad correspondiente, antes del multiplicador; incluye “sin combinación”.
</td>
</tr>
<tr>
<td>
C06
</td>
<td>
Impares
</td>
<td>
Aumenta el poder de todos los números impares: 1, 3 y 5.
</td>
<td>
Pasiva: +2 puntos por cada dado de la paridad correspondiente, antes del multiplicador; incluye “sin combinación”.
</td>
</tr>
<tr>
<td>
U01
</td>
<td>
Impulso 1 y 3
</td>
<td>
Aumenta los puntos de los resultados 1 y 3 durante este enfrentamiento.
</td>
<td>
De un uso: +3 puntos por cada resultado 1 o 3 hasta terminar el encuentro.
</td>
</tr>
<tr>
<td>
U02
</td>
<td>
Una tirada más
</td>
<td>
Otorga una tirada extra en esta mano.
</td>
<td>
De un uso: +1 tirada disponible en la mano actual; no pasa a la siguiente mano.
</td>
</tr>
</table>

## Valores iniciales confirmados para probar

- C01–C04: <b>+1 al multiplicador de los grupos de su categoría</b>. No aplicar a otras categorías ni al bono por repetición: el autor confirmó que solo afectan a los grupos correspondientes.
- C05 y C06: <b>+2 puntos por cada dado</b> cuyo resultado sea de la paridad correspondiente, antes del multiplicador de su grupo. Incluye dados en “sin combinación”.
- U01: <b>+3 puntos a cada resultado 1 o 3</b> de cualquier dado activo durante el encuentro, después de consumirla. Se añade al valor, sin cambiar el número que forma combinaciones.
- U02: <b>+1 tirada disponible</b> en la mano actual; con tres tiradas base pasa a cuatro. La tirada adicional no convierte un relanzamiento en servida.<br /><b>CONFIRMADO por el autor:</b> estos tipos, operaciones, valores y duraciones se usan en el prototipo inicial. Son ajustables al probar, no balance validado. La distinción de grupos y categorías se mantiene.

## Reglas operativas heredadas

- Las monedas pasivas y activas comparten hasta cinco espacios; las de un uso empiezan con una ranura aparte. Para este recorte están confirmadas las seis pasivas y las dos de un uso listadas.
- Cada moneda de un uso se consume una vez. No gasta una mano ni una tirada salvo costo explícito.
- Las que requieren un encuentro no se consumen en tienda para preparar un efecto diferido. U02 necesita una mano en curso; U01 se usa durante un encuentro y expira al terminarlo. Ambas se consumen antes de anotar, sin preparar efectos diferidos desde la tienda.
- Comprar y usar sin almacenar solo es posible si su efecto es válido en ese contexto. Si necesita guardarse, requiere capacidad.
- Una moneda normal no modifica dados de grupos bloqueados. Los efectos de puntuación no reagrupan dados ni cambian sus resultados.<br /><b>APLICACIÓN de los efectos confirmados:</b> U01 aumenta la puntuación de los resultados 1 y 3 presentes al anotar, sin cambiar miembros ni números de grupos bloqueados. No acredita retroactivamente manos ya anotadas. U02 agrega una oportunidad de lanzamiento a la mano aún en curso; no sirve después de “Anotar mano”. Los botones requieren un momento de decisión válido.

# 4. Jefe confirmado

<b>Regla: generala prohibida.</b> No se puede anotar la categoría generala durante ese encuentro.

- Los dados no se invalidan por mostrar cinco iguales.
- El jugador puede seleccionar tres para trío y dos para par, o cualquier división válida permitida.
- La regla se muestra antes de entrar al jefe. En el nivel de prueba confirmado se anuncia desde su comienzo, como en el diseño principal.
- La moneda de generala no evita la prohibición: ayuda en rivales normales, pero hay que buscar otra estrategia para este jefe.<br /><b>CONFIRMADO — objetivo del jefe:</b> 110 puntos iniciales. No hacen falta nombre final, retrato o animación exclusivos para comprobar la regla.

# 5. Flujo de prueba

## Paso A: mesa funcional

Un encuentro configurable, con opción de asignar las monedas de prueba directamente desde herramientas de depuración. Sirve para probar efectos sin depender del azar de tienda.

## Paso B: nivel corto jugable

<b>CONFIRMADO:</b> un nivel con dos rivales normales y el jefe de generala prohibida. Objetivos iniciales: <b>40 → 70 → 110 puntos</b>, ajustables durante las pruebas. Hay tienda entre encuentros; vencer al jefe cierra la sesión.<br /><b>CONFIRMADO — inicio:</b> vaso común de cuero, cinco dados básicos de caras 1 a 6, cero monedas equipadas y <b>\$0</b>. No hay tienda inicial ni moneda gratuita: la primera compra ocurre después de ganar el primer rival.<br /><b>CONFIRMADO — economía completa:</b> se incluye premio base por victoria, premio por manos sin usar, premio por exceso de puntos e intereses. Se preserva la estructura del PRD principal; estos valores confirmados pertenecen únicamente al prototipo.

### Economía inicial confirmada

- <b>Base por victoria:</b> 8 de plata.
- <b>Manos sobrantes:</b> 2 por cada mano efectivamente no utilizada al cerrar el encuentro.
- <b>Exceso de puntos:</b> 1 por cada 10 puntos completos sobre el objetivo, con máximo de 3 por encuentro. Fórmula: mínimo entre 3 y la parte entera de (puntos acumulados − objetivo) / 10, sin valores negativos.
- <b>Intereses:</b> se calculan sobre el saldo anterior a cobrar cualquiera de las recompensas del encuentro. Primeros 10 de ahorro al 20%; siguientes 20 al 10%; lo que exceda 30 al 5%. Son tasas marginales: cada una afecta solo a su tramo.
- Sumar los intereses de los tramos y <b>redondear hacia abajo una sola vez</b> a plata entera. No hay tope total de intereses.
- Ejemplos de intereses: saldo 0 paga 0; 10 paga 2; 30 paga 4; 50 paga 5.
- <b>Cobro total:</b> base + manos sobrantes + exceso + intereses. Se acredita una sola vez al cerrar con victoria, no tras cada mano ni al alcanzar por primera vez el objetivo.<br /><b>Ejemplo de liquidación:</b> primer rival con objetivo 40, victoria en una mano con 55 puntos y saldo previo 0: 8 base + 2 por mano sobrante + 1 por exceso + 0 intereses = <b>11 de plata</b>. Si se juega la segunda mano, deja de contarse como sobrante.<br />Estos valores se mantienen configurables para balancear después de jugar.
- Cada encuentro tiene dos manos y tres tiradas base por mano.
- Los puntos de las manos se acumulan dentro del encuentro y se reinician para el siguiente.
- Tras alcanzar el objetivo, el jugador puede cerrar o usar una mano sobrante para buscar más puntos.
- Sin objetivo alcanzado al agotar manos, termina la partida; rescates quedan fuera de este catálogo inicial.

### Tienda inicial confirmada

- Tienda reducida exclusivamente a monedas; las cuatro secciones del juego final quedan fuera de esta primera prueba.
- Dos ofertas visibles: una moneda pasiva y una moneda de un uso.
- Cada una de las seis pasivas cuesta 4 de plata. Cada una de las dos monedas de un uso cuesta 2 de plata.
- Comprar deja vacío el lugar de esa oferta hasta renovar o visitar la siguiente tienda.
- Renovar actualiza las dos ofertas de esta tienda reducida. Cuesta 1 la primera vez, 2 la segunda, 3 la tercera, y así sucesivamente. La progresión aumenta por renovación realizada y se reinicia en 1 al visitar la siguiente tienda.
- Comprar no aumenta el costo de renovación.
- Se conservan los límites de equipamiento y almacenamiento ya descritos; las monedas de un uso de este catálogo necesitan guardarse para usarlas durante un encuentro.
- Precios y escalado de renovación son valores iniciales para probar, configurables para el balance.<br /><b>Propuesta anterior superada por la decisión de cinco dados fijos:</b> cargar seis u ocho dados era una herramienta sugerida para probar grupos múltiples. No forma parte del alcance jugable hasta Dios. Las pruebas históricas de cantidades mayores no habilitan dados adicionales en la partida.

# 6. Reglas de dados y grupos a preservar

1. Primera tirada de todos los dados activos.
2. Selección manual y botón “Armar grupo”; la categoría usa exactamente los dados seleccionados.
3. Reservar un dado suelto no lo bloquea como combinación.
4. Enviar dados al vaso para relanzar bloquea los grupos ya armados. Retirar dados del vaso después no desbloquea esos grupos.
5. Los grupos bloqueados no admiten quitar o añadir dados para convertirlos en otra categoría.
6. Solo se relanzan los dados del vaso. La reserva en mesa conserva sus resultados.
7. Al anotar temprano se renuncia a las tiradas restantes; los sobrantes se calculan como un único grupo “sin combinación”.
8. “Anotar mano” acredita todos los puntos juntos. La libreta muestra previsión en lápiz y resultado definitivo en azul.
9. Servida exige terminar después de la primera tirada, sin relanzar ningún dado.

## Bases heredadas

<table fit-page-width="true" header-row="true">
<tr>
<td>
Categoría
</td>
<td>
Base normal
</td>
<td>
Base servida
</td>
</tr>
<tr>
<td>
Sin combinación
</td>
<td>
0
</td>
<td>
0; sin bono específico
</td>
</tr>
<tr>
<td>
Par
</td>
<td>
5
</td>
<td>
5; sin bono específico
</td>
</tr>
<tr>
<td>
Trío
</td>
<td>
10
</td>
<td>
10; sin bono específico
</td>
</tr>
<tr>
<td>
Escalera
</td>
<td>
20
</td>
<td>
25
</td>
</tr>
<tr>
<td>
Full
</td>
<td>
30
</td>
<td>
35
</td>
</tr>
<tr>
<td>
Póker
</td>
<td>
40
</td>
<td>
45
</td>
</tr>
<tr>
<td>
Generala
</td>
<td>
50
</td>
<td>
100 provisionales, sin victoria automática
</td>
</tr>
</table>

- Sumar los valores de los dados y mejoras de puntos aplicables a la base.
- Repetir categoría desde trío añade una base de esa categoría por cada grupo adicional; par y “sin combinación” no reciben ese bono.
- El multiplicador de sticker afecta al bono de su categoría si se incluyen stickers posteriormente. El alcance del catálogo de monedas de esta prueba debe fijarse por separado.
- Dentro del mismo alcance, sumar aportes al multiplicador y después aplicar factores.
- Mantener decimales y redondear una vez al total de mano, al entero más cercano, con 0,5 hacia arriba.

# 7. Datos necesarios antes de ejecutar la primera sesión

<b>La configuración jugable básica ya permite iniciar la implementación.</b> Las probabilidades y herramientas técnicas indicadas como propuestas pueden ajustarse durante la construcción y las pruebas.

- <b>Resuelto:</b> C01–C04 pasivas +1 al multiplicador de sus grupos; C05–C06 pasivas +2 puntos por dado de su paridad; U01 +3 puntos a cada 1 o 3 durante el encuentro; U02 +1 tirada en la mano.
- <b>Resuelto:</b> dos rivales y un jefe con objetivos iniciales 40, 70 y 110.
- <b>Resuelto:</b> plata inicial \$0, sin monedas ni tienda antes del primer rival. <b>Resuelto:</b> base 8, manos sobrantes 2 cada una, exceso 1 por cada 10 con máximo 3 e intereses marginales 20% / 10% / 5%. <b>Resuelto:</b> pasivas a 4 y monedas de un uso a 2; una oferta de cada tipo; renovación a 1, 2, 3… con reinicio en la siguiente tienda.
- <b>Resuelto:</b> la prueba usa la economía completa: base, manos sobrantes, exceso de puntos e intereses. Las cifras confirmadas están en la sección 5 y no se trasladan al PRD principal.
- <b>Resuelto:</b> intereses sobre saldo previo al cobro, con tasas marginales 20% para los primeros 10, 10% para los siguientes 20 y 5% para el resto, sin tope de pago y redondeo hacia abajo a plata entera. Exceso con máximo 3.
- Probabilidades de ofertas: al principio pueden fijarse o forzarse desde depuración para asegurar cobertura; no es necesario balancear rarezas antes de comprobar efectos.<br /><b>PROPUESTA técnica:</b> una configuración editable para todos estos valores, semilla reproducible, reinicio rápido y desglose de cálculo. Estas son herramientas de prueba, no ventajas del jugador.

# 8. Verificación funcional

- [ ] Crear una mano con cinco dados, tres tiradas y dos manos por encuentro.
- [ ] Comprobar conservación, selección exacta, armado y bloqueo de grupos.
- [ ] Comprobar que la vista previa coincide con los puntos acreditados.
- [ ] Probar cada una de las seis monedas de mejora por separado y en combinación.
- [ ] Comprobar que pares/impares se basan en el número del resultado y no en su valor mejorado: un 4 que vale 7 sigue siendo par.
- [ ] U01 afecta únicamente a 1 y 3, funciona en ambas manos si se consumió antes y expira al terminar el encuentro.
- [ ] U02 aumenta la mano actual en una tirada, se consume y no cambia la base de la siguiente mano.
- [ ] La generala se reconoce en los rivales normales y no puede anotarse contra el jefe.
- [ ] Cinco iguales contra el jefe sí pueden dividirse en trío y par.
- [ ] Las monedas de un uso respetan su ranura y sus ventanas válidas.
- [ ] Ganar y perder conducen al estado correcto; reiniciar limpia efectos temporales.
- [ ] Primer rival con objetivo 40, 55 puntos en una mano y saldo previo 0 acredita exactamente 11: 8 base + 2 sobrante + 1 exceso.
- [ ] Exceder el objetivo por 50 da 3 de premio por exceso, no 5. Usar las dos manos elimina el bono por mano sobrante.
- [ ] Intereses sobre saldos previos de 10, 30 y 50 pagan 2, 4 y 5 respectivamente; el premio del encuentro no entra en ese cálculo.
- [ ] Cerrar el encuentro acredita una sola recompensa; ni la vista previa ni continuar tras alcanzar el objetivo duplican el cobro.
- [ ] La tienda muestra una oferta pasiva a 4 y una de un uso a 2; comprar descuenta una sola vez y deja vacío su lugar.
- [ ] Renovar actualiza ambas ofertas y cobra 1, luego 2, luego 3; comprar no incrementa ese costo y la siguiente tienda vuelve a 1.
- [ ] Comprobar grupos múltiples sin doble conteo dentro de cinco dados: trío + par y dos pares + un sobrante. La prueba previa con seis u ocho dados queda como antecedente técnico, fuera del alcance jugable confirmado.

# 9. Qué se mide jugando

- Si reservar y fijar grupos generan decisiones comprensibles.
- Si las monedas cambian las jugadas que conviene buscar.
- Si prepararse contra la prohibición de generala resulta viable.
- Tiempo por mano, errores de selección y facilidad para entender la libreta.
- Categorías elegidas, compras, causas de derrota y puntos por encuentro.<br /><b>Puede esperar:</b> resto de materiales y vasos, catálogo completo, 18 jefes, progresión permanente, narrativa completa, escenario CMD, cinemáticas y arte definitivo.

# 10. Estado

<b>Primera implementación funcional — 25 de octubre de 2026.</b>

<b>Actualización visual v2 solicitada por el autor:</b> integrada en la aplicación, no solo como imagen conceptual. Recursos en <code>assets/art/club-table-v2.png</code> y <code>assets/art/coins-v2.png</code>; prompts completos en <code>ART-PROMPTS.md</code>. Diseño anterior respaldado en <code>backups/visual-v1/</code>. Se conservaron las mecánicas y la economía. Se volvieron a aprobar 105 comprobaciones y se revisaron capturas de mesa, grupos, tienda y cobro con el nuevo arte.

- Proyecto Godot 4.7.1 con GDScript en la carpeta solicitada: <code>C:\Users\Kazan\Desktop\Godot\project-dice</code>.
- Implementados: recorrido 40 → 70 → 110, mesa con selección y arrastre, reserva, grupos y bloqueo, libreta y cálculo, seis pasivas, dos monedas de un uso, tienda y renovación, economía, victoria, derrota y reinicio con semilla reproducible.
- <b>Verificación realizada:</b> 105 comprobaciones automáticas aprobadas, incluyendo recorrido de tres encuentros, reglas, recompensas y controles de interfaz. Informe local: <code>test-results/tests.json</code>. Capturas revisadas de inicio, grupos, tienda y cobro en <code>test-results/</code>.
- <b>Cómo jugar:</b> abrir <code>project.godot</code> y pulsar F5, o ejecutar <code>Jugar.cmd</code>. <code>Probar.cmd</code> vuelve a ejecutar las comprobaciones.
- <b>Supuestos provisionales de implementación, no decisiones definitivas del autor:</b> venta de pasivas por 2 y monedas de un uso por 1; ofertas uniformes dentro de cada tipo. Se excluyen pasivas equipadas de las ofertas, porque el catálogo no incluye la habilitadora de duplicados. Anotar con dados dentro del vaso conserva su último resultado si no se han relanzado.
- <b>Pendiente de validar jugando:</b> diversión, equilibrio, dificultad y claridad de los controles. Presentación visual v2 basada en el concepto aprobado del PRD: fondo ilustrado del club, paño bordó, vaso de cuero con sol, libreta y atlas de ocho monedas generados con imagegen; dados con volumen y controles dinámicos de Godot. Sigue en iteración y sin sonido. Sin guardado a mitad de partida. No se generó un ejecutable independiente: se ejecuta con Godot instalado.

El PRD principal permanece sin cambios. Los archivos [README.md](http://README.md) y [ESTADO.md](http://ESTADO.md) del proyecto describen alcance, supuestos y ejecución.
</content>
</page>

