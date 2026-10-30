# 11 — Generación de tienda y renovación por sección

Versión 1 · 25 de octubre de 2026.

**Entrega:** Nivel jugable. **Estado actual:** Modelo, generador y pruebas completados el 26 de octubre de 2026; dependencias 03, 09 y 10 completadas. D01/D02/D04 siguen pendientes para contenido comercial final; tablas completas verificadas con fixtures.

**Depende de:** [03 — Mejoras globales, locales y cambios de cara](03-numeros-caras.md), [09 — Stickers por categoría y paquetes](09-stickers-paquetes.md), [10 — Monedas iniciales e inventario extensible](10-monedas-inventario.md). **Decisiones vinculadas:** D01, D02, D04. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [11 en Notion](https://app.notion.com/p/404c28142b55813982bcfbec44d67f24?pvs=204).

Generar la distribución aprobada y renovar solo una sección, con precio creciente compartido durante la visita.

## Fuente y alcance normativo
PRD-PROTOTIPO: tienda ampliada, último reparto confirmado; PRD IA §10 stock y renovación. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Reemplazar el arreglo de dos monedas por secciones y ofertas identificadas, con tipo y datos de efecto.
2. Monedas: cuatro espacios mezclados al azar entre normales y de un uso, sin garantizar dos de cada tipo.
3. Material/carcasa/elemento: dos espacios; cualquiera puede ofrecer cualquiera de las tres familias, y renovar puede cambiar de familia.
4. Números/caras: dos espacios que pueden mezclar globales, locales y cambio de cara sin cupos por tipo.
5. Stickers: un espacio individual y uno de pack. Vaso: espacio reservado sin oferta.
6. Comprar vacía el espacio; renovar repone vacíos y cambia todas las ofertas de la sección elegida, conservando las otras.
7. Usar un contador de renovaciones único por visita. Secuencia inicial heredada 1, 2, 3…; al abrir otra tienda vuelve a 1. Comprar no incrementa el contador.
8. Separar generación de presentación y conservar resultados de la generación, para que renderizar/abrir un panel no vuelva a sortear.
9. Definir tablas configurables de precios y pesos. D01/D02/D04 deben cerrarse para ofrecer contenido final; pruebas pueden forzar ofertas explícitas.
10. Mantener probabilidades base de rareza numérica constantes entre niveles; no aplicar ese requisito automáticamente a otras familias.

## Criterios de aceptación
- Renovar monedas no cambia las otras tres secciones ni objetos ya comprados.
- Tras renovar monedas por 1, renovar otra sección cuesta 2; comprar entre ambas no altera ese precio.
- Un slot de elemento puede convertirse en material tras renovar.
- Una compra deja vacío solo su slot hasta renovación o siguiente tienda.
- Las cuatro ofertas de monedas pueden ser del mismo tipo si el sorteo lo produce.
- Sin saldo para renovar, ofertas, RNG y precio quedan intactos.
- Misma semilla y mismas acciones reproducen las mismas ofertas.

## Entregable
Modelo de tienda, generador y pruebas de stock/costo. No declarar precios o probabilidades balanceados por el hecho de funcionar.

## Fuera de alcance
Compra de dados nuevos, renovación global de toda la tienda y mejoras del vaso todavía sin definir.

## Cierre del paso
848 comprobaciones aprobadas, cero fallos: 795 anteriores y 53 nuevas. Generador/validación en scripts/shop.gd; stock, RNG y operaciones en scripts/game.gd; pestañas y tarjetas en scripts/main.gd. Pruebas en tests/shop_tests.gd, runner y fixtures de monedas; capturas mediante tests/visual_review.gd.

Se verificaron distribución 4/2/2/2, vaso reservado, mezcla sin cupos por subtipo, ofertas identificadas y almacenadas, renovación aislada, contador compartido, refill de vacíos, reproducibilidad, rechazo atómico sin saldo o con tablas inválidas, paquetes distintos y rareza numérica constante entre rivales. La UI no vuelve a sortear. Capturas revisadas: test-results/tienda-monedas-cuatro.png, tienda-componentes.png, tienda-numeros.png y tienda-stickers.png. Informe shop_demo en test-results/tests.json.

Ver [contrato y evidencia](../TIENDA-POR-SECCIONES.md). La tienda normal muestra cuatro monedas con datos provisionales; demás familias conservan tablas ausentes. D01/D02/D04 no se resuelven por funcionar el generador. Compras con objetivo y aplicación de otras familias en 12; siguiente recomendado.

