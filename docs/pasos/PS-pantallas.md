# PS — Pantallas y diseños

Ítem 6 de los pendientes post-paso 20 · 24 de noviembre de 2026.

**Estado actual:** PS0–PS7 implementados (PS2–PS7 juntos en `feature/pantallas`, a pedido del autor). Falta la prueba del autor dentro del juego y un boceto propio para Colecciones (ver `ESTADO.md`).

## Objetivo
Menú inicial sobre la mesa, pantalla de selección de encuentro (con tienda a la que se entra varias veces), cobro sin desglose, ayuda de la mano del jefe debajo de la mano y Colecciones. Decisiones en `DECISIONES.md` (D20).

## Pasos

| Paso | Rama | Qué | Necesita antes |
| --- | --- | --- | --- |
| PS0 | `feature/pantallas-preparacion` | Ficha, decisiones y generador de bocetos | — |
| PS1 | `feature/partida` | «Partida» en toda la UI; el metaprogreso pasa a «progreso» | PS0 |
| PS2 | `feature/menu-en-la-mesa` | Menú sobre el paño 1, modos y tutorial en el paño 2, mano oculta, fondo sin interacción salvo el mate | PS1 |
| PS3 | `feature/entre-encuentros` | Fase `lobby` en `game.gd`, cobro → reparación → selección, tienda con varias entradas | PS1 |
| PS4 | `feature/seleccion-encuentro` | Pantalla de selección de encuentro | PS3 |
| PS5 | `feature/cobro-simple` | «+$total» y Continuar | PS4 |
| PS6 | `feature/ayuda-mano-jefe` | Recuadro de ayuda debajo de la mano | PS0 |
| PS7 | `feature/colecciones` | Colecciones (ficha aparte, con boceto propio) | PS2 |

Cada paso: rama desde la anterior o desde `main`, pruebas nuevas en `tests/run_tests.gd`, suite sin fallos nuevos, capturas con un `*_review.gd`, registro en `ESTADO.md` y PR contra `main`.

## No se negocia
- Entrar y salir de la tienda o mirar Colecciones no consume azar de la partida.
- «Continuar partida» restaura exacto, sin volver a sortear el stock.
- El tutorial y La Semilla siguen funcionando de punta a punta.
- Se respetan «Reducir movimiento», la velocidad y la navegación con teclado.
- No se cambia el arte de la mesa ni de los dados.

## Bocetos
Página: https://claude.ai/artifact/88nJDsVTnGX6u2urfwMGd1 (aprobada por el autor el 24/11/2026 junto con el plan).
Generador: `tools/art/bocetos-pantallas/bocetos_review.gd` (propuestas) y `base_review.gd` (estado anterior). Se corren sin `--headless`; los PNG quedan en esa carpeta y no van a Git.

## Plan completo
https://app.notion.com/p/423c28142b558008bee4c30a69584556
