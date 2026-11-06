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

**Pasos afectados:** TX1–TX3.

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
4. **Sin definir (bloquea cablearlos):** si "acero" pasa a llamarse "hierro"; efecto de los oxidados y del oro (el oro "da dinero si no se usa para hacer puntos": cuánto, cuándo, cómo se compra); si entran a la tienda y al guardado.
5. **Reglas de las animaciones:** respetan "Reducir movimiento" y la velocidad, usan un azar aparte y no tocan semilla ni guardado.

**Fuente:** [bocetos del 5 de noviembre](https://claude.ai/artifact/F6gWSJHa3X4ubawQ1SFUMo) y la página «4. Texturas» de Notion.
