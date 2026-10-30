# F01 — Monedas activas, copias y rescates

Versión 1 · 25 de octubre de 2026.

**Entrega:** Posterior. **Estado al crear el plan:** Diferido.

**Depende de:** [10 — Monedas iniciales e inventario extensible](10-monedas-inventario.md), [15 — Guardado versionado y continuar partida](15-guardado-continuar.md), [17 — Reglas de jefe y efectos suspendidos](17-motor-jefes.md). **Decisiones vinculadas:** D03, D09. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [F01 en Notion](https://app.notion.com/p/404c28142b5581f0b8bdfa57fc596383?pvs=204).

Conservar el diseño de monedas avanzadas en un paso independiente, activable cuando exista catálogo concreto.

## Fuente y alcance normativo
PRD IA §3 rescates, §9 monedas y §12 suspensión. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Alcance y condición de inicio
Diferido respecto de la ruta inicial hasta Dios; puede adelantarse si se eligen monedas concretas. No requiere rehacer el catálogo inicial ni supone que las propuestas de nombres ya estén aprobadas.

## Trabajo a realizar
1. Definir por activa: disparador, efecto, objetivos válidos, cooldown y su unidad (manos jugadas o rivales vencidos). Nunca por tiempo real, tiradas o cantidad de dados.
2. Activa comprada llega lista y guarda un solo uso disponible. Tras usarla comienza su recarga; no acumula cargas extra.
3. Mantener cooldown entre encuentros y tienda. Una moneda suspendida no puede usarse, pero recarga por sus eventos normales.
4. Evitar que efectos normales cambien dados de grupos bloqueados; excepciones deben ser explícitas.
5. Definir moneda habilitadora de copias: ella y cada copia ocupan un espacio; las copias activas tienen cooldown independiente.
6. Al vender habilitadora, conservar copias compradas; no generar nuevas. D03 decide qué ocurre con ofertas duplicadas que ya estaban visibles.
7. Implementar ranuras variables de un uso sin borrar exceso de inventario al perder capacidad. Rechazar nuevas guardadas sin espacio; comprar y usar solo si el efecto es válido en tienda.
8. Rescates: pausar derrota, listar únicamente los válidos y permitir elegir uno o aceptar perder. No consumirlos todos ni elegir automáticamente.

## Criterios de aceptación
- Lanzar o mover dados no recarga activas; completar una mano sí cuando esa sea su unidad.
- Una activa lista no acumula dos usos al pasar dos eventos extra.
- Dos copias tienen contadores distintos; vender habilitadora no las desactiva.
- Pérdida de una ranura conserva consumibles guardados y bloquea nuevas compras para almacenar.
- Un rescate que no resuelve la causa de derrota no aparece como opción.
- Guardar/cargar una elección de rescate no consume ni duplica objetos.

## Entregable y pendientes
Catálogo seleccionado con valores y pruebas, UI y guardado extendidos. D03/D09 deben resolver reglas faltantes antes de habilitar contenido al jugador.

## Fuera de alcance
No confundir desbloquear monedas con recibirlas gratis; no implementar beneficios de vaso permanente en estas cinco ranuras.

## Cierre del paso
Al completar, registrar archivos modificados, pruebas ejecutadas, demostración, decisiones resueltas y límites conocidos. Actualizar Estado en Notion solo con evidencia; crear esta ficha no equivale a implementarla.

