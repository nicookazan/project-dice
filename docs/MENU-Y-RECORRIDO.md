# Menú y recorrido del nivel de prueba

Paso 14 completado el 26 de octubre de 2026. Conserva los objetivos y reglas vigentes; D05 se concreta como decisión de implementación de presentación, sin atribuirla a una aprobación previa del usuario.

Actualización del paso 15: [guardado y Continuar](GUARDADO-Y-CONTINUAR.md) implementados. La evidencia de 978 comprobaciones al final de este documento corresponde al cierre histórico de 14; la suite actual tiene 1083 sin fallos.

## Inicio y navegación

La aplicación abre en `menu`: Nueva partida, Opciones y Salir. Desde 15 muestra Continuar solo con un guardado válido activo, o Recuperar respaldo y continuar cuando existe respaldo válido. Opciones muestra controles y el estado de pantalla; F11 alterna pantalla completa y restaura el modo previo, sin cambiar la partida. Las preferencias duran esta sesión.

Nueva partida usa `begin_run()` para limpiar deuda, inventario, stickers, caras, mejoras, efectos, roturas, compras y decisiones pendientes, y entra en `level_intro`. Anuncia 40 → 70 → 110 y la generala prohibida del jefe. `begin_level()` inicia únicamente el primer encuentro. No hay tienda inicial: cuero, cinco dados base, cero monedas y $0.

El constructor del motor y `restart()` conservan su uso de inicialización en `play` para consumidores de reglas y pruebas; la aplicación usa las operaciones de sesión `begin_run()`, `begin_level()` y `return_to_menu()`. Los estados de sesión se incluyen en el snapshot existente; aún no se escriben archivos de guardado.

## D05 aplicada

Recorrido se consulta mediante el botón superior o M, también desde cobro, reparación y final. Muestra objetivos, estado de cada encuentro y regla del jefe. Es una proyección separada del estado, sin botones que permitan elegir otro rival. La tienda solo permite avanzar al siguiente: rival 1 → rival 2 → jefe.

Desde 15, Menú guarda y conserva la sesión. Abandonar partida es una acción separada con confirmación, que la retira de Continuar. Cerrar la ventana confirma Guardar y salir; un error de guardado mantiene la partida abierta. Seguir jugando, Escape o cerrar la confirmación conserva la sesión. Nueva partida que reemplaza un guardado pide confirmación y conserva archivos anteriores. Desde victoria/derrota se puede volver al menú o reiniciar; la sesión anterior permanece cerrada.

## Estados y transiciones

| Fase | Acciones de avance |
|---|---|
| `menu` | Nueva partida → `level_intro`; opciones o salir |
| `level_intro` | Empezar primer encuentro → `play`; abandonar con confirmación |
| `play` | Tirar, agrupar, reservar, usar moneda, anotar → `hand_result` o `lost` |
| `hand_result` | Segunda mano disponible → `play`; objetivo cumplido → cerrar y cobrar |
| `reward` | Cobro ya acreditado; abrir tienda una sola vez → `shop` |
| `repair` | Elegir carcasas y ver costo/saldo; confirmar selección o continuar sin reparar |
| `shop` | Comprar, vender, renovar; continuar únicamente al siguiente encuentro |
| `purchase_target` / `sticker_choice` | Resolver o cancelar según contrato de compras; no saltear el encuentro |
| `won` / `lost` | Final de sesión, menú, nueva partida; derrota también permite misma semilla |

El cobro es una operación atómica dentro de `close_encounter()`: no existe una fase intermedia con plata parcialmente acreditada. Si hay carcasas rotas, entra en reparación después del cobro y antes de tienda o victoria. D08 se conserva también después del jefe. Sin reparaciones pendientes, vencer al jefe llega directamente a `won` y no abre otra tienda.

Si ya se alcanzó el objetivo en la primera mano, aparecen Cerrar y cobrar y Jugar segunda mano. La pantalla explica que jugar consume el premio de $2 por la mano sobrante. La recompensa se calcula con manos realmente no gastadas. Perder no acredita plata ni abre tienda. Consultar recorrido, cerrar diálogos o redibujar no vuelve a cobrar, resolver reparaciones ni generar stock.

Generala prohibida impide agrupar cinco iguales como generala. Se permite seleccionarlos como trío + par; no se agrupan automáticamente.

## Evidencia

- Suite: **978 comprobaciones, cero fallos**; 938 anteriores y 40 nuevas. `tests/level_flow_tests.gd` y arranque de escena en `tests/run_tests.gd`.
- Recorrido automatizado mediante controles reales de UI, sin modificar resultados, plata ni ofertas: semilla 3, rival 1 con 20 + 40 = 60; rival 2 con 91; jefe con 133. Compra monedas de stock normal. El snapshot final completo (incluido RNG, plata, inventario y eventos) coincide con las mismas acciones sobre el motor. No equivale a una sesión humana ni valida balance.
- Casos controlados separados comprueban mano adicional, derrota sin premio, generala frente a trío/par, reparación final, reinicio total y protecciones contra repeticiones.
- `test-results/tests.json`, sección `level_flow_demo`, conserva la traza natural. `Probar.cmd` repite la suite.
- `tests/level_flow_review.gd` produce once capturas por resolución a 1280×800 y 1440×900: menú, opciones, anuncio, recorrido, abandono, victoria natural, objetivo, cobro, tienda, reparación final y derrota. Prefijos `test-results/1280x800-flujo-` y `1440x900-flujo-`. Ambos procesos terminan sin errores; verifican F11/pantalla completa/restauración en una ventana real y que la partida no cambia.

## Límites

Guardado y Continuar se completaron en 15 (D06 aplicada). Catálogos comerciales finales D01/D02/D04 siguen pendientes: las ofertas normales conservan monedas; las demás familias tienen pruebas explícitas y no se inventaron precios. Siete niveles, otros jefes y arte/audio finales quedan en sus pasos posteriores.
