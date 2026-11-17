# Tutorial

Contrato del 17/11/2026 (ficha [TU-tutorial](pasos/TU-tutorial.md), fases TU4–TU8, decisión D18). Requerimientos del autor en [fuentes/REQUERIMIENTOS-TUTORIAL-2026-11-17.md](fuentes/REQUERIMIENTOS-TUTORIAL-2026-11-17.md). Todos los textos, cifras y el guion son **datos** en `scripts/tutorial_script.gd`.

## Qué es

Una jugada de un solo nivel, idéntica en objetivos al nivel 1: **40** (rival 1), **70** (rival 2) y **125** (jefe: El Vendedor). Se pregunta en cada jugada nueva; no existe «Saltear tutorial». Como toda jugada, no se guarda: abandonarla no da el logro ni la moneda.

- `Game.begin_tutorial()` arma los tres encuentros fijos (`TutorialScript.ENCOUNTERS`), sin campaña ni sorteo de jefes, y marca `Game.tutorial`. Es estado en memoria: no entra en `snapshot()`. Usa las tablas de tienda del perfil de prueba (`ValidationProfile.apply`), igual que la campaña.
- «Ir a otro nivel» no aparece (no hay campaña).

## Carteles

- `scripts/tutorial_overlay.gd`: una capa con un cartel de texto junto a cada zona (`TutorialScript.ZONES`, coordenadas lógicas 1440 × 900). **Un solo «Continuar»** cierra todos los de una pantalla informativa (tienda, jefe); después queda un botón **«?»**. Los pasos de acción (primer encuentro) no tapan nada ni piden «Continuar»: el cartel dice qué tocar, los dados a elegir brillan (`highlight`) y se avanza haciéndolo.
- El **paso actual** se calcula del estado visible (`TutorialScript.step(ctx)`: fase, encuentro, mano, tiradas, grupos, dados en el vaso, selección), no se guarda. `Main.tutorial_seen` recuerda qué carteles ya se cerraron en la jugada.
- **Acciones obligatorias**: cada paso lista las acciones permitidas (`allow`); las demás quedan bloqueadas (botones deshabilitados y atajos de teclado ignorados), el mismo patrón con que los jefes bloquean movimientos. Los pasos que piden una selección exacta (`to_cup_select`, `group_select`) solo dejan «Al vaso» / «Armar grupo» con esos dados. «Desarmar» no aparece.

## Recorrido

1. **Presentación**: el vendedor de la tienda con su burbuja «Veo que querés desafiar a Dios. Él no juega a los dados, pero quizás puedas vencerlo.». El texto se escribe de a poco, el cartel se mece y suena un cue `speak` (`PresentationAudio`); sin animación o con «Reducir movimiento» sale todo junto.
2. **Primer encuentro (40), guionado**: `TutorialScript.ROLLS` fija los valores de cada tirada (mano 1: `4 4 2 6 3` → se tiran los tres últimos → `4 1 5`, trío de cuatros; mano 2: `6 6 3 3 2` → se tira el último → `3`, full). Enseña tirar, elegir dados, mandarlos al vaso, volver a tirar, armar el grupo, anotar (la previsión de la libreta coincide con lo anotado en cada paso) y jugar la segunda mano. Las tiradas guionadas **no gastan azar** de la jugada y solo valen con `Game.tutorial` en el encuentro 1; se llega a 40 sin falta.
3. **Elección**: la tienda es obligatoria («Seguir sin tienda» deshabilitado).
4. **Tienda guiada**: se entra con **$20** (`SHOP_CASH`), con una **semilla fija** (`SHOP_SEED`, que no toca el azar principal ni cambia aunque la partida tenga monedas desbloqueadas). Hay un cartel por sección: stickers, números y caras, componentes (gemas, elementos y material) y monedas, más la plata y el botón de seguir. Para elegir otra tienda: `godot --headless --path . --script res://tools/tutorial_shop_seeds.gd -- 1 60` lista lo que ofrece cada semilla; el autor elige y se cambia la constante. (La elegida, 2, muestra una gema, un elemento, una cara, una mejora de número, un sticker y monedas; **falta la elección o aprobación del autor**.)
5. **Segundo encuentro (70)**: sin guía y con azar normal.
6. **Jefe: El Vendedor (125)**. Poder «Se queda con todo»: al cerrar el encuentro el dinero queda en 0 (`Game.close_encounter`, `payout.drained` guarda cuánto se llevó). No da recompensa. Es una fila aparte, `BossCatalog.TUTORIAL_BOSS`, que **no está en `ROWS`** (no entra al sorteo de la campaña ni a sus conteos); el poder `cash_drain` está en `BossCatalog.POWERS`. Carteles: cada jefe tiene su mecánica y se puede tocar su mano para verla. La mano usa la mano común del fondo (el arte propio del vendedor queda para el pase artístico).
7. **Fin** (ganando o perdiendo un encuentro; no si se abandona): la jugada termina, la partida suma el logro «Tutorial completado» y desbloquea «El regalo del vendedor». Pantalla de cierre que lo anuncia (`Main.render_tutorial_end`). No suma jugadas ni victorias.

## Logros y monedas bloqueadas

- `scripts/achievements.gd`: logros como datos (`DATA`: nombre, texto y qué monedas desbloquean). Hoy solo `tutorial_completed`; la estructura permite sumar más.
- **Monedas bloqueadas** (`Coins.LOCKED`): `Shop.generate(..., unlocked)` no ofrece una moneda bloqueada (ni suelta ni dentro de un paquete) salvo que la partida la haya desbloqueado (`Game.unlocked_coins`, que carga la interfaz al empezar la jugada). Hoy la única es C58; todas las demás siguen disponibles como siempre.
- **C58 «El regalo del vendedor»** (`vendor_gift`): pasiva rara (precio 6, reventa 3), «todas las monedas sueltas de la tienda cuestan $1 menos». **Se acumula** (`Coins.STACKABLE`: puede haber varias copias; es la única pasiva con esa excepción, `Shop.clean_passive_offers` y `Coins.can_store/can_replace` la respetan) y el precio **nunca baja de $1**. Orden (decisión 3): primero los porcentajes (Descuento C45, Descuento de visita U16), después se resta $1 por copia, piso de $1. **No abarata los paquetes de monedas ni las renovaciones** (decisión 2): `Game.offer_price(price, single_coin)` solo lo aplica a ofertas de moneda suelta; la tienda y la compra usan esa misma función, así el precio mostrado es el que se cobra. Arte: **ficha provisional** (`CoinArt.PROVISIONAL_ART`) hasta que el autor apruebe el boceto del «$ con flecha hacia abajo»; va al final de `Coins.DATA` para no mover las celdas de la hoja `coins-v4.png`.

## Pruebas

`tests/tutorial_tests.gd`: guion (cada paso permite algo, nada queda sin salida, bloqueos y selecciones), tutorial de punta a punta en `Game` y por la interfaz, tiradas guionadas sin gastar azar, tienda fija con $20, jefe vendedor, C58 (precios, piso, combinaciones, acumulación, bloqueo/desbloqueo), carteles («Continuar», «?»), logro y moneda tras el tutorial, abandono sin logro. `tests/tutorial_review.gd` genera capturas (GPU).

## Pendiente (no resuelto)

- Aprobación del autor: arte del menú en el bar, carteles, vendedor hablando y la moneda C58 (los bocetos del plan TU0 no se hicieron: se integró con el arte existente y una ficha provisional); semilla de la tienda; textos de los carteles.
- Sesión del autor jugando el tutorial dentro del juego.
- Marcar a mano en Notion las fases hechas (no hay sincronización) y actualizar la ficha F03 (metaprogreso: se abrió una parte acotada).
