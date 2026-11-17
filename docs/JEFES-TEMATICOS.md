# Jefes temáticos — borrador de diseño (D07)

**Estado: borrador v2, en revisión con el autor.** Propone los jefes de los niveles 1–6 (3 por nivel, se enfrenta 1 por nivel) y las 3 reglas de Dios (nivel 7). Los nombres son originales e *inspirados* en arquetipos conocidos (no usar marcas ni personajes con licencia tal cual; D10). Reemplaza, cuando se apruebe, las etiquetas de prueba de `DATOS-DE-PRUEBA-CAMPANA.md`. Todos los números son provisionales (D01/D02/D04/D11).

## 1. Identidad visual (decisión confirmada)

- Niveles 1–6: **todos los jefes son manos que salen de la nube**, distinguidas por textura, objetos, gestos y efectos. Sin cuerpos completos.
- Nivel 7: **Dios es un triángulo con un ojo**, siempre el mismo jefe. Lo que se sortea son sus tres reglas.
- Cada fondo es el ambiente del nivel; la mano y su objeto deben comunicar el poder.

## 2. Cómo se fija la exigencia

Coherente con lo confirmado en el PRD («cada jefe o regla tiene su objetivo prefijado; no se adapta al poder del jugador»): cada nivel tiene una **potencia esperada `P`**, una tabla de datos con lo que debería poder hacer un jugador razonable con el poder que se espera en ese nivel. No se lee el inventario.

`objetivo del jefe = P del nivel × k del jefe`, redondeado a múltiplos de 5.

`k` compensa la severidad del poder: poder leve → k alto; poder duro → k bajo. Los tres jefes de un nivel quedan con dificultad parecida pero castigan builds distintos.

| Severidad | k | Recompensa base |
|---|---|---|
| ● leve | 1,15 – 1,20 | $11 – $12 |
| ●● media | 1,05 – 1,10 | $9 – $10 |
| ●●● fuerte | 0,95 – 1,00 | $7 – $8 |
| ●●●● muy fuerte | 0,85 – 0,90 | $6 |

Recompensa = $8 + round((k − 1) × 20), piso $6. `P` provisional: 110 · 160 · 230 · 320 · 440 · 600 (niveles 1–6) y 800 (Dios). Calibrar con el simulador F02 / Validar-nivel.

Tipo de poder: **E** = ya existe en `boss_rules.gd`; **E+** = existe pero hay que ampliar el objetivo; **N** = regla nueva.

## 3. Catálogo

### Nivel 1 — Día (P = 110)
| | Jefe (mano) | Textura y objeto | Poder | Tipo | Sev. | Obj. | $ |
|---|---|---|---|---|---|---|---|
| A | **El Kioskero** | Mitones de lana, un billete arrugado y un paquete de chicles | *Impuesto al kiosco*: cada anotación te cobra $2 | N | ● | 125 | 11 |
| B | **El Payador Tramposo** | Cuero curtido con tientos, un as de espadas entre los dedos | *Con truco no hay generala*: Generala prohibida | E | ● | 130 | 12 |
| C | **El Rey de las Palomas** | Plumas grises, migas de pan y palomas posadas en los dedos | *Paloma ladrona*: en la primera tirada de cada mano una paloma se lleva un dado al azar al vaso (no se puede conservar; tiradas | N | ●● | 115 | 9 |

### Nivel 2 — Tarde (P = 160)
| | Jefe (mano) | Textura y objeto | Poder | Tipo | Sev. | Obj. | $ |
|---|---|---|---|---|---|---|---|
| A | **Don Cebador** | Yerba mate pegada a la piel; sostiene tu termo flotando entre los dedos | *Robo del termo*: te roba el termo, que flota hacia el cielo y queda suspendido mientras dura el jefe; sin termo, los stickers no aportan | N | ●●● | 160 | 8 |
| B | **El Vendedor Ambulante** (antes El Chamuyero) | Anillos y cadenas doradas de bijouterie, un cartel de «oferta» | *No te vendo dos veces lo mismo*: repetir en la mano 2 la categoría de la mano 1 vale 50 % | N | ●● | 175 | 10 |
| C | **El Referí del Domingo** | Césped en los nudillos, silbato y tarjeta roja | *Tarjeta roja*: una moneda al azar (sorteada al entrar al jefe) queda expulsada | E | ●● | 170 | 9 |

### Nivel 3 — Noche (P = 230)
| | Jefe (mano) | Textura y objeto | Poder | Tipo | Sev. | Obj. | $ |
|---|---|---|---|---|---|---|---|
| A | **El Gótico** | Guante de cuero negro; una luz potente proyectada sobre las nubes de fondo, sin ninguna figura dentro | *Sombra*: el dado más alto de la 1.ª tirada de cada mano queda valiendo 1 hasta relanzarlo | N | ●●● | 230 | 8 |
| B | **El Conde Sed** | Piel pálida, uñas largas negras, anillo de sello y copa de líquido rojo | *Fuego apagado*: elemento fuego suspendido | N | ●● | 255 | 10 |
| C | **El Lobizón** | Pelaje gris y garras, luna llena enorme detrás | *Maldición del séptimo hijo*: las caras 6 valen 0 de cara (las combinaciones no cambian) | N | ●●● | 220 | 7 |

### Nivel 4 — Cierre (P = 320)
| | Jefe (mano) | Textura y objeto | Poder | Tipo | Sev. | Obj. | $ |
|---|---|---|---|---|---|---|---|
| A | **El Timbero** (antes El Tahúr) | Fieltro verde de mesa, guante de crupier, fichas y dados cargados | *Dado cargado*: un dado al azar por mano queda fijo en 1, sin relanzar | N | ●●● | 305 | 7 |
| B | **El Patovica** | Cuero negro, brazalete STAFF, auricular y soga de terciopelo rojo | *Lista cerrada*: Par y Doble par prohibidos | E+ | ●● | 350 | 10 |
| C | **El Payaso** (antes El Payaso de la Risa Final) | Guante blanco con volados rayados, flor que echa agua, sonrisa pintada en la palma | *Cara espejo*: tras cada tirada, un dado al azar pasa a su cara opuesta (7 − x) | N | ●● | 335 | 9 |

### Nivel 5 — Espacio (P = 440)
| | Jefe (mano) | Textura y objeto | Poder | Tipo | Sev. | Obj. | $ |
|---|---|---|---|---|---|---|---|
| A | **El Visitante** (alien) | Piel verde lisa y brillante, tres dedos largos con ventosas, luz de rayo tractor en la palma | *Abducción*: un dado por mano es abducido y no cuenta (juegan cuatro) | N | ●●●● | 375 | 6 |
| B | **El Farolero Cósmico** (portador de anillo linterna) | Mano con un anillo que brilla en verde y crea construcciones de luz sólida (un farol) | *Carga del anillo*: solo se pueden conservar hasta 3 dados | N | ●●● | 420 | 7 |
| C | **La Sonda** (antes La Computadora de Bordo; nombre provisional) | Placas metálicas y cables; una lente roja en la palma que mira fijo | *Lo siento, no puedo permitirlo*: la categoría anotada en la mano 1 queda bloqueada en la mano 2 | N | ●● | 460 | 9 |

### Nivel 6 — Agujero negro (P = 600)
| | Jefe (mano) | Textura y objeto | Poder | Tipo | Sev. | Obj. | $ |
|---|---|---|---|---|---|---|---|
| A | **El Horizonte** | Materia estirada hacia el agujero negro, brillo naranja de disco de acreción | *Gravedad*: las caras 5 y 6 valen la mitad de cara | N | ●●● | 570 | 7 |
| B | **El Relojero del Instante** | Engranajes y reloj derretido, arena cayendo entre los dedos | *Tiempo detenido*: la ranura de moneda de un uso queda inutilizable (su recarga sigue avanzando normal, como está confirmado) | E+ | ● | 690 | 11 |
| C | **El Durmiente del Abismo** (tipo Cthulhu) | Tentáculos con ventosas, escamas verdes viscosas y un ojo que se abre en la palma | *Locura*: la previsión de puntos se oculta; solo se ve al anotar | N | ● | 720 | 12 |

### Nivel 7 — Cielo: Dios (triángulo con ojo)
Un solo jefe; se sortea una de sus tres reglas ya diseñadas (sin cambios de poder). Objetivos de la tabla de prueba actual.

| | Regla | Frase propuesta | Tipo | Obj. |
|---|---|---|---|---|
| A | Generala prohibida | *Dios no juega a los dados* | E | 800 |
| B | Metales suspendidos | *Lo terrenal no cuenta* | E | 850 |
| C | Carcasas suspendidas | *Ojo que no ve* | E | 900 |

## 4. Banco de poderes de reserva

- Elemento suspendido (fuego, agua, electricidad, tierra, viento): una regla, cinco variantes. Muy barato.
- Sin Full / sin Escalera / sin Póker (ampliar `forbid_category`).
- Acero, cobre, metales, gemas o monedas suspendidos (existentes).
- *Una sola puerta*: se sortea una categoría bendita; solo ella vale 100 %, el resto 50 %.
- *Ruleta*: cada mano tiene un multiplicador sorteado ×0,5 o ×1,5 visible antes de tirar.
- *Eco*: la primera mano sube el piso de la segunda en un porcentaje.
- *Niebla*: los dados no conservados se ven recién al terminar la tirada.
- *Peaje*: cada dado conservado cuesta $1.

Repetir un poder entre niveles es válido si cambia la escala.

## 5. Qué pide al motor

- Familias nuevas de `kind`: `suspend_sticker`, `suspend_element`, `suspend_coin_slot`, `forbid_category` con más objetivos, modificadores de tirada/dado, de valor de cara, de puntaje por repetición, de economía y de UI (`hide_preview`).
- Los sorteos propios del jefe (moneda expulsada, dado asustado, dado cargado, abducido) se hacen **una vez al empezar el encuentro** o de forma reproducible por semilla, y se guardan; nada se re-sortea al cargar.
- Animación del robo del termo (Don Cebador): al empezar el jefe, el termo del jugador se despega de la mesa, flota hacia el cielo y queda suspendido junto a la mano. Al terminar el jefe vuelve a su lugar. Es solo presentación; el efecto de juego es la suspensión de stickers. Al vencer al jefe, el termo vuelve a su lugar flotando de la misma manera (el recorrido inverso).
- Guardado: nueva versión con migración; la regla elegida ya se guarda completa.
- `Rules.score` y la previsión deben recibir el mismo contexto (contrato actual).
- `Relojero` depende de F01: hoy no existen monedas activas en el catálogo. Reemplazo si F01 se demora: *Ruleta*.
- Con 2 reglas por jefe ya no hace falta nada: Dios usa una sola cada vez.

## 6. Decisiones

Confirmadas por el autor el 4 de noviembre de 2026:

1. Se permiten *Abducción* (cuatro dados) y *Locura* (previsión oculta) como poder temporal de jefe.
2. El nivel 3 no cambia ni suma jefes.
3. El termo robado por Don Cebador vuelve a su lugar al vencerlo, flotando de la misma manera que se fue.

Abiertas:

4. Nombres definitivos y revisión de nombres parecidos a marcas o personajes ajenos (D10).
5. Aprobar el esquema `P × k` frente a objetivos manuales por jefe.


## Manos v4 (08/11/2026)

Cada jefe de los niveles 1 a 6, salvo El Gótico, tiene una mano nueva y una animación propia al clic que reemplaza a piedra, papel o tijera (El Gótico queda como estaba; los guardianes de Dios tienen la suya desde el 08/11/2026, ver abajo). El dibujo es el de los bocetos aprobados: Kioskero (fajo de billetes), Payador (mano de truco), Rey de las Palomas (migas y dos palomas), Don Cebador (ceba con tu termo), Vendedor Ambulante (cartel «OFERTA»/«2X1»), Referí (amarilla y roja), Conde Sed (murciélago colgado), Lobizón (transformación), Timbero (pila de fichas), Patovica («NO»), Payaso (pistola de dedo), Visitante (rayo tractor), Farolero (farol de luz), Sonda (garra), Horizonte (espaguetización), Relojero (péndulo) y Durmiente (tentáculos del abismo).
Se generan con `tools/art/make_manos_clic_v4.py` (reusa `tools/art/bocetos-jefes/`) y salen en `assets/art/pixel-v3/manos-clic-v4.png`, `manos-clic-atras-v4.png` y `manos-contorno-v4.png`, más la tabla `scripts/boss_hand_clips.gd` (generada). El cuadro 0 es el reposo; el resto, el clic a 110 ms por cuadro.

**Guardianes de Dios: animación al clic (08/11/2026).** Elegidas por el autor sobre los bocetos (dos ideas por guardián): el ojo solar (Generala prohibida) hace girar su corona una vuelta entera, cierra la pupila en una raya y suelta dos anillos de luz; la figura de luz (metales suspendidos) levanta de sus manos un dado de hierro y otro de cobre, que flotan, pierden el color y se deshacen en luz; el dado cósmico (carcasas suspendidas) hace una tirada: la cara grande pasa por varios números con un temblor y vuelve al seis mientras una luz corre por los ocho dados chicos. Son 16 cuadros de 110 ms (`pixel-v3/guardianes/guardianes-clic-v4.png`, generado por `tools/art/make_guardianes_clic_v4.py` a partir de `tools/art/bocetos-dios/guardianes.py`). El cuadro 0 y el último son el dibujo de siempre. Al hacer clic, el guardián anima (animación `guardian` de `bar_props.gd`) y al terminar se abre su ficha; con «Reducir movimiento» o velocidad cero la ficha se abre enseguida. Es solo presentación: no toca la partida ni su azar. Además, a pedido del autor, en reposo el ojo solar parpadea y mira a un lado y al otro (la idea A de los bocetos): 16 cuadros de 110 ms y 3 s de pausa, en bucle (`guardian-ojo-reposo-v4.png`, `Backdrop.eye_idle_frame`). Con «Reducir movimiento» o velocidad cero queda quieto. El clic sigue siendo la corona que gira. La figura de luz, también a pedido del autor, flota en reposo: sube y baja más alto y más despacio que los otros guardianes (±6 px, `Backdrop.guardian_bob`) mientras las esferas de sus manos respiran y titilan estrellas del manto (24 cuadros de 120 ms en bucle, `guardian-figura-reposo-v4.png`). El clic sigue siendo los metales en el aire. El dado cósmico queda quieto en reposo.
