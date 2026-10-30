> Actualización del 28/10/2026: siempre mate con termo; stickers sobre el termo; exteriores ilustrados según el PRD; gemas brillantes. Sustituye las referencias históricas a cerveza, stickers en vaso y puntos opacos. Ver docs/CAMBIOS-VISUALES-2026-10-28.md.

# Presentación, audio y accesibilidad — paso 19

27 de octubre de 2026. Implementación de prototipo; dirección artística, textos y mezcla finales pendientes de revisión del autor.

## Decisión D10 del usuario

«cambiamos a tener mate siempre». Se mantiene el mate en **los siete ambientes**, incluida la noche. Sustituye la cerveza nocturna y elimina la decisión pendiente sobre bebida posterior. No modifica reglas ni economía.

## Integración

El club, la cámara, el paño, el vaso, el mate y las posiciones de los controles se conservan. Las cuatro aberturas cambian a día, tarde, noche, cierre con tablones opacos, espacio con planeta, agujero negro con disco y cielo con nubes. El nombre de ambiente y número de nivel también se escriben; la progresión no depende únicamente del color.

Los rivales comunes y los jefes de los primeros seis niveles reutilizan la **mano y nube originales del club**. Se recuperan sus píxeles mediante polígonos texturados, sin modificar la imagen original ni redibujar la figura. Se retiraron las manos geométricas y sus objetos por indicación del usuario: no respetaban el pixel art existente. La regla activa se conserva en texto y Recorrido. Las variantes de jefes con gestos/objetos quedan pendientes de producción artística coherente con esta referencia. Dios conserva una silueta provisional de triángulo/ojo; tampoco se considera arte final aprobado ni resuelve identidades D07.

Cada ambiente tiene una frase breve: mate cotidiano al principio, cierre, desaparición del barrio, amenaza y llegada a Dios. El jefe anuncia su condición. Las frases son propuestas editables en `presentation_state.gd`. La línea tiene información completa en su ayuda al pasar el puntero; la regla completa también sigue disponible en Recorrido.

La presentación observa acciones ya resueltas: tirada, movimiento, grupo, anotación, rotura, compra y reparación. Añade texto y sonido sin tapar la libreta ni retrasar la aplicación/guardado. Se mantienen SEL, FIJO, R/grieta, listado de efectos y desglose por dado. Silenciar no elimina información necesaria.

## Opciones y persistencia

Desde **Opciones** en menú o partida:

- Silencio general y volumen independiente de dados/cuero, club, ambiente y efectos; cero silencia una categoría.
- Velocidad normal, rápida y sin animación. Afecta únicamente el movimiento decorativo y el desvanecimiento de avisos.
- Reducir movimiento deja estáticas las figuras. Reducir destellos está activado inicialmente: los avisos no varían de opacidad. No se utilizan estrobos ni sacudidas de cámara.
- Mayor contraste aplica fondos oscuros, texto blanco y bordes claros a los botones de juego. El foco de teclado tiene borde blanco en ambos modos.
- Probar dados permite comprobar el volumen; respeta el silencio general. Los atajos figuran en la misma ventana y en Ayuda.

Se guardan en `%APPDATA%/DiosNoJuegaALosDados/preferences.cfg`, versión 1, mediante temporal y renombrado. Un archivo ausente usa valores iniciales; uno ilegible o de versión futura se conserva y muestra un aviso. Se reemplaza solo al elegir opciones nuevas. Fallar la escritura conserva las opciones durante la sesión e informa el problema. Pantalla completa con F11 sigue siendo una opción de sesión.

Las preferencias no forman parte del guardado v3 ni del estado de la partida. El dibujo, el audio y sus tiempos no llaman al generador aleatorio de jugabilidad. No se inventan resultados intermedios de dados. Reanudar no vuelve a emitir sonidos de compras o anotaciones anteriores.

## Inventario y procedencia D10

**Tienda renovada:** mesa de cuatro sectores y atlas de ofertas generados con Imagegen e integrados en controles nativos. Club/mano originales conservados. Nuevos recursos `assets/art/shop-table-v1.png` y `shop-items-v1.png`; [prompts y verificación](TIENDA-ESTILO.md). Suite actual 2025, cero fallos; no atribuye aprobación artística final.

| Recurso | Procedencia | Uso y estado |
|---|---|---|
| `assets/art/club-table-v2.png` | Imagegen previo, prompt en `ART-PROMPTS.md` | Club, mesa, mate, vaso y encuadre reutilizados; archivo original conservado |
| `assets/art/coins-v2.png` | Imagegen previo, prompt en `ART-PROMPTS.md` | Atlas existente de ocho monedas |
| `assets/art/ivory-die-v3.png`, `ivory-die-front-v4.png` | Imagegen previo, prompts junto a recursos | Dados actuales con valores dibujados por juego |
| Mano y nube | Píxeles del `club-table-v2.png` existente, reutilizados mediante polígonos texturados | Referencia visual conservada; variantes de jefe pendientes; no se modificó el bitmap |
| Ventanas, edificios, tablones, estrellas, planeta, disco y Dios | Dibujo con primitivas de Godot en `scripts/backdrop.gd` | Marcadores nativos provisionales; necesitan pase artístico consistente con el pixel art existente |
| Dados/cuero, club, ambiente, efectos | PCM sintetizado original en `scripts/presentation_audio.gd` | Ruido determinista, tonos y envolventes, sin grabaciones ni bibliotecas externas; mezcla provisional |
| Frases y avisos | Texto original en `scripts/presentation_state.gd` y `main.gd` | Propuestas de tono y legibilidad; aprobación narrativa final pendiente |

El sonido se crea a 22050 Hz, mono, 16 bits. Club y ambiente son bucles; acciones duran 0,30 s. Cuatro reproductores separados conservan su volumen; silenciar detiene todos. El ambiente cambia su tono según nivel. No se encontraron archivos de audio previos que reutilizar. El ruido sintetizado usa una función matemática local, no sorteos del juego. Muestra reproducible: `test-results/presentacion-dados.wav`.

Prioridades artísticas pendientes: producir variantes de manos y objetos a partir del pixel art existente y del catálogo final D07; llevar exteriores y Dios al mismo acabado; revisar frases y mezcla. No se autoriza cambiar de estilo para resolver estas variantes. La integración técnica no da por aprobado ese trabajo artístico.

## Verificación reproducible

`Probar.cmd` ejecuta la regresión y añade `presentation_demo` a `test-results/tests.json`: preferencias válidas/inválidas, conservación de archivo futuro, controles reales, silencio, señales únicas y partidas naturales de semilla 3 por UI con velocidad normal/rápida/sin movimiento. Se comparan **snapshots completos**, incluidos azar, compras, stock, cobros y puntuación. También se comprueban los siete límites de ambiente y el PCM no silencioso por categoría/acción.

`tests/presentation_review.gd`, ejecutado con renderizado a 1280×800 y 1440×900, produce doce capturas por resolución en `test-results/<resolución>-presentacion-*.png`: siete ambientes/jefes, rival común, tirada, opciones, contraste y ayuda larga. Comprueba además inicio real del reproductor y silencio posterior, sin interferir con las preferencias del jugador. Las escenas de campaña usan un laboratorio explícito para alcanzar los niveles; no prueban dificultad o balance humano.

La revisión visual verifica ventanas cubiertas, espacio/disco distinguibles, triángulo/ojo, mate conservado, diálogo separado de cifras, ayuda larga y opciones dentro de ambas resoluciones. No sustituye una sesión humana de accesibilidad, escucha, diversión o aprobación de arte. El paso 20 conserva balance, mediciones humanas y exportación del ejecutable.

