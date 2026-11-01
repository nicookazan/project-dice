# Plan de arte — menos "IA", más pixel art real

Fecha: 31 de octubre de 2026. Estado (01/11/2026): **fases 0–7 hechas (Dios queda para cuando exista el jefe final); 8 pendiente** (ver el registro de avance al final). Se avanza una fase por vez, con aprobación del autor antes de pasar a la siguiente.

## Decisiones de partida (del autor)

- **El estilo de los dados se conserva** (`assets/art/dice-master-v1/` y las 30 caras de `dice-faces-v1/`). Son la referencia de estilo y no se tocan.
- **Todo lo demás es modificable**: mesa, club, libreta, vaso, mate, termo, monedas, tienda, vendedor, exteriores, mano/nube, Dios, stickers, marcos de UI.
- **Meta:** densidad de píxel algo menor (píxeles más grandes y legibles) y apariencia de pixel art hecho a mano, no de imagen generada y "pixelada".

## Diagnóstico (revisado sobre los archivos actuales)

Lo que delata el arte como generado por IA:

1. **Falso pixel art**: son imágenes grandes (p. ej. club-table-v2 ≈ 1586×992, coins-v2 ≈ 1774×887) con bloques de tamaño irregular; no hay una grilla lógica única. El mismo cuadro mezcla píxeles de 3 px, 6 px y detalle subpíxel.
2. **Densidad excesiva**: texturas de ruido (paño bordó, madera, piedra de las monedas), vetas finas, cientos de detalles de 1–2 px sin intención. Los dados, en cambio, tienen bloques grandes y grupos deliberados: ese es el nivel a imitar.
3. **Degradados suaves y brillos tipo render**: halos de luz, rayos, resplandor de elementos (fuego, agua, electricidad), gemas facetadas con destellos. Pixel art real usa rampas de pocos tonos con bordes duros.
4. **Paletas sin control**: cada imagen trae cientos o miles de colores; los exteriores son saturados y distintos a los interiores.
5. **Contornos incoherentes**: unos objetos con borde negro, otros sin borde, otros con borde de color.
6. **Perspectivas mezcladas**: los dados son frontales (aprobado), pero los cubos de `shop-items-v1` son isométricos y la tienda mezcla estilos.
7. **Rasgos típicos de IA**: manos y caras con detalle excesivo y artefactos (vendedor, sol de mayo, mano), simetrías falsas, texto/ornamentos ilegibles al ampliar.

## Reglas de estilo objetivo ("biblia de píxel")

Se fijan en la Fase 0 y todo asset nuevo debe cumplirlas.

| Regla | Valor propuesto (a confirmar en Fase 0) |
|---|---|
| Píxel lógico | Un solo tamaño en todo el juego: el que resulte de medir los dados en pantalla. Cada píxel lógico = N×N píxeles reales, siempre con N entero. |
| Resolución lógica de escena | Fondos/escenas en una grilla baja (orden de 480×300 o 384×240, que escala a 1440×900 con N=3 o 3,75; elegir la que dé N entero) |
| Paleta | Una paleta maestra compartida de 32–48 colores, derivada de los colores del dado (marfil, miel, marrón cálido, bordó, azul noche, dorado). Sin colores fuera de paleta. |
| Rampas | 3–4 tonos por material (sombra, base, luz, brillo puntual). Sin degradados continuos; el sombreado se hace con bloques, y dithering solo muy puntual. |
| Contorno | Contorno oscuro de 1 px lógico, de color cálido (no negro puro) en objetos jugables y de interacción; fondos sin contorno. |
| Luz | Una sola dirección: arriba-izquierda, igual que el dado. |
| Detalle | Un detalle = un grupo de ≥2×2 píxeles lógicos con intención. Prohibido el ruido de 1 px como textura (usar 2–3 tonos en parches). |
| Brillos y efectos | Formas duras y planas con 2–3 colores; sin halos ni blur. Las animaciones usan pocos cuadros. |
| Escalado en Godot | `texture_filter = NEAREST`, sin rotación ni escala fraccionaria en sprites estáticos (o rotar con cuidado/shader de pixel-snap), `canvas_items` con stretch entero cuando sea posible. |

## Cómo se produce el arte (honesto sobre las herramientas)

Claude Code aquí **no pinta ni genera imágenes**: solo puede escribir código y archivos. Opciones para producir los PNG finales, de mayor a menor control:

1. **A mano en un editor de píxeles** (Aseprite, LibreSprite, Pixelorama): el autor dibuja, o parte de los borradores. Es lo que mejor quita el aspecto IA.
2. **IA como borrador + limpieza**: generar a baja resolución o con prompt de "pixel art de N×N", y luego pasar por el *pipeline de normalización* de abajo y retocar a mano. La IA no debe ser el acabado.
3. **Procedural en GDScript** (formas, rampas, tilesets) para fondos geométricos: paños, madera, cielos, estrellas, nubes simples. Claude puede escribir y ajustar estos scripts, y revisar capturas.

**Pipeline de normalización** (Claude lo puede implementar como script de Godot `tools/pixelize.gd`, porque no hay Python instalado): detectar o fijar el tamaño del píxel, reducir con vecino más cercano al tamaño lógico, cuantizar a la paleta maestra, limpiar píxeles sueltos (*orphans*) y bordes, y reescalar en entero. Con esto un borrador de IA pierde ruido y degradados, pero **no sustituye el retoque a mano**: formas y poses malas (caras, manos) deben rehacerse, no filtrarse.

## Fases (de a una)

Cada fase termina con: assets en `assets/art/pixel-v3/`, capturas antes/después con `tests/*_review.gd`, suite de pruebas sin fallos (`Probar.cmd`), registro en `ESTADO.md` y **visto bueno del autor**. Los assets anteriores se conservan en su carpeta hasta aprobar; se cambia el que se carga mediante una constante, para poder revertir.

### Fase 0 — Biblia de píxel y herramientas (sin tocar arte visible)
- Medir el tamaño real del píxel del dado y cuántos píxeles ocupa en pantalla en mesa, tienda y reserva.
- Elegir píxel lógico N y resolución lógica de escena; extraer la paleta maestra desde `dado-base-aprobado-5.png` y las gemas mates; documentarla en `docs/PALETA-MAESTRA.md` y como `assets/art/pixel-v3/paleta.png` (+ `.gpl` para Aseprite).
- Escribir `tools/pixelize.gd` (reducir, cuantizar, limpiar) y una escena de comparación lado a lado.
- Congelar el dado: guardar SHA-256 de los archivos protegidos y una prueba que falle si cambian.
- Aceptación: el autor aprueba paleta, N y resolución con una muestra de un solo objeto.

### Fase 1 — Piloto: monedas (8 sprites)
- Son pocos, aislados, y muy "IA" hoy (textura metálica con ruido, laureles finos, rostro del sol).
- Rehacer a ~32×32 lógicos: borde dentado simple, un emblema grande por moneda, 3 tonos por metal, sin laureles ni fleur-de-lis salvo que se reduzcan a 3–4 píxeles.
- Aceptación: se ven bien en el inventario (5+1 espacios), en la mesa y en la tienda; el autor aprueba la dirección antes de continuar. **Esta fase decide el método para el resto.**

### Fase 2 — Termo, stickers y vaso
- Termo plateado y los 6 stickers (curvatura, hover e inspección ya implementados): rehacer con el mismo píxel lógico; revisar el sombreado por curvatura del código para que no genere degradados continuos.
- Vaso de cuero negro con sol (mesa y tienda): simplificar el sol a un emblema pequeño y las costuras a patrón regular.

### Fase 3 — Mesa de juego
- Paño bordó, borde dorado y esquinas ornamentales, libreta cuadriculada, lápiz, mate: pasar el paño de textura de ruido a 3 tonos con bordes limpios y ornamento mínimo.
- Madera de la mesa con vetas en bloques, no ruido.
- Debe respetar `docs/PROPORCIONES-v3.md` (`assets/art/environment-v2/`) y las zonas de interacción; no mover posiciones de UI.

### Fase 4 — Salón del club (fondo)
- Fondo con ventanas, lámparas, cuadros, sillas, bandera: rehacerlo en baja resolución por capas (fondo, mobiliario, luces) con iluminación de 3 niveles. Los cuadros de la pared, hoy ilegibles, pasan a siluetas simples.

### Fase 5 — Tienda
- Vendedor (la pieza más "IA": rostro, manos, traje con trama): rehacer con menos detalle, rasgos esquemáticos y expresión legible, o simplificar a busto estilizado. **Conviene que el autor decida si mantiene la inspiración en sus fotos.**
- Maletín con cuatro compartimentos y objetos de oferta: unificar a vista frontal (como el dado) y reemplazar los cubos isométricos de `shop-items-v1`.
- Iconos de ofertas: elementos (fuego, agua, tierra, viento, electricidad) como señales planas de 2–3 colores sobre el mismo dado frontal; gemas según los acabados mates ya aprobados; paquete de stickers.

### Fase 6 — Exteriores y ambientes (7 niveles)
- Seis escenarios hoy muy densos y saturados. Rehacer con paleta reducida por ambiente, planos de profundidad y pocos elementos grandes (casas, torre, luna, galaxia, agujero negro, ciudad celestial). Mate siempre, incluso de noche.
- Se puede hacer parcialmente procedural (cielos, estrellas, nubes) y a mano para siluetas.

### Fase 7 — Mano, nube, Dios y efectos
- Mano y nube originales (ya restauradas) y Dios (triángulo/ojo): llevarlos a la grilla y paleta comunes. Efectos de puntuación/rotura con pocos cuadros.

### Fase 8 — Interfaz y cierre
- Marcos de tooltips, paneles bordó/dorado, botones, tipografía pixelada coherente, estados de selección. Revisión de resoluciones 1280×800 y 1440×900, accesibilidad (contraste, reducción de destellos) y limpieza de los assets viejos que ya no se usen.

## Riesgos y decisiones abiertas para el autor

1. **Producción de los PNG**: ¿los dibujás vos en un editor, los generás con IA y los limpiamos, o querés que Claude intente versiones procedurales/escritas por código para formas simples? Esto condiciona los plazos de cada fase.
2. **Valor de N / resolución lógica** (Fase 0): bajarla hace el juego más "retro" pero reduce el detalle legible de textos y fichas.
3. **Dados vs resto**: si el píxel nuevo es más grande que el del dado actual, el dado se verá más fino que el entorno. Opción: escalar el dado ×1 al tamaño del nuevo píxel (sin redibujar) o rediseñar solo el entorno con el píxel del dado. Se decide en Fase 0 con una prueba visual.
4. **Aprobación artística** es del autor; el cierre técnico de cada fase no la sustituye (ver D10 en `docs/pasos/DECISIONES.md`).
5. **Procedencia**: registrar en `ART-PROMPTS.md` el origen (a mano, IA + limpieza, procedural) de cada archivo nuevo.

## Siguiente paso propuesto

**Fase 8** (interfaz y cierre), cuando el autor lo pida. Aparte, quedan por iterar los gestos de la mano y por definir el jefe final con los tres guardianes (ver Fase 7).

## Registro de avance

**Decisiones del autor (31/10/2026):** no dibuja; Claude produce todo el arte a partir de los conceptos actuales; el autor solo dirige y quizás retoque.

**Método adoptado:** el arte se genera por código con scripts de Godot (`tools/art/`), con paleta maestra, rampas de 5 tonos, luz arriba-izquierda y sombreado automático de máscaras. Es reproducible y retocable cambiando datos. Ejecutar: `godot --headless --path . --script res://tools/art/make_<cosa>.gd`. Las vistas ampliadas ×6 para revisar caen en `test-results/` (ignorado por Git).

**Fase 0 — hecha (parcial):** píxel lógico fijado en **2×2 px del viewport de 1440×900** (escena lógica 720×450; el dado ocupa ~60 px en pantalla, así que el píxel nuevo es algo más grueso que el actual). Paleta inicial en `tools/art/pixel_lib.gd` (oro, plata, cobre, azul, marfil; contorno `#2a1a14`). Hashes de los dados protegidos en `assets/art/PROTEGIDOS.sha256`. Pendiente: documentar la paleta completa (`PALETA-MAESTRA.md`) cuando se sumen más materiales, y la prueba automática de hashes.

**Fase 1 — hecha, pendiente de aprobación del autor:** las 8 monedas rehechas a 32×32 px lógicos en `assets/art/pixel-v3/coins-v3.png` (`tools/art/make_coins.gd`), cargadas desde `scripts/coin_art.gd`. Los originales `assets/art/coins-v2.png` se conservan; para revertir basta cambiar la ruta de `SHEET`. Suite: 2195 comprobaciones, 0 fallos. Captura: tienda (inventario, ofertas, vista de monedas).
- Pendiente de revisión: ¿se aprueba esta dirección (contorno oscuro, 3 tonos por metal, emblema grande autosombreado, sin laureles)? Si sí, se aplica a las fases 2–8.

**Fase 2 — hecha, pendiente de aprobación (rama `feature/pixel-termo-vaso`):**
- Termo plateado nuevo (`pixel-v3/termo-v3.png`, 72×165 px lógicos) en la tienda, el inspector de stickers y la animación de paquetes.
- Seis stickers nuevos (`pixel-v3/stickers-v3.png`, 19×19): insignia redonda con borde marfil, color por categoría y dados planos; en el termo se comprimen por columna con sombreado de tres pasos (sin degradados). Ya no se renderizan con polígonos suavizados.
- Stickers en grilla par (38 px, paso 42) tanto en el termo nuevo como sobre el termo de la mesa.
- **Cambio de alcance:** el termo de la mesa de juego, el mate y el vaso están integrados en la imagen de la mesa (`mesa-libreta-frontal-v1.png`), por lo que **solo pueden reemplazarse junto con la mesa en la Fase 3**. El vaso pasa a la Fase 3; en la mesa seguirá visible el termo viejo con los stickers nuevos hasta entonces.
- Suite: 2195 comprobaciones, 0 fallos.

**Fase 3 — hecha, pendiente de aprobación (rama `feature/pixel-mesa`):**
- Mesa rehecha desde la fila 272 hacia abajo (`pixel-v3/mesa-v3.png`, 720×314 px lógicos, `tools/art/make_mesa.gd`): madera en bloques de veta (sin ruido), paño bordó con pelo corto en tres tonos, tres paneles con filo dorado y ornamentos en las esquinas (mismas posiciones que las zonas de juego), frente con ménsulas y piso de tablas. Ya no se usa la parte baja de `mesa-libreta-frontal-v1.png`; el salón de arriba sigue siendo el original (Fase 4).
- Termo de la mesa: el termo nuevo alargado (`termo-mesa-v3.png`, 72×175), con los stickers en su grilla. Se eliminó el recorte del termo viejo sobre la ventana.
- Mate (`mate-v3.png`, con virola de greca y bombilla) y vaso de cuero (`vaso-v3.png`, costuras doradas y fieltro verde), más sombras de contacto sobre el paño.
- `mesa-parche-v3.png` reconstruye por barrido el fondo que tapaba el termo viejo; desaparece cuando se rehaga el salón.
- Libreta y lápiz no se tocaron: la libreta es una interfaz plana de Godot (no está en la imagen) y no hay lápiz en la mesa actual.
- Posición del termo para stickers: `Backdrop.THERMOS_ORIGIN`; zonas de clic y `CUP_MOUTH` sin cambios. Suite: 2195 comprobaciones, 0 fallos.

**Fase 4 — hecha, pendiente de aprobación (rama `feature/pixel-salon`):**
- Salón rehecho (`pixel-v3/salon-v3.png`, 720×150 px lógicos, `tools/art/make_salon.gd`): paredes con friso de madera, vigas, marcos de ventana con alféizar, lámparas colgantes y de mesa con halo en tres niveles, cuadros simplificados a siluetas (bailarines, edificio con cúpula, retratos), sillas y mesas del fondo, banderín y planta.
- Las ventanas (panorama animado) y su posición no cambian; el salón solo dibuja el marco. La mano y la nube se conservan hasta la Fase 7.
- Se eliminó `mesa-parche-v3.png` (ya no hace falta). Suite: 2195 comprobaciones, 0 fallos.
- **Mate y vaso rehechos (opción A aprobada):** forma original, rampas de 7 tonos (madera, plata, cuero) y 5 (yerba, fieltro), sombreado esférico y bombilla con anillos. Generados con `tools/art/make_mate_vaso.gd` (la variante fina B quedó descartada).

**Fase 5 — hecha y aprobada por el autor (01/11/2026, rama `feature/pixel-tienda`):**
- Fondo de la tienda (`pixel-v3/tienda-v3.png`, 720×450 px lógicos, 119 colores), generado con `python tools/art/make_tienda.py`: salón con los motivos de `salon-v3.png` y bandas de arriba y abajo tranquilas para la interfaz.
- **Vendedor** (`tools/art/vendedor.py`): conversión fiel del dibujo de `shop-salesman-v1.png` con el método de sprite-forge. Se usa la mediana por celda en la grilla lógica, un suavizado que respeta bordes, una paleta propia por zona (cara 10 tonos, pelo 6, traje 6, manos 8) y limpieza de manchas fuera de los rasgos. A mano solo se repuso el brillo de las pupilas y el blanco del ojo.
- **Regla del autor:** al pasar arte existente se limpia, no se rediseña. La primera versión, redibujada con formas esquemáticas, se rechazó porque no respetaba la cara ni las manos del original.
- **Maletín** (`tools/art/maletin.py`): tiene la silueta del original (tapa casi frontal, interior en trapecio, base que se abre hacia abajo), con cuero, costura, herrajes dorados y el terciopelo de la mesa. Una versión rectangular de frente se descartó por "demasiado cuadrada". Las zonas de ofertas de `main.gd` no se movieron.
- **Íconos** (`pixel-v3/tienda-iconos-v3.png`, celdas de 44×44): medallón de mejora numérica y sobre de stickers en diagonal (~13°, como el original). `scripts/shop_art.gd` los dibuja a escala entera: ×2 en la tienda, ×4 en la animación del sobre. El atlas isométrico `shop-items-v1.png` ya no se usa: las ofertas de dados se dibujan con el dado frontal real y sus marcas de elemento planas.
- **Terciopelo de descripciones y paneles** (`pixel-v3/terciopelo-v3.png`): baldosa del terciopelo del maletín que `scripts/tooltip_frame.gd` repite 1:1.
- **Sin cambios:** dados (protegidos), monedas, stickers y termo (fases 1 y 2), marcos de interfaz (Fase 8).
- **Herramientas:** los generadores de esta fase son de Python 3.13 (Pillow, numpy, scipy), porque convierten una ilustración existente; los demás siguen en GDScript.
- **Para revertir:** cambiar `SELLER_ART` en `scripts/backdrop.gd`, `SHEET` en `scripts/shop_art.gd` y `VELVET` en `scripts/tooltip_frame.gd`. Los archivos originales se conservan.
- Suite: 2195 comprobaciones, 0 fallos. Revisiones visuales de tienda, descripciones, sobre, venta por arrastre, termo e interfaz sin errores.

**Fase 6 — hecha y aprobada por el autor (01/11/2026, rama `feature/pixel-exteriores`):**
- Los seis exteriores de las ventanas (`pixel-v3/exteriores-v3.png`, `tools/art/make_exteriores.py`) son una conversión fiel de `environment-v2/exteriores-v2.png`, sin rediseño: cada panel se reduce a 401×110 px lógicos (el panorama de 801×220 px), se suaviza respetando bordes y se pinta con una paleta corta propia de 20 a 24 colores. Las estrellas se conservan, ajustadas a la paleta.
- Los límites de los paneles en la hoja original no son tercios iguales (filas en y=342 y 671, columna en x=768). Con los límites reales desaparece una línea clara que se colaba al pie de las ventanas de noche y espacio, y que ya estaba en el juego anterior.
- Cada celda del atlas mide 402×111 (panel más una columna y una fila repetidas) para que el medio píxel de las ventanas de ancho impar no tome el borde del vecino. `scripts/backdrop.gd` mapea un píxel lógico a 2×2 de pantalla. El ambiente «cierre» (ventanas tapadas) no cambia.
- Para revertir: la constante `EXTERIORS` y el cálculo de `source` en `scripts/backdrop.gd`. El original se conserva.
- Suite: 2195 comprobaciones, 0 fallos. Revisión de presentación de los siete ambientes sin errores.

**Fase 7 — hecha y aprobada por el autor (01/11/2026, rama `feature/pixel-mano-dios`):**
- **Mano y nube integradas:** conversión fiel del original (`pixel-v3/mano-v3.png`, 8 cuadros de 61×53; `pixel-v3/nube-v3.png`, 131×20; generadores `make_mano_dios.py` y `make_mano_anim.py`). La mano tamborilea (meñique → índice, pulgar quieto) a 110 ms por cuadro. El vaivén pasó de 3 px sin redondear a pasos de 2 px para respetar la grilla; con movimiento reducido o apagado queda el cuadro 0. Para revertir, ver las constantes `CLOUD_V3` y `HAND_V3` y el dibujo final de `scripts/backdrop.gd`.
- **Los tres guardianes (decisión del autor):** el triángulo de Dios era un placeholder y se reemplaza por tres figuras épicas de contraste fuerte, que serán los **guardianes** del jefe final: derrotados los tres, se accede al jefe final. Quedan guardadas en `pixel-v3/guardianes/` (124×100 px lógicos), sin integrar al juego, con su generador `tools/art/make_dios_opciones.py`:
  - **Ojo solar** (`guardian-ojo-v3.png`): ojo de pupila vertical en un vacío oscuro con anillos y 32 rayos.
  - **Figura de luz** (`guardian-figura-v3.png`): silueta encapuchada con ojos blancos, túnica estrellada y brazos abiertos.
  - **Dado cósmico** (`guardian-dado-v3.png`): dado dorado con un ojo en un punto, mandorla y dados en órbita.
- **Pendiente de definir (no está en el PRD):** el jefe final y su relación con los guardianes (cantidad y orden de encuentros, reglas, en qué nivel aparecen, arte del jefe). No se agregó nada al PRD ni a las fichas; el tablero de Notion debe actualizarse a mano cuando el autor lo decida. Mientras tanto, `scripts/backdrop.gd` conserva el triángulo provisional para `actor == "god"`.
- **Gestos de la mano (descartados por ahora):** se probaron abrir, cerrar, pulgar arriba y pulgar abajo y no convencieron al autor; no quedan en el repo. La mano conserva solo la animación inicial. Se iteran más adelante, probablemente con piezas dibujadas de cero (puño con nudillos, pulgar plegado) y disparadas por lo que haga el jugador.
- **Efectos de puntuación y rotura:** no hay arte existente y no se inventó; quedan fuera hasta que el autor los pida.
- Suite: 2195 comprobaciones, 0 fallos.
