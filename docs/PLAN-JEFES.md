# Plan de implementación — jefes temáticos

Diseño de contenido: [JEFES-TEMATICOS.md](JEFES-TEMATICOS.md) (18 jefes de los niveles 1 a 6 y las 3 reglas de Dios). Este plan lo lleva al juego en tres frentes:

1. **Agregar todos los jefes**: datos, poderes, objetivos y recompensas, con guardado y pruebas.
2. **Tocar la mano muestra el poder del jefe.**
3. **Manos con diseño propio** que combinen con el estilo actual del juego, que no destaquen de más y que no queden feas.

Estado: **fases A, B, D y E completas y F técnica hecha (04/11/2026)**; C (arte, espera aprobación del autor) y la calibración de P y k con simulador, más la sesión humana, pendientes. También publicado en la página de Notion «Bosses - project-dice - PRD». Convención del proyecto: una fase por vez, cada una en `feature/<nombre>` con PR contra `main`, suite verde antes de cerrar, resultado y límites en `ESTADO.md` y en el contrato del sistema. Todo número es provisional (D01/D02/D04/D07/D11).

> Las monedas nuevas ya están en `main` (PR #14). Las fases de jefes parten de `main` actualizado y tocan `game.gd`, `rules.gd`, `main.gd` y `save_*.gd`.

## 1. Cómo funciona hoy (lo que condiciona el plan)

| Pieza | Hoy | Consecuencia |
|---|---|---|
| `BossRules` | Una regla es `{id, name, kind, target}` (exactamente 4 campos). Tipos: `forbid_category` (solo Generala), `suspend_material`, `suspend_shell`, `suspend_coin` | Hay que ampliar tipos y objetivos sin romper los 4 campos de lo ya guardado |
| `Campaign` | `prototype()` arma 7 niveles con 3 candidatos de prueba (`prueba_l1_1`...) y tablas de 5 campos por candidato | Pasa a construirse desde un catálogo de datos con los 18 jefes y las 3 reglas de Dios |
| Elección | Se sortea 1 de 3 al entrar al nivel y se guarda el id en `selected_bosses`; no se re-sortea al cargar | Se mantiene |
| Contexto | `Game.boss_context()` solo está activo en `play`/`hand_result` de un jefe; `Rules.score(..., boss_context, coin_context)` lo recibe | Todo poder nuevo entra por ese contexto para que previsión y anotación coincidan |
| Guardado | Versión 7 con migraciones (`save_migrations.gd`) | Los jefes nuevos exigen v8 y migración de los ids `prueba_*` |
| Mano del fondo | `Backdrop` dibuja una sola mano (`mano-v3.png`: 8 cuadros de 61×53, dibujada a 122×106 en `Rect2(624, 34, ...)`) con `actor` común; Dios es un triángulo provisional | Hay que elegir sprite por jefe. No hay ningún botón sobre la mano: `Backdrop` ignora el mouse |
| Inspección | `main.gd` abre detalles con `present_detail(...)` (vaso, termo, dados, monedas) y botones transparentes sobre `Backdrop.*_RECT` | La mano usa el mismo patrón |
| Anuncio de regla | Texto en el encabezado, el recorrido y la nota del nivel (`BossRules.description`) | Hay que describir 21 poderes en lenguaje claro, en un solo lugar de datos |
| Presentación | `PresentationState.profile` usa `boss_rule.kind` como `actor` | Pasa a usar el id del jefe |

## 2. Decisiones que fijo para poder arrancar

Defaults míos. Los marcados **(confirmar)** conviene validarlos antes de la fase que los usa. Las decisiones del autor del 4 de noviembre de 2026 están marcadas como confirmadas.

1. **Catálogo como dato.** Un `scripts/boss_catalog.gd` con una fila por jefe: `id`, `level`, `name`, `hand` (id del sprite), `power` (id del poder), `power_name`, `power_text` (la explicación del jugador), `severity`, `k`. El objetivo es `P del nivel × k` redondeado a 5 y la recompensa es `8 + round((k−1)×20)` con piso 6; ambos se **escriben como datos** y un test comprueba que coinciden con la fórmula. No se calculan en juego ni se leen del inventario (decisión confirmada del PRD).
2. **Ids estables.** `l1_kioskero`, `l1_payador`, `l1_palomas`, `l2_cebador`... `l7_dios_dados`, `l7_dios_metales`, `l7_dios_carcasas`. Dios es un solo jefe con tres reglas.
3. **Sorteos del jefe sin tocar el azar principal.** Moneda expulsada, dado asustado, dado cargado, dado abducido, categoría de la mano 1 bloqueada: se derivan de `run_seed + nivel + mano + tirada` con un generador aparte, y el resultado va a `boss_state` en el guardado. Las semillas actuales no cambian y cargar no re-sortea.
4. **Estado del jefe en el guardado.** `boss_state` (diccionario chico: dados marcados, moneda expulsada, categoría bloqueada, termo robado sí/no). Se reinicia al cambiar de encuentro. Validado por `save_validator`.
5. **Relojero (6B).** Depende de F01 (monedas activas). Hasta que F01 exista, se implementa con *Ruleta* como reemplazo y queda anotado. **(confirmar)**
6. **Abducción (5A) y Locura (6C)** rozan «siempre cinco dados» y «la previsión coincide con la anotación». **Confirmados por el autor** (poder temporal de jefe, solo durante su encuentro).
7. **Termo robado.** Al vencer al jefe, el termo vuelve a su lugar flotando de la misma manera que se fue (recorrido inverso). **Confirmado por el autor.**
8. **Mano clickeable en todos los encuentros.** En un rival muestra el próximo jefe (la regla es visible desde la entrada al nivel, decisión confirmada); en el jefe muestra su poder.

## 3. Fases

Orden por dependencias. Cada fase deja el juego jugable y la suite en verde. Las fases B y C son independientes entre sí y de las de poderes: pueden hacerse en paralelo (la C, el arte, en otra sesión).

### Fase A — Catálogo, campaña y guardado (frente 1)

- Crear `boss_catalog.gd` con los 18 jefes + 3 reglas de Dios (nombres, textos, severidad, k, objetivo, recompensa).
- `Campaign.prototype()` genera niveles y candidatos desde el catálogo; se ajustan `valid`, `candidate` y `valid_progress` a la nueva forma (campo `hand` y `power`). Las etiquetas «Jefe de prueba» desaparecen.
- Guardado **v8**: migra ids `prueba_l{n}_{k}` a `l{n}_*` por nivel y posición, conserva `boss_rule` y el RNG exacto; v7 se respalda y nunca se sobrescribe un archivo inválido.
- Los poderes que **ya existen** quedan jugables desde acá: 1B Payador (Generala), 2C Referí (moneda expulsada, sorteada una vez), las 3 reglas de Dios. El resto muestra su texto y su objetivo pero aplica «sin efecto aún» **solo en builds de desarrollo**; no se publica un jefe sin poder.
- Pruebas: catálogo (3 por nivel, ids únicos, fórmula de objetivo y recompensa, textos no vacíos), migración v7→v8 con próxima tirada exacta, `campaign_tests` recorre los 21 encuentros con jefes del catálogo.
- Riesgo: bajo. Tamaño: M.

### Fase B — Tocar la mano muestra el poder (frente 2)

- `main.gd`: botón transparente sobre `Rect2(624, 34, 122, 106)` (y sobre el triángulo de Dios), con el mismo patrón que `inspect_thermos`. Respeta foco con teclado, texto alternativo y reducción de movimiento.
- Contenido del panel (de `boss_catalog`, no hardcodeado): nombre del jefe, nombre del poder, explicación en una o dos frases, objetivo y recompensa, y en jefes con sorteo propio el resultado ya conocido («Expulsada: Moneda Pares», «Dado asustado: se sortea cada mano»).
- En rivales: «Rival común: objetivo N. Próximo jefe: X · poder». Antes de entrar al nivel el anuncio sigue igual.
- Hover: cursor de mano y resalte mínimo; sin cambiar el aspecto del fondo.
- Mantener sincronía: encabezado, recorrido y panel leen del mismo texto.
- Pruebas: el botón existe en juego normal, en jefe, en rival y en Dios; el panel muestra el poder correcto de cada uno de los 21; no aparece en tienda ni menús; `tests/boss_hand_review.gd` captura a 1280×800 y 1440×900.
- Riesgo: bajo. Tamaño: S.

### Fase C — Manos con diseño propio (frente 3)

Reglas de diseño para que combinen y **no destaquen**:

- **Misma silueta y misma animación.** Parte de `mano-v3.png`: los 8 cuadros de 61×53 no se redibujan; se repinta por rampa de color y se agregan objetos chicos (respetar el diseño original, limpiar y no rediseñar).
- **Paleta del juego.** Cada mano usa una rampa de 4–5 tonos derivada de la paleta de `pixel-v3` (cuero, bronce, tela, verde de fieltro), con saturación contenida. Nada de brillos, halos ni dither de luz alrededor.
- **Un objeto por mano, de 8–14 px lógicos**, de 3–4 colores y con el mismo contorno oscuro del arte del juego. Ocupa la zona de la muñeca o los nudillos, que se mueve poco. Los objetos en la punta de un dedo siguen una tabla de desplazamiento por cuadro medida de la mano base.
- **Sin fondos propios.** El ambiente ya existe (día, tarde, noche, cierre, espacio, agujero negro, cielo). Los bocetos de concepto con cielo y suelo no se usan en juego.
- **Nube igual**, salvo un detalle chico en 3A El Gótico (la luz proyectada sobre la nube, sin figura) que se prueba y se descarta si distrae.
- **Dios** no cambia: se conserva el triángulo con ojo.

Proceso (convención del proyecto): generar por código en `tools/art/make_jefes_manos.py` (parte de `make_jefes_bocetos.py`), una hoja `assets/art/pixel-v3/manos-jefes-v3.png` con una fila de 8 cuadros por jefe (18 filas), y escribir prompts/procedencia. **Primero capturas dentro del juego real** (la mano sobre cada ambiente, a 1× y a la escala de pantalla) en una página de Artifact para que el autor apruebe antes de integrar; recién después se commitea y se abre el PR. `Backdrop` elige la fila por id de jefe; con movimiento reducido usa el cuadro 0.

Criterios de aceptación: contraste de cada mano contra la ventana similar al de la mano común, legible a 1× sin zoom, y aprobación del autor en capturas reales. Los dados siguen protegidos (`PROTEGIDOS.sha256`).

- Pruebas: la hoja tiene 18 filas de 8 cuadros de 61×53; cada jefe del catálogo tiene fila; `presentation_tests` actualizado; captura por jefe y por ambiente.
- Riesgo: medio (gusto y legibilidad). Tamaño: L. Puede ir en paralelo.

### Fase D — Poderes por familia (frente 1)

Cada poder entra por `boss_context` y por un gancho en `Game` o `Rules`, con una prueba que verifique que la **previsión coincide con la anotación** y que el resultado se conserva al guardar y cargar.

| Familia | Jefes | Cambio principal | Dónde |
|---|---|---|---|
| Suspensiones nuevas | 2A Cebador (stickers), 3B Conde (fuego), 6B Relojero (ranura de moneda) | Nuevos `kind` `suspend_sticker`, `suspend_element`, `suspend_coin_slot` | `boss_rules.gd`, `rules.gd`, `game.gd`, UI de fichas |
| Prohibiciones y valor | 4B Patovica (Par y Doble par), 3C Lobizón (6 valen 0 de cara), 6A Horizonte (5 y 6 a la mitad), 2B Chamuyero (repetir vale 50 %) | `forbid_category` con más objetivos; modificadores de valor de cara; penalización por repetir | `Rules.score`, `Rules.category`, selección |
| Dados en la tirada | 1C Palomas (dado asustado), 4A Tahúr (dado cargado en 1), 4C Payaso (cara espejo), 3A Gótico (dado alto vale 1), 5B Farolero (máx. 3 conservados), 5A Visitante (dado abducido) | Ganchos en `roll()` y en el conservado; marcas visibles en el dado | `game.gd`, `die.gd`, `main.gd` |
| Memoria entre manos | 5C Computadora (categoría de la mano 1 bloqueada en la 2) | `boss_state` guarda la categoría | `game.gd`, validador |
| Economía | 1A Kioskero ($2 por anotación) | Cobro al anotar, con el aviso en pantalla y sin dejar saldo ilegal | `game.gd`, `purchases.gd` |
| Información | 6C Durmiente (previsión oculta) | Solo UI; la anotación no cambia | `main.gd` |

Orden sugerido dentro de la fase: suspensiones (barato), prohibiciones y valor, dados, memoria, economía, información. Una PR por familia. Cada dado afectado muestra una marca chica y el panel de la mano explica qué le pasó.

- Pruebas por poder: se aplica solo durante el jefe y solo a ese encuentro; la previsión coincide; el guardado a mitad de mano conserva el estado exacto; un jefe distinto no hereda el efecto; los 7 jefes con sorteo propio son reproducibles por semilla.
- Riesgo: alto en dados y memoria entre manos (tocan el flujo de tirada). Tamaño: L.

### Fase E — Animación del termo robado (Don Cebador)

- Al entrar al jefe 2A, el termo del fondo sube con ritmo suave hacia el cielo, con los stickers pegados, y queda flotando junto a la mano con un leve vaivén. Reduce a un cuadro final con movimiento reducido o apagado.
- Es presentación pura: `PresentationState.observe` dispara el cue una sola vez; al cargar una partida en medio del jefe aparece directo en su posición final, sin repetir la animación. Mientras flota, el botón del termo abre un detalle que explica el robo.
- Al vencer al jefe, el termo vuelve a la mesa con el recorrido inverso, flotando igual que al irse (confirmado).
- Pruebas: estado final correcto al cargar, no se repite, respeta movimiento reducido. Riesgo: bajo. Tamaño: S.

### Fase F — Integración, balance y cierre

- Modo de desarrollo para forzar un jefe por id (como «Nivel-corto»), para jugar y probar cada uno.
- `campaign_tests`: recorrido de los 21 encuentros con cada jefe forzado al menos una vez.
- Calibrar `P` y `k` con el simulador/Validar-nivel (F02); ajustar solo datos.
- Actualizar `ESTADO.md`, `docs/REGLAS-DE-JEFE.md`, `docs/CAMPANA-HASTA-DIOS.md`, `docs/DATOS-DE-PRUEBA-CAMPANA.md` y `docs/JEFES-TEMATICOS.md`; avisar que el tablero de Notion debe actualizarse a mano.
- Sesión humana de juego: pendiente y no se da por hecha.

## 4. Mapa de los 21 jefes

| Jefe | Familia | Fase | Ya existe |
|---|---|---|---|
| 1A Kioskero | Economía | D | No |
| 1B Payador | Prohibición (Generala) | A | Sí |
| 1C Palomas | Dados | D | No |
| 2A Cebador | Suspensión de stickers + termo | D, E | No |
| 2B Chamuyero | Repetición | D | No |
| 2C Referí | Moneda expulsada | A | Sí |
| 3A Gótico | Dados | D | No |
| 3B Conde | Suspensión de elemento | D | No |
| 3C Lobizón | Valor de cara | D | No |
| 4A Tahúr | Dados | D | No |
| 4B Patovica | Prohibición (Par/Doble par) | D | Parcial |
| 4C Payaso | Dados | D | No |
| 5A Visitante | Dados | D | No |
| 5B Farolero | Dados | D | No |
| 5C Computadora | Memoria entre manos | D | No |
| 6A Horizonte | Valor de cara | D | No |
| 6B Relojero | Ranura de moneda (depende de F01) | D | No |
| 6C Durmiente | Información | D | No |
| 7 Dios (3 reglas) | Generala / metales / carcasas | A | Sí |

## 5. Riesgos y decisiones abiertas

- Las monedas nuevas comparten archivos con estas fases (`game.gd`, `rules.gd`, `main.gd`, `save_*.gd`): partir siempre de `main` actualizado y hacer una PR chica por vez.
- Los poderes de dados modifican el flujo de tirada: son la parte más delicada y la que más pruebas necesita.
- Legibilidad de las manos a escala real: se valida con capturas dentro del juego, no con los bocetos.
- Pendientes de diseño: nombres definitivos y revisión de parecidos con marcas o personajes ajenos (D10), y el esquema `P × k`. El nivel 3 queda como está.
- Fuera de alcance: nivel 8/CMD, vasos, metaprogreso, más de 5 dados, dos tiradas por mano.
