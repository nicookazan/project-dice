# 08 — Rotura de carcasas y reparación opcional

Versión 1 · 25 de octubre de 2026.

**Entrega:** Motor de reglas. **Estado actual:** Completado y probado el 26 de octubre de 2026; dependencia 07 completada. D08 resuelta: selección de carcasas con costo total, según respuesta del usuario en este chat.

**Depende de:** [07 — Poderes de esmeralda, rubí, zafiro y diamante](07-poderes-gemas.md). **Decisiones vinculadas:** D08. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [08 en Notion](https://app.notion.com/p/404c28142b55812a801efd55f31d93bd?pvs=204).

Resolver el riesgo después de puntuar y permitir reparar tras cobrar una victoria, manteniendo siempre los cinco dados.

## Fuente y alcance normativo
PRD-PROTOTIPO: riesgo, resquebrajado, reparación y deuda. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Después de acreditar la mano, comprobar una vez por cada carcasa intacta que puntuó en combinación: esmeralda 10%, rubí 20%, zafiro 30%, diamante 50%.
2. Las carcasas de sobrantes y las ya rotas no sortean. No hay usos seguros ni pérdida del poder en la mano que acaba de acreditar.
3. Marcar resquebrajada la carcasa. Conservar dado, caras, mejoras, material, elemento e identidad visual; solo suspender el poder de esa gema.
4. Al cerrar una victoria, cobrar la recompensa una sola vez y ofrecer reparación antes de continuar. Precios por carcasa: 2/3/4/5 respectivamente.
5. Aceptar deuda y sumar luego recompensas normalmente. Intereses con saldo previo negativo siempre cero.
6. Preparar una operación de reparación que reciba IDs y calcule costo. D08 resuelta el 26 de octubre: el usuario eligió seleccionar carcasas y mostrar el costo total. Se ofrece la misma selección tras el último jefe, antes de mostrar la victoria final.
7. Proteger doble clic y llamadas repetidas; reanudar más adelante debe respetar si la mano ya sorteó y si la recompensa ya se cobró.

## Criterios de aceptación
- Forzar un sorteo por debajo/por encima del umbral verifica rotura sin pruebas estadísticas inestables.
- Un rubí que se rompe aporta su ×1,5 en la mano recién anotada y nada en la siguiente hasta repararse.
- Dos diamantes pueden producir tres copias en total y solo dos comprobaciones de riesgo, una por dado.
- Declinar deja la carcasa rota y no cobra.
- Saldo previo −3 más recompensa 8 queda en 5, sin intereses negativos.
- Reparar una carcasa recupera su poder y conserva todas las demás modificaciones.
- No se puede reparar entre manos, cobrar dos veces ni reducir el conjunto a cuatro dados.

## Entregable y dependencias de diseño
Motor, pruebas y estado de resolución de victoria. La interacción por selección ya está implementada según D08; los pasos 13–14 la integrarán al recorrido completo.

## Fuera de alcance
Destrucción definitiva del dado, reserva de repuestos, rotura antes de puntuar y reparación automática obligatoria.

## Cierre del paso
666 comprobaciones aprobadas, cero fallos: 581 anteriores y 85 nuevas. Implementación en scripts/game.gd, scripts/gems.gd y scripts/main.gd. Pruebas en tests/repair_tests.gd y tests/support/breakage_game.gd; actualizados runner, pruebas de gemas/estado y observador de eventos. Capturas mediante tests/visual_review.gd.

Se verificaron umbrales deterministas, rotura después de acreditar, una comprobación por dado, copias sin sorteos extra, suspensión sin perder identidad/componentes, reparación selectiva tras cobro, costos, deuda, declinación y protección de repeticiones. Capturas revisadas: test-results/reparacion-seleccion.png y reparacion-cobrada.png. Informe repairs_demo en test-results/tests.json.

Ver [contrato y evidencia](../ROTURA-Y-REPARACION.md). D08 resuelta por el usuario: elegir carcasas y mostrar total. Guardado en disco en 15 y compras en 12. Siguiente recomendado: 09, stickers y paquetes, usando fixtures mientras se resuelve D02; el 10 sigue disponible.

