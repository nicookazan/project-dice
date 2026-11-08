> Actualización del 07/11/2026 (suite: 4337 comprobaciones, cero fallos): **TX10 (elementos animados en la cara de arriba), rama `feature/elementos-arriba`, PR abierto (apilado sobre TX8).** Los cinco elementos (el viento también) son un emblema en perspectiva sobre la cara de arriba del dado, en 12 cuadros de 120 ms (`pixel-v3/elementos-v4.png`, `tools/art/make_elementos_v4.py`). `Die.draw_element_edges()` dibuja el cuadro que toca; la mesa lo activa con `animate_element()` (mano y «Tus dados» de la tienda, ofertas de elemento y galería de Opciones) con los mismos interruptores que el resto del movimiento: «Reducir movimiento» o velocidad cero dejan el primer cuadro, la velocidad rápida acorta el cuadro a 75 ms y «Reducir destellos» salta los pasos de destello del rayo. La fase de cada dado sale de su lugar en la mano, no del azar; un elemento suspendido por un jefe se ve quieto. Falta la aprobación del autor dentro del juego. Las marcas laterales de TX1 (`elementos-v3.png`) ya no se cargan. Revisión visual nueva: `tests/elementos_review.gd`. Decisión D17.

> Actualización del 07/11/2026 (suite: 4316 comprobaciones, cero fallos): **TX8 (stickers por nivel), rama `feature/stickers-nivel`, PR abierto (apilado sobre TX9).** Calcomanía brillante hasta el nivel 9 y medallón dorado desde el 10, con el dado modelo del autor (hojas `stickers-grande-v4.png` y `stickers-termo-v4.png`, generador `tools/art/make_stickers_v4.py`). `StickerArt.style_for_level()` elige el estilo con la constante `GOLD_FROM_LEVEL`; el nivel llega al termo (mesa y tienda), la oferta (con el nivel que tendrá tras comprarla), el álbum, el vuelo y el revelado. Las zonas de clic y los lugares del termo no cambian. Falta la aprobación del autor dentro del juego. Revisión visual nueva: `tests/sticker_style_review.gd`. `tests/sticker_pack_review.gd` ya reportaba un error de verificación antes de este cambio (vuelo de stickers). Decisión D17.

> Actualización del 07/11/2026 (suite: 4272 comprobaciones, cero fallos): **TX9 (monedas en ficha esmaltada), rama `feature/monedas-esmalte`, PR abierto.** Las 75 monedas del catálogo y los dos paquetes salen de una sola hoja (`pixel-v3/coins-v4.png`, `tools/art/make_coins_v4.py`); el aro marca la rareza y el esmalte la familia. `coin_art.gd` lee la hoja por `ALL_IDS` (una prueba lo compara con `Coins.DATA`) y ya no hay ficha provisional con abreviatura. El tamaño en pantalla no cambia. Falta la aprobación del autor dentro del juego; las hojas viejas quedan sin cargar hasta entonces. Decisión D17.

> Actualización del 07/11/2026 (suite: 4238 comprobaciones, cero fallos): **Texturas: se ejecutó el plan de implementación (TX0–TX5) sobre `main`.** TX1 y TX2 (elementos grandes y fondos animados) ya estaban integrados; se agregó **TX3** (arte de hierro oxidado, cobre oxidado y oro con máscaras fijas en `die_body.gdshader`, generador `tools/art/make_metales.py`, galería de Opciones), **TX4** (los tres metales en el juego: tabla `Materials.TABLE` con metal base, tienda, guardado, jefes y moneda de metales; mecánicas provisionales iguales a su base; «Hierro» reemplaza a «Acero» en la interfaz, id `steel`) y **TX5** ([inventario de texturas](docs/INVENTARIO-TEXTURAS.md), propuesta que el autor debe marcar). **No hecho:** TX6 (reemplazar placeholders) y TX7 (vendedor nuevo): necesitan el inventario aprobado y definir el personaje con el autor. Siguen sin la prueba del autor dentro del juego: elementos, fondos y metales. Decisiones por defecto del plan aplicadas: 1 (espacio: rocas de A + ondas de B), 3, 4, 5, 6 («Hierro») y 8 (oro funciona como hierro). El tablero de Notion debe actualizarse a mano.

> Actualización del 06/11/2026 (merge a `main`): **la etapa de monedas (MON0–MON9) y el prototipo de texturas (TX1 y TX2) quedan en `main`.** Cómo seguir desde otro dispositivo: clonar o actualizar `main`, abrir `project.godot` una vez (para que Godot importe los assets nuevos) y correr `Probar.cmd` (suite: 4175 comprobaciones, cero fallos al cierre). Lo que sigue es el plan de implementación «4- Plan de implementación TEXTURAS» de Notion (fichas locales [TX1–TX3](docs/pasos/README.md), decisiones D16): el prototipo de TX1 y TX2 está integrado pero **sin aprobar por el autor dentro del juego**, y TX3 (metales) sigue solo en bocetos. Pendientes de la etapa de monedas que no se dan por resueltos: prueba del autor con `Jugar-jefe.cmd` y una partida completa, marcar la tarea en Notion, valores provisionales para el ítem 7, y el pase de arte de las 51 monedas con placeholder.

> Actualización del 06/11/2026: **Texturas: prototipo de TX1 y TX2 guardado en la rama `feature/texturas`, sin integrar a `main`.** Se construyó antes de tiempo (el autor pidió un plan, no la implementación) y queda como base para ejecutar el plan de la página de Notion «4- Plan de implementación TEXTURAS». Contiene los elementos grandes (`die.gd`, `elementos-v3.png`) y los fondos animados (`window_fx.gd`, `window_swirl.gdshader`, cambios en `backdrop.gd`), con pruebas y scripts de captura. Según D16: día (nubes y pájaros), tarde, noche (la luna queda fija), batiseñal con El Gótico en su encuentro de jefe, espacio (mezcla a confirmar), agujero negro y cielo. 

> Actualización del 08/11/2026: **Arte v4 de jefes y tienda integrado (sin commitear aún).** (1) Manos de los 17 jefes de los niveles 1 a 6 (menos El Gótico) con animación propia al clic en lugar de piedra, papel o tijera (`make_manos_clic_v4.py`, `boss_hand_clips.gd`, `BarProps.play_hand(boss_id)`); renombres: El Vendedor Ambulante, El Timbero, El Payaso y La Sonda (nombre provisional de la ex Computadora de Bordo). (2) Paquetes de monedas en bolsita de terciopelo (`make_paquetes_v4.py`, celdas 75–76 de `coins-v4.png`). (3) Maletín: cada oferta cuelga de un gancho con etiqueta de cartón y el precio escrito en ella; el hueco vendido muestra «VENDIDO» en su etiqueta (`shop_fixtures.gd`). (4) Bandejas de madera para tus dados (paño verde), tus monedas (terciopelo bordó, siguen la capacidad) y la de un uso (con un hueco con aro dorado). Los dados y las monedas de la tienda bajaron unos píxeles para centrarse en las bandejas. Suite en verde.

> Actualización del 04/11/2026: **Plan de jefes, fase F (integración) hecha en lo técnico.** Modo de desarrollo para forzar jefes por id: `Jugar-jefe.cmd l3_conde,l5_visitante` (argumento `--boss=`; solo en builds de desarrollo, no se guarda). `tests/boss_run_tests.gd` recorre los 21 encuentros tres veces, con los 21 jefes forzados al menos una vez, validando el guardado en cada paso. Suite: 3245 comprobaciones, cero fallos. **Pendiente y no dado por hecho:** calibrar P y k con el simulador F02 y Validar-nivel (no hay evidencia de balance: los números siguen provisionales), la fase C (manos con arte propio: espera bocetos dentro del juego y aprobación del autor), la revisión de nombres D10 y la sesión humana de juego. **Notion: marcar a mano las fases A, B, D, E y F (parcial).**

> Actualización del 04/11/2026: **Plan de jefes, fase E (termo robado de Don Cebador) implementada.** Al entrar al jefe 2A el termo del fondo sube con ritmo suave (2,6 s) con los stickers pegados y queda flotando con un leve vaivén junto a la mano; al vencerlo vuelve a la mesa con el recorrido inverso. Es presentación pura (`Backdrop.thermos_t`, bandera `thermos_stolen` del perfil): el aviso no se repite al redibujar, cargar a mitad del jefe lo muestra directo en su posición final, y con movimiento reducido o apagado se ve el cuadro final. Mientras flota, el botón del termo se mueve con él y explica el robo. Suite: 3234 comprobaciones, cero fallos (`tests/thermos_theft_tests.gd`); captura en `tests/boss_hand_review.gd` (`termo-robado`, probada a 1440×900). Posición y escala del termo flotante (`STOLEN_THERMOS_*`) son provisionales hasta la revisión del autor. **Notion: marcar a mano.**

> Actualización del 04/11/2026: **Plan de jefes, fase D completa: ya existen los 21 poderes.** Últimas familias: 5C Computadora de Bordo (la categoría con más puntos anotada en la mano 1 queda prohibida en la mano 2; memoria en `boss_state.locked`), 1A Kioskero (cada anotación cobra $2 sin profundizar una deuda, con aviso en el mensaje; total cobrado en `boss_state.tax`) y 6C Durmiente (previsión de la libreta y de la selección oculta; la anotación no cambia). `BossCatalog.ready_for_release()` ahora es verdadero. Suite: 3219 comprobaciones, cero fallos. Interpretaciones a confirmar: «la categoría anotada» de la Computadora = la de mayor puntaje de la mano 1; Relojero sigue con *Ruleta del instante* hasta F01. Quedan las fases C (manos con arte propio: requiere aprobación de capturas del autor), E (animación del termo) y F (integración, balance y sesión humana). **Notion: marcar a mano.**

> Actualización del 04/11/2026: **Plan de jefes, fase D, familia 3 (dados en la tirada) implementada:** 1C Palomas (dado asustado: no se puede conservar en las dos primeras tiradas; queda en el vaso), 4A Tahúr (dado cargado fijo en 1, sin relanzar), 4C Payaso (tras cada tirada un dado *recién tirado* pasa a 7 − x), 3A Gótico (el dado más alto de la 1.ª tirada queda en 1 hasta relanzarlo), 5B Farolero (conservar hasta 3 dados: relanzar exige mandar al menos dos al vaso) y 5A Visitante (un dado por mano abducido: no cuenta ni agrupa). El dado marcado de cada mano se sortea con un generador aparte (semilla + nivel + encuentro + mano) y vive en `boss_state.die`; el dado muestra una insignia (P, 1, A) y la regla anuncia «Dado marcado: N». Los efectos de tirada se aplican antes de registrar el evento, sin tocar el azar principal. Poderes con efecto: 18 de 21 (faltan Kioskero, Computadora y Durmiente). Suite: 3193 comprobaciones, cero fallos. Interpretaciones a confirmar: el Payaso voltea un dado de los recién tirados (no uno conservado); el Visitante abduce un dado que sí se tira la primera vez (para mantener el guardado válido) pero no cuenta. **Notion: marcar a mano.**

> Actualización del 04/11/2026: **Plan de jefes, fase D, familia 2 (prohibiciones y valor) implementada:** 4B Patovica (Par y Doble par prohibidos; la regla de categoría admite una lista), 3C Lobizón (caras 6 valen 0 de cara, las combinaciones no cambian), 6A Horizonte (5 y 6 valen la mitad de cara) y 2B Chamuyero (repetir en la mano 2 una categoría anotada en la mano 1 vale 50 %; la memoria vive en `boss_state.scored`, se guarda y se reinicia por encuentro). La rebaja de cara entra como ajuste negativo por dado, así previsión y anotación coinciden y el desglose lo nombra. El validador ahora comprueba las categorías prohibidas con el contexto traducido. Poderes con efecto: 12 de 21. Suite: 3153 comprobaciones, cero fallos. Interpretación a confirmar: «la categoría de la mano 1» se tomó como *todas* las categorías con dados anotadas en la mano 1. **Notion: marcar a mano.**

> Actualización del 04/11/2026: **Plan de jefes, fase D, familia 1 (suspensiones) implementada:** 2A Don Cebador (stickers suspendidos; el termo queda pegado, solo sin aporte), 3B El Conde Sed (fuego apagado, el elemento queda en el dado) y 6B Relojero. **Relojero usa *Ruleta del instante* como reemplazo** (multiplicador ×0,5 o ×1,5 sorteado por mano, visible antes de tirar, guardado en `boss_state`) porque las monedas activas (F01) no existen todavía, tal como fija el plan; «Tiempo detenido» vuelve cuando haya F01. Todo entra por `BossRules.context` (previsión = anotación). Poderes con efecto: 8 de 21. Suite: 3125 comprobaciones, cero fallos (`tests/boss_power_tests.gd`). Quedan las familias de prohibiciones/valor, dados, memoria entre manos, economía e información, y las fases C (manos con arte propio, requiere aprobación de capturas del autor), E y F. **Notion: marcar a mano.**

> Actualización del 04/11/2026: **Plan de jefes, fase B (tocar la mano muestra el poder) implementada.** Botón transparente sobre la mano del fondo y sobre el triángulo de Dios (`InspectBoss`, mismo patrón que el termo, foco de teclado, texto alternativo, cursor de mano y resalte mínimo). El panel sale de `scripts/boss_info.gd` y del catálogo: en un jefe muestra nombre, poder, explicación, objetivo, recompensa y sus sorteos (p. ej. «Expulsada: Impares»); en un rival, «Rival común: objetivo N. Próximo jefe: X · poder». No aparece en la tienda. Suite: 3099 comprobaciones, cero fallos (50 nuevas en `tests/boss_panel_tests.gd`, que recorre los 21 jefes). Capturas con `tests/boss_hand_review.gd` (probadas a 1440×900; la de 1280×800 queda para la sesión humana). Apilada sobre la fase A (PR 18).

> Actualización del 04/11/2026: **Plan de jefes, fase A (catálogo, campaña y guardado v8) implementada.** `scripts/boss_catalog.gd` define los 18 jefes y las 3 reglas de Dios como datos (objetivo = P × k redondeado a 5, recompensa = 8 + round((k−1)×20), piso 6; un test compara las 21 filas con la tabla del PRD). `Campaign.prototype()` se arma desde el catálogo y desaparecen las etiquetas «Jefe de prueba». Guardado **v8**: migra `prueba_l{n}_{k}` a ids estables por nivel y posición, agrega `boss_state` (sorteos propios del jefe, con generador aparte de la semilla) y conserva semilla, estado del azar y próxima tirada. Jugables desde ya: 1B Payador, 2C Referí (moneda expulsada) y las 3 reglas de Dios; los otros 16 poderes muestran texto y objetivo pero **sin efecto** y solo se sortean en builds de desarrollo (`Game.development_bosses`); si un nivel no tiene ningún poder listo se usa el pool completo para no romper la campaña, y `BossCatalog.ready_for_release()` queda en falso hasta terminar la fase D. Suite: 3049 comprobaciones, cero fallos (220 nuevas en `tests/boss_catalog_tests.gd`). Siguen provisionales los números (D01/D02/D04/D07/D11). **El tablero de Notion no se sincroniza solo: la fase A del plan debe marcarse a mano.** Límites de la migración: un guardado v7 se reasigna al jefe del catálogo en la misma posición (su regla y objetivo cambian); si estaba ya cobrado y el objetivo nuevo es mayor, los puntos se suben al objetivo para no invalidar el cobro.

> Actualización del 03/11/2026: **primera tanda de monedas nuevas implementada** (C07–C51, U01–U08) sobre un núcleo data-driven (`coins.gd` + `coin_effects.gd`), guardado v7, tienda por tipo y rareza, crédito, descuento, ranuras, gemas y cambios de regla (escalera de 4, comodín, par doble). Arte provisional (moneda en blanco con abreviatura). Sin simulación de balance (fase 9) ni sesión humana de juego. U01 pasó a "1 y 4". Detalle y decisiones en [MONEDAS-NUEVAS](docs/MONEDAS-NUEVAS.md). Suite: 2829 comprobaciones, cero fallos. La ruta natural de validación usa la primera semilla candidata que gana, porque el catálogo cambia lo que compra el bot.

> Actualización del 02/11/2026: vaso, mate, paño y salón de la mesa con más textura; parteluces sobre las ventanas. Opciones elegidas por el autor entre bocetos. Ver el registro de avance de [PLAN-ARTE-PIXEL](docs/PLAN-ARTE-PIXEL.md). Suite: 2198 comprobaciones, cero fallos.

> Actualización del 28/10/2026: materiales y elementos ya integrados en dados frontales, combinables con gemas brillantes y sin emblemas inferiores. Ver [Dados compuestos](docs/DADOS-COMPUESTOS.md). Suite: 2133 comprobaciones, cero fallos.

> Actualización del 28/10/2026: siempre mate con termo; stickers sobre el termo; exteriores ilustrados según el PRD; gemas brillantes. Sustituye las referencias históricas a cerveza, stickers en vaso y puntos opacos. Ver docs/CAMBIOS-VISUALES-2026-10-28.md.

# Estado actual — 27 de octubre de 2026

**Etapa de monedas (6 de noviembre de 2026): MON0 a MON8 completados; MON9 (cierre) en curso, a la espera de la prueba del autor.** MON7–MON8: paquete de monedas, reglas e interfaz, fase `coin_choice` y panel de elección ([detalle](docs/MONEDAS-NUEVAS.md)). MON6: Relanzo total, Voltear dado y Escudo de jefe, con `Game.boss_power_on()` y monedas de una vez por partida ([detalle](docs/MONEDAS-NUEVAS.md)). MON5: siete monedas de un uso simples (U10, U11, U13, U15, U16, U17, U18), catálogo de 72 ([detalle](docs/MONEDAS-NUEVAS.md)). MON4: Mano extra (C52), tres manos por encuentro con límite único `Game.hand_limit()` ([detalle](docs/MONEDAS-NUEVAS.md)). MON3: cinco pasivas nuevas (C53-C57), Cobrador en la pantalla del cobro y C20 suspendida corregida ([detalle](docs/MONEDAS-NUEVAS.md)). La suite ahora cede un cuadro entre las pruebas con pantalla: sin eso, el volumen de mensajes diferidos de Godot llegaba al tope de 32 MB y la suite se caía. MON1: arte de 16 monedas y 2 paquetes aprobado por el autor e integrado (`coins-nuevas-v3.png`, generador `tools/art/make_coins_nuevas.gd`). Fichas [MON0–MON9](docs/pasos/README.md) y decisiones D15, confirmadas por el autor. MON2: 10 cambios de rareza ([tabla](docs/MONEDAS-NUEVAS.md)) y guardado v9 con migración `coins_v9` ([contrato](docs/GUARDADO-Y-CONTINUAR.md)). Suite: 4117 comprobaciones, cero fallos (base: 3452). Siguiente: prueba del autor (`Jugar-jefe.cmd` y una partida) y pasar los valores provisionales al ítem 7.

**Etapa de jugabilidad e interactividad (4 de noviembre de 2026): J00 completado.** Fichas [J00–J08](docs/pasos/README.md), decisiones D14, generadores de los bocetos aprobados en `tools/art/bocetos-jugabilidad/` (reproducen byte a byte los GIF/PNG aprobados) y sprites del vaso (`vaso-brillo-v3.png`, `vaso-frente-v3.png`, de `tools/art/make_vaso_jugabilidad.py`). Sin cambios de comportamiento. Siguiente: J01.

**J01 (vaso, arrastre y Reservar) implementado, a la espera de tu prueba en el juego:** soltar un dado sobre el vaso, el termo o la tela libre lo manda al vaso; la zona izquierda sigue el borde dorado (incluida la esquina inferior izquierda); "Reservar" y el brillo del vaso aparecen solo al arrastrar un dado; el dado cae por la boca y queda detrás de la pared del vaso (solo presentación); corregido el texto que pisaba "Armar grupos arrastrando" en Opciones. Nuevos: `felt_layout.gd`, `table_drag_overlay.gd`, `cup_entry.gd`, `tests/felt_drop_tests.gd`. Limitación de las pruebas: el soltado sobre el vaso/termo se prueba llamando a las funciones reenviadas, porque el mouse sintético no actualiza la posición real. Siguiente: J02.

**J02 (ficha del dado) implementado, a la espera de tu prueba en el juego:** al pasar el mouse sobre un dado aparece su ficha (material · gema · elemento en color, caras con la actual en dorado, "Vale N puntos") sobre la tela izquierda en la mesa y arriba del dado en la tienda; contempla dado común, caras cambiadas, gema rota, material suspendido por el jefe y dado en el vaso. "Vale N" sale del mismo cálculo que la puntuación (número, mejora global, acero y pérdida de cara de jefe; lo que depende de la jugada se explica en Inspeccionar). Se quitó el texto largo anterior del hover de dados (también la lista de combinaciones, que pasa a la lista de J03) y Inspeccionar suma la explicación del material y la permanencia del elemento; cuatro pruebas viejas que leían ese texto ahora leen Inspeccionar. Nuevos: `die_card.gd`, `tests/die_card_tests.gd`. Siguiente: J03.

**J03 (jugadas posibles) implementado, a la espera de tu prueba en el juego:** después de tirar, la tela izquierda lista la mejor jugada de cada categoría con los dados libres, de más a menos puntos, con el mismo puntaje que al armarla (probado fila por fila contra la previsión). El mouse sobre una fila marca los dados y el clic arma ese grupo, igual que "Armar grupo"; con grupos armados el título pasa a "SIGUEN POSIBLES" y baja debajo de ellos. La ficha del dado baja debajo de la lista mientras el mouse está sobre un dado. Jefes: no lista categorías prohibidas y, si ocultan la previsión, muestra "?" y ordena sin delatar puntos. Opción nueva "Mostrar jugadas posibles" (activada por defecto; las preferencias viejas siguen cargando). Los grupos armados se corrieron 12 px para no pisar el borde inclinado, y el interruptor nuevo de Opciones acomodó el diálogo. Nuevos: `plays_panel.gd`, `tests/plays_panel_tests.gd`. Siguiente: J04.

**J04 (stickers al pasar el mouse) implementado, a la espera de tu prueba en el juego:** al pasar el mouse sobre un sticker del termo aparece una ventanita con su borde dorado: "Jugada · Nivel N" y "+X puntos · +Y mult." con los totales de ese nivel (salen de la misma función que la puntuación). Mesa: a la izquierda del termo; tienda: a la derecha. Hay una zona invisible solo sobre los stickers que se tienen, que deja pasar el clic del termo y el soltado de dados al vaso; no se abre mientras se arrastra un dado y con el termo robado no hay zonas ni ventanitas. Nuevos: `sticker_tip.gd`, `tests/sticker_tip_tests.gd`. Siguiente: J05.

**J05 (objetos del bar) implementado, a la espera de tu prueba en el juego:** en la mesa, clic en cada sifón (chorro largo que cae al vaso de al lado y lo llena con espuma), en la bandera (ondula por filas sobre su dibujo exacto) y en el termo (sube, cruza por delante del mate y se inclina 68° para cebar, con chorro, yerba y vapor). Los objetos tienen borde dorado que sigue su silueta al pasar el mouse (se apaga mientras animan). Un objeto no acepta otro clic mientras anima; con "Reducir movimiento" o velocidad 0 no hay animación; al pasar a la tienda se cortan. El estado de la partida y el azar quedan iguales (azar cosmético propio). El termo ya no abre su ventana de detalle en la mesa (los stickers se leen al pasar el mouse); robado y en la tienda conserva el detalle. Nuevos: `bar_props.gd`, `tools/art/make_bar_props.py` (bandera, pared sin bandera y aros), `tests/bar_props_tests.gd`. El termo gira en píxeles de pantalla, no sobre la grilla lógica como en el boceto. Siguiente: J06.

**J06 (vaso que tira) implementado, a la espera de tu prueba en el juego:** el clic en el vaso tira igual que TIRAR (mientras haya tiradas; si no, abre la información del vaso) y las dos vías usan la misma animación A: el vaso se sacude con dados detrás de su pared, sube a (1230, 372), se inclina 118° y los dados salen por su boca hasta sus lugares de siempre; después baja y se asienta. El vaso se dibuja aparte y por delante de los dados mientras tira. Tiene borde dorado al pasar el mouse. No se puede tirar dos veces durante la animación; con "Reducir movimiento" o velocidad 0 la tirada es directa; misma semilla, mismo resultado por clic o botón. **La tirada pasa de 0,85 s a unos 3 s (1,9 s en velocidad rápida): conviene confirmar jugando que no se haga pesada; la duración es una sola constante (`CupThrow.FRAME_SECONDS`).** Nuevo: `cup_throw.gd`, `tests/cup_throw_tests.gd`. Siguiente: J07.

**J07 (mano del jefe) implementado, a la espera de tu prueba y de la aprobación de la hoja de poses:** el clic en la mano del fondo juega piedra, papel o tijera (tres golpes con el puño que cuentan PIEDRA…, PAPEL…, TIJERA… y la jugada final, con azar cosmético propio, solo un gesto sin ganador ni efecto) y vuelve a tamborilear; los guardianes de Dios no juegan y su clic sigue mostrando su información; el poder del jefe se lee en la libreta y al pasar el mouse. Ahora los rivales de cada nivel muestran la mano del jefe del nivel (antes la común); Dios y los niveles sin jefe, la común. La mano tiene borde dorado. Las poses son de `tools/art/make_manos_poses.py` (19 manos × piedra/papel/tijera, partiendo del dibujo de cada mano; papel es el dibujo original). **El puño todavía no fue aprobado explícitamente: la hoja de revisión sale de `py tools/art/make_manos_poses.py` en `test-results/manos-poses-revision.png`.** Nuevos: `tests/hand_gesture_tests.gd`; tres pruebas viejas de `boss_panel_tests.gd` leen ahora la información por `inspect_boss_hand`. Siguiente: J08.

**J08 (vuelo del sticker) implementado, a la espera de tu prueba en el juego:** al comprar un sticker suelto nuevo vuela desde la oferta hasta su lugar en el termo (arco, estela dorada, destellos al pegarse y aviso "¡Nuevo! Trío · Nivel 1"), sin oscurecer la pantalla y sin bloquear la tienda; si ya se tenía, no vuela y sube el aviso "Trío · Nivel 1 → 2". En los paquetes (de dos y de elegir uno) solo vuela lo nuevo; lo repetido se desvanece en su lugar. La compra ya está hecha y guardada antes de animar, y cortar la animación (o cambiar de pantalla) deja el termo con el estado real; con "Reducir movimiento" o velocidad 0 la compra es directa. Nuevos: `sticker_flight.gd`, `tests/sticker_flight_tests.gd`. **Etapa de jugabilidad J00–J08 completa en alcance técnico, a la espera de las pruebas del autor.**

**Tres ajustes tras la tercera revisión (5 de noviembre), con bocetos aprobados:** (1) el agua del termo sale de la punta de la lengüeta roja de la tapa y cae a la izquierda de la bombilla; (2) el termo sirve en 2,9 s (antes 5,5) con un recorrido curvo: sube en arco, se inclina mientras viaja con un pasito de más, se mece apenas al servir y vuelve por el mismo arco; el chorro es más grueso, sale casi horizontal y se curva con una leve ondulación; (3) corregido el bug del clic en un sticker (dejaba pasar el clic al termo, que servía, y quedaba la ventanita flotando): ahora abre un panel con la lista de los seis stickers (los que no se tienen, apagados como \"Sin conseguir\"), el elegido en grande y su nivel, mejoras (lo que da ahora y con un nivel más) y qué hace; se cierra con Cerrar, Esc o clic afuera, y mientras está abierto no hay ventanita de hover ni atajos. El clic en el termo fuera de los stickers sigue sirviendo. Nuevos: `sticker_book.gd`, `tests/ajustes3_tests.gd`.

**Siete ajustes tras la segunda revisión (5 de noviembre), con bocetos aprobados:** (1) el agua del termo sale del pico (borde de la tapa) y el termo vierte 24 px más arriba; (2) los dados que entran al vaso y se sacuden dentro no traen recuadro; (3) los stickers brillan con un aro amarillo sobre su silueta al pasar el mouse (`aro-sticker-*-v3.png` de `make_bar_props.py`; el cuadro de texto sigue sin recuadro); (4) los dados se pueden usar apenas cae el último, a unos 2 s, y el vaso termina de bajar por su cuenta; tirar de nuevo corta el vaso viejo; (5) con varios dados seleccionados, arrastrar uno lleva todos en un bollito que se balancea: soltados en el vaso o la tela izquierda se mueven todos y en la mesa caen y se desparraman a sus lugares (con \"Armar grupos arrastrando\" activado queda como estaba: un dado por vez); (6) el cartel de venta sigue el trapecio de la valija, solo acepta soltar dentro de él y usa la letra de píxeles; (7) todas las ofertas de la tienda muestran la manito y un aro amarillo sobre su silueta (se arma la primera vez que se pasa el mouse, a partir del dibujo real, y queda en caché). Nuevos: `offer_ring.gd`, `tests/ajustes2_tests.gd`.

**Ajustes tras la primera revisión del autor (4 de noviembre):** la ventanita de los stickers ya no lleva recuadro dorado sobre el sticker (solo el cuadro de texto); la bandera de la tienda ondula al hacer clic igual que la de la mesa (mismo dibujo, `bandera-tienda-v3.png` y su pared de atrás generados por `tools/art/make_bar_props.py`), con su borde dorado al pasar el mouse.

**Treinta caras negras/de gema integradas y guardadas en el PRD:** seis números en cada acabado mate, más cuerpo sin resultado, treinta recursos individuales y galería desde menú/Opciones. Mesa, arrastre, libreta de tienda y ofertas de gema/cara usan el nuevo diseño. **2101 comprobaciones aprobadas, cero fallos**, con conteo sobre los píxeles de todas las caras y revisión a dos resoluciones. [Catálogo, procedencia y límites](docs/CARAS-DE-DADOS.md). Resto del pase artístico pendiente.

**Cambio visual confirmado:** las mejoras antes llamadas carcasas pasan a ser **material de los puntos**; negro base y gemas en los puntos, conservando sus efectos y reglas. No recolorean el cuerpo. Decisión documentada en ambos PRD y en el [diseño maestro](docs/DISENO-MAESTRO-DADOS.md). Aplicación en sprites, tienda y terminología de interfaz pendiente del pase artístico de 19; sin cambios de código en esta revisión.

**Diseño maestro de dados aprobado y documentado:** imagen marfil frontal de cinco preservada como referencia obligatoria para todos los dados y sus variantes, incluidas las ofertas de tienda. [Contrato e imagen aprobada](docs/DISENO-MAESTRO-DADOS.md). Este avance conserva y documenta la decisión; aún no sustituye sprites en el juego.

**Tienda renovada e integrada según la referencia del usuario:** nuevo paño de cuatro sectores, marcos de pixel art y atlas de ofertas; libreta, vaso, monedas equipadas, compra, venta, renovación y confirmaciones reales. Club/mano originales conservados. **2025 comprobaciones sin fallos** y siete capturas por resolución revisadas. [Detalle y procedencia](docs/TIENDA-ESTILO.md). El paso 19 sigue en curso por el resto del pase artístico.

**Revisión artística del usuario:** restauradas mano/nube originales y retirados los sustitutos geométricos. Variantes de jefe pendientes de producción con el mismo pixel art; exteriores y Dios aún provisionales. El cierre técnico del 19 no significa aprobación artística. Ver [presentación y procedencia](docs/PRESENTACION-Y-ACCESIBILIDAD.md).

**Paso 19 completado en alcance técnico:** siete exteriores del mismo club, nube/mano y objetos por regla, Dios triángulo/ojo, frases breves y avisos, audio sintetizado original por cuatro categorías y preferencias persistidas aparte de la partida. Silencio, volúmenes, velocidad, reducción de movimiento/destellos y contraste. **Mate siempre**, por decisión del usuario, incluida noche.

Verificación de la integración inicial del paso 19: **2017 comprobaciones aprobadas, cero fallos** (1959 anteriores + 58 nuevas); partidas naturales de semilla 3 idénticas con tres velocidades, incluidas compras, azar y puntuación. Doce capturas por resolución revisadas a 1280×800 y 1440×900; reproductor real/silencio comprobados. Informe `presentation_demo` en test-results/tests.json. [Contrato y procedencia](docs/PRESENTACION-Y-ACCESIBILIDAD.md).

Próximo: **20, balance, pruebas finales y ejecutable**. Acabado de arte/manos, textos y mezcla siguen provisionales y requieren revisión del autor; D07/D11 y sesión humana pendientes. No se declara balance ni aprobación artística definitiva.

## Historial del paso 18

**Paso 18 completado en alcance técnico:** campaña provisional de siete niveles/21 encuentros hasta Dios, tres candidatos propios por nivel, objetivos fijos, anuncio y sorteo guardados. Seis transiciones con conservación de piezas/monedas/stickers/plata y reinicio de puntos/contadores. Tienda tras jefe intermedio, victoria final sin nivel 8. Guardado v3 compatible con v1/v2 como partidas cortas.

Verificación actual: **1959 comprobaciones aprobadas, cero fallos** (1598 anteriores + 361 nuevas). Laboratorio por UI: 21 encuentros, seis fronteras, seis reparaciones y 21 previsiones iguales a la anotación. Derrotas en inicio/nivel 4/Dios. Diez capturas por resolución revisadas a 1280×800 y 1440×900; arranque normal sin ayudas verificado. Informe campaign_demo en test-results/tests.json. [Contrato y límites](docs/CAMPANA-HASTA-DIOS.md).

Jugar.cmd/F5 inicia campaña con contenido provisional visible; Nivel-corto.cmd mantiene el anterior y Validar-nivel.cmd el perfil corto separado. D07, balance definitivo y sesión humana siguen pendientes. Siguiente recomendado: 19, ambientes/narrativa/audio/accesibilidad, con D10 por resolver. Los tintes actuales no son arte final.

## Historial del paso 17

**Paso 17 completado:** reglas de jefe configurables, elección al entrar al nivel, contexto aplicado solo durante el jefe y restitución al cerrarlo. D09 resuelta por el usuario e implementada: suspensión completa sin poder/riesgo/ganancias nuevas, conservando piezas y reinicios normales. Guardado v2 con migración v1 sin volver a sortear. El pool normal conserva únicamente Generala prohibida; D07 sigue pendiente para catálogo final.

Verificación del paso 17 en ese momento: **1598 comprobaciones aprobadas, cero fallos** (1553 anteriores + 45 nuevas). Ocho capturas por resolución a 1280×800 y 1440×900, más reapertura entre procesos con siguiente tirada exacta. Informe boss_demo en test-results/tests.json. [Contrato](docs/REGLAS-DE-JEFE.md).

Siguiente recomendado: 18, campaña de siete niveles, con dependencias completas. D07 debe concretar catálogo/objetivos/recompensas; datos técnicos provisionales no son contenido final aprobado. Balance y sesión humana siguen pendientes.

## Historial del paso 16

**Paso 16 completado en validación técnica:** perfil provisional optativo con guardado separado, cuatro rutas naturales con reanudaciones, 19 compras de laboratorio y matriz de catálogo. Corregido guardado tras cambio de cara sobre último resultado y aclarados riesgo, stickers, materiales y motivo de derrota. D01/D02/D04 tienen datos de prueba explícitos; no son balance final aprobado.

Verificación del paso 16 en ese momento: **1553 comprobaciones aprobadas, cero fallos** (1083 anteriores + 470 nuevas). **68 manos comparadas, cero diferencias** de previsión/anotación. Normal: semilla 3 victoria / 0 derrota; perfil v1: semilla 1 victoria / 0 derrota. Nueve capturas por resolución a 1280×800 y 1440×900. Informe level_validation_demo en test-results/tests.json. [Informe integral y pendientes](docs/VALIDACION-INTEGRAL-NIVEL.md).

Para una sesión humana con todas las ofertas: Validar-nivel.cmd, balance provisional señalado y guardado separado. No se midieron tiempo de compra, comprensión ni diversión humana. Siguiente recomendado: 17, motor de reglas de jefe; D07/D09 pendientes antes de habilitar nuevos efectos.

## Historial del paso 15

**Paso 15 completado:** guardado local v1 y Continuar real, validación antes de restaurar, semilla/RNG int64 exactos, respaldo verificado, recuperación explícita conservando archivos y marcador de sesión cerrada para no resucitar partidas terminadas. Menú conserva; Abandonar y nueva partida reemplazante confirman. Errores permiten reintentar sin perder la sesión viva. D06 aplicada como decisión técnica de implementación.

Verificación del paso 15 en ese momento: **1083 comprobaciones aprobadas, cero fallos** (978 anteriores + 105 nuevas). Ocho fases activas, próxima tirada/stock idénticos, guardas de rotura/cobro/compra/pack/reparación, fallos de escritura, versiones/archivos inválidos y reapertura UI. Dos procesos independientes verificaron el estado y la siguiente tirada exactos. Siete capturas por resolución revisadas a 1280×800 y 1440×900. Informe save_demo en test-results/tests.json. [Contrato](docs/GUARDADO-Y-CONTINUAR.md).

Siguiente recomendado: 16, validación integral del primer nivel, con dependencia técnica completada. Antes de la sesión integral deben quedar explícitos los datos de prueba D01/D02/D04; el balance final y la diversión validada por el usuario siguen pendientes.

## Historial del paso 14

**Paso 14 completado:** menú, anuncio 40 → 70 → 110, recorrido consultable sin saltos, confirmación de abandono y cierre, opciones de pantalla y finales de victoria/derrota conectados. Nueva partida limpia todos los datos. Cobro único, mano adicional y reparación selectiva tras el jefe conservados. D05 aplicada como decisión de implementación de presentación.

Verificación del paso 14 en ese momento: **978 comprobaciones aprobadas, cero fallos** (938 anteriores + 40 nuevas). Prueba natural desde menú hasta jefe por UI: semilla 3, resultados 60/91/133, compras de stock generado y snapshot final igual al motor. Once capturas por resolución revisadas a 1280×800 y 1440×900; F11 y restauración de ventana verificados en ambas. Informe: level_flow_demo en test-results/tests.json. [Contrato](docs/MENU-Y-RECORRIDO.md).

Siguiente recomendado: 15, guardado y Continuar, con dependencia 14 completada y D06 por definir. D01/D02/D04 conservan pendientes los datos comerciales finales.

## Historial del paso 13

**Paso 13 completado:** mesa conservada con selección calculada y marcas SEL/EDITABLE/FIJO/R; fichas de dado, vaso y moneda; detalles desplazables; cinco zonas de tienda simultáneas con renovación por sección. Ratón, arrastre y teclado conectados a operaciones reales, sin reglas nuevas.

Verificación del paso 13 en ese momento: **938 comprobaciones aprobadas, cero fallos** (898 anteriores + 40 nuevas). Capturas revisadas a 1280×800 y 1440×900 mediante tests/interface_review.gd. Flujo compra/anotación acredita 130 iguales a la previsión. Informe: interface_demo en test-results/tests.json. [Contrato](docs/INTERFAZ-E-INSPECCION.md).

Siguiente recomendado: 14, menú y recorrido de nivel, con 08/13 completados. D05 de presentación sigue pendiente; D01/D02/D04 conservan datos comerciales finales.

## Historial del paso 12

**Paso 12 completado:** transacciones con ofertas identificadas, selección de dado/cara, cancelación sin cargo, confirmación revalidada y reemplazos aislados por familia. Stickers/paquetes conectados al stock real con pago único, opciones persistidas y recibos. Paneles provisionales operativos; D01/D02/D04 siguen pendientes para contenido comercial normal de otras familias.

Verificación del paso 12 en ese momento: **898 comprobaciones aprobadas, cero fallos** (848 anteriores + 50 nuevas). Capturas revisadas: test-results/compra-reemplazo.png, compra-confirmada.png, compra-cara.png y compra-pack-eleccion.png. Informe: purchases_demo en test-results/tests.json. [Contrato](docs/COMPRAS-Y-OBJETIVOS.md).

Siguiente recomendado: 13, interfaz e inspección, con dependencia 12 completada y D08 resuelta.

## Historial del paso 11

**Paso 11 completado en modelo y generador:** distribución 4/2/2/2 y vaso reservado; ofertas identificadas, renovación independiente con contador compartido y estado/azar reproducibles. La tienda normal ofrece cuatro monedas mixtas; otras familias usan tablas explícitas de prueba hasta cerrar datos comerciales.

Verificación del paso 11 en ese momento: **848 comprobaciones aprobadas, cero fallos** (795 anteriores + 53 nuevas). Capturas revisadas: test-results/tienda-monedas-cuatro.png, tienda-componentes.png, tienda-numeros.png y tienda-stickers.png. Informe: shop_demo en test-results/tests.json. [Contrato](docs/TIENDA-POR-SECCIONES.md).

Siguiente recomendado: 12, compras y objetivos, con dependencias técnicas completas. D01/D02/D04 siguen pendientes para datos comerciales finales.

## Historial del paso 10

**Paso 10 completado:** catálogo de ocho monedas con metadatos completos e instancias independientes; cinco espacios compartidos y una ranura de un uso. Compras, ventas y uso validan contexto/capacidad antes de cobrar o consumir. Se conservan los poderes originales y la economía provisional.

Verificación del paso 10 en ese momento: **795 comprobaciones aprobadas, cero fallos** (722 anteriores + 73 nuevas). Capturas revisadas: test-results/monedas-inventario.png, moneda-inspeccion.png y monedas-limites-tienda.png. Informe: coins_demo en test-results/tests.json. [Contrato](docs/MONEDAS-E-INVENTARIO.md).

Siguiente recomendado: 11, tienda por secciones, con dependencias técnicas completas. D01/D02/D04 siguen pendientes para datos comerciales finales; D03 para monedas futuras.

## Historial del paso 09

**Paso 09 completado en modelo y operaciones:** niveles por tipo, alcance por categoría, recompra sin duplicados, precio base constante y paquetes de elegir uno entre tres o recibir dos distintos. Pago único y elección pendiente incluida en snapshot. D02 sigue pendiente para balance final; ofertas comerciales en 11–12 y panel de elección en 13.

Verificación del paso 09 en ese momento: **722 comprobaciones aprobadas, cero fallos** (666 anteriores + 56 nuevas). Fixture de trío nivel 2: 68 + par 9 = 77. Capturas revisadas: test-results/stickers-categorias.png y sticker-desglose.png. Informe: stickers_demo en test-results/tests.json. [Contrato](docs/STICKERS-Y-PAQUETES.md).

Siguiente recomendado: 10, monedas iniciales e inventario extensible.

## Historial del paso 08

**Paso 08 completado:** rotura por carcasa intacta en combinación después de acreditar; reparación opcional por IDs tras cobrar, con costo total y deuda. La selección conserva las carcasas no elegidas. Resoluciones y sorteos protegidos contra repeticiones. D08 resuelta por el usuario: elegir carcasas y mostrar total, también antes de cerrar la victoria del último jefe.

Verificación del paso 08 en ese momento: **666 comprobaciones aprobadas, cero fallos** (581 anteriores + 85 nuevas). Capturas revisadas: test-results/reparacion-seleccion.png y reparacion-cobrada.png. Informe: repairs_demo en test-results/tests.json. [Contrato](docs/ROTURA-Y-REPARACION.md).

Siguiente recomendado: 09, stickers y paquetes; motor con fixtures mientras se define D02. El 10 también está disponible. Compras de componentes en 12.

## Historial del paso 07

**Paso 07 completado:** esmeralda ×2 a puntos propios, zafiro +2 al multiplicador, rubí ×1,5 después de las sumas y diamante +1 copia del resultado final. Carcasas rotas o sobrantes no activan poderes. Cálculo puro y desglose por origen.

Verificación del paso 07 en ese momento: **581 comprobaciones aprobadas, cero fallos** (524 anteriores + 57 nuevas). Ejemplo mixto: 129 × 7,5 × 3 = 2902,5, acreditable 2903. Capturas revisadas: test-results/gemas.png, gemas-desglose.png y gema-resquebrajada.png. Informe: gems_demo en test-results/tests.json. [Contrato](docs/GEMAS.md).

Siguiente recomendado: 08, rotura y reparación. D08 sigue pendiente para su interacción visual en 13–14; las operaciones pueden avanzar. También está disponible 10. Compras de componentes en 12.

## Historial del paso 06

**Paso 06 completado:** tierra gana +2 puntos propios por cada otro dado conservado durante un relanzamiento ajeno; viento gana +0,5 al multiplicador por relanzamiento propio. Ambos se reinician cada mano, conservando los bonos de acero/cobre del encuentro. Relanzar tierra borra solo su acumulación.

Verificación del paso 06 en ese momento: **524 comprobaciones aprobadas, cero fallos** (470 anteriores + 54 nuevas). Demostración mixta: mano 64; siguiente mano sin nuevos relanzamientos 43, conservando solo metales. Capturas revisadas: test-results/elementos-mano.png, tierra-acero.png, viento-cobre.png y reinicio-elementos-mano.png. Informe: hand_elements_demo en test-results/tests.json. [Contrato](docs/ELEMENTOS-DE-MANO.md).

Siguiente recomendado: 07, poderes de gemas. También está disponible 10. Compras de elementos en 12.

## Historial del paso 05

**Paso 05 completado:** fuego +5 con caras 4–6 y agua +5 con caras 1–3 en combinaciones; electricidad +3 por cada otro dado del mismo número en su grupo, incluidos sobrantes. Evaluación pura, permanente durante la partida y sin consumo. La libreta muestra aportes y razones de inactividad.

Verificación del paso 05 en ese momento: **470 comprobaciones aprobadas, cero fallos** (391 anteriores + 79 nuevas). Capturas revisadas: test-results/elementos.png, fuego-agua.png y electricidad.png. Demostración: par 39 + trío 40,5 = 79,5, acreditable 80. Informe: elements_demo en test-results/tests.json. [Contrato](docs/ELEMENTOS-CONDICIONALES.md).

Siguiente recomendado: 06, tierra y viento. También está disponible 10. Las compras de elementos llegan en 12.

## Historial del paso 04

**Paso 04 completado:** acero +3 puntos propios por relanzamiento ajeno conservado; cobre +0,5 al multiplicador por relanzamiento propio. Duran el encuentro, conservan acumulación entre manos y se reinician contra el siguiente rival. Acero también suma en sobrantes; cobre requiere combinación desde par.

Verificación del paso 04 en ese momento: **391 comprobaciones aprobadas, cero fallos** (328 anteriores + 63 nuevas). Con dos aceros y dos cobres se comprueba una mano de 49; otro recorrido con mejoras numéricas acredita 80 + 106 = 186. Capturas revisadas: test-results/metales.png, acero.png y cobre.png. Informe: materials_demo en test-results/tests.json. [Contrato](docs/METALES.md).

Siguiente recomendado: 05. El 10 continúa disponible; el 06 aún depende del 05. La compra de materiales queda en 11–12.

## Historial del paso 03

**Paso 03 completado:** mejoras globales/locales acumulables y cambios de cara con validación atómica. Puntuación integrada y desglose por origen; números ausentes conservan su mejora, sin cambiar identidad de combinación/paridad.

Verificación del paso 03 en ese momento: **328 comprobaciones aprobadas, cero fallos** (242 anteriores + 86 nuevas). Un 4 con +3 global y +12 local aporta 19; otro 4 sin local aporta 7. Captura revisada: test-results/mejoras-numericas.png. Informe: number_upgrades_demo en test-results/tests.json. [Contrato](docs/MEJORAS-NUMERICAS.md).

Siguiente recomendado: paso 04. También están disponibles 05 y 10 por dependencias. D01 sigue pendiente para precios, probabilidades y rangos locales en 11–12.

## Historial del paso 02

**Paso 02 completado:** cálculo puro con validación de grupos y desglose por dado, sumas, factores y copias. Eventos efectivos de tirada, relanzamiento, anotación y cierre; hooks posteriores a la resolución, sin ejecutarlos durante la previsión. Libreta con detalle de contribuciones y decimales.

Verificación del paso 02 en ese momento: **242 comprobaciones aprobadas, cero fallos** (173 anteriores + 69 nuevas). Ejemplos: multiplicador (2+1)×1,5 = 4,5; dos grupos de 10,25 acreditan 21 una sola vez. Informe: scoring_events_demo en test-results/tests.json. Captura revisada: test-results/desglose-puntos.png. [Contrato](docs/PUNTUACION-Y-EVENTOS.md).

Siguiente paso recomendado: 03, números y caras. El 10 también tiene dependencias completas. Las entradas siguientes conservan el historial.

## Historial del paso 01

**Paso 01 completado:** los mismos cinco dados conservan ID, caras, mejoras locales, material, carcasa/rotura y elemento entre manos y rivales. Mejoras globales y vaso pertenecen a la partida. Reinicios separados por mano, encuentro y partida; copia de estado en memoria sin alterar el azar.

Verificación del paso 01 en ese momento: **173 comprobaciones aprobadas, cero fallos** (132 anteriores + 41 nuevas). El informe test-results/tests.json incluye state_demo: primera mano 37, segunda 80, acumulado 117 y paso al siguiente rival con atributos conservados y contadores reiniciados. [Contrato de datos](docs/ESTADO-DE-PARTIDA.md).

Siguiente entrega: paso 02, cálculo y eventos. Los poderes y el guardado en disco todavía corresponden a pasos posteriores. Las notas siguientes conservan el historial de la base.

## Historial del paso 00 — base recuperada

Primera entrega de ampliación completada en C:/Users/Kazan/Documents/ChatGPT/Dios no juega a los dados. Demo recuperada desde el Escritorio, doble par integrado y ayuda actualizada; intereses con deuda corregidos a cero y validación de identificadores de dados.

Verificación de la base en ese momento: **132 comprobaciones aprobadas**, incluida una clasificación exhaustiva de 1.296 selecciones de cuatro dados. Capturas revisadas: test-results/doble-par.png y test-results/doble-par-anotado.png. Se observa 29 del grupo + 6 sobrante = 35 tanto en previsión como al anotar.

Las reglas actuales están en [docs/REGLAS-VIGENTES.md](docs/REGLAS-VIGENTES.md) y las siguientes entregas en [docs/DESARROLLO.md](docs/DESARROLLO.md). El siguiente bloque es persistencia de dados y efectos. Materiales, carcasas, elementos, tienda ampliada y guardado siguen pendientes de implementación.

## Historial de la demo recuperada

Lo siguiente describe entregas anteriores y sus verificaciones de aquel momento.

### Primera entrega de la demo — 25 de octubre de 2026

Implementado en Godot 4.7.1 con GDScript, en esta carpeta.

Actualización visual v2: se integraron fondo de club, mesa y paño bordó, vaso de cuero con sol, libreta y atlas de ocho monedas basados en las referencias del PRD. Se reubicaron controles sobre el arte y los dados ahora muestran volumen. Las reglas y la economía no se modificaron. Prompts y procedencia: `ART-PROMPTS.md`. Copia del diseño previo: `backups/visual-v1/`.

- Recorrido completo de tres encuentros: 40, 70 y 110 puntos; jefe sin generala.
- Tiradas, reserva, selección y arrastre, grupos editables hasta el bloqueo, sobrantes, servida y libreta con desglose.
- Seis pasivas, dos monedas de un uso, tienda, compras, venta y renovación.
- Cobro con intereses marginales, exceso y manos sobrantes; continuación opcional después de llegar al objetivo.
- Victoria, derrota y reinicio, incluida repetición de la semilla al perder.

Verificación: **105 comprobaciones automáticas aprobadas**, incluyendo estados de la interfaz, selección por clic y protocolo de arrastre. El informe está en `test-results/tests.json`. Revisión visual de inicio, grupos, tienda y cobro en capturas de la aplicación, ejecutada con la GPU local.

Pendiente de validación por el jugador: sensación de juego, claridad de controles, equilibrio económico y dificultad. Esto no es una afirmación de balance ni una prueba manual exhaustiva. Arte, animaciones y sonidos definitivos no forman parte de esta entrega.

Supuestos para esta entrega: ofertas uniformes dentro de cada tipo; reventa de pasivas a $2 y consumibles a $1. Ver README para reglas, límites y cómo ejecutar.

Actualización de dados v3: cuerpo ilustrado de marfil cálido con biseles, textura y sombras, generado con imagegen e integrado en assets/art/ivory-die-v3.png. Los puntos se dibujan dinámicamente, con entre uno y seis puntos exactos; selección con esquinas azules y previsualización del sprite al arrastrar. Se revisaron las seis caras y su tamaño real en mesa. Se mantienen 105 comprobaciones aprobadas. Capturas: test-results/dados-en-mesa.png y test-results/dados-seis-caras.png. Prompt completo: assets/art/ivory-die-v3-prompt.md. Diseño anterior: backups/dice-before-v3/.

Dados v4: cara de resultado frontal y ortogonal según la nueva referencia del autor, con volumen limitado al plano superior y biseles. Sprite generado con imagegen en assets/art/ivory-die-front-v4.png, prompt en assets/art/ivory-die-front-v4-prompt.md. Grilla de puntos sin inclinación. Revisadas las seis caras y aprobadas las 105 comprobaciones existentes. Respaldo: backups/dice-before-v4/.



## Fase C de jefes: manos y guardianes (4 de noviembre de 2026, rama `feature/jefes-manos`, sin PR)

- `tools/art/make_jefes_manos.py` genera `assets/art/pixel-v3/manos-jefes-v3.png` (18 filas de 8 cuadros de 61×53): misma silueta y animación de la mano común, rampa de 5 tonos y un objeto de 8 a 14 px. `Backdrop` elige la fila por id de jefe (`BossCatalog.hand_row`).
- Los tres guardianes de `pixel-v3/guardianes/` reemplazan al triángulo en los tres encuentros de Dios (`BossCatalog.GUARDIANS`: ojo → Generala prohibida, figura → metales, dado → carcasas). La semilla sortea el encuentro como en los otros niveles. El orden es una tabla de datos, cambiable.
- Pendiente: aprobación del autor de las 18 manos en capturas reales (dudas de contraste: El Gótico, El Horizonte) antes de commit y PR. Capturas: `tests/boss_hands_review.gd`.
- Suite: 3251 comprobaciones, 0 fallos.

> Actualización del 08/11/2026: **Jefe 1C, «Paloma ladrona» (antes «Dado asustado»).** Solo en la primera tirada de cada mano una paloma sale de la mano del jefe, baja al dado marcado y se lo lleva al vaso (animación `thief_pigeon.gd`, `paloma-ladrona-v4.png`); antes el dado marcado volvía al vaso en las dos primeras tiradas y desaparecía sin explicación, así que parecía que se tiraban solo 4 dados. De paso, `die.gd` fallaba al dibujar la insignia de los dados marcados por un jefe (tipo equivocado) y dibujaba un «=0» suelto: corregido. El id interno sigue siendo `scared_die` (no cambia el guardado).
