# TU — Pantalla inicial, partidas guardadas y tutorial

17 de noviembre de 2026. **Rama:** `feature/tutorial-partidas`. **Estado:** implementado en una sola rama (TU0–TU9 de punta a punta, a pedido del autor: «ejecutá todo y después corregimos»); **a la espera de la prueba y la aprobación del autor**. Origen: la página de Notion «Plan de implementación — Pantalla inicial, partidas y tutorial» y sus requerimientos (copia en [fuentes/REQUERIMIENTOS-TUTORIAL-2026-11-17.md](../fuentes/REQUERIMIENTOS-TUTORIAL-2026-11-17.md)). Contratos: [PARTIDAS-GUARDADAS](../PARTIDAS-GUARDADAS.md) y [TUTORIAL](../TUTORIAL.md). Decisión: D18.

El plan decía una fase por rama y PR; se hicieron todas juntas en esta rama y no hay PR todavía.

| Fase | Qué entrega | Estado |
| --- | --- | --- |
| TU0 | Ficha local, decisiones, contratos, requerimientos copiados | Hecho. **Los bocetos para aprobar no se hicieron**: se usó el arte existente (el bar, el vendedor de la tienda, las manos) y una ficha provisional para C58. |
| TU1 | Partidas guardadas (3 ranuras) | Hecho: `profile_store.gd`, panel en Opciones, estadísticas solo al terminar |
| TU2 | Las jugadas dejan de guardarse | Hecho. Sin «Continuar» ni «Guardar y salir»; `SaveStore`/migraciones se conservan solo para las pruebas (ver el contrato) |
| TU3 | Menú principal en el bar | Hecho con el arte del salón y las interacciones de `BarProps`; **falta que el autor lo apruebe dentro del juego** |
| TU4 | Motor del tutorial | Hecho: guion como datos, carteles, «?», acciones obligatorias |
| TU5 | Presentación y primer encuentro guiado | Hecho (texto que se escribe, cartel que se mece, cue `speak`; tiradas guionadas) |
| TU6 | Tienda guiada | Hecho ($20, semilla 2 provisional, carteles por sección). **Falta la elección de la semilla por el autor** |
| TU7 | Jefe vendedor | Hecho: `BossCatalog.TUTORIAL_BOSS`, poder `cash_drain` |
| TU8 | Logro y moneda | Hecho: `achievements.gd`, C58 acumulable, monedas bloqueadas, descuento con piso de $1 |
| TU9 | Integración | Suite completa en verde (5374 comprobaciones, 0 fallos); capturas en `test-results/` (`tests/tutorial_review.gd`). **Falta la sesión del autor y marcar a mano las fases en Notion.** |

## Decisiones por defecto del plan (se aplicaron tal cual)

1. Varias copias solo para «El regalo del vendedor». 2. Abarata monedas sueltas, no paquetes ni renovaciones. 3. Primero los porcentajes, después $1 por copia, piso de $1. 4. El tutorial no suma jugadas ni victorias. 5. El código del guardado de la jugada se deja de escribir; se conserva en memoria para las pruebas (**desvío del plan**, que proponía retirarlo). 6. El jefe se llama «El Vendedor» (ya existe «El Vendedor Ambulante», jefe del nivel 2). 7. El jefe no da recompensa. 8. «Ir a otro nivel» no aparece en el tutorial.

## Límites

- Datos de campaña y de la tienda del tutorial **provisionales**. Arte y sonido del vendedor, del menú y de C58: pendientes de aprobación (D10).
- El jefe vendedor usa la mano común del fondo; su arte propio queda para el pase artístico.
- No se probó con una sesión humana.
