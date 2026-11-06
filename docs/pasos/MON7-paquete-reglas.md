# MON7 — Paquete de monedas: reglas

Etapa de monedas · 5 de noviembre de 2026.

**Rama:** `feature/monedas-paquete` (junto con MON8). **Depende de:** MON2. **Estado actual:** Completado (suite: 4102 comprobaciones, cero fallos). **Decisiones vinculadas:** D15 (puntos 1 y 2), D04.

## Objetivo
El cuarto espacio de la sección de monedas pasa a ser un paquete: chico (muestra 2, se elige 1; $7; 65 %) o grande (muestra 5, se eligen 2; $14; 35 %). Valores provisionales hasta el ítem 7.

## Trabajo a realizar

### Generación
1. Tabla `coin_packs` en `Shop.default_tables()` y en el perfil de validación. Siguen siendo 4 espacios: 3 monedas sueltas y el paquete.
2. Sin tabla `coin_packs`, los 4 espacios siguen siendo monedas, como necesitan los escenarios de prueba actuales.
3. Oferta `coin_pack`, sorteada con las mismas etapas que las sueltas. El contenido queda guardado en la oferta.
4. Sin repetidos dentro del paquete, sin pasivas propias y sin pasivas iguales a las sueltas de la misma visita.
5. El paquete grande trae siempre al menos 2 pasivas.

### Compra y elección
1. Sumar `coin_pack` a `Purchases`. Se puede comprar con el inventario lleno.
2. Fase `coin_choice` y `pending_coin_pack` (paquete, elecciones restantes, monedas recibidas y lo pagado). Bloquea vender, usar monedas, comprar, renovar y salir.
3. Revisar cada lista de fases donde aparece `sticker_choice`, sobre todo en `game.gd`, `main.gd` y `save_validator.gd`.
4. `choose_coin(id, replace_instance_id)`: una sola operación que aplica elección y reemplazo juntos.

### Reemplazo
1. `Coins.can_replace(inventory, instance_id, incoming_id)` calcula capacidad con la moneda que entra.
2. Se reemplaza por `instance_id`. Una pasiva reemplaza a una pasiva, y una de un uso a una de un uso.
3. La moneda que sale paga su reventa. Se pide moneda por moneda, y la recién recibida del mismo paquete no se puede reemplazar.

## Criterios de aceptación
- Mismo contenido con la misma semilla, y sin cambios al mirar o cambiar de pestaña.
- Guardar y continuar en cada momento de la elección, con los dos tipos de paquete.
- Sin salida: muchas semillas con inventarios extremos (lleno, con Bolsillo, con Bolsillo chico y con una ranura de un uso) siempre dejan una elección legal.
- Bolsillo y Bolsillo chico no se pueden reemplazar si quedarían más monedas que ranuras.
- El descuento baja el precio y se registra lo pagado de verdad.
- Moneda de oro permite comprar con deuda.
- Suite completa sin fallos, con las pruebas que asumen 4 monedas sueltas ajustadas.
