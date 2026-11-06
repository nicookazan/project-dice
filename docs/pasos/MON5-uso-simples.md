# MON5 — Monedas de un uso simples

Etapa de monedas · 5 de noviembre de 2026.

**Rama:** `feature/monedas-uso-simples`. **Depende de:** MON1, MON2. **Estado actual:** Completado (suite: 3875 comprobaciones, cero fallos). **Decisiones vinculadas:** D15 (puntos 5, 6 y 9).

## Objetivo
Agregar siete monedas de un uso que no necesitan elegir objetivo.

## Trabajo a realizar
1. **U10 Mult +2** (Rara, mesa): `hand_mult_bonus`, solo a combinaciones, acumulable y antes de Doble mult.
2. **U11 Bolsa de puntos** (Común, mesa): `hand_points_bonus`, fila plana sin multiplicar.
3. **U13 Dos tiradas más** (Épica, mesa): reutiliza `use_extra_roll` con 2.
4. **U15 Plata rápida** (Común): +$5. Se usa durante el encuentro, no en la tienda.
5. **U16 Descuento de visita** (Rara, tienda): `visit_discount` en `offer_price()`. Se multiplica con C45 y aplica a renovaciones y paquetes, no a reparaciones.
6. **U17 Reparar todas** (Épica, reparación): resuelve todas gratis al usarla, sin estado nuevo.
7. **U18 Impulso par** (Común, mesa): solo datos, `impulse` con 2, 4 y 6.
8. Limpieza: los dos bonos de mano se limpian al anotar y en `start_hand()`; `visit_discount`, en `open_shop()`.
9. Mensajes: el de `use_extra_roll` sale del valor, y el de impulso no dice "cada 2 y 4 y 6".
10. Pantalla de reparación: hoy cada moneda usable dibuja su botón en el mismo lugar. Ubicarlos en fila.

## Criterios de aceptación
- Mult +2 se suma antes de Doble mult y no aplica a sobrantes; Bolsa de puntos no se multiplica.
- Previsión igual a anotación, y ambos efectos terminan con la mano.
- Guardar y continuar con cada efecto activo.
- El descuento termina con la visita y se redondea igual que C45.
- Reparar todas no cobra y no deja la fase trabada.
- Impulso par se acumula con otros impulsos y termina con el encuentro.
- Suite completa sin fallos.
