# 10 — Monedas iniciales e inventario extensible

Versión 1 · 25 de octubre de 2026.

**Entrega:** Nivel jugable. **Estado actual:** Completado y probado el 26 de octubre de 2026; dependencias 01 y 02 completadas. D03 sigue pendiente para monedas futuras y no bloqueó adaptar las ocho actuales.

**Depende de:** [01 — Estado persistente de partida y dados](01-estado-dados.md), [02 — Cálculo de puntos y eventos sin efectos secundarios](02-puntuacion-eventos.md). **Decisiones vinculadas:** D03. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [10 en Notion](https://app.notion.com/p/404c28142b558133972acafa40ca32ef?pvs=204).

Adaptar las ocho monedas existentes al estado nuevo y preparar límites y transacciones sin exigir definir todo el catálogo.

## Fuente y alcance normativo
PRD-PROTOTIPO §3; PRD IA §9 tipos, ventanas y límites. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Trasladar las seis pasivas y dos consumibles actuales a definiciones de datos con ID, tipo, alcance, disparador, duración, precio y descripción.
2. Separar definición de moneda e instancia equipada/guardada, para que futuras copias no compartan estado.
3. Mantener cinco espacios compartidos para pasivas/activas; una ranura inicial de un uso. Las activas futuras se documentan en F01 y no aparecen sin catálogo.
4. Preservar C01–C04: +1 al multiplicador de full/escalera/generala/póker; C05–C06: +2 por resultado par/impar, incluidos sobrantes.
5. U01: +3 por resultado 1 o 3 hasta acabar el encuentro; U02: +1 tirada de la mano actual. Consumir una vez, antes de anotar, sin gastar mano o tirada.
6. Rechazar uso de estas dos en tienda y compra para guardar sin ranura. Preparar validez por contexto para futuras monedas que sí puedan usarse en tienda.
7. Reventa inicial 2/1 y ofertas uniformes quedan como datos provisionales, no decisiones nuevas de rareza.
8. Mantener la restricción de no duplicados hasta implementar la habilitadora. D03 guarda las definiciones futuras pendientes.

## Criterios de aceptación
- Las ocho pruebas de efecto existentes siguen válidas con el nuevo modelo.
- Un 4 con mejora que le haga aportar 7 sigue activando paridad par.
- U01 aplica en grupos bloqueados sin cambiar números ni miembros y no recalcula manos anteriores.
- U02 usada antes de la primera tirada deja cuatro oportunidades, pero la siguiente mano vuelve a tres.
- Moneda inválida en el contexto no se cobra ni consume.
- Cinco pasivas impiden guardar una sexta; no eliminan ninguna automáticamente.
- Reiniciar partida borra boost y consumibles gastados no reaparecen.

## Entregable
Catálogo inicial compatible con el motor nuevo, inventario y pruebas de contextos. Los datos de nuevas monedas pueden incorporarse después sin rehacer la tienda.

## Fuera de alcance
Activas con cooldown, rescates, copias habilitadas y recompensas permanentes no se simulan con objetos inventados; quedan cubiertos por F01/F03.

## Cierre del paso
795 comprobaciones aprobadas, cero fallos: 722 anteriores y 73 nuevas. Catálogo e inventario en scripts/coins.gd; estado/transacciones en scripts/game.gd, puntuación en scripts/rules.gd e inspección/validación de interfaz en scripts/main.gd. Pruebas en tests/coin_tests.gd y tests/run_tests.gd; capturas mediante tests/visual_review.gd.

Se verificaron ocho efectos, definición separada de instancia, identidades conservadas, estado independiente, cinco espacios compartidos y una ranura de un uso, no duplicados, transacciones atómicas, contextos, paridad sobre cara mejorada, U01 en grupos bloqueados e historial intacto, U02 antes de tirar y reinicios. Capturas revisadas: test-results/monedas-inventario.png, moneda-inspeccion.png y monedas-limites-tienda.png. Informe coins_demo en test-results/tests.json.

Ver [contrato y evidencia](../MONEDAS-E-INVENTARIO.md). D03 sigue pendiente para catálogo futuro; precios/reventa/ofertas mantienen carácter provisional. Siguiente recomendado: 11, con dependencias técnicas completas y D01/D02/D04 pendientes para contenido comercial final.

