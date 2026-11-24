# 21 — La Semilla (jefe final)

**Estado:** implementado en `feature/la-semilla` (24/11/2026), a la espera de la revisión del autor en el juego. Alcance nuevo posterior al paso 20 (punto 2 de los pendientes post-paso 20).

**Depende de:** 17 (motor de jefes), 18 (campaña hasta Dios), 19 (presentación), TX (guardianes animados), «Continuar partida».

**Contrato:** [docs/LA-SEMILLA.md](../LA-SEMILLA.md) · **Decisión:** D19.

## Alcance

1. Encuentro 22 después del guardián: objetivo × 1,5, manos estándar, un poder sorteado entre los jefes de la jugada, derrota = se pierde la jugada.
2. Mano con el maletín antes del derrumbe: un ítem por sección gratis; restock a $5 fijo, lo nuevo se paga.
3. Semilla visible arriba a la izquierda durante toda la jugada.
4. Cinemática: bar agrietado con el guardián vivo; al salir de la mano, muerte del guardián (A1), derrumbe (B1), Matrix y semilla que viaja al centro en la terminal (C2 + C3). Se puede omitir desde la segunda vez.
5. Victoria sin cartel: temblor, la mesa cae, se apagan la semilla y la Matrix → créditos → recompensas (sin definir) → pantalla de inicio.
6. Jugadas con semilla elegida: no suman nada a la partida guardada.

## Fuera de alcance

Premio al ganar, contenido de los créditos, música y efectos, campo para ingresar semilla a mano.

## Criterios de hecho

- [x] Semilla visible y exacta tras continuar.
- [x] Secuencia reproducible; el guardado de la mano con el maletín conserva los regalos.
- [x] Encuentro final jugable con previsión = anotación.
- [x] Revisión visual con capturas de cada fase (`tests/la_semilla_review.gd`).
- [x] Suite sin fallos.
- [ ] Revisión del autor en el juego y sesión humana.
