# Campaña técnica de siete niveles — paso 18

Implementada y verificada con datos provisionales `hasta-dios-prueba-v1`. **1959 comprobaciones aprobadas, cero fallos**: 1598 anteriores y 361 nuevas. La campaña técnica está completa; catálogo definitivo D07, balance y validación humana siguen pendientes.

## Recorrido y datos

`scripts/campaign.gd` contiene siete niveles, cada uno con dos rivales y un jefe: **21 encuentros**. Los niveles 1–6 tienen tres candidatos propios (18 alternativos, de los que se enfrentan seis); Dios tiene tres reglas alternativas propias y se enfrenta una. Todos usan poderes ya implementados en 17 y suspensión D09. Nombres/objetivos/recompensas se fijaron para prueba en [DATOS-DE-PRUEBA-CAMPANA.md](DATOS-DE-PRUEBA-CAMPANA.md), sin convertirlos en catálogo final aprobado.

El objetivo de un rival procede de su nivel/posición; el del jefe y su recompensa base de la definición elegida. No se consulta el poder del inventario para ajustar dificultad. Los valores de prueba usan base $8, más las reglas previas de manos sobrantes, exceso e intereses. El motor acepta otra base explícita de jefe y la prueba verifica que se use ese dato.

Al entrar a un nivel se sortea uno de sus tres candidatos una sola vez, se guarda su ID y se anuncia. Consultar mapa, tirar, comprar, renovar o cargar no cambia el jefe ya anunciado. Los jefes futuros se anuncian cuando se entra a su nivel. El listado muestra los 21 lugares y sus estados, sin botones de salto.

## Flujo y conservación

Cada victoria que tiene otro encuentro pasa por cobro único, reparación opcional D08 y tienda. Después de un jefe intermedio, la tienda permite **Entrar al nivel siguiente**. Ese avance reinicia puntos, manos, tiradas, grupos y contadores de encuentro/mano; conserva los mismos cinco dados, caras, mejoras locales/globales, materiales, carcasas/roturas, elementos, vaso/stickers, monedas/instancias, consumibles y saldo resultante. La suspensión anterior termina y la nueva regla queda anunciada para el siguiente jefe.

El nuevo nivel comienza en `level_intro`; avanzar abre solo su primer rival. Cambia el identificador y tinte del ambiente usando el arte existente: día, tarde, noche, cierre, espacio, agujero negro y cielo. Son señales provisionales; ventanas cubiertas, arte espacial, Dios triángulo/ojo, narrativa y audio finales corresponden a 19.

Vencer a Dios completa el encuentro 21. Si hay reparaciones pendientes se resuelven antes de `won`. No hay tienda posterior, nivel 8 ni modo sin fin. Ganar, perder o abandonar publica el cierre de sesión para que un respaldo previo no la resucite.

## Inicio y compatibilidad

- **Jugar.cmd / F5:** las nuevas partidas empiezan la campaña completa con aviso de contenido provisional y tablas de todas las familias del perfil de prueba. Cuero, cinco dados base, cero monedas y $0; sin tienda inicial.
- **Nivel-corto.cmd / `-- --short-run`:** conserva el recorrido histórico corto con tablas anteriores. Usa la misma ranura normal; reemplazar una partida activa pide confirmación y conserva archivos históricos.
- **Validar-nivel.cmd / `-- --validation-profile`:** mantiene el nivel corto de validación con su archivo separado.
- Los guardados antiguos continúan siendo partidas cortas; cargarlos no los expande a 21 encuentros. El modo de Continuar se obtiene de los datos guardados.

El formato es **v3**: guarda campaña completa, nivel actual, jefes elegidos por nivel y lista ordenada de encuentros completados, junto con todo el estado previo. Se valida que el jefe pertenezca a su nivel, los objetivos/regla actuales coincidan con esa definición y los encuentros completados formen exactamente el prefijo permitido. Una carga inconsistente se rechaza, no se arregla resorteando o saltando.

V1 y v2 se migran en memoria como nivel corto, sin alterar RNG, ofertas, decisiones ni cobros. Leer no modifica el original; el siguiente checkpoint publica v3 con respaldo. Nombres de archivo históricos estables: `partida-v1.json` normal y `validacion-nivel-v1.json` para el perfil corto. El nombre de archivo no es la versión del sobre.

## Pruebas

`tests/campaign_tests.gd` recorre por controles de UI los **21 encuentros**, con **seis fronteras de nivel** y **seis reparaciones**. Se guarda/reanuda en anuncios, manos agrupadas, cobro, reparación seleccionada y tienda. Cada transición se compara con un clon que avanza sin interrupción, incluido el siguiente sorteo de jefe y su estado RNG. Las 21 previsiones coinciden con las anotaciones. Una segunda pulsación de cobro no repite premio ni progreso.

Ese recorrido es un **laboratorio**, no una prueba de balance: semilla 600, mejora global explícita +250 al 4 y cartera inicial de prueba $100. Compra por UI cara, mejora local, acero, tierra, rubí, sticker de trío y moneda Pares. Se comprueba su conservación entre niveles y el borrado de contadores/puntos. Esas ayudas no se activan en una partida normal. Los resultados completos están en `campaign_demo.trace` y `comparisons` dentro de `test-results/tests.json`.

Derrotas controladas en nivel 1/encuentro 1, nivel 4/encuentro 2 y Dios conservan respectivamente 0, 10 y 20 encuentros completados, no conceden recompensa del encuentro fallido y no abren tienda ni permiten avanzar. Se prueban definiciones inválidas, jefe ajeno al nivel y progreso con saltos. El jefe final no abre una salida al nivel 8.

La regresión del nivel corto conserva sus expectativas anteriores usando modo corto explícito en las escenas de prueba. `tests/campaign_smoke.gd` verifica por separado el comportamiento nuevo por defecto del menú: siete niveles, 21 lugares, tablas provisionales y cero plata/monedas/mejoras iniciales. La reanudación del formato actual entre dos procesos independientes también conserva la siguiente tirada exacta.

`tests/campaign_review.gd` produjo **diez capturas por resolución**, 1280×800 y 1440×900; ambos procesos terminaron sin errores. Menú, anuncio inicial/siguiente/reanudado, tienda tras jefe, listado de 21, noche, Dios y finales de victoria/derrota. Prefijos `test-results/1280x800-campana-` y `1440x900-campana-`. La reanudación visual en frontera de nivel compara el snapshot completo. Las escenas avanzadas usan el laboratorio explícito.

## Archivos y límites

Campaña/datos: `scripts/campaign.gd`. Transiciones/guardado: `scripts/game.gd`, `scripts/save_store.gd`, `scripts/save_validator.gd`. Presentación: `scripts/main.gd`, `scripts/backdrop.gd`. Recompensa: `scripts/rules.gd`. Lanzador corto: `Nivel-corto.cmd`. Pruebas: `tests/campaign_tests.gd`, `tests/campaign_smoke.gd`, `tests/campaign_review.gd`, integración del runner y adaptación explícita de escenas cortas anteriores.

D07 no se declara resuelta; las 18 identidades alternativas y tres de Dios son etiquetas de prueba. D01/D02/D04 conservan balance final pendiente. La campaña natural completa todavía necesita partidas humanas y ajustes de 20; no se deduce duración ni tasa de victoria de los ensayos de laboratorio. D09 se conserva. Siguiente paso recomendado: **19 — Ambientes, narrativa breve, audio y accesibilidad**, con D10 por definir.
