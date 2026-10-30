# Plan de desarrollo — índice

Versión 1 · 25 de octubre de 2026.

**El [19 — Presentación](19-presentacion-ambientes.md) se reabrió para su pase artístico tras la revisión del usuario.** Mano/nube originales restauradas; variantes de jefes, exteriores y Dios deben respetar el pixel art existente. Integración técnica de 00–19 probada: 2017 comprobaciones, cero fallos. Luego sigue [20 — Balance, pruebas finales y entrega ejecutable](20-balance-entrega.md); cuatro futuros permanecen diferidos. [Presentación y pendientes](../PRESENTACION-Y-ACCESIBILIDAD.md). Mate siempre confirmado; textos, mezcla, catálogo D07 y balance/sesión humana pendientes.

## Cómo se organiza

- El PRD es la referencia del diseño; las decisiones posteriores de PRD-PROTOTIPO prevalecen.
- Cada archivo es una especificación de implementación acotada: objetivo, fuente, dependencias, acciones, ejemplos de aceptación y límites.
- El tablero de Notion mantiene estado y dependencias. Las fichas y sus archivos locales contienen la misma especificación inicial.
- No existe sincronización automática: al cambiar alcance, actualizar ficha y archivo en la misma revisión. No crear nuevos PRD generales que compitan con los actuales.
- Los nombres de archivos/módulos futuros son orientativos. Se puede resolver arquitectura técnica sin reabrir reglas ya confirmadas.

## Accesos

- [Guía en Notion](https://app.notion.com/p/404c28142b5581cb83f6d6e0dac2b518?pvs=204)
- [Tablero hasta Dios](https://app.notion.com/p/404c28142b55801bb144dacac6f0f68a?v=404c28142b5580968f14000cbe304990)
- [Próximo paso en Notion](https://app.notion.com/p/404c28142b558115afb1ea4f9eb6eaa1?pvs=204)
- [Decisiones pendientes](DECISIONES.md) y [su página en Notion](https://app.notion.com/p/404c28142b55811aa9a9deb54343f361?pvs=204)
- [Cobertura del PRD y precedencia](COBERTURA.md)
- [Reglas vigentes](../REGLAS-VIGENTES.md)

## Secuencia recomendada

| Paso | Entrega | Depende de | Estado actual |
|---|---|---|---|
| [00 — Base recuperada y reglas vigentes](00-base-verificada.md) | Base | — | Completado |
| [01 — Estado persistente de partida y dados](01-estado-dados.md) | Motor de reglas | 00 | Completado |
| [02 — Cálculo de puntos y eventos sin efectos secundarios](02-puntuacion-eventos.md) | Motor de reglas | 01 | Completado |
| [03 — Mejoras globales, locales y cambios de cara](03-numeros-caras.md) | Motor de reglas | 01, 02 | Completado |
| [04 — Acero y cobre con duración por encuentro](04-metales.md) | Motor de reglas | 02, 03 | Completado |
| [05 — Fuego, agua y electricidad](05-elementos-condicionales.md) | Motor de reglas | 02, 03 | Completado |
| [06 — Tierra y viento con duración por mano](06-elementos-acumulativos.md) | Motor de reglas | 04, 05 | Completado |
| [07 — Poderes de esmeralda, rubí, zafiro y diamante](07-poderes-gemas.md) | Motor de reglas | 02, 04, 05, 06 | Completado |
| [08 — Rotura de carcasas y reparación opcional](08-rotura-reparacion.md) | Motor de reglas | 07 | Completado; D08 resuelta |
| [09 — Stickers por categoría y paquetes](09-stickers-paquetes.md) | Nivel jugable | 02 | Modelo/operaciones completados; catálogo pendiente D02 |
| [10 — Monedas iniciales e inventario extensible](10-monedas-inventario.md) | Nivel jugable | 01, 02 | Completado; D03 futura pendiente |
| [11 — Generación de tienda y renovación por sección](11-tienda-ofertas.md) | Nivel jugable | 03, 09, 10 | Modelo/generador completados; datos finales D01/D02/D04 |
| [12 — Compras, selección de objetivos y reemplazos](12-compras-aplicacion.md) | Nivel jugable | 08, 09, 10, 11 | Transacciones completadas; datos finales D01/D02/D04 |
| [13 — Mesa, libreta, inspección y tienda jugable](13-interfaz-inspeccion.md) | Nivel jugable | 12 | Completado; D08 resuelta |
| [14 — Menú y recorrido de un nivel completo](14-flujo-nivel-menu.md) | Nivel jugable | 08, 13 | Completado; D05 aplicada |
| [15 — Guardado versionado y continuar partida](15-guardado-continuar.md) | Nivel jugable | 14 | Completado; D06 aplicada |
| [16 — Validación integral del primer nivel](16-validar-nivel.md) | Nivel jugable | 15 | Validación técnica completada; balance final y sesión humana pendientes |
| [17 — Reglas de jefe y efectos suspendidos](17-motor-jefes.md) | Hasta Dios | 10, 15 | Motor completado; D09 resuelta, D07 catálogo pendiente |
| [18 — Progresión de siete niveles hasta Dios](18-campana-dios.md) | Hasta Dios | 16, 17 | Campaña técnica provisional completada; D07 final pendiente |
| [19 — Ambientes, narrativa breve, audio y accesibilidad](19-presentacion-ambientes.md) | Hasta Dios | 13, 18 | En curso: pase artístico reabierto; mano/nube originales restauradas |
| [20 — Balance, pruebas finales y entrega ejecutable](20-balance-entrega.md) | Hasta Dios | 18, 19 | Listo para empezar; D07/D11 y sesión humana pendientes |
| [F01 — Monedas activas, copias y rescates](F01-monedas-avanzadas.md) | Posterior | 10, 15, 17 | Diferido |
| [F02 — Nivel 8, simulación y jefe CMD](F02-simulacion-cmd.md) | Posterior | 20 | Diferido |
| [F03 — Vasos, colección y progreso permanente](F03-vasos-progreso.md) | Posterior | F02 | Diferido |
| [F04 — Otros materiales y sinergias futuras](F04-materiales-sinergias-futuras.md) | Posterior | 20 | Diferido |

Orden no significa fecha ni duración. Se recomienda ejecutar una ficha por vez, comprobar su entrega y entonces habilitar la siguiente. Algunas dependencias permiten trabajo independiente, pero no se propone desarrollar todo simultáneamente.

## Hitos verificables

Persistencia de 15 y validación técnica de 16 completadas: [guardado y Continuar](../GUARDADO-Y-CONTINUAR.md), [informe integral](../VALIDACION-INTEGRAL-NIVEL.md), 1553 comprobaciones. No confundir cobertura automatizada con sesión humana o balance aprobado.

1. **Motor ampliado, 01–08:** dados persistentes, cálculo, números, materiales, elementos y carcasas. Se demuestra con estados controlados sin depender de compras aleatorias.
2. **Nivel corto completo, 09–16:** stickers, monedas, tienda, UI, menú y guardado. Debe poder jugarse de principio a fin antes de ampliar la campaña.
3. **Hasta Dios, 17–20:** reglas de jefe, siete niveles/21 encuentros, presentación, balance y ejecutable local.
4. **Posterior, F01–F04:** catálogo avanzado, CMD/22 encuentros, metaprogreso y otras ideas. El detalle queda preservado; activarlo exige priorización y resolver sus decisiones.

## Procedimiento para ejecutar una ficha

1. Leer la ficha, sus fuentes y decisiones vinculadas. Confirmar dependencias terminadas con evidencia.
2. Si falta una regla necesaria para ese paso, resolver solo esa decisión; continuar las partes independientes. No transformar ejemplos de fixtures en balance aprobado.
3. Pasar Estado a En curso e implementar el alcance indicado.
4. Ejecutar pruebas de la regla y sus interacciones; revisar la interfaz cuando cambie.
5. Registrar archivos, resultado de pruebas, demostración y límites conocidos. Marcar Listo solo cuando cumpla los criterios.
6. Revisar tareas dependientes y actualizar Disponibilidad a mano. El tablero no calcula automáticamente esta propiedad.
7. Sincronizar cambios de especificación entre la ficha y su archivo; conservar IDs.

## Cómo leer estados y decisiones

**Estado** usa las opciones existentes de Notion: Sin empezar, En curso y Listo. Listo significa terminado. **Disponibilidad** separa Completado, Listo para empezar, Depende de otro paso, Falta definir y Diferido.

D01–D13 describen qué falta, cuándo se necesita y qué puede hacerse antes. Por ejemplo, el motor numérico puede programarse con valores explícitos; sus precios se resuelven para las ofertas. La vista de decisiones muestra fichas vinculadas, no trece bloqueos globales.

## Evidencia de partida y límites

La base recuperada se documenta en 00 con 132 comprobaciones. Los pasos 01–14 llevaron la suite a 173, 242, 328, 391, 470, 524, 581, 666, 722, 795, 848, 898, 938 y 978 respectivamente. Ver los contratos de [estado](../ESTADO-DE-PARTIDA.md), [cálculo/eventos](../PUNTUACION-Y-EVENTOS.md), [mejoras numéricas](../MEJORAS-NUMERICAS.md), [metales](../METALES.md), [elementos condicionales](../ELEMENTOS-CONDICIONALES.md), [elementos de mano](../ELEMENTOS-DE-MANO.md), [gemas](../GEMAS.md), [rotura/reparación](../ROTURA-Y-REPARACION.md), [stickers/paquetes](../STICKERS-Y-PAQUETES.md), [monedas/inventario](../MONEDAS-E-INVENTARIO.md), [tienda por secciones](../TIENDA-POR-SECCIONES.md), [compras/objetivos](../COMPRAS-Y-OBJETIVOS.md), [interfaz/inspección](../INTERFAZ-E-INSPECCION.md), [menú/recorrido](../MENU-Y-RECORRIDO.md) y las fichas de cierre.

No se asignaron responsables, fechas ni estimaciones inventadas. Validación de diversión y equilibrio depende de sesiones del jugador. Los valores de la demo son punto de partida, no balance final.

## Alcance histórico

Se excluyen del recorrido actual la compra/venta de dados, ampliación de cantidad, destrucción del dado por carcasa, usos seguros de cristal, dos tiradas y victoria automática por generala servida. El nivel 8/CMD se conserva como futuro; infierno/diablo fue reemplazado. Ver COBERTURA.md para el mapa completo.

