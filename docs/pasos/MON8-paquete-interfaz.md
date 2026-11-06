# MON8 — Paquete de monedas: interfaz

Etapa de monedas · 5 de noviembre de 2026.

**Rama:** `feature/monedas-paquete` (junto con MON7). **Depende de:** MON1, MON7. **Estado actual:** Completado (suite: 4117 comprobaciones, cero fallos; capturas en `test-results/`). **Decisiones vinculadas:** D15.

## Objetivo
Mostrar el paquete en la tienda y permitir elegir y reemplazar en pantalla.

## Trabajo a realizar
1. **Carta:** icono cerrado, precio y aro dorado. El texto dice "Elegí 1 entre 2" o "Elegí 2 entre 5" y no muestra el contenido.
2. **Panel:** nuevo `scripts/coin_pack_panel.gd`, con el estilo de `render_pack_choice()`. Muestra 2 o 5 cartas con icono, nombre, rareza y efecto, y cuántas elecciones faltan.
3. **Cinco cartas:** el panel actual tiene 860 px para 3 cartas de 236; hay que achicarlas y comprobar que los textos largos entren.
4. **Reemplazo:** si no hay lugar, se muestran las monedas propias de ese tipo con su reventa. Las de ranura que no se pueden sacar van apagadas y explican por qué.
5. **Cerrar y reabrir:** reutilizar `pack_panel_open`, con el botón "Elegir moneda pendiente".
6. Respetar "Reducir movimiento" y la velocidad elegida.

## Criterios de aceptación
Capturas en `test-results/` (nuevo `tests/coin_pack_review.gd`) de: paquete chico y grande, inventario lleno, moneda de ranura bloqueada, panel cerrado y reabierto, carta cerrada sin mostrar contenido, y textos más largos sin pisarse. Suite completa sin fallos.
