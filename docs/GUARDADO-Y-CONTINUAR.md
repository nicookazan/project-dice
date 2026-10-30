# Guardado versionado y Continuar

Actualización del 30/10/2026: formato actual **v6**. Se eliminan las mejoras locales de puntos. Al leer v1–v5, sus bonos acumulados se suman al mapa global de cada número y desaparecen los mapas por dado. Las ofertas pendientes antiguas se convierten en globales dentro de los límites de su rareza; una selección local todavía sin pagar se cancela sin cobrar. El saldo, RNG e historia anotada se conservan. El archivo original sigue intacto hasta guardar un nuevo checkpoint.

Actualización del 30/10/2026: formato actual **v5**, con la marca de partida debug. «Continuar» conserva las ayudas de una partida debug; las partidas v1–v4 se cargan como normales. Las rutas se mantienen y no se sobrescribe el archivo al leerlo. Ver [Modo debug](MODO-DEBUG.md).

Actualización del 30/10/2026: formato actual **v4**, con cuatro precios de renovación independientes. V1–v3 migran sin cambiar saldo, stock, inventario ni RNG. Como el formato anterior no registraba qué sección se renovó, sus nuevos contadores comienzan en $1. El progreso sigue en la misma ruta y el próximo guardado conserva el archivo anterior como respaldo. Los apartados siguientes documentan versiones históricas.

Actualización de 18: formato actual **v3**, con campaña completa, nivel actual, jefes elegidos y prefijo de encuentros completados. V1/v2 se migran como partidas cortas, sin expandirlas ni cambiar RNG al leer. Las rutas históricas siguen estables. [Campaña y compatibilidad](CAMPANA-HASTA-DIOS.md). Suite actual: 1959 comprobaciones; los apartados v1/v2 siguientes son antecedentes.

Actualización de 17: formato actual **v2**, con definición elegida del jefe y encuentros/objetivos separados. V1 se migra en memoria a la regla histórica, sin sortear ni sobrescribir al leer; el siguiente checkpoint conserva el v1 como respaldo. Los nombres de archivo partida-v1.json y validacion-nivel-v1.json se mantienen estables para no perder acceso al progreso existente. [Contrato de jefes y compatibilidad](REGLAS-DE-JEFE.md). Suite actual: 1598 comprobaciones; los apartados v1 siguientes documentan la base histórica.

Paso 15 completado el 26 de octubre de 2026. D06 aplicada como decisión técnica al implementar la ficha; no se atribuye a una aprobación previa del usuario ni cambia reglas de juego.

Actualización de 16: corregida la validación después de comprar una cara sobre la posición de la última tirada. En tienda/selección de compra/pack se permiten resultado histórico y cara nueva distintos, conservando la anotación anterior; en juego sigue obligatoria su coincidencia. El formato continúa en v1. El perfil optativo de validación usa otro archivo, validacion-nivel-v1.json. Suite actual: 1553 comprobaciones; la evidencia de 1083 de este contrato corresponde al cierre histórico de 15.

## Uso y ubicación

La partida se guarda automáticamente después de cambios resueltos de juego o de decisiones pendientes de la interfaz. **Menú** guarda y vuelve al menú conservando la partida; **Continuar** restaura ese punto exacto. Cerrar la ventana pide **Guardar y salir**; si la escritura falla, la aplicación permanece abierta y permite reintentar. **Abandonar partida** es una acción separada, con confirmación: la sesión deja de estar disponible en Continuar. Nueva partida pide confirmación cuando reemplaza una sesión activa o un archivo inválido/incompatible.

Ruta normal de Windows: `%APPDATA%/DiosNoJuegaALosDados/saves/partida-v1.json`. Godot usa `user://saves/partida-v1.json`, con directorio de usuario personalizado y estable en `project.godot`. No depende de la carpeta de instalación. El servicio admite otra ruta para pruebas; la suite y capturas usan exclusivamente `test-results/` y una APPDATA de prueba dentro del proyecto.

## Formato v1

Sobre JSON con `format = dios-no-juega-save`, `version = 1`, `payload` y `sha256`. El payload es Base64 de datos Variant de Godot (sin objetos), conservando enteros de 64 bits, decimales, arrays y diccionarios. El hash es SHA-256 de la representación hexadecimal de esos bytes. La semilla y el estado RNG no pasan por números JSON de precisión flotante.

Dentro del payload: `game` es el snapshot completo; `ui` conserva selección de dados, selección de reparaciones, sección de tienda y panel del paquete abierto/cerrado. El nivel actual es el único nivel de prueba (1); `rival` identifica 0/1/2. El formato no incorpora campañas futuras que aún no existen.

Se conservan fase, puntos, mano, tiradas, resultados/índices/caras, grupos y bloqueos, mejoras globales/locales, vaso/stickers y su catálogo explícito, materiales/elementos/carcasas, acumulaciones, roturas, guardas y sorteos ya hechos, historia, eventos, instancias de monedas y consumibles gastados, deuda/plata, cobro aplicado, reparación pendiente o resuelta, tablas/stock/IDs/vacíos, precios de renovación independientes por sección, compras y objetivos pendientes, recibos y candidatos/pago de packs. Las vistas de compatibilidad de monedas/ofertas también se validan; al restaurar mandan las instancias y el stock canónicos, sin ejecutar sus setters de creación.

## Cuándo guardar

La aplicación captura el estado al terminar una acción y reconstruir su pantalla. Compara datos con el último checkpoint: un redibujado sin cambios, una inspección o un mensaje de rechazo no genera otra escritura. Las selecciones pendientes sí forman parte del checkpoint. No se guarda a mitad de puntuar, sortear roturas, pagar una compra o generar ofertas.

Se guarda el anuncio de nivel, las tiradas y movimientos, agrupación/desagrupación, mano anotada, segunda mano, cobro, reparación y su selección, apertura/renovación de tienda, compra/venta/uso, objetivo dado/cara, pack pagado, elección y panel cerrado. Cargar asigna datos validados y restaura semilla + estado RNG directamente: no vuelve a tirar, cobrar, sortear riesgos ni generar ofertas.

## Escritura y recuperación

1. Validar estructura y consistencia del checkpoint antes de escribir.
2. Escribir y vaciar `partida-v1.json.tmp`; leerlo y verificarlo.
3. Copiar el principal a `.bak.tmp`, verificarlo y publicarlo como `.bak` mediante renombrado.
4. Publicar el temporal como principal mediante renombrado que reemplaza el destino. Esta operación se probó en Windows. Si falla antes de publicar, el principal anterior permanece legible; el respaldo también puede recuperarse. No se consume un temporal incompleto al abrir el juego.

Un principal dañado/ausente con respaldo válido ofrece **Recuperar respaldo y continuar**. Recuperar conserva los bytes originales en un archivo `.preserved-…`, prepara y verifica un temporal y publica el respaldo. El respaldo representa el checkpoint anterior y la pantalla lo indica; no se promete recuperar un cambio que nunca llegó al disco.

Si el principal es de otra versión, no se retrocede silenciosamente a un respaldo más antiguo. Si no hay respaldo válido, Continuar no aparece y se informa el error. La escritura automática queda bloqueada para archivos dañados o incompatibles. Una nueva partida explícita conserva los archivos existentes antes de reemplazarlos. No hay migraciones automáticas desde versiones desconocidas.

La validación comprueba tipos y campos obligatorios, datos simples sin objetos ni valores no finitos, fases/rangos, cinco identidades y seis caras, correspondencia resultado/índice, grupos/categorías/bloqueos, inventario y capacidades/instancias, puntos/mejoras, efectos, vaso/stickers, resultados/desgloses, cobro, stock/ofertas, objetivos de compra, candidatos/recibos de pack y selección/destino de reparación. Una carga inválida no muta la partida viva.

## Sesión cerrada

Victoria, derrota o abandono publican el marcador `.closed`. Su presencia impide Continuar desde el principal **y desde respaldos activos anteriores**, incluso si luego se daña o desaparece el principal. No se ofrece una partida terminada ni se restablece una anterior por accidente. El marcador se conserva hasta que una nueva partida explícita tiene principal y respaldo nuevos verificados. Esto separa fin de sesión de preferencias/progreso permanente, todavía fuera de alcance.

Los errores de escritura muestran un botón de reintento sin perder el estado vivo. Salir o volver al menú conservando la partida se bloquea si el guardado no pudo completarse. Esto no promete durabilidad ante cortes de energía, fallos del sistema de archivos o cierre forzado antes de completar una escritura; el respaldo conserva el último checkpoint verificable.

## Evidencia

- **1083 comprobaciones, cero fallos:** 978 anteriores y 105 nuevas. `tests/save_tests.gd`, integrado en `tests/run_tests.gd`; informe `save_demo` en `test-results/tests.json`.
- Ida y vuelta exacta de ocho fases activas: anuncio, juego con grupo bloqueado y dado en vaso, resultado, cobro, tienda, reparación, compra objetivo y pack pendiente. Próxima tirada/stock/renovación idénticos a ejecución ininterrumpida. Conserva deuda, metales/elementos, moneda gastada y resultados de rotura/cobro sin repetirlos.
- Enteros extremos de 64 bits conservados sin pérdida. Fallos inyectados antes de escribir, después del temporal y después del respaldo; archivo corrupto/único, checksum, versión futura, recuperación y archivo original conservado. Rechazo de tipos y estados incoherentes.
- UI real: guardado por tirar, menú/Continuar, segunda instancia de aplicación, error y reintento, cancelación/confirmación de abandono, reparación seleccionada y pack pagado cerrado, y recorrido natural completo con autosave hasta victoria (semilla 3).
- Dos ejecuciones independientes de Godot con `tests/save_process_smoke.gd -- --write` y luego `-- --read`: el segundo proceso recupera estado y siguiente tirada exactos. Archivos en `test-results/process-save/`.
- Siete capturas por resolución, 1280×800 y 1440×900, con `tests/save_review.gd`: Continuar, confirmación de nueva partida, reanudada, error de escritura, respaldo disponible, versión futura y reparación pendiente. Ambos procesos terminan sin errores. Prefijos `1280x800-guardado-` / `1440x900-guardado-`.

## Límites

Persistencia local v1 para este prototipo; no sincroniza nube, cuentas, metaprogreso ni preferencias de pantalla. Los respaldos históricos se conservan; no se implementó una política de limpieza automática. Las pruebas no modifican el guardado del jugador. No se aprueba balance comercial pendiente D01/D02/D04 ni se declara validación humana de diversión. Siguiente paso: 16, validación integral y valores de prueba explícitos.
