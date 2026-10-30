> Actualización del 28/10/2026: materiales y elementos ya integrados en dados frontales, combinables con gemas brillantes y sin emblemas inferiores. Ver [Dados compuestos](docs/DADOS-COMPUESTOS.md). Suite: 2133 comprobaciones, cero fallos.

> Actualización del 28/10/2026: siempre mate con termo; stickers sobre el termo; exteriores ilustrados según el PRD; gemas brillantes. Sustituye las referencias históricas a cerveza, stickers en vaso y puntos opacos. Ver docs/CAMBIOS-VISUALES-2026-10-28.md.

# Dios no juega a los dados

Proyecto Godot 4.7.1 / GDScript. Pasos 00–18 completados en su alcance técnico. Campaña provisional de siete niveles y 21 encuentros hasta Dios, con reglas de jefe, mejoras, tienda, reparación y Continuar. Catálogo definitivo D07, balance, presentación final y sesión humana pendientes.

## Jugar

### Probar en Mac

Necesitás **Godot 4.7.1**. Cloná esta rama y abrí `project.godot` desde Godot; **F5** inicia el juego. También podés usar el lanzador incluido:

```sh
git clone --branch codex/mac-test-ready https://github.com/nicookazan/project-dice.git
cd project-dice
./Jugar.command
```

El lanzador busca `godot` en PATH o `Godot.app` en Aplicaciones. Incluye los recursos del juego; Godot regenera sus archivos de importación al abrir el proyecto. Los guardados, opciones personales, temporales y backups de desarrollo quedan fuera de Git. Para recorrer rápido los niveles, usá **Nueva partida debug**. La validación automatizada se ejecutó en Windows; queda pendiente la prueba real en macOS.

### Windows

Ejecutá **Jugar.cmd**, o abrí **project.godot** en Godot y pulsá **F5**. El lanzador busca Godot en el Escritorio.

Para probar rápido, elegí **Nueva partida debug**: daño infinito (tirar y anotar una mano vence al rival) y plata infinita para compras, renovación y reparación. El modo queda marcado y se conserva con Continuar. **Nueva partida** vuelve a las reglas normales. [Detalles del modo debug](docs/MODO-DEBUG.md).

Las nuevas partidas abren la **campaña provisional hasta Dios**. Sus objetivos, jefes y balance de prueba se anuncian como provisionales. [Datos](docs/DATOS-DE-PRUEBA-CAMPANA.md) e [informe de campaña](docs/CAMPANA-HASTA-DIOS.md). **Nivel-corto.cmd** conserva el recorrido histórico; los guardados antiguos continúan como cortos y no se expanden automáticamente.

Para probar todas las familias en un solo nivel, abrí **Validar-nivel.cmd**: activa el [perfil provisional v1](docs/DATOS-DE-PRUEBA-NIVEL.md), con guardado separado y $0 inicial. La campaña también usa esas tablas provisionales; Nivel-corto.cmd conserva las anteriores. El [informe integral](docs/VALIDACION-INTEGRAL-NIVEL.md) registra las pruebas de la base corta.

Esta es la copia de desarrollo en **C:/Users/Kazan/Documents/ChatGPT/Dios no juega a los dados**. La demo original de **C:/Users/Kazan/Desktop/Godot/project-dice** conserva su versión anterior; los cambios de este chat están aquí.

1. En el menú, elegí **Nueva partida** y **Empezar primer encuentro**. Cada nivel anuncia sus objetivos fijos y la regla del jefe elegido. Tirás los cinco dados: tres tiradas por mano, dos manos por rival.
2. Seleccionás exactamente los dados de una combinación y pulsás **Armar grupo**. También podés activar **Armar grupos arrastrando** en la mesa o en Opciones: llevás los dados al sector izquierdo y confirmás el grupo. Al pasar el mouse por un dado se muestran las combinaciones posibles. [Uso y controles](docs/AGRUPAR-ARRASTRANDO.md).
3. Conservás sueltos o los enviás al vaso para relanzar. Enviarlos bloquea los grupos ya formados; retirarlos no los desbloquea.
4. La selección muestra su combinación y puntos. **Anotar mano** suma grupos y sobrantes; tocá una fila de la libreta para ver el cálculo. Clic derecho en un dado abre su ficha; **Ver termo** muestra stickers. F1 abre ayuda y los atajos de teclado.
5. Si alcanzás el objetivo, podés cerrar y cobrar o jugar la mano restante (consume su premio de $2). Después de cobrar y resolver reparaciones, una pantalla permite **Ir a la tienda** o **Seguir sin tienda** al próximo rival. Saltar la tienda conserva el premio y las mejoras, sin generar ofertas. Al cambiar de nivel se presenta el nuevo jefe. **Recorrido / M** consulta el avance; **Menú** guarda y conserva la partida para **Continuar**. **Abandonar partida** la cierra con confirmación. Cerrar la ventana ofrece **Guardar y salir**. **Opciones / F11** permite cambiar la pantalla.

Los stickers comprados aparecen sobre el mismo termo plateado tanto en la tienda como durante los encuentros. Se muestra cada tipo una sola vez, con su nivel actual. Revisión visual de ambos destinos y de los seis stickers en la mesa: `godot --path . --script res://tests/encounter_choice_review.gd`.

**Nuevo: doble par.** Seleccioná cuatro dados de dos números distintos, por ejemplo 2-2-5-5. Aportan base 15 + dados 14 = **29**. Si sobra un 6, la mano da **35**. También podés elegir dos pares separados. Todavía no hay un bono adicional de servida definido para doble par.

## Alcance disponible

El [guardado actual v6](docs/GUARDADO-Y-CONTINUAR.md) conserva campaña, progreso, RNG, jefes, ofertas y decisiones sin repetir cobros ni sorteos. Migra v1/v2 como partidas cortas y conserva original como respaldo al guardar. Ruta normal estable: %APPDATA%/DiosNoJuegaALosDados/saves/partida-v1.json. Un archivo inválido se conserva y un respaldo válido se ofrece para recuperar. [Presentación, audio y accesibilidad](docs/PRESENTACION-Y-ACCESIBILIDAD.md) integrados: siete ambientes con mate siempre y opciones guardadas aparte. Siguiente paso: 20, balance y ejecutable; catálogo D07 pendiente.

- Campaña provisional de siete niveles y 21 encuentros; tres candidatos propios por nivel y reglas guardadas. Modo corto histórico 40 → 70 → 110 conservado.
- Cinco dados, selección y arrastre, reserva, grupos, bloqueo, servida y libreta.
- Seis monedas pasivas y dos de un uso.
- Tienda por secciones: cuatro monedas, dos componentes, dos mejoras numéricas y dos ofertas de stickers/paquetes; vaso reservado. La campaña usa precios/pesos provisionales explícitos. Comprar vacía el espacio y renovar una sección cuesta $1, $2, $3… con contador independiente por sección y visita.
- Cinco espacios pasivos, una ranura de un uso, sin duplicados equipados.
- $8 por victoria, $2 por mano sobrante y $1 por cada diez puntos completos de exceso, máximo $3.
- Intereses marginales sobre saldo anterior al cobro: primeros $10 al 20%, siguientes $20 al 10%, resto al 5%; redondeo hacia abajo una vez. Deuda produce cero intereses.
- Victoria, derrota, nueva partida y reintento con la misma semilla.

**Pendiente:** catálogo/objetivos/recompensas definitivos D07, balance comercial D01/D02/D04, acabado artístico/textos/mezcla finales y validación humana. Menú, compras, reparación selectiva con deuda, guardado, campaña y presentación/audio/accesibilidad ya están conectados. Los datos provisionales no son balance final aprobado.

Los valores de reventa de pasivas por $2 y consumibles por $1, y los pesos iguales entre monedas elegibles, son supuestos de la demo. Anotar con dados dentro del vaso utiliza su último resultado si no fueron relanzados. La dificultad y diversión requieren prueba del jugador. Audio original provisional integrado; aún no hay ejecutable independiente exportado.

## Documentación

- [Treinta caras negras y de gemas integradas](docs/CARAS-DE-DADOS.md): abrir **Jugar.cmd → Ver diseños de dados**, o desde Opciones. Las caras también aparecen en mesa y ofertas de gemas. Suite actual: **2101 comprobaciones, cero fallos**.

- [Diseño maestro aprobado de todos los dados](docs/DISENO-MAESTRO-DADOS.md): imagen conservada, perspectiva, paleta y reglas para todas las variantes; aplicación a sprites pendiente en el pase artístico.

- [Reglas vigentes](docs/REGLAS-VIGENTES.md): decisiones actuales, valores iniciales y pendientes, con precedencia sobre la documentación histórica.
- [Plan detallado de desarrollo](docs/pasos/README.md): 25 fichas separadas con dependencias, tareas, ejemplos de aceptación y acceso al tablero de Notion.
- [Decisiones pendientes](docs/pasos/DECISIONES.md): qué falta definir y cuándo hace falta para avanzar.
- [Cobertura del PRD](docs/pasos/COBERTURA.md): requisitos actuales, reglas reemplazadas y alcance posterior.
- [Fuentes originales](docs/fuentes/): copias fechadas de los dos PRD de Notion.
- [Estado e historial visual](ESTADO.md).
- [Prompts y procedencia del arte](ART-PROMPTS.md).

## Verificación

**Tienda con vendedor y maletín (30/10/2026):** vendedor de traje en pixel art inspirado en las fotos del usuario; cuatro compartimentos de cuero negro y paño bordó para todas las ofertas, sin la mesa de juego. Objetos centrados y precio único; las descripciones aparecen al pasar el mouse en recuadros bordó y dorados con letra pixelada. Inventario, compras y renovación por sección conservados. [Recursos, prompts y verificación](docs/TIENDA-ESTILO.md). Verificación actual: **2191 comprobaciones, cero fallos**. Compra tocando el objeto y mejoras numéricas solo globales; sin mecánica local. Venta de monedas arrastrándolas sobre el maletín, con devolución sin venta fuera de esa zona; dados y monedas comparten balanceo e inercia. Monedas pasivas sin ofertas repetidas ni equipadas; inventario de monedas abajo y continuación arriba a la derecha. Dados en la franja azul y termo plateado de pie abajo a la izquierda; las compras de stickers se ven pegadas al termo. Descripciones solo sobre los objetos, en un panel fijo; costos de renovación independientes por zona.

Ejecutá **Probar.cmd**. La suite devuelve un estado de error si falla y guarda **test-results/tests.json**.

Resultado actual: **2101 comprobaciones, cero fallos**. Conserva las 2025 anteriores y añade 76 de caras de dados: conteo sobre los píxeles de las treinta caras, recursos individuales, materiales/estados, galería sin mutación y compra con actualización de apariencia. Informe dice_art_demo en test-results/tests.json; seis capturas por resolución a 1280×800 y 1440×900. Conserva la regresión de compras, puntuación, campaña y guardado. El laboratorio no demuestra balance ni añade ayudas al jugar. Pruebas aisladas del guardado del jugador.

El [contrato del estado](docs/ESTADO-DE-PARTIDA.md) explica los datos y sus duraciones. Los bonos numéricos, acero/cobre y los cinco elementos iniciales ya se aplican al resultado; los cuatro poderes de gemas también están integrados; su rotura después de puntuar y reparación opcional también están integradas.

El [contrato de cálculo y eventos](docs/PUNTUACION-Y-EVENTOS.md) detalla el desglose y el orden de resolución. La libreta muestra los aportes por dado/moneda, con revisión visual en test-results/desglose-puntos.png.

El [contrato numérico](docs/MEJORAS-NUMERICAS.md) documenta las operaciones y D01 pendiente. Captura revisada: test-results/mejoras-numericas.png, con un 4 de 19 puntos y otro de 7. Las transacciones de mejoras ya están conectadas; las ofertas normales siguen limitadas a monedas mientras se definen precios y tablas de otras familias.

El [contrato de metales](docs/METALES.md) documenta acero/cobre y sus reinicios. Capturas revisadas: test-results/metales.png, acero.png y cobre.png. Los metales se asignan en fixtures de prueba; el inicio normal conserva cinco dados básicos hasta conectar la tienda.

El [contrato de elementos](docs/ELEMENTOS-CONDICIONALES.md) documenta fuego, agua y electricidad, su composición y condiciones. Capturas revisadas: test-results/elementos.png, fuego-agua.png y electricidad.png. Su asignación actual se demuestra mediante pruebas; las transacciones de compra están conectadas desde el 12 con tablas explícitas.

El [contrato de elementos de mano](docs/ELEMENTOS-DE-MANO.md) documenta tierra/viento y sus reinicios separados de los metales. Capturas revisadas: test-results/elementos-mano.png, tierra-acero.png, viento-cobre.png y reinicio-elementos-mano.png.

El [contrato de gemas](docs/GEMAS.md) documenta los poderes de esmeralda, zafiro, rubí y diamante, y la suspensión por carcasa resquebrajada. Capturas revisadas: test-results/gemas.png, gemas-desglose.png y gema-resquebrajada.png. Rotura/reparación implementada en 08; compras en 12.

El [contrato de rotura y reparación](docs/ROTURA-Y-REPARACION.md) documenta riesgos, cobro único, selección, costos y deuda. Capturas revisadas: test-results/reparacion-seleccion.png y reparacion-cobrada.png.

El [contrato de stickers y paquetes](docs/STICKERS-Y-PAQUETES.md) documenta niveles, ofertas explícitas, pagos y elección pendiente. Los paquetes aleatorios revelan sus stickers y los llevan automáticamente hasta el termo; se puede omitir la animación. Con movimiento reducido se muestran estáticos. Los paquetes de elección muestran tres tarjetas ilustradas con nombre, nivel y efecto; tocar una otorga solo ese sticker. La compra se guarda antes de animarse y cerrar/reabrir la selección conserva las mismas opciones sin volver a cobrar. Revisión visual y de interacción: `godot --path . --script res://tests/sticker_pack_review.gd`. D02 sigue pendiente; la campaña usa valores provisionales explícitos.

El [contrato de monedas e inventario](docs/MONEDAS-E-INVENTARIO.md) documenta definiciones e instancias, límites, consumo y contextos. Capturas revisadas: test-results/monedas-inventario.png, moneda-inspeccion.png y monedas-limites-tienda.png. Las ocho monedas actuales ya usan este modelo en la tienda normal; D03 conserva el catálogo futuro.

El [contrato de tienda por secciones](docs/TIENDA-POR-SECCIONES.md) documenta distribución, stock identificado, tablas y renovación aislada. Capturas revisadas: test-results/tienda-monedas-cuatro.png, tienda-componentes.png, tienda-numeros.png y tienda-stickers.png. D01/D02/D04 siguen pendientes; compras con objetivo en 12.

El [contrato de compras y objetivos](docs/COMPRAS-Y-OBJETIVOS.md) documenta selección, confirmación, cancelación, reemplazos y paquetes. Capturas revisadas: test-results/compra-reemplazo.png, compra-confirmada.png, compra-cara.png y compra-pack-eleccion.png. La UI provisional ya permite comprar cualquier oferta configurada; las tablas normales de otras familias siguen pendientes de datos comerciales.

El [contrato de interfaz e inspección](docs/INTERFAZ-E-INSPECCION.md) documenta cinco zonas de tienda simultáneas, fichas desplazables, marcas y controles de ratón/teclado. Capturas revisadas a 1280×800 y 1440×900 mediante tests/interface_review.gd, con prefijos de resolución en test-results.

Las capturas **test-results/doble-par.png** y **test-results/doble-par-anotado.png** fueron revisadas. Se regeneran ejecutando Godot con el guion **res://tests/visual_review.gd**, sin modo headless. Sus resultados controlados son exclusivos de pruebas y no se introducen en la partida normal.

## Estructura

- **scripts/rules.gd:** reglas puras de categorías, puntuación, monedas y recompensas.
- **scripts/game.gd:** estado y transiciones de la partida.
- **scripts/main.gd:** interfaz, mesa, libreta, tienda y resultados.
- **scripts/die.gd**, **drop_zone.gd**, **backdrop.gd**, **coin_art.gd:** representación y controles.
- **tests/run_tests.gd:** pruebas de reglas, recorrido e interfaz.

La estética recuperada utiliza el club argentino, paño bordó, vaso de cuero con sol, libreta, monedas y dados de marfil. Los respaldos de iteraciones visuales permanecen en **backups/**.



