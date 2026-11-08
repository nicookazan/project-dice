# Inventario de texturas (TX5)

Relevamiento del 7 de noviembre de 2026 sobre `main`. Hay **76 PNG** en `assets/art/` (con las máscaras de metales de TX3). **Todas las marcas son una propuesta**: la marca final de cada textura la pone el autor. Con «sin cita» se indica que ningún script de `scripts/` nombra el archivo; no significa que sobre (algunos se cargan por patrón, otros son referencia o materia prima de un generador).

Marcas: **Final** (aprobado por el autor, no se toca), **Placeholder** (provisorio, se reemplaza en TX6), **A rediseñar** (hay que rehacerlo), **Referencia** (no se usa en el juego, se conserva como origen), **Verificar** (falta comprobar si todavía se ve).

## Dados, elementos y metales

| Archivo(s) | Uso | Propuesta |
| --- | --- | --- |
| `dice-faces-v1/*` (6 PNG) | Caras negras y de gema, protegidas (`PROTEGIDOS.sha256`) | Final |
| `pixel-v3/elementos-v3.png` | Capa de elementos de los dados (TX1) | Final, a confirmar en el juego |
| `pixel-v3/metales-mascaras-v3.png` | Máscaras de hierro oxidado y cobre oxidado (TX3) | Final, a confirmar en el juego |
| `ivory-die-v3.png`, `ivory-die-front-v4.png`, `dice-master-v1/*` (4 PNG) | Diseño maestro y reglas de los dados; sin cita | Referencia |

## Salón, mesa y exteriores

| Archivo(s) | Uso | Propuesta |
| --- | --- | --- |
| `pixel-v3/salon-v3.png`, `mesa-v3.png`, `terciopelo-v3.png`, `parteluces-v3.png`, `nube-v3.png` | Salón, mesa, paño, ventanas, nube | Final, a confirmar |
| `pixel-v3/exteriores-v3.png` | Seis ambientes detrás de las ventanas; TX2 los anima | Final, a confirmar |
| `pixel-v3/guardianes/*` (3 PNG) | Guardián del triángulo de Dios | Final, a confirmar |
| `club-table-v2.png`, `shop-table-v1.png`, `environment-v2/mesa-libreta-frontal-v1.png`, `mesa-proporciones-v3.png`, `vaso-cuero-negro-mesa-v2.png`, `vaso-cuero-negro-tienda-v1.png` | `backdrop.gd` los carga todavía; buena parte quedó tapada por `pixel-v3` | Verificar y limpiar |
| `environment-v2/exteriores-v2.png`, `escenarios-1-4.png`, `escenarios-5-8.png`, `termo-v1.png`, `vaso-cuero-negro-mesa-v1.png` | Sin cita; `exteriores-v2` es materia prima de `make_exteriores.py` | Referencia (no borrar sin revisar) |

## Vaso, termo, mate, stickers e interfaz

| Archivo(s) | Uso | Propuesta |
| --- | --- | --- |
| `pixel-v3/vaso-v3.png`, `vaso-frente-v3.png`, `vaso-brillo-v3.png`, `termo-v3.png`, `termo-mesa-v3.png`, `mate-v3.png` | Vaso, termo, mate | Final, a confirmar |
| `pixel-v3/stickers-v3.png`, `stickers-termo-v3.png`, `aro-*-v3.png` (incluye seis `aro-sticker-*`, que se cargan por patrón en `sticker_tip.gd`), `bandera*-v3.png` | Stickers y aros de interfaz | Final, a confirmar |
| `pixel-v3/ui/*` (8 PNG), `tienda-iconos-v3.png`, `mano-v3.png` | Botones, paneles, íconos, mano de Dios | Final, a confirmar |

## Manos de jefes y poses

| Archivo(s) | Uso | Propuesta |
| --- | --- | --- |
| `pixel-v3/manos-jefes-v3.png` | 18 manos de jefe. Dudas de contraste en El Gótico y El Horizonte | Falta aprobación |
| `pixel-v3/manos-poses-v3.png` | Piedra, papel y tijera; el puño está a revisar | Falta aprobación |

## Monedas

| Archivo(s) | Uso | Propuesta |
| --- | --- | --- |
| `pixel-v3/coins-v3.png` | Monedas de la primera tanda (ya no se carga: TX9 la reemplaza con `coins-v4.png`) | Sobra cuando el autor apruebe TX9 |
| `pixel-v3/coins-nuevas-v3.png` | Monedas nuevas del paquete; las 51 sin arte propio usan la moneda en blanco con abreviatura | Placeholder (pase de arte pendiente) |
| `coins-v2.png` | Atlas anterior; sin cita | Referencia |

## Tienda y vendedor

| Archivo(s) | Uso | Propuesta |
| --- | --- | --- |
| `pixel-v3/tienda-v3.png` (generado por `make_tienda.py` y `vendedor.py`) | Tienda y vendedor. **El vendedor se parece a una persona real: bloquea publicar** | A rediseñar (TX7) |
| `shop-salesman-v1.png`, `shop-items-v1.png` | Materia prima y referencia de la tienda; sin cita | Referencia; sacar `shop-salesman-v1` al terminar TX7 |

## Cómo seguir

1. El autor marca cada fila (Final, Placeholder, A rediseñar o Referencia) y ordena por prioridad, con lo más visible primero.
2. De ahí salen TX6 (reemplazar placeholders, un PR por grupo) y la base visual del ítem 6 (pantallas).
3. Quedan por hacer, con capturas de cada pantalla: confirmar el uso real de las imágenes de «Verificar y limpiar» y revisar los 76 archivos uno por uno. Este relevamiento es por grupo, no textura por textura.
