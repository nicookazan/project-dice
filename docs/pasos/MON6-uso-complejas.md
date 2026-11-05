# MON6 — Relanzo total, Voltear dado y Escudo de jefe

Etapa de monedas · 5 de noviembre de 2026.

**Rama:** `feature/monedas-uso-complejas`. **Depende de:** MON5. **Estado actual:** Sin empezar. **Decisiones vinculadas:** D15 (puntos 3, 4, 7 y 8).

## Objetivo
Agregar las tres monedas de un uso (todas Raras) que tocan tiradas, objetivos y poderes de jefe.

## Trabajo a realizar

### U09 Relanzo total
1. Separar de `roll()` la parte que tira los dados del vaso, para reutilizarla con tirada gratis.
2. Requiere haber tirado. Deshace grupos, incluso bloqueados, y manda los dados al vaso, salvo el abducido. Usa el azar principal.
3. Cuenta como tirada hecha, sin gastar presupuesto. Moneda gastada pierde 1 por dado.
4. Reutiliza eventos, efectos de material y elemento, poderes de jefe y la animación de tirada.

### U12 Voltear dado
1. `face_index` pasa a `5 - face_index`: la cara física opuesta, también con caras cambiadas.
2. Solo dados sueltos ya tirados; no afecta dados fijados por un jefe.
3. `use_consumable` acepta un objetivo. La moneda se consume recién al elegir el dado, y se puede cancelar. El modo de elegir no se guarda en la partida.

### U14 Escudo de jefe
1. Solo se usa contra un jefe, incluido Dios. Si está suspendido, no se puede usar.
2. Una función común para saber si el poder está activo, usada por `boss_context()` y por cada consulta directa a `boss_rule` en `game.gd`.
3. `save_validator.gd` tiene en cuenta el escudo al recalcular categorías prohibidas.
4. Se apaga después de cobrar el impuesto al kiosco. La memoria del jefe sigue registrándose.
5. El termo robado vuelve durante la mano protegida.
6. `once_per_run` en los datos, `once_coins_seen` en la partida y exclusión en `Shop.generate`. Cuenta al generarse la oferta, aunque no se compre o no se vea, y se confirma cuando se aplica la generación.

## Criterios de aceptación
- Relanzo total con 0 tiradas restantes y con grupos bloqueados; misma semilla, mismo resultado.
- Relanzo total con Moneda gastada, dado cargado, dado asustado y abducido.
- Voltear dado con caras cambiadas, previsión actualizada y cancelación sin gastar.
- Escudo de jefe contra cada poder del catálogo, previsión igual a anotación y vuelta del poder en la mano siguiente.
- Escudo de jefe nunca aparece dos veces, ni entre renovaciones, paquetes o tras guardar y continuar.
- Suite completa sin fallos.
