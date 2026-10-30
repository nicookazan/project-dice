# 17 — Reglas de jefe y efectos suspendidos

Versión 1 · 25 de octubre de 2026.

**Entrega:** Hasta Dios. **Estado actual:** Motor completado el 26 de octubre de 2026: 1598 comprobaciones aprobadas, cero fallos. D09 resuelta por el usuario: suspensión completa sin poder/riesgo/acumulación nueva y con reinicios normales. D07 conserva catálogo/objetivos de campaña pendientes. Balance final y sesión humana siguen pendientes.

**Depende de:** [10 — Monedas iniciales e inventario extensible](10-monedas-inventario.md), [15 — Guardado versionado y continuar partida](15-guardado-continuar.md). **Decisiones vinculadas:** D07, D09. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [17 en Notion](https://app.notion.com/p/404c28142b5581059765efdd77ed2d82?pvs=204).

Reemplazar el jefe codificado por posición con reglas configurables que se anuncien a tiempo y duren solo su encuentro.

## Fuente y alcance normativo
PRD IA §12; PRD-PROTOTIPO jefe sin generala y nuevas carcasas. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Separar definición de jefe, regla aplicada y objetivo de puntos; quitar la dependencia directa de rival == 2 para prohibir generala.
2. Implementar primero la regla existente de generala prohibida como definición de datos.
3. Añadir contrato para suspender temporalmente un material o moneda sin quitarlo del inventario. Su alcance exacto sobre acumulaciones/carcasas actuales se decide en D09.
4. La regla debe sortearse al entrar al nivel y permanecer estable en sus dos encuentros, tiendas y recargas.
5. Aplicar restricciones en las operaciones y el cálculo, no solo deshabilitando un botón.
6. Restituir los efectos después del jefe. Mantener las duraciones normales de mano/encuentro; no borrar equipamiento como consecuencia de suspensión.
7. Reservar soporte de cooldown para F01: una activa suspendida no usa su poder, pero sus eventos de recarga siguen avanzando.
8. Diseñar pruebas con dos reglas explícitas antes de ampliar catálogos. Los ejemplos del PRD no se convierten automáticamente en jefes definitivos.

## Criterios de aceptación
- Cinco iguales pueden ser trío+par contra generala prohibida.
- Recargar durante la tienda no cambia el jefe anunciado.
- Una moneda suspendida permanece equipada y vuelve a funcionar cuando corresponde.
- Una regla de desactivación no permite riesgos sin beneficios cuando el contrato indica suspensión completa.
- Ninguna prohibición aparece por sorpresa después de anotar una mano.
- Cambiar de rival normal a jefe activa la regla en el momento correcto y cerrar el jefe la retira.

## Entregable y decisiones
Motor de reglas y definiciones de prueba. D07 aporta catálogo final y objetivos. D09 debe aclarar cómo trasladar la antigua suspensión de cristal a las actuales carcasas y contadores antes de habilitar esa regla jugable.

## Fuera de alcance
Generar nombres, retratos o las 18 reglas como si ya estuvieran aprobadas; añadir penalizaciones aleatorias no anunciadas.

## Cierre del paso

Definiciones de regla y encuentros separadas de objetivos. La posición no prohíbe generala: lo hace el contexto del jefe definido en datos. La elección ocurre al entrar al nivel y se guarda, sin resorteos por consulta, tienda, renovación o carga. Operaciones y cálculo puro rechazan grupos ilegales. Suspensiones dirigidas o de familia completa para materiales, carcasas y monedas, con restitución después del jefe y sin quitar instancias. D09 implementada; contrato de recarga de futuras activas reservado para F01.

UI: anuncio, encabezado, Recorrido, fichas, desglose y marca SUSP; consumible bloqueado sin gastarlo. Guardado v2 con migración conocida v1 sin consumir azar ni sobrescribir al leer; el siguiente checkpoint conserva original como respaldo. Se mantienen nombres de archivo estables.

Archivos: scripts/boss_rules.gd, scripts/game.gd, scripts/rules.gd, scripts/materials.gd, scripts/gems.gd, scripts/main.gd, scripts/save_store.gd, scripts/save_validator.gd, tests/boss_tests.gd, tests/boss_review.gd, tests/run_tests.gd y ayudante de selección de pruebas. [Contrato y evidencia](../REGLAS-DE-JEFE.md).

Suite: 1598 comprobaciones, 1553 anteriores + 45 nuevas, cero fallos. Prohibición en un jefe no final, selección estable de dos reglas explícitas, monedas conservadas y restituidas, metales sin ganancias nuevas con reinicios, riesgo de gemas apagado y restaurado, migración y próxima tirada exacta. Ocho capturas por resolución a 1280×800 y 1440×900; ambos procesos sin errores. Informe boss_demo en test-results/tests.json.

El pool normal sigue siendo únicamente Generala prohibida y el nivel 40 → 70 → 110. Las demás reglas son definiciones explícitas de prueba, no nombres/catálogo final aprobado. D07 queda para 18; rescates y activas concretas para F01. Siguiente recomendado: 18, campaña técnica con catálogo D07 pendiente.

