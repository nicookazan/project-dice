# 12 — Compras, selección de objetivos y reemplazos

Versión 1 · 25 de octubre de 2026.

**Entrega:** Nivel jugable. **Estado actual:** Transacciones, selección y pruebas completadas el 26 de octubre de 2026; dependencias 08, 09, 10 y 11 completadas. D01/D02/D04 siguen pendientes para datos comerciales finales; otras familias verificadas con fixtures.

**Depende de:** [08 — Rotura de carcasas y reparación opcional](08-rotura-reparacion.md), [09 — Stickers por categoría y paquetes](09-stickers-paquetes.md), [10 — Monedas iniciales e inventario extensible](10-monedas-inventario.md), [11 — Generación de tienda y renovación por sección](11-tienda-ofertas.md). **Decisiones vinculadas:** D01, D02, D04. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [12 en Notion](https://app.notion.com/p/404c28142b5581e0b8dcc60b1f283370?pvs=204).

Convertir cada oferta en una transacción completa: validar, elegir objetivo, cobrar y aplicar una sola vez.

## Fuente y alcance normativo
PRD IA §10 aplicación inmediata, packs y capacidad; PRD-PROTOTIPO sustitución. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Añadir flujo de compra con objetivo cuando corresponda: dado para mejora local/material/carcasa/elemento; dado y cara de origen para cambio de cara.
2. Mantener la oferta y el saldo mientras el jugador elige; cancelar no cobra ni consume stock. Al confirmar, volver a validar saldo, existencia de oferta, capacidad y objetivo.
3. Aplicar cambios inmediatamente. La oferta determina el número nuevo, pero el jugador elige qué cara sustituir.
4. Reemplazar solo el componente de la misma familia. El anterior se pierde sin devolución ni reserva. Conservar otros componentes y mejoras.
5. Para mejoras globales, aplicar una vez al estado global; para locales, solo al dado elegido.
6. Integrar stickers individuales y ambos packs. Cobrar el pack una vez y resolver su contenido sin duplicación aunque se cierre/reabra el panel.
7. Mantener capacidad de monedas y rechazo de compras sin saldo; deuda de reparación no autoriza endeudarse comprando.
8. Diseñar retorno de resultado legible: qué cambió, cuánto costó y por qué se rechaza una compra.

## Criterios de aceptación
- Acero + rubí + fuego pasa a acero + zafiro + fuego al comprar zafiro; rubí no queda en inventario.
- Reemplazar una carcasa rota por otra no borra caras ni mejora local. Definir explícitamente en datos que la oferta entrega carcasa intacta.
- Oferta de 4 aplicada sobre cara 2 de un dado cambia solo esa posición.
- Doble clic de confirmar cobra/aplica una vez y vacía un solo slot.
- Cancelar selección conserva plata, inventario y oferta.
- Falta de saldo o ranura no deja modificaciones parciales.
- Un pack pendiente de selección no permite obtener sus tres stickers.
- No hay pantalla que ofrezca vender o comprar un sexto dado.

## Entregable
Operaciones transaccionales, estados de selección y pruebas. La representación final se conecta en 13; puede verificarse con la UI provisional y fixtures.

## Fuera de alcance
Reserva de piezas, reintegros por sustitución, venta de dados y uso desde tienda de U01/U02.

## Cierre del paso
898 comprobaciones aprobadas, cero fallos: 848 anteriores y 50 nuevas. Plan puro en scripts/purchases.gd; estados, commit y recibos en scripts/game.gd; paneles en scripts/main.gd. Pruebas en tests/purchase_tests.gd y runner; capturas mediante tests/visual_review.gd.

Se verificaron cinco dados como únicos objetivos, selección de posición de cara, cancelación sin cargo, validación al confirmar, sustitución aislada de familia, carcasa nueva intacta, mejoras globales/locales, errores sin cambios parciales, deuda no habilitada para comprar, doble confirmación, tres modalidades de sticker y reapertura de pack sin nuevo cobro/sorteo. Capturas revisadas: test-results/compra-reemplazo.png, compra-confirmada.png, compra-cara.png y compra-pack-eleccion.png. Informe purchases_demo en test-results/tests.json.

Ver [contrato y evidencia](../COMPRAS-Y-OBJETIVOS.md). D01/D02/D04 siguen pendientes; no se convirtieron valores de fixtures en ofertas normales. Siguiente recomendado: 13, interfaz e inspección, con dependencias técnicas completas y D08 resuelta.

