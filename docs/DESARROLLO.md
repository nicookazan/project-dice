# Desarrollo — acceso al plan vigente

El plan detallado está en [pasos/README.md](pasos/README.md): 25 fichas separadas, dependencias, criterios de aceptación y vínculos al tablero de Notion. Los pasos 00–18 están completados en su alcance técnico; continuar por [19 — Ambientes, narrativa breve, audio y accesibilidad](pasos/19-presentacion-ambientes.md), con D10 por definir. Campaña provisional de siete niveles/21 encuentros y suite de 1959 comprobaciones. D07, balance definitivo y sesión humana siguen pendientes. D09 resuelta, D05/D06 aplicadas y D08 resuelta.

El esquema de cinco bloques que sigue se conserva como antecedente. Sus bloques amplios fueron descompuestos en las fichas del nuevo plan; usar esas fichas para ejecutar y registrar avances.

## Esquema anterior de cinco bloques

Fecha: 25 de octubre de 2026. Entregas incrementales para llegar a la versión hasta Dios. No representan plazos ni funcionalidades ya completadas.

## Bloque 1 — base recuperada y núcleo vigente

Estado: implementado y verificado.

- Demo recuperada desde C:/Users/Kazan/Desktop/Godot/project-dice a la carpeta de este proyecto, con arte y escenas.
- Godot 4.7.1 / GDScript confirmado contra el ejecutable instalado.
- Fuentes guardadas y reglas reconciliadas en [REGLAS-VIGENTES.md](REGLAS-VIGENTES.md).
- Doble par: cuatro dados, dos números distintos repetidos dos veces, base 15. Libreta, detalle, anotación y ayuda integrados.
- Dos pares separados siguen permitidos; el quinto dado solo puntúa una vez.
- Sin bono de servida inventado para doble par; queda documentado como pendiente.
- Intereses con deuda corregidos a cero, como exige la futura reparación.
- Movimientos con identificadores de dado fuera de rango rechazados sin cambiar estado.

Verificación: 105 comprobaciones previas aprobadas; 132 después de los cambios. Una de ellas recorre las 1.296 selecciones ordenadas de cuatro dados y reconoce exactamente las 90 de doble par. Incluye pruebas de la interfaz real, vista previa frente a anotación, bloqueo, categorías vecinas, monedas, tienda, victoria y derrota.

Informes: test-results/tests.json. Revisión visual: test-results/doble-par.png y test-results/doble-par-anotado.png. Para repetir: Probar.cmd. El guion de capturas es tests/visual_review.gd y usa estados controlados fuera de la partida normal.

La copia original del Escritorio conserva la demo anterior. La continuación de este chat utiliza esta carpeta. No hay cambios publicados ni sincronización automática entre ambas copias.

## Bloque 2 — dados persistentes y efectos

Objetivo: que los mismos cinco dados conserven caras, mejoras y componentes a lo largo de la partida.

Implementar datos por dado y mejoras globales; metales, elementos, carcasas, rotura posterior al puntaje y reparación opcional. Mantener separadas las duraciones de mano, encuentro y partida. Preparar un desglose que muestre decimales sin truncarlos.

Criterios: acero persiste entre manos y se borra al relanzarse; cobre acumula por encuentro; tierra/viento se reinician por mano; electricidad cuenta coincidencias de sobrantes; esmeralda afecta solo puntos propios; rubí multiplica después de sumar los aportes aditivos; diamantes no se duplican entre sí. Previsión sin consumir azar ni disparar roturas. Reparación cobra después de la recompensa y admite deuda.

Dependencia: bloque 1. No depende del catálogo completo ni de precios de tienda.

## Bloque 3 — tienda ampliada

Objetivo: conseguir y aplicar los efectos jugando.

Cuatro secciones de ofertas y vaso reservado con la distribución aprobada; renovación individual con costo compartido; selección de dado/cara; cambios de componente; stickers y paquetes; inventario y límites de monedas.

Criterios: comprar no repone; renovar no cambia otras secciones; sustituir una carcasa conserva material, elemento y mejoras; packs no repiten categorías dentro del mismo contenido. Precios y probabilidades iniciales deben quedar marcados como balance provisional.

Dependencias: bloque 2; incrementos iniciales de stickers y ofertas locales.

## Bloque 4 — menú, guardado y un nivel completo

Objetivo: nueva partida → presentación de nivel y regla del jefe → dos encuentros con tiendas → jefe → victoria/derrota, con continuar partida.

Criterios: guardar/reanudar mantiene dados, grupos y bloqueos, tiradas, inventario, plata, ofertas, fases y estado aleatorio. Retomar no duplica recompensas ni vuelve a sortear resultados. Nueva partida limpia efectos y progreso de la partida anterior.

Dependencias: bloques 2 y 3. Definir momentos de guardado antes de implementar persistencia.

## Bloque 5 — progresión hasta Dios

Objetivo: siete niveles y 21 encuentros con progresión de objetivos y reglas de jefe.

Dependencia: recorrido corto estable. Introducir contenido por datos y probar objetivos, economía y duración. Dios cierra este alcance; CMD queda para una etapa posterior.
