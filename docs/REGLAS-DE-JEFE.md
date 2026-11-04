# Reglas configurables de jefe — paso 17

Implementado el 26 de octubre de 2026. D09 resuelta por respuesta directa del usuario: **«Suspensión completa: sin poder, riesgo ni acumulación nueva; se mantienen los reinicios normales»**. El equipamiento se conserva; las futuras activas siguen recargando por eventos normales. Catálogo definitivo, nombres y objetivos de campaña D07 siguen pendientes.

## Definición, selección y alcance

`scripts/boss_rules.gd` valida definiciones simples: `id`, `name`, `kind` y `target`. El recorrido `level_encounters` define por separado identidad del encuentro, tipo normal/jefe y objetivo. La regla elegida `boss_rule` se guarda completa. No se usa la posición del rival para prohibir generala o activar poderes del jefe. El objetivo se obtiene del encuentro, sin adaptarlo al inventario.

`begin_run(seed, encounters, candidates)` valida entradas antes de reiniciar y elige una regla una sola vez al entrar al nivel. Un pool de varias reglas consume un sorteo reproducible; un pool de una sola regla no consume azar innecesario, manteniendo las semillas anteriores. Consultar recorrido, generar/renovar tienda, cargar o avanzar de rival no vuelve a elegir. No existe un botón de cambiar regla dentro de una sesión.

El contexto solo está activo durante `play`/`hand_result` de un encuentro marcado como jefe. Los rivales normales conservan el anuncio sin aplicar sus restricciones. Cerrar el jefe desactiva el contexto antes de cobro visible/reparación/tienda o victoria; el equipamiento queda intacto. Cada mano y encuentro sigue sus reinicios normales. Un jefe puede estar en otra posición en definiciones de prueba, y esa posición se respeta en objetivos, reglas y botón de avance de tienda.

El pool normal sigue teniendo únicamente la regla conocida **Generala prohibida**, con el recorrido 40 → 70 → 110. Las suspensiones tienen motor y definiciones de prueba; no se inventó ni habilitó un catálogo de 18 jefes finales. El perfil de validación conserva sus datos y el mismo jefe normal.

## Reglas soportadas

| Tipo | Objetivo | Efecto durante el jefe |
|---|---|---|
| `forbid_category` | Generala | Rechaza cinco iguales agrupados como generala; permite trío + par explícitos |
| `suspend_material` | Acero, cobre o ambos | No aportan poder ni ganan acumulación nueva; conservan pieza y reinicios normales |
| `suspend_shell` | Una gema o todas | No aportan poder y no se sortean sus roturas; las otras gemas siguen funcionando |
| `suspend_coin` | Una moneda o todas | No aportan pasiva/impulso ni se pueden consumir; permanecen equipadas o guardadas |

Las restricciones se comprueban en operaciones, anotación y cálculo puro, no solo en botones. `Rules.score(..., boss_context)` rechaza grupos prohibidos aunque se hayan introducido sin pasar por la selección de UI. La previsión de selección y el puntaje final reciben el mismo contexto. La suspensión no borra ni reemplaza instancias, caras, mejoras, stickers o efectos de otras familias.

## D09: acumulaciones, riesgo y reinicios

- Acero conservado no gana +3 mientras está suspendido. Si se relanza, el reinicio propio sigue borrando su bono, incluso durante suspensión.
- Cobre no gana +0,5 al relanzarse suspendido. Los contadores existentes no se borran solo por suspenderlo; el cálculo los ignora mientras dura la regla.
- Cambiar de mano conserva los contadores de encuentro y reinicia los de mano. Cambiar de encuentro reinicia los metales como siempre. La suspensión no congela esos reinicios ni permite arrastrar bonos a encuentros nuevos.
- Tierra/viento y los otros elementos siguen sus reglas cuando se suspende un material: son familias independientes.
- Una carcasa suspendida no aplica esmeralda/zafiro/rubí/diamante y no consume sorteos RNG de rotura. Se registra la mano ya procesada incluso si no hay carcasas elegibles. La suspensión no repara una carcasa previamente rota ni rompe una intacta.
- Al cerrar el jefe vuelve el poder de la pieza intacta. El riesgo vuelve a aplicarse en anotaciones futuras fuera de suspensión. La reparación opcional D08 conserva la selección, costo y posibilidad de deuda, incluidas carcasas que ya estaban rotas antes del jefe.
- Contrato reservado `cooldown_can_advance`: una activa suspendida seguirá recargando por eventos normales. F01 implementará poderes, contadores y rescates concretos; no se agregaron activas ficticias al catálogo inicial ni se definieron rescates no aprobados.

## Interfaz

El anuncio del nivel, encabezado y Recorrido muestran la definición elegida. Las fichas de dado/moneda explican la suspensión; el aviso del dado aparece al principio para que no quede oculto bajo probabilidades y estadísticas. Las monedas muestran SUSP sin perder su espacio y los consumibles suspendidos quedan deshabilitados. El desglose de una carcasa suspendida indica poder inactivo y ausencia de riesgo. La ayuda deja la prohibición de generala como regla condicional y dirige al recorrido actual.

## Guardado v2 y compatibilidad

El sobre pasa a **versión 2** para persistir `level_encounters` y `boss_rule`. Las rutas históricas se mantienen: `partida-v1.json` y `validacion-nivel-v1.json` son nombres estables de archivo; el nombre no cambia la versión real del sobre. No se mueve ni se descarta el guardado del usuario al actualizar.

Se admite una migración conocida desde v1: se añaden en memoria el recorrido histórico y Generala prohibida, sin sortear ni modificar semilla, estado RNG, ofertas, decisiones o cobros. Leer no sobrescribe el original. El siguiente checkpoint publica v2 y conserva el v1 como respaldo. Definiciones desconocidas o incoherentes se rechazan; no se sustituyen por una regla aleatoria. Versiones futuras siguen protegidas. El marcador de sesión cerrada mantiene su función y no permite revivir una partida terminada.

## Evidencia

- Suite: **1598 comprobaciones aprobadas, cero fallos** (1553 anteriores + 45 nuevas); `tests/boss_tests.gd`, informe `boss_demo` en `test-results/tests.json`.
- Prohibición fuera de la posición final y generala permitida en un rival normal final; cálculo y anotación rechazan grupos ilegales introducidos directamente.
- Elección reproducible entre dos reglas explícitas, anuncio estable durante rivales/tienda/carga/renovación, activación por avance real de UI y restauración al cerrar el jefe.
- Moneda suspendida conserva instancia y espacio; otra moneda sigue aportando; consumible no se consume; acero/cobre no acumulan y mantienen reinicios; tierra/viento independientes.
- Cuatro poderes de gemas apagados, ningún sorteo de riesgo durante suspensión completa; suspensión dirigida conserva riesgo de otras gemas. Poderes/riesgos vuelven al terminar y las roturas previas no se reparan automáticamente.
- Migración v1 sin escritura ni sorteo al leer, próxima tirada exacta, primer checkpoint v2 con respaldo v1 y rechazo de regla guardada desconocida. Reapertura del formato actual en procesos independientes conserva estado y próxima tirada exactos.
- Ocho capturas por resolución a 1280×800 y 1440×900 mediante `tests/boss_review.gd`; ambos procesos terminaron sin errores. Anuncios, moneda equipada/ficha, carcasa, recorrido, desglose y consumible bloqueado. Prefijos `1280x800-jefe-` / `1440x900-jefe-`.

## Límites y siguiente paso

No se cambia el balance provisional D01/D02/D04 ni se declara sesión humana realizada. D09 queda resuelta para materiales y carcasas actuales; rescates/activas concretas permanecen en F01. D07 conserva el catálogo de jefes, objetivos y recompensas definitivos. El paso 18 puede preparar la campaña técnica con datos provisionales etiquetados, pero su aceptación de contenido requiere ese catálogo.

## Catálogo y estado del jefe (plan de jefes, fase A — 04/11/2026)

- **Catálogo:** `scripts/boss_catalog.gd` es la fuente de los 21 jefes (18 de los niveles 1 a 6 y las 3 reglas de Dios). Una fila tiene id estable (`l1_kioskero`, ..., `l7_dios_dados`), nivel, posición, nombre, mano, poder, texto, severidad, k, regla (`kind`/`target`) y `implemented`. Objetivo = P del nivel × k redondeado a 5 (P = 110, 160, 230, 320, 440, 600, 800); recompensa = 8 + round((k − 1) × 20), piso 6. Dios usa los objetivos fijos 800/850/900 y recompensa base 8. Todo provisional.
- **Regla:** sigue siendo `{id, name, kind, target}` (4 campos). Se agrega el tipo `boss_power`, cuyo `target` es un poder propio listado en `BossCatalog.POWERS`; el id de la regla es el id del jefe y el nombre es el del poder.
- **Contexto:** `BossRules.context(rule, active, state)` es la única entrada de los poderes. La tarjeta roja del Referí se traduce a una suspensión de la moneda expulsada, de modo que previsión, anotación y botones leen lo mismo.
- **`boss_state`:** sorteos propios del jefe (hoy `{"coin": id}` para el Referí; `""` si no hay monedas equipadas). Se calcula al empezar el encuentro con un generador aparte derivado de semilla + nivel + encuentro + poder, nunca toca el azar principal, se guarda tal cual y no se vuelve a sortear al cargar. Fuera de un jefe con sorteo propio debe ser `{}`.
- **Sorteo del jefe del nivel:** entre los candidatos con poder implementado; en builds de desarrollo (`Game.development_bosses`) entran todos. Si un nivel no tiene ninguno listo se usa el pool completo.
- **Guardado v8:** migra los ids `prueba_l{n}_{k}` por nivel y posición, reconstruye campaña, encuentros y regla desde el catálogo y no toca semilla ni estado del azar. v7 se respalda al primer checkpoint nuevo; ids desconocidos se rechazan sin tocar el archivo.
- **Pruebas:** `tests/boss_catalog_tests.gd` (catálogo contra la tabla del PRD, campaña, filtro de lanzamiento, tarjeta roja, migración v7 a v8).

## Mano clickeable (plan de jefes, fase B — 04/11/2026)

La mano del fondo (`Backdrop.HAND_RECT`) y el triángulo de Dios (`Backdrop.GOD_RECT`) llevan un botón transparente `InspectBoss` fuera de la tienda. `BossInfo.panel(game)` arma título y texto desde el catálogo y el estado del jefe (`boss_state`); es de solo lectura. Pruebas: `tests/boss_panel_tests.gd`; capturas: `tests/boss_hand_review.gd`.
