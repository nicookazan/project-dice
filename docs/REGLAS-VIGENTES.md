# Reglas vigentes — versión hasta Dios

Fecha: 25 de octubre de 2026. Este documento guía la implementación; no afirma que todos los sistemas estén programados. El estado comprobado está en [DESARROLLO.md](DESARROLLO.md).

## Fuentes y precedencia

1. Decisiones posteriores de [PRD-PROTOTIPO](https://app.notion.com/p/404c28142b5581679265d602cec7e69b).
2. Reglas heredadas compatibles del [PRD IA](https://app.notion.com/p/3fec28142b55815c9f84c21402b73154).
3. Valores provisionales de la demo, identificados como tales.

Las copias completas consultadas están en [fuentes](fuentes/). Se conservan como referencia histórica, con sus contradicciones. La demo localizada está en C:/Users/Kazan/Desktop/Godot/project-dice. La copia de desarrollo de este chat está en C:/Users/Kazan/Documents/ChatGPT/Dios no juega a los dados.

## Alcance y decisiones que reemplazan versiones anteriores

**Diseño de dados confirmado — 27 de octubre de 2026:** todos los dados deben seguir el [diseño maestro aprobado](DISENO-MAESTRO-DADOS.md): vista casi frontal con parte superior corta visible, silueta redondeada y paleta marfil cálida. Materiales, carcasas, elementos, roturas y representaciones de tienda conservan esa geometría y estilo. Las perspectivas isométricas de ilustraciones anteriores no son referencias vigentes. Imagen aprobada conservada y adjunta en el PRD; aplicación a los sprites pendiente en 19.

| Tema | Regla vigente |
|---|---|
| Motor | Godot; base recuperada en Godot 4.7.1 con GDScript |
| Recorrido objetivo | Hasta Dios, nivel 7: dos rivales y un jefe por nivel, 21 encuentros |
| Recorrido disponible | Campaña técnica provisional de siete niveles/21 encuentros hasta Dios; nivel corto histórico conservado |
| Dados | Cinco durante toda la partida; sin compra de dados ni ampliación de capacidad |
| Inicio | Vaso común de cuero, caras 1–6, $0, sin monedas ni tienda inicial |
| Componentes | Material del cuerpo + material de los puntos (antes carcasa) + elemento pueden coexistir. Negro es el punto base; las gemas cambian los puntos, no recubren el cuerpo |
| Rotura | Se resquebraja la carcasa; el dado permanece y pierde solo el poder de esa carcasa |
| Tienda objetivo | Cuatro secciones con ofertas y un espacio reservado al vaso |
| Sinergias especiales | Diferidas; cada componente aplica su efecto normal |

El nivel 8/CMD, otros vasos, logros, rescates, activas con cooldown, ferromagnetismo, brillo y otras familias del PRD amplio no son requisitos del primer bloque. La venta de dados y el crecimiento del conjunto quedan fuera del alcance de cinco dados fijos. Los bonos por repetir tríos o categorías mayores son antecedentes no alcanzables con cinco dados.

## Mano, grupos y puntuación

- Dos manos base por encuentro, tres tiradas base por mano.
- La primera tirada lanza los cinco dados. Los relanzamientos solo afectan a los dados enviados al vaso.
- Selección manual exacta: un dado no puede pertenecer a dos grupos. Los sueltos se pueden conservar sin agrupar.
- Enviar un dado al vaso bloquea los grupos ya armados. Retirarlo no los desbloquea.
- Los grupos sin bloquear pueden desarmarse; los bloqueados no pueden ampliarse ni convertirse.
- Anotar termina la mano y acredita todos los puntos juntos. Los sobrantes forman un único grupo sin combinación.
- Servida requiere anotar después de la primera tirada sin ningún relanzamiento, aunque se haya conservado un grupo.
- Los puntos se acumulan dentro del encuentro. Alcanzado el objetivo, se puede cerrar o usar la mano restante.
- Sin objetivo al agotar manos, termina la partida.
- La previsión debe coincidir con el cobro; lápiz antes de anotar y tinta azul después.

| Categoría | Selección exacta | Base | Base servida |
|---|---|---:|---:|
| Sin combinación | Todos los sobrantes | 0 | 0 |
| Par | Dos iguales | 5 | 5 |
| Doble par | Cuatro dados: dos pares de números distintos | 15 | 15 provisional, sin bono adicional definido |
| Trío | Tres iguales | 10 | 10 |
| Escalera | 12345, 23456 o 13456 | 20 | 25 |
| Full | Trío y par de números distintos | 30 | 35 |
| Póker | Cuatro iguales | 40 | 45 |
| Generala | Cinco iguales | 50 | 100 |

Doble par 2-2-5-5 = 15 + 14 = 29. Si sobra un 6, la mano da 35. También se pueden formar dos pares separados: 9 + 15 + 6 = 30. Seleccionar los cinco dados de 2-2-5-5-6 no forma una combinación válida.

Los valores numéricos mejorados no cambian la identidad de la cara: un 4 que aporta 19 sigue siendo un 4 para combinaciones y paridad.

Orden para los efectos definidos: calcular puntos propios de cada dado (incluidas mejoras y bonos); aplicar esmeralda; sumar dados y base de categoría; sumar aportes al multiplicador y después aplicar factores como rubí; añadir las copias de diamante; sumar los grupos. Mantener decimales y redondear una sola vez al total de mano, con 0,5 hacia arriba. Después de acreditar, comprobar las roturas.

## Componentes del dado — definidos, pendientes de implementación

**Terminología vigente — 27 de octubre de 2026:** donde el historial dice carcasa/gema, ahora se entiende **material de los puntos**. Se mantienen los poderes, riesgos, reparaciones y coexistencia de familias. La representación cambia a puntos negros base o puntos con material de esmeralda/rubí/zafiro/diamante. Esta familia no modifica visualmente el cuerpo del dado; el daño se señala en los puntos sin quitarlos. [Contrato visual](DISENO-MAESTRO-DADOS.md).

| Componente | Efecto inicial | Duración y alcance |
|---|---|---|
| Acero | +3 puntos propios por relanzamiento ajeno en que permanece en mesa | Dura el encuentro; relanzarlo borra su acumulación. Funciona en sobrantes |
| Cobre | +0,5 al multiplicador por relanzamiento propio | Dura el encuentro; solo aplica en combinaciones desde par |
| Fuego | +5 puntos propios con resultado 4, 5 o 6 | Solo en combinación desde par; no se acumula por lanzar |
| Agua | +5 puntos propios con resultado 1, 2 o 3 | Solo en combinación desde par |
| Tierra | +2 puntos por cada otro dado conservado junto a él durante un relanzamiento efectivo | Acumula durante la mano, se borra al relanzarlo; también funciona en sobrantes |
| Viento | +0,5 al multiplicador por relanzamiento propio | Dura la mano; solo en combinación desde par |
| Electricidad | +3 puntos propios por cada otro dado del mismo grupo con igual número | Incluye coincidencias dentro del grupo de sobrantes |

Mover dados sin lanzar no activa ganancias. La primera tirada de cada mano no es un relanzamiento. El acero y el cobre conservan sus acumulaciones entre manos del mismo encuentro; tierra y viento las reinician entre manos. Los elementos son pasivos y permanecen equipados hasta reemplazarlos.

| Carcasa intacta | Poder en su grupo | Riesgo por mano puntuada en grupo | Reparación |
|---|---|---:|---:|
| Esmeralda | ×2 a todos los puntos propios de ese dado, antes de sumarlos | 10% | $2 |
| Rubí | ×1,5 al multiplicador después de las sumas; varios se multiplican | 20% | $3 |
| Zafiro | +2 al multiplicador; varios se suman | 30% | $4 |
| Diamante | Una copia de la puntuación final del grupo por diamante | 50% | $5 |

Dos diamantes convierten un grupo de 100 en 300, sin reactivar efectos. Las gemas no aportan poder ni corren riesgo en sobrantes. La comprobación ocurre una sola vez por dado intacto que haya puntuado en combinación, después de acreditar, desde el primer uso.

Una carcasa rota conserva su identidad y apariencia resquebrajada, caras, mejoras numéricas y los otros componentes. Reparar es opcional al cerrar un encuentro ganado, después de cobrar; se permite quedar en deuda. No hay reparación entre manos ni recargos por deuda. D08 resuelta el 26 de octubre de 2026: el usuario eligió seleccionar carcasas y mostrar costo total; se muestra también el saldo resultante. El mismo paso de reparación opcional precede la victoria final del último jefe.

Comprar un reemplazo descarta el componente anterior de esa familia sin reintegro ni reserva; conserva las otras familias, caras y mejoras.

## Números, caras y stickers — definidos, pendientes de implementación

- Todas las mejoras numéricas de puntos son globales por número para toda la partida. La mecánica local se eliminó el 30/10/2026.
- Se suman y acumulan. Ejemplo: +3 al 4 hace que todos los dados que muestren 4 aporten 7 puntos numéricos.
- Una mejora para un número ausente permanece guardada y se aplica cuando cualquier dado vuelva a mostrarlo.
- Cambiar una cara cambia probabilidades, no duplica mejoras. La oferta fija el número destino; el jugador elige dado y cara de origen.
- Rangos: común +1–3, rara +4–5, épica +6–8, legendaria +9–10.
- Número, magnitud, rareza y precio visibles antes de comprar. Probabilidades base de rareza constantes entre niveles, modificables solo por efectos explícitos.
- Stickers por categoría; par y sin combinación comparten uno. Sin cupo ni nivel máximo. Recomprar aumenta el nivel del mismo sticker al mismo precio base, sujeto a que reaparezca.
- Incrementos de puntos/multiplicador y precios de stickers pendientes. Doble par aún no tiene mejora específica ni bono servido definido.
- Packs: elegir uno entre tres distintos, o recibir dos distintos. Puede salir un sticker ya poseído: aumenta un nivel si se recibe. Los descartados no tienen efecto.

## Monedas y economía disponibles

Seis pasivas: full, escalera, generala y póker añaden +1 al multiplicador de su categoría; pares e impares añaden +2 puntos a cada dado correspondiente, incluidos sobrantes.

Dos monedas de un uso: impulso añade +3 a resultados 1 o 3 durante el encuentro; tirada extra añade una oportunidad a la mano actual. Se consumen antes de anotar, no en tienda para efectos diferidos. Cinco espacios pasivos y una ranura de un uso. El catálogo de la demo no permite duplicados.

Valores iniciales del nivel corto: $8 por victoria; $2 por mano sin usar; $1 cada diez puntos completos de exceso con máximo $3. Intereses sobre saldo previo al cobro: primeros $10 al 20%, siguientes $20 al 10%, resto al 5%; redondeo hacia abajo una vez. Saldo negativo produce cero intereses. Se cobra una sola vez al cerrar.

Desde el paso 11, la tienda disponible genera cuatro ofertas mixtas de monedas con precios provisionales $4/$2, sin garantizar cupos por tipo. Renovar solo la sección elegida cuesta $1, $2, $3… con contador independiente por sección que reinicia en otra visita. Reventa a $2/$1 y pesos iguales entre monedas elegibles son supuestos de la demo. Las demás secciones usan tablas explícitas de prueba hasta definir contenido comercial; no se declara balance definitivo.

## Tienda objetivo — sustituye a la tienda reducida

| Ubicación | Contenido |
|---|---|
| Arriba izquierda | Hasta cuatro monedas aleatorias mezcladas entre normales y de un uso, sin cupos por tipo |
| Arriba derecha | Dos ofertas, cada una sorteada entre material, carcasa o elemento |
| Abajo izquierda | Dibujo del vaso actual; espacio reservado, sin compras por ahora |
| Abajo centro | Dos ofertas de mejora global o cambio de cara, sin cupos por tipo |
| Abajo derecha | Un sticker individual y un paquete |

Renovar actúa solo sobre la sección elegida, repone vacíos y vuelve a sortear ofertas y sus tipos. El costo aumenta solo en la sección renovada y se reinicia en la siguiente visita. Comprar deja el espacio vacío y no aumenta ese costo. Modificaciones se aplican al comprar y elegir su objetivo, sin almacenar piezas.

## Decisiones abiertas que no bloquean el primer bloque

- Objetivos y recompensas de los 21 encuentros, catálogo adicional de monedas y reglas de jefes.
- Precios y probabilidades de las nuevas ofertas, crecimiento de stickers.
- Mejora específica y eventual bono servido de doble par.
- Presentación de niveles, menú y transición a tienda.
- Puntos de guardado, formato versionado y reanudación exacta de estado y azar.
- Sonido, animación y arte final; balance y diversión por validar jugando.

El jefe disponible prohíbe generala; cinco iguales se pueden dividir en trío y par. Doble par sigue permitido si la selección cumple su regla.
