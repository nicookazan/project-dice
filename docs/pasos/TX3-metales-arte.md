# TX3 — Arte de los metales nuevos

Ítem 4 (texturas) · 5 de noviembre de 2026.

**Rama:** `feature/metales-arte`. **Depende de:** ninguna. **Estado actual:** Completado el 07/11/2026; falta la aprobación del autor dentro del juego. **Decisiones vinculadas:** D16.

## Objetivo
Hierro oxidado (B), cobre oxidado (A) y oro (A): cuerpos nuevos para el dado, comprados ya oxidados.

## Alcance
Arte y shader del cuerpo. En lugar de seis imágenes por cara se usa **una máscara fija por metal** (`assets/art/pixel-v3/metales-mascaras-v3.png`, 124×62: hierro oxidado y cobre oxidado). `die_body.gdshader` suma el brillo de cada cara a la máscara y recorre la rampa de color, así que funciona con cualquier cara, gema y elemento y no toca los puntos (se saltan con las mismas cajas que acero y cobre). El oro no necesita máscara: rampa por brillo y franja de reflejo en diagonal.

Generador: `tools/art/make_metales.py` (semillas fijas, resultado idéntico siempre; lee la cara protegida solo para la silueta). Tabla de materiales en `Materials.TABLE`. Los tres metales se ven en la galería de Opciones (ahí no se compran).

## Cómo se ve
`tests/metales_review.gd` (requiere GPU) escribe `test-results/metales-dados.png`: los cinco metales con las seis caras y combinados con gemas y elementos.

## Fuera de alcance
Reglas, tienda, guardado y balance: ver [TX4](TX4-metales-juego.md).
