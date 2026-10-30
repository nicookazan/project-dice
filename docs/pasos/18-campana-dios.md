# 18 — Progresión de siete niveles hasta Dios

Versión 1 · 25 de octubre de 2026.

**Entrega:** Hasta Dios. **Estado actual:** Campaña técnica provisional implementada y probada: 1959 comprobaciones aprobadas, cero fallos. Siete niveles/21 encuentros y continuidad de guardado completos. D07 conserva catálogo/objetivos/recompensas definitivos pendientes; no se declara aceptación del contenido final ni balance humano.

**Depende de:** [16 — Validación integral del primer nivel](16-validar-nivel.md), [17 — Reglas de jefe y efectos suspendidos](17-motor-jefes.md). **Decisiones vinculadas:** D07. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [18 en Notion](https://app.notion.com/p/404c28142b558179b72fdb4c16dd46a9?pvs=204).

Extender el recorrido estable a siete niveles y 21 encuentros, con objetivos fijos y preparación visible para cada jefe.

## Fuente y alcance normativo
PRD IA §3, §11–12; recorte posterior hasta Dios en PRD-PROTOTIPO. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Sustituir TARGETS y posiciones fijas por datos de siete niveles, cada uno con dos rivales y un jefe.
2. Objetivos comunes predeterminados por nivel/posición; objetivos de jefe por su definición o regla. No adaptarlos a las mejoras del jugador.
3. Niveles 1–6: tres candidatos propios por nivel, uno sorteado por partida. Nivel 7: Dios con una de tres reglas posibles.
4. Registrar D07: nombres, reglas, objetivos y recompensas no están completos. Un recorrido técnico puede usar datos provisionales etiquetados; la aceptación de contenido exige completar ese catálogo.
5. Anunciar el jefe al entrar al nivel y mantener su condición visible durante preparación. Guardar el sorteo.
6. Tienda después de cada victoria que tenga siguiente encuentro. Vencer a Dios cierra esta versión; CMD está en F02.
7. Conservar mejoras y plata; reiniciar puntuación y contadores de encuentro según contrato; cambiar ambiente después del jefe.
8. Mostrar avance en mapa/lista sin permitir saltos.

## Criterios de aceptación
- Exactamente 21 encuentros por partida de esta versión; no se confunde el catálogo de 18 jefes alternativos con 18 jefes enfrentados.
- Cada uno de los primeros seis jefes pertenece al conjunto de su nivel.
- Dos partidas con igual semilla/acciones reproducen sorteos, incluidas cargas intermedias.
- La fuerza del inventario no cambia los objetivos.
- Al pasar de un jefe al nivel siguiente persisten caras, monedas y stickers, pero no puntos ni acumulaciones de encuentro.
- Una victoria ante Dios cierra la partida y no abre una tienda hacia un nivel no implementado.

## Entregable
Campaña por datos y pruebas de avance completo, derrota en distintos puntos y continuidad de guardado. Tabla de objetivos/recompensas con valores aprobados para prueba.

## Fuera de alcance
Nivel 8, saltar encuentros, modo sin fin y rellenar el catálogo con efectos no definidos sin marcarlos como provisionales.

## Cierre del paso

[Contrato y evidencia](../CAMPANA-HASTA-DIOS.md) y [datos provisionales](../DATOS-DE-PRUEBA-CAMPANA.md). Nuevas partidas de Jugar.cmd/F5 abren campaña provisional completa con cinco dados y $0; Nivel-corto.cmd conserva el modo anterior y Validar-nivel.cmd el corto de validación. Guardados antiguos se reanudan como cortos, sin expandirlos.

Campaña por datos con tres candidatos propios en niveles 1–6 y tres reglas de Dios, sorteadas al entrar al nivel y guardadas. Objetivos fijos, recompensa base del jefe por definición y progresión sin saltos. Tras cada victoria con siguiente encuentro: cobro, reparación y tienda. Las seis transiciones conservan equipamiento/plata y reinician puntos/contadores; nuevo anuncio y ambiente provisional. Dios cierra exactamente el encuentro 21, sin tienda/nivel 8.

Guardado v3 con migración v1/v2 sin perder azar/decisiones; valida pool del jefe y prefijo de progreso. Archivos: scripts/campaign.gd, game.gd, rules.gd, save_store.gd, save_validator.gd, main.gd, backdrop.gd, Nivel-corto.cmd y pruebas campaign_tests.gd/campaign_smoke.gd/campaign_review.gd más integración/escenas cortas explícitas.

Suite: 1959 (1598 anteriores + 361 nuevas), cero fallos. Ruta UI de laboratorio completa: 21 encuentros, seis cambios de nivel, seis reparaciones, 21 previsiones/anotaciones iguales y cargas entre etapas. Ayudas explícitas de laboratorio: +250 global al 4 y $100; no se aplican al jugar. Derrotas en inicio, nivel 4 y Dios; comprobación de objetivo fijo, sorteo reproducible, continuidad de piezas/monedas/stickers y bloqueo de duplicaciones/saltos. Informe campaign_demo en test-results/tests.json.

Diez capturas por resolución revisadas a 1280×800 y 1440×900, ambos procesos sin errores. Inicio normal verificado sin ayudas. Ambientes son tintes/identificadores con arte actual; presentación final en 19. D07 y balance final siguen pendientes. Siguiente: 19 con D10.

