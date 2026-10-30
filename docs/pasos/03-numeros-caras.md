# 03 — Mejoras globales, locales y cambios de cara

Versión 1 · 25 de octubre de 2026.

**Entrega:** Motor de reglas. **Estado actual:** Completado y probado el 25 de octubre de 2026. D01 sigue pendiente para las ofertas finales de 11–12.

**Depende de:** [01 — Estado persistente de partida y dados](01-estado-dados.md), [02 — Cálculo de puntos y eventos sin efectos secundarios](02-puntuacion-eventos.md). **Decisiones vinculadas:** D01. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [03 en Notion](https://app.notion.com/p/404c28142b5581538586d426d84cb51b?pvs=204).

Modificar probabilidades y puntos de forma independiente, con las reglas necesarias para conectar después las compras.

## Fuente y alcance normativo
PRD IA §7 Números y caras, §10 aplicación inmediata; PRD-PROTOTIPO cinco dados fijos. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Hacer que cada lanzamiento elija una de las seis caras del dado y utilice el número almacenado; no sortear siempre un entero 1–6 ignorando sus caras.
2. Acumular mejoras globales por número y locales por dado/número. Valor propio inicial = número + global + local.
3. Conservar mejoras de números ausentes. Cambiar la última cara 4 no borra la mejora del 4.
4. Exponer operaciones de aplicar mejora y sustituir una cara con validación de dado, cara y número destino. La tienda elegirá el objetivo más adelante.
5. Mantener categorías y paridad basadas en el número visible, nunca en el valor mejorado.
6. Definir datos de ofertas globales con sus rangos confirmados: común +1–3, rara +4–5, épica +6–8 y legendaria +9–10. Magnitud exacta visible antes de comprar.
7. Registrar como pendiente D01 los rangos locales, precios y probabilidades; no copiar automáticamente los globales ni inventar distribuciones definitivas.

## Criterios de aceptación
- Un 4 con +3 global y +12 local aporta 19; otro 4 sin local aporta 7 y ambos siguen formando par.
- Comprar +3 y luego +8 global al 4 produce 15 por cada 4.
- Caras 1-2-3-4-4-5: dos de los seis índices posibles dan 4. Comprobar el mapeo de índices, no una frecuencia aleatoria frágil.
- Quitar todas las caras 4 desactiva su mejora local; restituir una reactiva el mismo valor.
- Una cara repetida no duplica el aporte de mejora de un solo resultado.
- Cambiar caras conserva material, carcasa, elemento y otros números mejorados.
- Una operación inválida no aplica cambios parciales.

## Entregable y demostración
Operaciones de dominio y pruebas con tiradas controladas. Mostrar comparación de un dado modificado y otro básico mediante un fixture, sin esperar a la tienda.

## Qué puede avanzar
El motor puede implementarse completamente con magnitudes explícitas de prueba. D01 solo impide cerrar generación y balance de ofertas reales en 11–12.

## Fuera de alcance
Compra de dados, venta de dados, caras con símbolos nuevos y físicas como determinante de probabilidades.

## Cierre del paso

Implementado y probado: **328 comprobaciones aprobadas, cero fallos** (242 anteriores y 86 nuevas).

- Operaciones internas validadas para sumar mejoras globales/locales y cambiar caras sin efectos parciales al fallar.
- Puntuación integrada: número + global + local; paridad y combinaciones conservan el número visible.
- Números ausentes conservan su mejora local y la reactivan cuando vuelve una cara.
- Mapeo real de seis posiciones y conservación de componentes, mejoras y contadores.
- Datos de ofertas globales con magnitud/precio explícitos y rangos confirmados por rareza.
- Código: scripts/number_upgrades.gd, dice_state.gd, rules.gd, game.gd y main.gd.
- Pruebas: tests/number_upgrade_tests.gd y suite/fixtures existentes.
- Contrato: [MEJORAS-NUMERICAS.md](../MEJORAS-NUMERICAS.md).
- Evidencia: number_upgrades_demo en test-results/tests.json y captura revisada test-results/mejoras-numericas.png.

D01 no se dio por resuelta: precios, probabilidades, distribución y rangos locales siguen pendientes. Las ventas y transacciones corresponden a 11–12.

Siguiente recomendado: 04. Los pasos 05 y 10 también tienen completas sus dependencias técnicas.

