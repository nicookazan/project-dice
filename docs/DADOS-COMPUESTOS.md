# Dados: cuerpo, elemento y puntos

28/10/2026. Implementación de la dirección revisada por el usuario: dados frontales como las gemas y sin dibujitos inferiores. Las propuestas originales se conservan en `docs/propuestas/dados-v1`; la revisión sin iconos sustituye los emblemas de la primera propuesta.

## Presentación integrada

- Cuerpo básico de marfil, acero de tonos plateados o cobre anaranjado; misma silueta frontal y biseles.
- Fuego, agua, electricidad, tierra y viento añaden acentos estáticos sobre los bordes. No tienen un emblema inferior ni ocupan los puntos.
- Puntos negros o gemas brillantes: rubí, zafiro, esmeralda y diamante. Coexisten con el material y el elemento; por ejemplo acero + electricidad + diamante.
- Los números 1–6 mantienen su cantidad real de puntos; el dado sin tirar conserva `?`.
- Mesa, reserva, grupos, vaso, inventario de tienda y arrastre comparten las tres capas. Las ofertas de material/elemento muestran un cinco frontal con el acabado correspondiente, sustituyendo cubos isométricos e iconos separados.
- La compra confirmada actualiza solo la familia comprada y conserva las otras dos. Daño, selección, foco y suspensión siguen señalados.

## Dónde verlos

**Ver diseños de dados → Ver materiales y elementos** desde menú u Opciones. Galería desplazable con 48 muestras: seis caras de acero, cobre, los cinco elementos y la combinación acero/electricidad/diamante. No equipa ni cobra piezas.

## Implementación y límites

`die.gd` es la representación común. `configure_appearance` recibe los componentes persistidos y contexto de jefe. `die_body.gdshader` aplica los acabados metálicos a la textura frontal original, conserva sus biseles y excluye los límites de los puntos. Los bordes elementales y facetas se dibujan como píxeles nativos de Godot. Son acabados compuestos en ejecución inspirados en las láminas revisadas, no una reproducción píxel por píxel de sus imágenes grandes.

Las marcas y acentos son estáticos, sin destellos ni dependencia del azar. No cambian puntuación, poderes, economía, guardado v3 ni componentes iniciales. Conserva las claves históricas `material`, `element` y `shell`.

## Revisión

`tests/component_art_review.gd` genera capturas reales a 1440×900 y 1280×800 de galería, combinación, daño/selección y tienda, sin guardar una partida del jugador. `tests/dice_art_tests.gd` comprueba que las ofertas de material y elemento usen el dado frontal, que comprar conserve las otras capas y que la galería no altere estado/RNG.

Capturas: `test-results/<resolución>-componentes-*.png`. Las piezas equipadas de estas escenas son fixtures de revisión, no ventajas añadidas a partidas normales.

Resultado: **2133 comprobaciones, cero fallos**. Revisadas las capturas de ambas resoluciones. La valoración artística del usuario sigue abierta para ajustar el acabado dentro del juego.
