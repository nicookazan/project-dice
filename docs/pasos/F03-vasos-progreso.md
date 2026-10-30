# F03 — Vasos, colección y progreso permanente

Versión 1 · 25 de octubre de 2026.

**Entrega:** Posterior. **Estado al crear el plan:** Diferido.

**Depende de:** [F02 — Nivel 8, simulación y jefe CMD](F02-simulacion-cmd.md). **Decisiones vinculadas:** D12. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [F03 en Notion](https://app.notion.com/p/404c28142b5581bba1dae33a6a55554f?pvs=204).

Implementar desbloqueos y recompensas persistentes solo después de validar las mecánicas directas y definir su catálogo.

## Fuente y alcance normativo
PRD IA §8–9, beneficios permanentes pospuestos por el autor. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Definir vasos desbloqueables por logros, sus reglas e inventario inicial. El vaso elegido conserva su material durante toda la partida.
2. Separar guardado de progreso permanente y partida activa. Perder borra mejoras de la partida, no beneficios ya obtenidos en victorias anteriores.
3. Registrar hitos limitados de victorias contra CMD por cada vaso; número de hitos y premios requieren D12.
4. Modelar alcances por recompensa: universal, seleccionable para otra partida, exclusiva de ciertos vasos o pasiva directa.
5. Las seleccionables desbloqueadas son reutilizables y no se consumen por elegirlas.
6. Desbloquear una moneda solo habilita su aparición en tienda, no la entrega gratis.
7. Añadir colección y selección de vaso/beneficios al menú cuando haya contenido; mostrar condiciones y progreso.
8. Adaptar reglas de capacidad de consumibles conservando objetos guardados si disminuye la capacidad.

## Criterios de aceptación
- Perder una partida conserva logros y beneficios previos.
- Seleccionar un beneficio no consume su desbloqueo ni exige otra victoria.
- Un beneficio exclusivo de un vaso no afecta a otro sin regla explícita.
- Una moneda desbloqueada entra al conjunto de ofertas, pero no al inventario inicial automáticamente.
- Los hitos tienen tope de recompensas; victorias posteriores no conceden mejoras infinitas.
- Una actualización del catálogo migra progreso sin duplicar premios ya cobrados.

## Entregable y decisiones
Catálogo con requisitos, efectos, límites y compatibilidades; esquema de progreso, menú y pruebas. El autor pospuso este desarrollo: no bloquea ningún paso 01–20.

## Fuera de alcance
No inventar otros vasos ni premios por victoria como balance definitivo. No colocar beneficios permanentes en los cinco espacios de monedas por defecto.

## Cierre del paso
Al completar, registrar archivos modificados, pruebas ejecutadas, demostración, decisiones resueltas y límites conocidos. Actualizar Estado en Notion solo con evidencia; crear esta ficha no equivale a implementarla.

