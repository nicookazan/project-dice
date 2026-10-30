> Actualización del 28/10/2026: siempre mate con termo; stickers sobre el termo; exteriores ilustrados según el PRD; gemas brillantes. Sustituye las referencias históricas a cerveza, stickers en vaso y puntos opacos. Ver docs/CAMBIOS-VISUALES-2026-10-28.md.

# Caras de dados: negro y gemas mates — integración v1

27 de octubre de 2026. Pedido del usuario: seis números en negro y en las cuatro gemas, conservarlos en el PRD e integrarlos al juego si es posible. **Entregado: 30 caras, guardadas en ambos PRD e integradas en Godot.**

## Catálogo conservado

Cada lámina tiene seis caras: **1, 2, 3 arriba; 4, 5, 6 abajo**. La cara superior corta no muestra otro resultado. Las variantes mantienen la vista frontal y cuerpo marfil del maestro; los puntos son mates, opacos y apagados. Las referencias aprobadas anteriores no se modificaron.

| Acabado | Archivo fuente | Recursos individuales |
|---|---|---|
| Negro base | `assets/art/dice-faces-v1/negro-v1.png` | `individual/negro-1.tres` a `negro-6.tres` |
| Rubí | `assets/art/dice-faces-v1/ruby-v1.png` | `individual/ruby-1.tres` a `ruby-6.tres` |
| Zafiro | `assets/art/dice-faces-v1/sapphire-v1.png` | `individual/sapphire-1.tres` a `sapphire-6.tres` |
| Esmeralda | `assets/art/dice-faces-v1/emerald-v1.png` | `individual/emerald-1.tres` a `emerald-6.tres` |
| Diamante | `assets/art/dice-faces-v1/diamond-v1.png` | `individual/diamond-1.tres` a `diamond-6.tres` |

El cuerpo sin resultado está en `sin-tirar-v1.png`. Los treinta recursos individuales de Godot comparten el PNG correspondiente, sin duplicar o modificar sus píxeles. Las regiones recortan únicamente el margen para alinear el cuerpo visible. El negro base y los cuatro materiales contienen cada número exacto; el seis usa dos columnas de tres puntos separados.

## Dónde verlos

Abrir **Jugar.cmd → Ver diseños de dados**. También está en **Opciones → Ver diseños de dados** durante una partida. La galería muestra las treinta caras sin equipar piezas, cobrar ni cambiar estado/azar. Cerrar vuelve a la pantalla actual.

En la partida, mesa, grupos, reserva y vaso usan el nuevo cuerpo y el color correspondiente a la gema persistida del dado. La libreta de la tienda muestra los mismos dados; las ofertas de gema ilustran puntos de esa gema sobre el cuerpo marfil. Las ofertas de cambio de cara representan exactamente el número vendido. Una compra confirmada actualiza la apariencia del dado elegido y conserva el cargo único.

Antes de tirar se usa el cuerpo sin número con `?`; no se dibuja un uno ficticio. Selección y foco conservan sus marcas. El estado dañado conserva el color de la gema y añade una grieta pequeña dentro de un punto y la marca **R**, sin agrietar el cuerpo ni eliminar puntos. La suspensión por jefe conserva la identidad y muestra **S**; el poder/riesgo siguen las reglas ya implementadas. El arrastre conserva número, material y estados del dado.

## Contrato técnico

`scripts/dice_art.gd` selecciona textura y región; `scripts/die.gd` las dibuja con filtro vecino más cercano. El número procede de `die.value`, el acabado de `die.shell`; `shell_broken` conserva el daño y el contexto de jefe informa suspensión. Las claves históricas siguen siendo alias de material de puntos. No se modifica el modelo, guardado v3, efectos, riesgo, economía o generador de azar por este cambio visual.

Los dibujos se generaron con la herramienta integrada Imagegen, con una llamada por lámina/variante, a partir de los maestros aprobados. Se copiaron los resultados al proyecto preservando los originales. [Prompts completos](../assets/art/dice-faces-v1/PROMPTS.md). Las láminas están adjuntas nativamente en el [PRD general](https://app.notion.com/p/3fec28142b55815c9f84c21402b73154) y el [PRD-PROTOTIPO](https://app.notion.com/p/404c28142b5581679265d602cec7e69b).

## Evidencia

**2101 comprobaciones aprobadas, cero fallos**: 2025 previas más 76 de este cambio. `tests/dice_art_tests.gd` cuenta los grupos de píxeles oscuros de cada cara para verificar que hay exactamente 1–6 puntos en las treinta imágenes; valida los 30 recursos individuales, estados y mapeo a dados reales, galería sin mutación, representación de oferta y compra con cambio de apariencia. La regresión anterior conserva input nativo, puntuación, compras, campaña y guardado.

`tests/dice_art_review.gd` produce seis capturas por resolución a 1280×800 y 1440×900: menú, galería de treinta, mesa, daño/selección, tienda y galería desde opciones. Revisadas con renderizado real, sin errores. Evidencia: `test-results/<resolución>-dados-mate-*.png` e informe `dice_art_demo` en `test-results/tests.json`.

Las escenas de mesa/tienda de revisión tienen equipamiento y resultados de laboratorio explícitos para comparar colores; no añaden ventajas ni cambian el inicio normal. La galería de producto solo muestra diseños.

## Límites del avance

Esta entrega integra las caras negras y de gemas. Acero/cobre como acabado del cuerpo, señales de elementos, acabado de jefes/exteriores y otros pendientes del paso 19 conservan su alcance. No se presentan como completados por haber integrado estos treinta resultados. La dirección visual está aprobada por el usuario; las nuevas caras son derivados generados y verificados, sin atribuir otra revisión humana que no haya ocurrido.

