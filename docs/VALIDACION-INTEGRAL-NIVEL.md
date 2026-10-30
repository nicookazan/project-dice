# Validación integral del primer nivel — paso 16

Fecha: 26 de octubre de 2026. Godot 4.7.1 estable, Windows. Perfil `nivel-corto-prueba-v1`; datos fijados antes de la validación en [DATOS-DE-PRUEBA-NIVEL.md](DATOS-DE-PRUEBA-NIVEL.md). Resultado: **validación técnica completada; sesión humana y balance final pendientes**.

## Resultado verificable

**1553 comprobaciones aprobadas, cero fallos**: 1083 anteriores y 470 nuevas. Se ejecutó la regresión completa de reglas, compras, UI y persistencia. **68 manos comparadas: cero diferencias** entre el desglose previsto y el acreditado. Cada comparación conserva contexto, total previsto, total acreditado y filas completas en `level_validation_demo.comparisons` de `test-results/tests.json`; `mismatches` quedó vacío.

Los controles usados son los de la escena jugable: tirar, seleccionar, agrupar, anotar, cobrar, tienda, confirmar compra, elegir pack, reparar, Menú y Continuar. Las pruebas usan archivos propios bajo `test-results/integral/`; el guardado normal del jugador permanece separado. No se cambió una expectativa heredada para ocultar un fallo funcional.

## Rutas naturales reproducibles

| Datos | Semilla | Resultado por encuentro | Final | Plata final |
|---|---:|---|---|---:|
| Normal, monedas existentes | 3 | 20 + 40 = 60 / 91 / 133 | Victoria al jefe | $29 |
| Normal, monedas existentes | 0 | 37 + 25 = 62 / 25 + 25 = 50 | Derrota contra objetivo 70 | $6 |
| Perfil provisional v1 | 1 | 30 + 30 = 60 / 100 / 126 | Victoria al jefe | $29 |
| Perfil provisional v1 | 0 | 37 + 25 = 62 / 24 + 31 = 55 | Derrota contra objetivo 70 | $6 |

Las rutas parten de menú y dados base. Solo se fija la semilla: **no se inyectan dados, resultados, plata ni stock**. El jugador automatizado conserva coincidencias y compra una moneda pasiva del stock generado cuando puede pagarla. Las rutas con perfil generan todas las secciones, aunque esta estrategia natural solo compra monedas. Las demás compras se cubren en el escenario controlado siguiente. Los $6 en derrota proceden del encuentro anterior: perder no paga recompensa del encuentro fallido.

Cada mano agrupada se guarda y reanuda antes de anotar. También se reanudan resultados, cobro y tienda, comparando snapshot completo, azar y elecciones. La segunda pulsación sobre el botón original de anotar no repite puntos ni riesgo. El cobro reanudado no se acredita otra vez; victoria y derrota quedan cerradas y sin Continuar.

## Cobertura controlada

Escenario con semilla 400 y cartera de laboratorio **$200**, explícitamente distinto de las rutas naturales. Se compran mediante UI 19 ofertas con los precios del perfil: global, local, cambio de cara, acero y cobre, los cinco elementos, las cuatro gemas, una moneda pasiva, un consumible, sticker individual y ambos packs. Los contenidos/objetivos de esas ofertas son fixtures identificados; no se afirman como una secuencia comercial natural.

Se reanuda cada compra pendiente y aplicada; seleccionar objetivo no cobra, confirmar descuenta una vez y la segunda pulsación de la oferta original no duplica la compra. Se verifica el pack pagado antes de elegir y después de aplicar. Los datos equipados pasan al siguiente encuentro, se usa el consumible, se reanuda la mano y se anotan **478 puntos previstos = 478 acreditados**. La reparación posterior conserva cobro y estado al reanudar. Las pruebas heredadas además cubren selección de carcasas/costo/deuda, reparación única y ambos caminos tras el jefe.

La matriz añade **50 manos controladas**: dos escenarios por cada una de ocho monedas, dos metales, cinco elementos, cuatro gemas y seis stickers. Las monedas y stickers de categoría se prueban con su combinación correspondiente; acero/cobre/tierra/viento acumulan mediante relanzamientos reales. Fuego/agua se contrastan en 2 y 4. Cada caso se guarda/reanuda antes de anotar y compara el desglose completo, incluido redondeo final. Las otras 18 comparaciones son 16 manos naturales, apertura de laboratorio y combinación comprada.

## Defectos encontrados y resueltos

| Gravedad | Hallazgo | Resolución y evidencia |
|---|---|---|
| P1 — continuidad | Comprar una cara sobre la posición recién tirada hacía fallar el guardado porque el validador exigía que el resultado histórico coincidiera con la cara nueva. | En tienda/compra/pack se conservan resultado y puntuación históricos y se validan índice/rango; la coincidencia estricta sigue obligatoria durante juego. Prueba: cara 4 → 6 del dado 5, reanudación, anotación azul intacta; estado incoherente en juego sigue rechazado. |
| P2 — claridad | Ofertas de stickers solo decían que mejoraban una categoría. | Muestran nivel actual/siguiente e incrementos exactos. Las opciones de un pack muestran esos incrementos y categorías al posar el cursor. |
| P2 — claridad | No se veía riesgo/costo de reparar antes de comprar una carcasa; los materiales tenían descripción genérica. | Oferta y selección de carcasa muestran riesgo y reparación. Acero/cobre explican disparador, duración y reinicio aplicable. |
| P2 — claridad | Resultado de dado anterior a cambio de cara podía parecer inconsistente con sus caras actuales. | La ficha explica que se trata del resultado previo y que la cara comprada afecta tiradas futuras. |
| P2 — claridad | La derrota informaba rival y puntos pero la causa quedaba fuera del panel principal. | El panel indica que se agotaron las manos sin alcanzar el objetivo. |

No quedan fallos observados de puntuación o continuidad abiertos en los escenarios ejecutados. Esto no significa que toda interacción futura esté cubierta.

## Revisión visual y claridad

Nueve capturas por resolución revisadas a **1280×800 y 1440×900** mediante `tests/level_validation_review.gd`, ambos procesos con salida correcta y cero verificaciones fallidas. Menú/anuncio del perfil, tienda mixta, reemplazo/riesgo, cara reanudada, pack reanudado, reparación reanudada, victoria y derrota naturales. Prefijos `test-results/1280x800-integral-` y `1440x900-integral-`. Las capturas de laboratorio usan cartera/resultados explícitos; las finales proceden de las rutas naturales.

Conservar/fijar dispone de marcas EDITABLE/FIJO/SEL y explicaciones de reglas; la reanudación conserva los bloqueos. Compra muestra precio/saldo y familia reemplazada; carcasa rota muestra R/estado y reparación opcional. Desglose conserva decimales y anotación azul. Se revisó legibilidad y que los controles queden dentro de sus paneles en ambas resoluciones. Descripciones largas de las tarjetas de monedas usan texto completo al posar el cursor; es una limitación conocida del espacio visible.

**Tiempo de compra, comprensión y diversión:** todavía no hay mediciones ni respuestas de una sesión humana. No se inventa una duración a partir de una ejecución automatizada, ni se extrapola a la campaña de 21 encuentros.

## Pendientes clasificados

| Tipo/prioridad | Pendiente | Alcance siguiente |
|---|---|---|
| Funcional P0/P1 observado | Ninguno abierto en los escenarios ejecutados | Mantener regresión al modificar reglas/campaña |
| Equilibrio | Magnitudes, precios, pesos y repeticiones provisionales de D01/D02/D04 | Ajustar después de jugar; no se declaran decisiones finales resueltas |
| Experiencia humana | Comprensión de bloqueo, riesgo, crecimiento de stickers, decisiones de compra y tiempo por tienda | Sesión del usuario con `Validar-nivel.cmd` |
| Presentación P2 | Descripciones largas requieren posar cursor; arte/audio siguen provisionales | Revisar con comentarios del jugador y paso 19 |
| Alcance futuro | Suspensiones/jefes D07/D09; siete niveles; balance/duración global | Pasos 17–20 |

## Cómo probar y repetir

- `Jugar.cmd`: juego normal con guardado normal y tablas anteriores.
- `Validar-nivel.cmd`: perfil provisional completo, aviso visible y guardado separado `%APPDATA%/DiosNoJuegaALosDados/saves/validacion-nivel-v1.json`. Comienza con $0 y dados base; no activa la cartera de laboratorio.
- `Probar.cmd`: suite completa, incluido `tests/level_validation_tests.gd`.
- Inicio alternativo de Godot: `--path . -- --validation-profile`. `tests/validation_profile_smoke.gd` verifica bandera, aviso, catálogo, ruta separada y plata cero sin escribir un guardado del jugador.

D05/D06 aplicadas y D08 resuelta se conservan. D01/D02/D04 cuentan con datos de prueba explícitos, no con balance final aprobado. Siguiente recomendado: **17 — Reglas de jefe y efectos suspendidos**, empezando por la regla existente y resolviendo D09 antes de habilitar suspensión jugable.
