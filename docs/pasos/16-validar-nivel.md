# 16 — Validación integral del primer nivel

Versión 1 · 25 de octubre de 2026.

**Entrega:** Nivel jugable. **Estado actual:** Validación técnica completada el 26 de octubre de 2026: 1553 comprobaciones aprobadas, cero fallos; 68 manos comparadas sin diferencias. Perfil provisional v1 explícito para D01/D02/D04; balance final y sesión humana pendientes. D05/D06 aplicadas y D08 resuelta.

**Depende de:** [15 — Guardado versionado y continuar partida](15-guardado-continuar.md). **Decisiones vinculadas:** D01, D02, D04, D05, D06, D08. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [16 en Notion](https://app.notion.com/p/404c28142b558140978ee9aa8864392a?pvs=204).

Cerrar una versión corta verdaderamente jugable y estable antes de multiplicar el contenido a siete niveles.

## Fuente y alcance normativo
PRD-PROTOTIPO §8–9; PRD IA §18 criterios de aceptación. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Ejecutar regresión de reglas, compras y persistencia con los datos nuevos. Adaptar pruebas heredadas por representación, nunca rebajar expectativas para ocultar un fallo.
2. Cubrir una ruta con modificaciones numéricas, cada familia de componente, moneda, sticker y pack; crear escenarios controlados para los contenidos difíciles de obtener.
3. Jugar una ruta normal desde menú a victoria y otra a derrota, con tiendas, reparación y reanudación.
4. Comparar cada previsión con la puntuación acreditada y registrar el desglose si difieren.
5. Revisar que no se pueda duplicar una compra, recompensa, sticker de pack o reparación por doble clic, cambio de pantalla o carga.
6. Registrar observaciones de claridad: dudas al conservar/fijar, interpretación de riesgo, precios, desglose y tiempo de compra.
7. Elegir valores de prueba explícitos para decisiones de balance aún abiertas antes de esta sesión. No afirmar que son definitivos.
8. Resolver defectos que rompan reglas o continuidad antes del paso 18; separar cambios de equilibrio de errores funcionales.

## Criterios de aceptación
- Suite funcional sin fallos, con informe fechado y versión/datos usados.
- Capturas revisadas de fases principales y demostración reproducible del recorrido con semilla.
- Cero diferencias entre previsión y anotación en los escenarios del catálogo inicial.
- El jugador puede reconocer qué compra, qué se reemplaza, qué está roto y por qué perdió.
- Guardar/cargar en compra, mano y recompensa no altera el resultado.
- Lista de problemas restante clasificada por gravedad y equilibrio; nada que impida completar la sesión queda oculto.

## Entregable
Informe de pruebas del nivel corto, datos de balance usados y lista de ajustes. La validación humana de diversión queda explícita como pendiente hasta que el usuario juegue.

## Fuera de alcance
No declarar balance global ni extrapolar la duración del nivel corto a 21 encuentros. No exigir todas las monedas o jefes antes de validar la base.

## Cierre del paso

[Informe integral](../VALIDACION-INTEGRAL-NIVEL.md) y [datos de prueba v1](../DATOS-DE-PRUEBA-NIVEL.md). Suite: 1553 comprobaciones (1083 anteriores + 470 nuevas), cero fallos. Cuatro rutas naturales por UI con reanudaciones: normal semilla 3 victoria y 0 derrota; perfil semilla 1 victoria y 0 derrota. No se inyectan resultados, plata ni stock en esas rutas.

Laboratorio separado: 19 compras con cartera $200 explícita cubren números, todas las familias de componentes, monedas, sticker y ambos packs. Combinación equipada acredita 478 iguales a la previsión. Matriz activa de catálogo: 50 manos, con relanzamientos para metales/elementos acumulativos; 68 comparaciones totales sin diferencias. Cobro, compras, packs, reparación y anotación no se duplican por carga o segunda pulsación.

Corregido un fallo de continuidad: comprar una cara sobre la posición de la última tirada impedía guardar. Ahora la tienda conserva el resultado histórico y aplica la cara nueva a futuras tiradas; los estados incoherentes durante juego siguen rechazados. Mejoras de claridad: riesgo/costo de carcasas, incrementos de sticker y opciones de pack, disparadores/duración de materiales, explicación de resultado anterior a cambio de cara y motivo de derrota.

Nueve capturas por resolución revisadas a 1280×800 y 1440×900, procesos sin errores. Archivos: scripts/validation_profile.gd, scripts/main.gd, scripts/save_validator.gd, Validar-nivel.cmd, tests/level_validation_tests.gd, tests/level_validation_review.gd, tests/validation_profile_smoke.gd, integración en tests/run_tests.gd y ajuste del ayudante de selección de pruebas. Informe level_validation_demo en test-results/tests.json.

El usuario puede abrir Validar-nivel.cmd para una sesión con todas las secciones y balance provisional señalado; su guardado está separado del normal y comienza con $0. D01/D02/D04 siguen pendientes para balance final. No se midió tiempo de compra ni se validó comprensión/diversión mediante una sesión humana. No quedan fallos observados de continuidad o puntuación abiertos en los escenarios ejecutados. Sigue 17 con D07/D09 pendientes.

