# 00 — Base recuperada y reglas vigentes

Versión 1 · 25 de octubre de 2026.

**Entrega:** Base. **Estado al crear el plan:** Completado y verificado.

**Depende de:** Sin dependencias. **Decisiones vinculadas:** Ninguna bloqueante. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [00 en Notion](https://app.notion.com/p/404c28142b558142b7d5d3c98c997ae7?pvs=204).

Conservar una referencia funcional sobre la cual desarrollar sin reconstruir la demo ni confundir reglas antiguas con actuales.

## Fuente y alcance normativo
PRD-PROTOTIPO: secciones 5, 6 y 10; definición posterior de doble par. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Punto de partida y alcance
Este paso ya está implementado. La copia de desarrollo está en C:/Users/Kazan/Documents/ChatGPT/Dios no juega a los dados. La demo anterior permanece en C:/Users/Kazan/Desktop/Godot/project-dice. Motor comprobado: Godot 4.7.1, GDScript.

## Trabajo realizado
1. Recuperación de escenas, scripts, arte y pruebas.
2. Consolidación de reglas vigentes frente a los dos PRD y sus antecedentes.
3. Doble par de cuatro dados con base 15; alternativa de dos pares separados.
4. Intereses negativos eliminados: con deuda, cero intereses.
5. Validación de identificadores de dados fuera de rango.
6. Verificación de la libreta antes y después de anotar.

## Evidencia de aceptación
- 132 comprobaciones aprobadas en test-results/tests.json; una recorre las 1.296 selecciones de cuatro dados.
- Capturas revisadas: test-results/doble-par.png y doble-par-anotado.png.
- 2-2-5-5 forma doble par de 29; un 6 sobrante lleva la mano a 35, idéntico al resultado acreditado.
- Se mantiene el recorrido 40 → 70 → 110, monedas y tienda reducida.

## Entregable y conservación
README.md, ESTADO.md, docs/REGLAS-VIGENTES.md y suite existente. Esta ficha registra trabajo comprobado, no implica que materiales, guardado o campaña estén terminados. Antes de otro paso, ejecutar la suite como referencia y conservar su resultado.

## Fuera de este paso
No volver a implementar lo que ya existe. El plan no declara balance validado, arte definitivo ni una partida completa hasta Dios.

## Cierre del paso
Al completar, registrar archivos modificados, pruebas ejecutadas, demostración, decisiones resueltas y límites conocidos. Actualizar Estado en Notion solo con evidencia; crear esta ficha no equivale a implementarla.

