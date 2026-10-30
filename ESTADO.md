> Actualización del 28/10/2026: materiales y elementos ya integrados en dados frontales, combinables con gemas brillantes y sin emblemas inferiores. Ver [Dados compuestos](docs/DADOS-COMPUESTOS.md). Suite: 2133 comprobaciones, cero fallos.

> Actualización del 28/10/2026: siempre mate con termo; stickers sobre el termo; exteriores ilustrados según el PRD; gemas brillantes. Sustituye las referencias históricas a cerveza, stickers en vaso y puntos opacos. Ver docs/CAMBIOS-VISUALES-2026-10-28.md.

# Estado actual — 27 de octubre de 2026

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


