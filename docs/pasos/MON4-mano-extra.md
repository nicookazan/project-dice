# MON4 — Mano extra

Etapa de monedas · 5 de noviembre de 2026.

**Rama:** `feature/moneda-mano-extra`. **Depende de:** MON3. **Estado actual:** Completado (suite: 3685 comprobaciones, cero fallos). **Decisiones vinculadas:** D15 (puntos 10 y 11).

## Objetivo
Agregar C52 Mano extra (Legendaria): 3 manos por encuentro en vez de 2. Va aparte porque "2 manos" está escrito en todo el juego.

## Trabajo a realizar
1. Función única para el límite de manos: 2 más `extra_hands`, sin contar monedas suspendidas. La usan el juego y el validador.
2. Usarla en `game.gd` (derrota, `next_hand`, manos sobrantes del cobro), `main.gd` ("Mano %d / 2" y "Jugar segunda mano") y `save_validator.gd` (rango de `hand` y final por derrota).
3. Impuesto al kiosco: subir el máximo de `boss_rules.gd` de $4 a $6, o un guardado válido con 3 manos se rechazaría.
4. La tercera mano repite la ruleta de la segunda. La memoria de Chamuyero y del bloqueo de categoría sigue siendo de la mano 1.
5. Cada mano sobrante sigue pagando $2.
6. Sumar la excepción a `docs/REGLAS-VIGENTES.md`.

## Criterios de aceptación
- Se pierde recién al terminar la tercera mano y se puede ganar en cualquiera.
- Premio correcto por manos sobrantes.
- Guardar y continuar en la mano 3, también en derrota.
- Tarjeta roja sobre Mano extra deja 2 manos.
- Ruleta, Chamuyero, bloqueo de categoría e impuesto funcionan en la tercera mano.
- Segunda mano (C39) sigue pagando solo en la mano 2.
- Suite completa sin fallos.
