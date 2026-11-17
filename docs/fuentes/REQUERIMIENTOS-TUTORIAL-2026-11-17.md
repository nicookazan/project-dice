# Requerimientos — Pantalla inicial y tutorial (17/11/2026)

Copia local del texto de Notion «Requerimientos — Pantalla inicial y tutorial» (dictados por el autor el 17/11/2026, requerimientos cerrados, sin preguntas abiertas). Resumen fiel de lo que manda; el plan y el contrato están en [TU-tutorial](../pasos/TU-tutorial.md), [PARTIDAS-GUARDADAS](../PARTIDAS-GUARDADAS.md) y [TUTORIAL](../TUTORIAL.md). Si el original cambia, pedir al autor que lo pegue acá.

## Vocabulario
- **Run** = una corrida de juego; en pantalla se llama **«jugada»**. Las runs no se guardan ni se continúan: salir a mitad la pierde y no cuenta en las estadísticas.
- **Partida (guardada)**: perfil con las estadísticas de todas sus runs, los desbloqueos de monedas y los logros. Es lo único que se guarda y se carga. 3 ranuras: «Partida guardada 1/2/3».
- **Logro**: por partida; surge de hacer cosas en las runs (ejemplo futuro: 100.000 puntos en una sola tirada).

## R1 — Pantalla inicial
Opciones: Nueva jugada; Nueva jugada debug (solo menú principal, no llega a la versión final, no cuenta para nada); Opciones (las actuales + cargar otra partida guardada + borrar partida); Salir del juego (con confirmación). Sin «Continuar». Fondo: el bar; a la izquierda el menú; a la derecha el mate y el bar, interactuables, y la mano de Dios, clickeable; solo las interacciones que ya existen. Menú de pausa: «Abandonar jugada» (aviso) y Opciones; se quita «Guardar y salir».

## R1b — Partidas guardadas
Siempre está cargada la última partida usada. Desde Opciones se carga otra (también a mitad de una jugada, con aviso). Cargar inicia una run nueva con la pregunta del tutorial; una ranura vacía se crea de cero. Cada partida muestra monedas totales, monedas desbloqueadas, jugadas, jugadas ganadas, logros y nivel más alto. Las abandonadas o cortadas no cuentan. Borrar con dos confirmaciones («¿Seguro que querés borrar esta partida?» / «¿Estás muy, muy seguro?»). La primera vez no hay ninguna partida creada.

## R2 — Pregunta de tutorial
En cada jugada nueva. Sí → tutorial; No → selección de rival de la campaña.

## R3 — Tutorial
Un nivel idéntico al 1: rivales normales (40 y 70) y el vendedor como jefe (125). No se guarda: salir lo pierde y no da logro ni moneda.
- **Formato**: carteles superpuestos con un texto junto a cada zona; un solo «Continuar» cierra todos los de la pantalla; botón «?» al costado para volverlos a ver; mismo formato en tienda y jugada; no existe «Saltear tutorial».
- **3.1** Presentación: el vendedor de la tienda hablando, leve animación y sonido básico; burbuja «Veo que querés desafiar a Dios. Él no juega a los dados, pero quizás puedas vencerlo.»
- **3.2** Primer encuentro guiado (40): paso a paso; hay que hacer cada acción (seleccionar, tirar, agrupar, anotar); tiradas guionadas, prácticamente imposible de perder.
- **3.3** Selección de rival → tienda obligatoria con $20 y semilla fija elegida a mano; carteles por sección: stickers, cambios de cara, mejoras de número, los 3 tipos de modificadores (gemas, elementos, material) y monedas.
- **3.4** Segundo encuentro (70) sin guía.
- **3.5** Jefe: el vendedor (125); poder «Al finalizar te saca todo el dinero».
- **3.6** Si se pierde un encuentro: termina la jugada y se otorgan igual el logro y la moneda.
- **3.7** Fin (ganando o perdiendo un encuentro; no si se abandona): termina la jugada; la partida suma el logro «Tutorial completado» y desbloquea la moneda **«El regalo del vendedor»**: pasiva (no de un uso), todas las monedas cuestan $1 menos en la tienda, se acumula (dos copias: $2 menos), precio mínimo $1, «se desbloquea» = puede aparecer en las tiendas de esa partida, precio de las plateadas (raras), arte: un signo $ con una flecha hacia abajo.

## R4 — Logros
Por partida. En este alcance solo «Tutorial completado», con la estructura para sumar más.

## Fuera de alcance por ahora
Lista completa de logros; qué desbloquea cada uno; qué monedas están bloqueadas al empezar (por ahora todas las actuales siguen disponibles).

## Notas de implementación (borrador del autor)
Metaprogreso acotado (estaba diferido, F01–F04). Se elimina el guardado de la run; el guardado viejo no se migra. Estadísticas solo al terminar una jugada; «última partida usada» en preferencias; la jugada debug no escribe nada. Textos del tutorial, guion de tiradas, semilla, dinero, objetivos, jefe y logros en tablas de datos. El descuento de C58 debe verse en la tienda y en la previsión de precios, con mínimo 1. La animación del vendedor, la pantalla del bar y el arte de C58 necesitan bocetos aprobados antes de integrar.
