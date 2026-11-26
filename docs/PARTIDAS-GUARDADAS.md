# Partidas guardadas (metaprogreso)

Contrato del 17/11/2026 (ficha [TU-tutorial](pasos/TU-tutorial.md), fases TU1–TU3, decisión D18). **Reemplaza** al guardado de la jugada en curso: ver [GUARDADO-Y-CONTINUAR](GUARDADO-Y-CONTINUAR.md), que queda como historia.

## Vocabulario

> **Cambio del 24/11/2026 (D20, PS1):** en la interfaz la corrida de juego se llama **partida** («Nueva partida», «Abandonar partida») y el perfil de metaprogreso se llama **progreso** («Progreso guardado», «Progreso 1», «2» y «3»). El formato y los nombres de archivo de abajo no cambian, para no perder progresos ya guardados. El resto de este contrato usa todavía los nombres viejos.

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

## Final de La Semilla visto (24/11/2026)

Clave opcional `seed_finale_seen` (sí/no): se escribe al ver entero el final de La Semilla y habilita «Omitir animación». Un archivo sin la clave sigue siendo válido y no cambia la versión. Una jugada con semilla elegida (por ejemplo «Reintentar misma semilla») no suma nada a la partida guardada. Ver `docs/LA-SEMILLA.md`.

## Guardado de «Continuar partida» v11 (25/11/2026)

`SaveStore.VERSION` pasa a 11 porque la tienda suma la sección `single_use` (moneda de un uso, D20 opción B). `save_migrations.gd: single_use_v11` agrega a las partidas guardadas antes su contador de renovación (en 1) y, si estaban en una tienda, la sección vacía y sin configurar: no se re-sortea nada, así el azar queda exacto. Los regalos de la mano con el maletín pueden ser hasta cinco (uno por sección).

## Guardado v12 (25/11/2026)

`save_migrations.gd: rewards_v12`: el stock de monedas guardado se recorta a tres (sin re-sortear), las tablas guardadas pierden el paquete y pasan sus gemas a `gems`, y se agrega `pending_reward` vacío. Fase nueva `bonus` (recompensa pendiente).
