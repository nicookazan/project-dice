# Partidas guardadas (metaprogreso)

Contrato del 17/11/2026 (ficha [TU-tutorial](pasos/TU-tutorial.md), fases TU1–TU3, decisión D18). **Reemplaza** al guardado de la jugada en curso: ver [GUARDADO-Y-CONTINUAR](GUARDADO-Y-CONTINUAR.md), que queda como historia.

## Vocabulario

- **Jugada** (en el código «run»): una corrida de juego, de empezar a ganar o perder. **No se guarda ni se continúa.** Salir a mitad la pierde y no cuenta en nada.
- **Partida guardada**: el perfil que reúne las estadísticas de sus jugadas, los logros y las monedas desbloqueadas. Es **lo único que se guarda**. Hay tres ranuras: «Partida guardada 1», «2» y «3», sin nombre propio.

## Archivos

- `user://partidas/partida-guardada-N.json` (N = 1–3), en `%APPDATA%/DiosNoJuegaALosDados/partidas/`. Código: `scripts/profile_store.gd`.
- Sobre JSON con `format = dios-no-juega-partida-guardada`, `version = 1`, `data` (el contenido como texto JSON) y `sha256` de ese texto.
- Contenido (`data`): `plays`, `wins`, `best_level` (0–7), `achievements` (lista de ids), `unlocked_coins` (lista de ids). **«Monedas totales» no se guarda**: sale del catálogo (`Coins.catalog()`), así crece solo cuando se agregan monedas.
- La **última partida usada** va en las preferencias (`last_profile`: 0 = ninguna, 1–3), no en el archivo de la partida.
- Escritura atómica (temporal + renombrado). **Un archivo inválido, de otra versión o con la suma de control rota nunca se sobrescribe**: la lectura devuelve el error, `record_run` y `create` fallan y el archivo queda como estaba. Borrar es la única forma de eliminarlo (siempre con dos confirmaciones).

## Cuándo se escribe

- **Solo cuando una jugada termina** (ganada o perdida): `Main.record_finished_run()`, una vez por jugada (`run_recorded`). Suma una jugada, una victoria si ganó y sube `best_level` al nivel alcanzado.
- **Abandonar, volver al menú o cerrar el juego no escriben nada.** Tampoco los cambios de pantalla ni redibujar.
- **La jugada debug no escribe nada** (ni estadísticas, ni logros, ni desbloqueos), y tampoco carga las monedas desbloqueadas de la partida.
- **El tutorial terminado** (ganando o perdiendo un encuentro; no si se abandona) **no suma jugadas ni victorias**: solo da el logro «Tutorial completado» y, con él, desbloquea «El regalo del vendedor» (ver [TUTORIAL](TUTORIAL.md)).
- Primera vez que se abre el juego: no hay ninguna partida. La primera «Nueva jugada» crea la Partida guardada 1 (vacía) y la deja como última usada.

## Interfaz

- **Pantalla inicial** (`Main.render_menu`): menú a la izquierda (Nueva jugada, Nueva jugada debug —solo si `OS.has_feature("debug")`, no llega al ejecutable final—, Opciones, Salir del juego con confirmación). No hay «Continuar». A la derecha, el bar con el mate, la bandera, los sifones y la mano de Dios (`BarProps`, las interacciones de siempre, sin inventar nuevas). Los botones toman el foco: se navega con el teclado.
- **Nueva jugada** pregunta «¿Querés jugar el tutorial?» en cada jugada nueva (Sí → tutorial, No → campaña). Si hay una jugada en curso, pide confirmación antes porque se pierde.
- **Menú de la jugada**: «Seguir jugando», «Recorrido · M», «Opciones», «Ir a otro nivel» (solo campaña) y **«Abandonar jugada»** (aviso: se pierde y no cuenta). Ya no existe «Guardar y salir» ni «Guardar y volver al menú».
- **Opciones → «Partidas guardadas»**: las tres ranuras con jugadas, ganadas, nivel más alto, logros, monedas totales y desbloqueadas. «Cargar» (o «Crear y cargar» si está vacía) deja esa partida en uso y arranca una jugada nueva con la pregunta del tutorial; con una jugada en curso avisa que se pierde. «Borrar» pide dos confirmaciones: «¿Seguro que querés borrar esta partida?» y «¿Estás muy, muy seguro?». Cancelar vuelve al panel.
- Al abrir el juego **siempre está cargada la última partida usada** (la primera existente si la guardada ya no existe).

## Qué pasó con el guardado de la jugada

- La jugada ya no se escribe a disco y no existe forma de continuarla. El guardado viejo (`partida-v1.json`) **no se migra ni se borra**.
- Se conserva **en memoria** `Game.snapshot()`, `SaveStore` (codificar/validar/restaurar), `SaveValidator` y las migraciones v1–v9: las usan las pruebas para comprobar que el azar es exacto tras restaurar. `main.gd` ya no las usa. `save_tests.gd` se redujo a lo que prueba esas piezas más la comprobación de que la interfaz no ofrece continuar ni escribe el archivo viejo. (El plan proponía retirarlas; se dejaron porque 17 suites dependen de ellas y de nada más sirve borrarlas.)

## Pruebas

`tests/tutorial_tests.gd` (crear, leer, registrar jugadas y tutorial, archivo dañado/alterado, escritura interrumpida, borrar, preferencias, panel de Opciones con la doble confirmación, abandono sin escritura, debug sin escritura, partidas independientes).
