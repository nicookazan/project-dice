# Decisiones pendientes y momento de resolverlas

Versión 1 · 25 de octubre de 2026. Este registro evita bloquear todo el proyecto por decisiones que solo necesita un paso posterior. Propuestas técnicas y valores de prueba no son reglas nuevas aprobadas.

## D01 — Mejoras numéricas

**Avance 16:** [Perfil de prueba v1](../DATOS-DE-PRUEBA-NIVEL.md) optativo con magnitudes locales, precios y pesos explícitos. Datos para validar, sin aprobar rangos locales ni balance final. El juego normal conserva sus tablas anteriores.

**Falta definir:** Rangos de locales, precios por rareza, probabilidades y distribución de magnitudes.

**Pasos afectados:** 03, 11, 12.

**Cuándo resolver / qué puede avanzar:** El motor de mejoras acepta magnitudes explícitas. Resolver antes de habilitar ofertas reales; mantener constantes las rarezas numéricas entre niveles.

**Avance del paso 03:** motor completado y probado con 328 comprobaciones. Los rangos globales ya están definidos en código; los precios, probabilidades y rangos locales siguen pendientes para 11–12. Completar el paso 03 no resuelve D01.

**Límite o propuesta:** No asignar rangos globales a locales. Las propuestas de balance deben distinguirse de lo confirmado.

**Estado:** Pendiente. Registrar aquí la decisión adoptada, su fuente y fecha al resolverla.

## D02 — Stickers y doble par

**Avance 16:** Perfil optativo con incrementos y precios explícitos de los seis stickers y ambos packs. 68 manos integradas comparadas sin diferencias dentro de la suite de 1553 comprobaciones. No añade sticker/servida de doble par ni resuelve el balance final. Ver [datos](../DATOS-DE-PRUEBA-NIVEL.md).

**Falta definir:** Tabla de puntos/multiplicador por categoría/nivel, precios y probabilidad; si doble par tendrá sticker y bono de servida.

**Pasos afectados:** 09, 11, 12.

**Cuándo resolver / qué puede avanzar:** Modelo y packs completados en 09 con fixtures: 722 comprobaciones aprobadas en la suite. Catálogo de juego con datos ausentes identificados, sin ofertas normales habilitadas. Cerrar incrementos, precios y probabilidades para la integración comercial y antes de validar nivel 16. Completar el motor no resuelve D02.

**Límite o propuesta:** Doble par conserva base 15 sin bono adicional mientras no exista decisión; no duplicar todos los stickers por igual.

**Estado:** Pendiente. Registrar aquí la decisión adoptada, su fuente y fecha al resolverla.

## D03 — Catálogo de monedas

**Falta definir:** Nuevas monedas normales/de un uso, activas, rarezas, reventa, duplicados elegibles y ofertas visibles tras vender habilitadora.

**Pasos afectados:** 10, F01.

**Cuándo resolver / qué puede avanzar:** Las ocho monedas actuales se adaptaron en 10 con catálogo e inventario por instancias; suite de 795 comprobaciones aprobadas. D03 sigue pendiente para monedas nuevas, rarezas y habilitadoras. Diseñar ficha por nueva moneda antes de ofrecerla; completar el inventario no resuelve este catálogo futuro.

**Límite o propuesta:** Ejemplos de nombres y poderes del PRD amplio no son catálogo aprobado. No es un bloqueo global.

**Estado:** Pendiente. Registrar aquí la decisión adoptada, su fuente y fecha al resolverla.

## D04 — Economía y ofertas

**Avance 16:** Precios/pesos y repetición con reemplazo explícitos en perfil optativo, guardado separado y aviso de datos de prueba. Ofertas normales anteriores conservadas. Cartera de $200 solo en laboratorio, nunca al iniciar el perfil jugable. [Informe](../VALIDACION-INTEGRAL-NIVEL.md). Política comercial final y validación humana siguen pendientes.

**Falta definir:** Precios y probabilidades de componentes, números y packs, política de repetición de ofertas y valores de reventa adicionales.

**Pasos afectados:** 11, 12, 16.

**Cuándo resolver / qué puede avanzar:** Generador y stock completados en 11 con tablas de prueba; suite de 848 comprobaciones aprobadas. D04 conserva pendientes precios, pesos y política comercial final de repeticiones. Validación comercial necesita datos iniciales etiquetados; completar el generador no aprueba esos valores.

**Límite o propuesta:** Herencia temporal: monedas 4/2, renovación 1,2,3… y economía de demo. Ofertas mixtas no garantizan cupos por tipo.

**Estado:** Pendiente. Registrar aquí la decisión adoptada, su fuente y fecha al resolverla.

## D05 — Presentación de recorrido

**Estado:** Aplicada el 26 de octubre de 2026 como decisión de implementación del paso 14; no se atribuye a una aprobación previa del usuario.

**Pasos afectados:** 14.

**Decisión:** Inicio con menú y anuncio del nivel 40 → 70 → 110, incluida generala prohibida del jefe. Botón Recorrido y tecla M permiten consultar desde partida, cobro, reparación y final; no permiten saltar encuentros. La tienda continúa únicamente al siguiente. Menú, nueva partida activa y cierre de ventana piden confirmar abandono; cancelar conserva exactamente la sesión. Desde victoria/derrota se vuelve al menú o reinicia sin confirmación de partida activa.

**Fuente y alcance:** Elección de presentación realizada al ejecutar la instrucción del usuario de implementar la ficha 14. No modifica reglas de grupos, economía ni progresión. Probada dentro de las 978 comprobaciones y revisada a dos resoluciones. Ver [contrato](../MENU-Y-RECORRIDO.md).

**Actualización en 15:** Menú guarda y conserva la partida para Continuar. Abandonar partida es ahora una acción explícita separada y confirmada. Cerrar ventana confirma Guardar y salir y bloquea el cierre si falla la escritura. El menú muestra Continuar solo para guardado válido activo. Campaña en 18; preferencias de pantalla siguen limitadas a la sesión.

## D06 — Guardado

**Actualización técnica de 17:** Sobre v2 para regla elegida del jefe y encuentros/objetivos. Migración conocida desde v1 en memoria, sin sortear ni sobrescribir al leer; siguiente checkpoint conserva el v1 como respaldo. Los nombres de archivo históricos siguen estables. [Compatibilidad](../REGLAS-DE-JEFE.md).

**Estado:** Aplicada el 26 de octubre de 2026 como decisión técnica al implementar 15; no se atribuye a aprobación previa del usuario.

**Pasos afectados:** 15, F02.

**Decisión:** Guardado automático después de cada cambio resuelto, en %APPDATA%/DiosNoJuegaALosDados/saves/partida-v1.json. Sobre JSON versión 1 y payload Variant sin objetos para conservar enteros RNG exactos. Temporal verificado, respaldo anterior y publicación mediante renombrado. Validar antes de restaurar datos, sin volver a ejecutar tiradas, cobros o sorteos.

**Recuperación y cierre:** Principal dañado/ausente ofrece respaldo validado con recuperación explícita conservando original. Versión futura o archivo inválido no se sobrescribe automáticamente. Nueva partida conserva archivos anteriores. Victoria/derrota/abandono dejan marcador cerrado que impide Continuar desde respaldos activos previos. Menú conserva; Abandonar y nueva partida reemplazante confirman; cerrar ventana guarda o informa error y mantiene abierta la sesión.

**Evidencia y límites:** 1083 comprobaciones sin fallos, reapertura en procesos independientes con siguiente tirada exacta, capturas a dos resoluciones. Ver [contrato](../GUARDADO-Y-CONTINUAR.md). Persistencia local v1; sin migración de versiones desconocidas, nube ni metaprogreso. Preferencias separadas. Esta decisión cubre 15; F02 extenderá formato/campaña cuando exista.

## D07 — Campaña y jefes

**Avance de 18:** Campaña técnica de siete niveles/21 encuentros con tres candidatos propios por nivel y reglas conocidas; objetivos y base $8 explícitos en [datos provisionales](../DATOS-DE-PRUEBA-CAMPANA.md). Jugar.cmd/F5 abre esa campaña con aviso; Nivel-corto.cmd conserva las tablas anteriores. Suite 1959 sin fallos. Identidades/reglas/objetivos/recompensas definitivos siguen pendientes: completar el recorrido técnico no aprueba D07 ni balance humano.

**Falta definir:** Objetivos y recompensas por encuentro; 18 candidatos de niveles 1–6; tres reglas de Dios; reglas CMD en fase posterior.

**Pasos afectados:** 17, 18, 20, F02.

**Cuándo resolver / qué puede avanzar:** Motor de jefes inicia con generala prohibida. Catálogo completo se necesita para aceptar campaña; no para desarrollar efectos.

**Límite o propuesta:** Progresión fija, sin adaptación al poder del jugador; datos provisionales deben quedar visibles como tales.

**Estado:** Pendiente. Registrar aquí la decisión adoptada, su fuente y fecha al resolverla.

## D08 — Interfaz de reparación

**Estado:** Resuelta el 26 de octubre de 2026.

**Decisión:** Elegir qué carcasas reparar y mostrar costo total y saldo resultante antes de confirmar. Permite continuar sin reparar y usar deuda. Tras el último jefe se presenta la misma selección antes de la victoria final.

**Fuente:** Respuesta directa del usuario en este chat: «Elegir carcasas; mostrar costo total». El flujo posterior al último jefe usa la misma resolución opcional antes de `won`.

**Pasos afectados:** 08, 13, 14. Implementada y probada en 08; los pasos 13–14 conservarán esta selección al integrar el recorrido.

**Reglas conservadas:** Opcional, después de cobrar, permite deuda, no entre manos. Ver [contrato](../ROTURA-Y-REPARACION.md).

## D09 — Suspensión y efectos especiales

**Estado:** Resuelta para materiales/carcasas actuales el 26 de octubre de 2026 por respuesta directa del usuario en este chat.

**Pasos afectados:** 17, F01.

**Decisión del usuario:** «Suspensión completa: sin poder, riesgo ni acumulación nueva; se mantienen los reinicios normales». Se conserva equipamiento; las futuras activas siguen recargando por eventos normales.

**Implementación en 17:** Acero/cobre no ganan bonos suspendidos; el reinicio propio de acero, los de mano y los de encuentro siguen vigentes. La pieza y sus contadores no se borran por suspender, pero no puntúan durante el jefe. Suspender carcasa quita poder y sorteos de rotura; no rompe ni repara automáticamente. La suspensión termina al cerrar el jefe. Monedas siguen ocupando espacio y no aportan poder ni se consumen. Elementos de otra familia siguen funcionando.

**Evidencia y límites:** Motor probado dentro de 1598 comprobaciones, cero fallos, con UI a dos resoluciones. [Contrato](../REGLAS-DE-JEFE.md). El catálogo definitivo D07 sigue pendiente. Rescates y activas concretas conservan su diseño/implementación en F01; este cierre no inventa esos poderes.

## D10 — Arte y narrativa

**Avance integrado — 27 de octubre de 2026:** generadas treinta caras 1–6 de negro y cuatro gemas mates, conservadas en ambos PRD y usadas en mesa, vaso/reserva/grupos, libreta de tienda y ofertas de gema/cara. Galería desde menú y Opciones. Los maestros originales permanecen intactos. [Catálogo](../CARAS-DE-DADOS.md), 2101 comprobaciones sin fallos y revisión a dos resoluciones. Materiales del cuerpo, elementos y restantes pendientes artísticos conservan su alcance.

**Acabados de puntos aprobados — 27 de octubre de 2026:** el usuario aprueba la comparación mate de los cuatro dados: rubí bordó, zafiro azul oscuro, esmeralda verde oscuro y diamante gris; colores apagados, opacos y sin destellos, con sombreado suave como el punto negro. Imagen intacta `assets/art/dice-master-v1/puntos-gema-mate-aprobados.png`; referencia en [diseño maestro](../DISENO-MAESTRO-DADOS.md). Sustituye la comparación brillante. Aprobación artística conservada; integración de sprites y estados de daño pendiente.

**Cambio posterior confirmado — 27 de octubre de 2026:** las antiguas mejoras de carcasa pasan a representar el **material de los puntos**. Negro es la base; esmeralda, rubí, zafiro y diamante cambian color/material/acabado de los puntos, no recubren el cuerpo. Se conservan poderes, condiciones, riesgo/reparación y coexistencia con material del cuerpo y elemento. El daño se señala en los puntos, sin borrar puntos ni agrietar el cuerpo. `shell`/`shell_broken` pueden mantenerse como alias internos; no hay migración de datos por documentar el cambio. Aplicación visual pendiente en 19; [contrato actualizado](../DISENO-MAESTRO-DADOS.md).

**Diseño maestro de dados confirmado — 27 de octubre de 2026:** el usuario aprueba la muestra marfil de cinco y exige ese diseño para todos los dados. Referencia obligatoria: `assets/art/dice-master-v1/dado-base-aprobado-5.png`. Perspectiva casi frontal con techo corto visible, cuerpo redondeado/biselado, paleta marfil cálida y puntos oscuros hundidos. Materiales, gemas, elementos, grietas y tienda conservan esa base; los cubos isométricos anteriores quedan superados. [Contrato e imagen aprobada](../DISENO-MAESTRO-DADOS.md). Esta aprobación de dirección no equivale a implementación ni aprobación de variantes aún no vistas.

**Revisión del usuario — 27 de octubre de 2026:** la mano debe coincidir con el pixel art existente. Se retiraron manos/objetos geométricos y se reutilizan mano y nube originales. Las variantes artísticas de jefes siguen pendientes; no se aprueba cambiar de estilo por utilizar marcadores provisionales. Exteriores y Dios aún necesitan el mismo pase artístico. La validación funcional del 19 no cierra la aprobación visual.

**Decisión del usuario — 27 de octubre de 2026:** «cambiamos a tener mate siempre». Mate en los siete ambientes, incluida noche. Reemplaza cerveza nocturna y continuidad de bebida posterior propuesta.

**Falta definir:** Acabado artístico final de manos/jefes y Dios, aprobación de recursos de cada ambiente, textos y mezcla de sonido.

**Pasos afectados:** 19, F02.

**Cuándo resolver / qué puede avanzar:** Reutilizar arte actual y marcadores provisionales. Producir recursos finales conforme al catálogo.

**Límite o propuesta:** Mate siempre confirmado; Dios triángulo con ojo integrado. Audio original, exteriores y símbolos nativos integrados como recursos provisionales. No sustituyen aprobación artística ni las identidades definitivas D07. Inventario y prioridades en [presentación y accesibilidad](../PRESENTACION-Y-ACCESIBILIDAD.md).

**Avance de 19:** Integración técnica completada: 2017 comprobaciones, cero fallos; doce capturas por resolución a 1280×800 y 1440×900. Preferencias separadas y partidas idénticas con distintas velocidades. Bebida resuelta; revisión artística/narrativa/auditiva final pendiente.

**Estado:** Parcialmente resuelta. Bebida confirmada por respuesta directa del usuario; integración técnica completada. Acabado y aprobación de arte/textos/sonido finales pendientes.

## D11 — Balance y duración

**Falta definir:** Meta de duración para la versión de 21 encuentros, criterios de dificultad y datos de sesiones humanas.

**Pasos afectados:** 20.

**Cuándo resolver / qué puede avanzar:** Recoger tiempos y decisiones reales antes de fijar metas o tasas de victoria.

**Límite o propuesta:** 20–30 minutos era meta del recorrido de 22 encuentros, no una medida ya validada.

**Estado:** Pendiente. Registrar aquí la decisión adoptada, su fuente y fecha al resolverla.

## D12 — Metaprogreso y vasos

**Falta definir:** Vasos, hitos de victorias CMD, premios, cupos de seleccionables y compatibilidades.

**Pasos afectados:** F03.

**Cuándo resolver / qué puede avanzar:** Diferido por decisión del autor; no bloquea hasta Dios.

**Límite o propuesta:** Distinguir beneficios permanentes de monedas equipadas y preservar selecciones reutilizables.

**Estado:** Pendiente. Registrar aquí la decisión adoptada, su fuente y fecha al resolverla.

## D13 — Nuevos materiales y sinergias

**Falta definir:** Qué ideas históricas se retoman, familia, magnitudes, precios y reglas de interacción.

**Pasos afectados:** F04.

**Cuándo resolver / qué puede avanzar:** Diferido; cada incorporación requiere RFC específico y criterios de aceptación.

**Límite o propuesta:** No reintroducir destrucción del dado, usos seguros, crecimiento del conjunto o sinergias automáticas.

**Estado:** Pendiente. Registrar aquí la decisión adoptada, su fuente y fecha al resolverla.

## D14 — Jugabilidad e interactividad (etapa posterior al paso 20)

**Decidido por defecto, a confirmar jugando:** (1) Reservar: la tela izquierda muestra "Reservar" pero el dado sigue armando grupo; la tela del medio sigue guardando dados sueltos. (2) Clic en la mano: juega piedra, papel o tijera; el poder del jefe se lee en la libreta y al pasar el mouse. (3) Piedra, papel o tijera es solo un gesto, sin ganador ni efecto. (4) Los guardianes de Dios no juegan; el clic muestra su información. (5) Clic en el termo: ceba el mate y se quita la ventana de detalle (los stickers se leen al pasar el mouse); si está robado conserva el clic actual. (6) Clic en el vaso: tira siempre que TIRAR esté habilitado; el botón TIRAR se queda. (7) "Jugadas posibles" viene activada por defecto. (8) Objetos con borde dorado: mano, sifones, bandera, termo y vaso.

**Pasos afectados:** J01–J08.

**Cuándo resolver / qué puede avanzar:** Todo avanza con estas decisiones; el autor las confirma o cambia al probar cada rama.

**Preguntas abiertas:** ¿Reservar debería apartar el dado? ¿El jugador también elige en piedra, papel o tijera? ¿Se quita la ventana del termo? ¿El vaso tira solo con los 5 dados? ¿Más objetos con borde dorado?

**Fuente:** plan de implementación de jugabilidad en Notion (4 de noviembre de 2026) y bocetos aprobados. T4 (vendedor enojado) quedó afuera por pedido del autor.

**Estado:** Aplicada por defecto; confirmación pendiente.

## D15 — Monedas: catálogo ampliado y paquete de la tienda

**Estado:** Confirmada por el autor el 5 de noviembre de 2026, al aceptar las propuestas del plan. Reglas confirmadas; precios, pesos y probabilidades siguen provisionales hasta el ítem 7 (D01/D02/D04 no se cierran con esto).

**Pasos afectados:** MON1–MON9.

**Decisiones:**

1. **Reemplazo en el paquete de 5:** se pide moneda por moneda. Una moneda elegida del paquete no puede ocupar el lugar de la otra.
2. **Paquete de 5 sin salida:** trae siempre al menos 2 pasivas, para que siempre exista una elección legal.
3. **Escudo de jefe, una vez por partida:** cuenta al generarse la oferta, aunque no se compre o no se vea.
4. **Uso de Escudo de jefe:** solo contra un jefe, incluido Dios. Si está suspendido, no se puede usar.
5. **Plata rápida:** se usa durante el encuentro, no en la tienda, para evitar generar plata sin límite.
6. **Descuento de visita + Descuento (C45):** se multiplican (precio × 0,8 × 0,5). Aplica a renovaciones y paquetes, no a reparaciones.
7. **Relanzo total:** requiere haber tirado. Deshace los grupos, incluso los bloqueados, y cuenta como tirada hecha, sin gastar presupuesto. Moneda gastada pierde 1 por dado. El dado abducido queda afuera.
8. **Voltear dado:** va a la cara física opuesta, sea cual sea su número. Solo dados sueltos, ya tirados. No afecta dados fijados por un jefe.
9. **Mult +2:** se acumula y se suma antes de Doble mult.
10. **Mano extra y premio:** cada mano sobrante sigue pagando $2; ganar en la primera de tres paga $4.
11. **Mano extra y jefes:** la tercera mano repite la ruleta de la segunda. La memoria de Chamuyero y del bloqueo de categoría sigue siendo de la mano 1.
12. **Monedas suspendidas:** no dan manos, tiradas ni plata. Corrige a Tirada permanente (C20), que hoy sigue dando la tirada.

**Fuente:** [plan de implementación del ítem 5](https://app.notion.com/p/40fc28142b5580f78431fc36d9e1f587) y [tarea con las monedas aprobadas](https://app.notion.com/p/40fc28142b55803db5fec97224f065e0). La subpágina "Decisiones de monedas" es una versión anterior.

## D16 — Texturas: elecciones sobre los bocetos del 5 de noviembre

**Estado:** Confirmada por el autor el 5 de noviembre de 2026 al elegir entre bocetos A/B. Es arte y presentación; los efectos de los metales nuevos no están definidos.

**Pasos afectados:** TX1–TX5 (TX3 y TX4 integrados el 07/11/2026; ver la ficha de cada uno).

**Decisiones:**

1. **Fondos animados:**
   - Día: nubes de A y pájaros de B (sin destellos en los techos).
   - Tarde: B (ventanas que se encienden y murciélagos).
   - Noche: B (ventanas calmas, estrellas, fugaz), pero **la luna queda fija**: las estrellas titilantes no la tocan.
   - Noche con El Gótico: B (señal chica y lejana).
   - Espacio: mezcla de A y B, a confirmar: rocas a la deriva (A) y galaxia con ondas (B).
   - Agujero negro: B (el disco se retuerce).
   - Cielo: A (rayos y nubes).
2. **Elementos de los dados:** A para los cinco. Marcas grandes sobre el borde del dado, sin tapar los puntos.
3. **Metales nuevos (solo arte):** hierro oxidado B (goteos y costra), cobre oxidado A (pátina en manchas), oro A (pulido).
4. **Metales nuevos en el juego (06/11/2026):** los tres entran a la tienda y al guardado con el mismo precio y peso que su metal base, en tabla y provisionales hasta el ítem 7. Por ahora **no tienen mecánica propia**: hierro oxidado funciona como acero, cobre oxidado como cobre y oro como acero (decisión 8 del plan: el oro no tiene metal base; imita al acero). Las reglas propias y la del oro ("da dinero si no se usa para hacer puntos": cuánto, cuándo, cómo se compra, y qué significa "no se usa" si hoy los sobrantes suman) las define el autor más adelante; si cambian el formato del guardado llevan su migración.
4b. **Nombre:** se muestra «Hierro» en todo el juego. El id interno sigue siendo `steel` para no migrar partidas.
5. **Reglas de las animaciones:** respetan "Reducir movimiento" y la velocidad, usan un azar aparte y no tocan semilla ni guardado.

**Fuente:** [bocetos del 5 de noviembre](https://claude.ai/artifact/F6gWSJHa3X4ubawQ1SFUMo) y la página «4. Texturas» de Notion.

## D17 — Arte: stickers, monedas y elementos (bocetos del 7 de noviembre)

**Estado:** Confirmada por el autor el 7 de noviembre de 2026 tras cuatro vueltas de bocetos. Es arte y presentación; no cambia reglas ni el formato del guardado.

**Pasos afectados:** TX8 (stickers), TX9 (monedas) y TX10 (elementos). TX10 reemplaza las marcas laterales de TX1.

**Decisiones:**

1. **Stickers:** calcomanía brillante (A) del nivel 1 al 9 y medallón dorado (B) desde el nivel 10. Todos los dados usan el dado modelo del autor: contorno, luz arriba y a la izquierda, sombra abajo y a la derecha, sin banda, puntos de 2×2 en una grilla pareja (2, 5 y 8 en el dado de 12). La escalera son cinco barras, como en la moneda «Acumulada». Tamaños: 52×52 (tienda y álbum, 104 px en pantalla) y 19×19 (termo).
2. **Monedas:** ficha esmaltada (C) para las 75. El aro marca la rareza (cobre común, plata rara, violeta épica, oro legendaria) y el esmalte la familia. Acumulada (C49) y Veterana (C48) siguen los diseños del autor. **El tamaño en pantalla no cambia.**
3. **Elementos:** emblema pintado en perspectiva sobre la cara de arriba del dado, animado (12 cuadros de 120 ms), para los cinco, incluido el viento. Reemplaza las marcas laterales de D16.2.
4. **Valores por defecto del plan:** la oferta de un sticker en la tienda muestra el estilo del nivel que va a tener tras la compra; sin animación propia al pasar al nivel 10; la fase de cada dado sale de su lugar en la mano y no del azar; un elemento suspendido se ve quieto con la «S»; el arte viejo se conserva hasta que el autor apruebe cada PR.

**Fuente:** [bocetos del 7 de noviembre](https://claude.ai/artifact/K55SgNyQyi45GDKj3dmFTz) y [plan en Notion](https://app.notion.com/p/412c28142b5581aa99a0d783a67077b9).

## D18 — Pantalla inicial, partidas guardadas y tutorial

**Estado:** requerimientos cerrados por el autor el 17/11/2026; las ocho decisiones por defecto del plan se aplicaron sin cambios (a confirmar por el autor). Abre una parte acotada del metaprogreso (F03).

**Pasos afectados:** TU0–TU9 ([ficha](TU-tutorial.md)); toca 14 (menú), 15 (guardado), 10 (monedas) y 17 (jefes).

**Decisiones:**

1. Las jugadas no se guardan ni se continúan; lo único que se guarda son tres partidas con estadísticas, logros y monedas desbloqueadas.
2. «El regalo del vendedor» (C58) es la única pasiva acumulable y la única moneda bloqueada; abarata monedas sueltas (no paquetes ni renovaciones): primero los porcentajes, después $1 por copia, piso de $1.
3. El tutorial terminado no suma jugadas ni victorias: solo logro y moneda.
4. El jefe del tutorial se llama «El Vendedor», vive fuera de `ROWS` y no entra al sorteo de la campaña; no da recompensa.
5. **Desvío del plan:** `SaveStore`, `SaveValidator` y las migraciones v1–v9 no se retiraron: se conservan en memoria para las pruebas de reproducibilidad (17 suites las usan) y `main.gd` ya no las usa.
6. **Desvío del plan:** los bocetos de TU0 no se hicieron; se integró con arte existente y una ficha provisional para C58, a la espera de la aprobación del autor.

**Fuente:** [requerimientos](../fuentes/REQUERIMIENTOS-TUTORIAL-2026-11-17.md) y [plan en Notion](https://app.notion.com/p/41bc28142b5581629c82c90e7e08bccb).

## D19 — La Semilla, jefe final

**Estado:** cerrada por el autor el 24/11/2026 (diseño y bocetos A1, B1 y C2 + C3). Implementada en `feature/la-semilla`.

**Pasos afectados:** 21 ([ficha](21-la-semilla.md)); toca 17 (jefes), 18 (campaña), 19 (presentación), 11 (tienda) y el guardado (v10).

**Decisiones:**

1. La Semilla es el encuentro 22, después del guardián del cielo (cualquiera de los tres). Perderle pierde la jugada. Ganarle no muestra cartel: tiembla todo, la mesa se rompe hacia abajo, la Matrix se queda sin líneas, los números de la semilla se apagan parpadeando (sin poder omitirlo) y aparecen solos los créditos; después, las recompensas (mecánica posterior, sin definir) y la pantalla de inicio.
2. Objetivo: el del guardián × 1,5. Manos y tiradas estándar.
3. Tiene **un solo poder**, sorteado entre los de los jefes de la jugada. Se descartó sumar un segundo poder a mitad de vida: el motor admite una sola regla por encuentro y no se agrega ese trabajo.
4. La mano con el maletín aparece cuando cruje el bar, antes del derrumbe: un ítem por sección y todos gratis; el restock cuesta $5 siempre y lo nuevo ya no es gratis.
5. La semilla se ve completa, arriba a la izquierda sobre la libreta; en el final viaja al centro en un recuadro llamativo. No se muestra en el tutorial.
6. La cinemática se ve entera la primera vez; después se puede omitir la animación (no la tienda). El guardián no muere al vencerlo: sigue en el cielo mientras está la mano con el maletín y muere al salir de la tienda, justo antes del derrumbe.
7. Una jugada con semilla elegida (repetida al perder o ingresada a mano) no suma nada a la partida guardada.
8. La Matrix usa de todo (armenias, katakana), pero sobre todo números y letras latinas.
9. Rayos de los guardianes: blancos y semitransparentes. Música y efectos, más adelante (D10).

**Fuente:** [diseño en Notion](https://app.notion.com/p/422c28142b55807f8c72f79c1a366033) y [plan](https://app.notion.com/p/422c28142b558089aaeccc27942b4245).

## D20 — Pantallas y diseños

**Estado:** plan aprobado por el autor el 24/11/2026 («lo veo muy bien»); las decisiones por defecto del plan se aplican sin cambios hasta que el autor diga otra cosa.

**Pasos afectados:** PS0–PS7 ([ficha](PS-pantallas.md)); toca 14 (menú y flujo), 15 (continuar), 11 (tienda) y el tutorial (D18).

**Decisiones:**

1. En la interfaz, «partida» reemplaza a «jugada» (Nueva partida, Abandonar partida…). Lo que D18 llamaba «partida guardada» (las tres ranuras de metaprogreso) pasa a llamarse «progreso». «Jugada» sigue significando una combinación de dados («jugadas posibles»).
2. Menú inicial sobre el paño izquierdo, sin recuadro: Continuar partida (si hay), Nueva partida, Colecciones, Opciones, Salir y «Nueva partida debug» solo en desarrollo. Nueva partida elige el modo en el paño del medio (Campaña y modos en gris) y ahí mismo pregunta por el tutorial. El debug arranca directo.
3. En el menú no hay mano en la ventana y solo responden los botones y el mate (termo que ceba el mate y el mate mismo). Durante el encuentro y en la tienda el fondo no cambia.
4. Después de ganar: «+$total» sin desglose y Continuar, que lleva a la selección de encuentro. **Desvío al implementar (25/11):** la reparación sigue yendo antes del cobro, como antes (su pantalla ya muestra lo cobrado); invertir el orden rompía unas 40 pruebas sin cambio visible para el jugador.
5. Selección de encuentro (fase `lobby`): reemplaza al anuncio de nivel y al cartel de destino. «Jugar contra el siguiente rival», objetivo, nivel/rival/jefe en chico, «Saltear» en gris (sin acción), «Ir a la tienda», y en lugar de la libreta, Opciones y Abandonar partida.
6. La tienda está en gris en el primer encuentro de cada nivel (lectura literal de la ficha; queda en `shop_available()` por si se cambia). Entre dos encuentros se puede entrar las veces que se quiera: el stock se genera la primera vez y se conserva, igual que precios de renovación y descuentos.
7. La ayuda de la mano del jefe sale centrada debajo de la mano.
8. **Implementación (25/11, a pedido del autor: «hacé todo junto»):** PS2–PS7 en una sola rama, `feature/pantallas`. Colecciones (PS7) es una versión básica sin boceto: Dados y gemas y Materiales y elementos abren las galerías de Opciones; Stickers abre el álbum del termo en modo colección (todos encendidos, con lo que da cada nivel) y Monedas, estantes de madera con todas las monedas en páginas de 18, con flechas a los costados (`scripts/coin_shelf.gd`), a pedido del autor el 25/11. El poder del jefe ya no se anuncia en un cartel: se lee en la mano y en Recorrido (M). «Ir a otro nivel» sigue solo en el menú de la partida. La tienda sale a la mesa con «Volver a la mesa →».

**Preguntas abiertas (no frenan el trabajo):** si la tienda en gris es en cada nivel o solo al empezar; si la libreta del cobro queda en blanco o desaparece; cuántos modos en gris; si se ve todo el catálogo en Colecciones.

**Fuente:** [ficha en Notion](https://app.notion.com/p/422c28142b55801781bdfeb9107c8e15), [plan](https://app.notion.com/p/423c28142b558008bee4c30a69584556) y [bocetos](https://claude.ai/artifact/88nJDsVTnGX6u2urfwMGd1).
