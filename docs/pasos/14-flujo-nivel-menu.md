# 14 — Menú y recorrido de un nivel completo

Versión 1 · 25 de octubre de 2026.

**Entrega:** Nivel jugable. **Estado actual:** Completado el 26 de octubre de 2026; 978 comprobaciones aprobadas, cero fallos. D05 aplicada como decisión de implementación de presentación; dependencias 08 y 13 completadas.

**Depende de:** [08 — Rotura de carcasas y reparación opcional](08-rotura-reparacion.md), [13 — Mesa, libreta, inspección y tienda jugable](13-interfaz-inspeccion.md). **Decisiones vinculadas:** D05. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [14 en Notion](https://app.notion.com/p/404c28142b558165b8fff353bb0348c4?pvs=204).

Conectar los sistemas en una sesión coherente: nueva partida, anuncio del nivel, dos rivales, jefe, compras y final.

## Fuente y alcance normativo
PRD IA §3, §12–13; PRD-PROTOTIPO §4–5. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Crear estados explícitos de menú, presentación del nivel, encuentro, resultado de mano, cobro, reparación, tienda y final.
2. Nueva partida comienza con cuero, cinco dados base, cero monedas y plata cero; no hay tienda inicial.
3. Mantener el nivel de prueba 40 → 70 → 110. Anunciar generala prohibida desde el comienzo del nivel y mantener la regla consultable.
4. Permitir únicamente el siguiente encuentro; la selección del recorrido sirve para consultar y continuar, no para saltar.
5. Al llegar al objetivo después de anotar, ofrecer cerrar/cobrar o jugar otra mano disponible. Recompensa usa manos realmente no gastadas.
6. Resolver cobro una vez, reparación opcional y luego tienda antes del siguiente encuentro. Vencer al jefe cierra este nivel de prueba.
7. Mostrar victoria/derrota y nueva partida. Continuar se conectará con el guardado real en 15; no presentar un botón que no hace nada.
8. Propuesta de menú mínimo: Nueva partida, Continuar cuando exista guardado, Opciones y Salir. Colección se difiere hasta tener contenido.
9. Definir bajo D05 dónde se puede consultar el recorrido y qué confirma abandonar una partida activa.

## Criterios de aceptación
- Recorrido completo desde menú hasta jefe ganado sin utilizar herramientas de prueba.
- Generala prohibida rechaza cinco iguales agrupados como generala, pero permite trío+par.
- Salir del resultado no repite cobro, reparación ni renovación inicial.
- Perder antes del objetivo no abre tienda ni concede recompensas.
- Jugar la mano adicional después de alcanzar el objetivo elimina el premio de mano sobrante correspondiente.
- Nueva partida limpia todos los efectos, inventario y deuda.

## Entregable
Primer recorrido corto con todos los sistemas nuevos accesibles y estados documentados para guardado. D05 es una elección de presentación, no una reapertura de las reglas de grupos.

## Fuera de alcance
Siete niveles, catálogo de jefes y menú de logros completos.

## Cierre del paso

Menú real, anuncio inicial, recorrido consultable sin saltos, confirmación de abandono/cierre y finales conectados. Opciones incluye F11 funcional. Sin Continuar ficticio ni tienda inicial. La mano adicional informa el premio que consume; cobro, reparación D08 y generación de tienda conservan sus guardas de ejecución única, también al vencer al jefe.

Archivos: scripts/game.gd, scripts/main.gd, tests/run_tests.gd, tests/level_flow_tests.gd, tests/level_flow_review.gd y [contrato del recorrido](../MENU-Y-RECORRIDO.md). Documentación de estado, índice y D05 actualizados.

Suite: 978 comprobaciones (938 anteriores + 40 nuevas), cero fallos. Partida natural mediante UI con semilla 3: 60 contra 40, 91 contra 70, 133 contra 110; compras de stock generado, sin inyección de dados, plata u ofertas. Snapshot final exacto igual al recorrido del motor. Evidencia: level_flow_demo en test-results/tests.json. Casos de borde separados usan fixtures explícitos.

Once capturas por resolución revisadas a 1280×800 y 1440×900; pruebas de pantalla completa/restauración F11 en ambas ventanas, sin cambios de partida. No es validación de balance ni sesión humana. D01/D02/D04 siguen pendientes; el paso 15 sigue con guardado y decisión D06. D05 no cambia reglas y no se atribuye a aprobación previa del usuario.

