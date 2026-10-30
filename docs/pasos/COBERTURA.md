# Cobertura, fuentes y precedencia

Versión 1 · 25 de octubre de 2026. Revisión de los tres PRD de Notion, el resumen vigente y el código recuperado. Este mapa cubre las familias de requisitos y secciones; no afirma que las funciones estén implementadas.

## Fuentes

- [PRD original](https://app.notion.com/p/3fdc28142b5580bcb634de0539a326f1).
- [PRD IA](https://app.notion.com/p/3fec28142b55815c9f84c21402b73154).
- [PRD-PROTOTIPO](https://app.notion.com/p/404c28142b5581679265d602cec7e69b).
- [Reglas vigentes](../REGLAS-VIGENTES.md) y evidencia local en ESTADO.md y test-results/tests.json.

Las últimas decisiones específicas del prototipo prevalecen; propuestas de arquitectura y producción siguen identificadas como propuestas. Una imagen conceptual no cambia reglas escritas. El estado de la demo en Notion menciona 105 pruebas históricas; el informe local posterior registra 132.

## Mapa de requisitos

| Fuente / tema | Requisito | Paso responsable | Tratamiento |
|---|---|---|---|
| PRD original: idea y juego | Generala, modificaciones, monedas y stickers; punto de partida histórico. | 00–20 | Base preservada con decisiones posteriores. |
| PRD IA §1: visión | Azar con decisiones, construcción de estrategia, club argentino. | 03–13, 19–20 | Confirmado; público/plataforma propuestos se concretan en demo PC. |
| §2: historia y adversario | Mano/nube, Dios triángulo con ojo, tono y revelaciones. | 19, F02 | Hasta Dios ahora; CMD y desenlace posterior. |
| §3: estructura | Dos manos, suma de puntos, continuar al alcanzar objetivo, derrota. | 00, 14, 16, 18 | Implementado parcialmente; campaña y flujo ampliado pendientes. |
| §3: rescates | Elección explícita entre rescates válidos o derrota. | F01 | Diferido hasta catálogo. |
| §4: manos/tiradas | Tres tiradas, conservar sueltos, selección exacta, bloqueo al enviar, servida. | 00–02, 13, 16 | Confirmado y preservado. |
| §5: combinaciones | Bases, escaleras al as, generala servida sin victoria automática. | 00, 02 | Confirmado. |
| Prototipo: doble par | Exactamente cuatro dados, dos números distintos, base 15; dos pares alternativa. | 00, 02, 09 | Implementado; sticker/bono servido pendiente D02. |
| §5: repetición de categorías | Bono histórico desde trío, nunca pares/sobrantes. | COBERTURA; F04 si cambia alcance | Inalcanzable con cinco dados, no requisito actual. |
| §6: puntuación | Número vs puntos, sumas antes de factores, alcance por grupo, redondeo final. | 02–10, 13, 16 | Confirmado; ejemplos de cálculo se usan como pruebas. |
| §7: identidad de dado | Caras, datos locales/globales, persistencia entre manos. | 01, 03, 15 | Pendiente. |
| §7: números | Globales/locales acumulables, números ausentes, rarezas e información previa. | 03, 11–13 | Reglas confirmadas; balance D01. |
| §7: cambio de cara | Número destino por oferta, cara y dado elegidos; modifica probabilidades. | 03, 12–13 | Confirmado. |
| Prototipo: metales | Acero +3 al conservar, cobre +0,5 al relanzar; duración de encuentro. | 04 | Confirmado. |
| Prototipo: elementos | Fuego/agua +5, electricidad +3 por coincidencia, tierra +2 por conservado, viento +0,5. | 05–06 | Confirmado; alcance/duración explícitos. |
| Prototipo: tres componentes | Un material, carcasa y elemento simultáneos, sustitución por familia. | 01, 07, 12 | Confirmado; reemplaza límite previo de dos. |
| Prototipo: gemas | Esmeralda ×2 puntos propios, zafiro +2, rubí ×1,5, diamante copias lineales. | 07 | Confirmado. |
| Prototipo: rotura | Después de puntuar, por carcasa intacta en grupo; no en sobrantes. | 08, 15 | Confirmado; no destruye el dado. |
| Prototipo: reparación/deuda | Opcional tras cobrar victoria, precios 2/3/4/5, permite deuda, intereses cero. | 00, 08, 13–15 | Motor e interfaz selectiva implementados en 08; D08 resuelta. |
| §7: familias históricas | Ferromagnético, hielo, brillo y otras variantes. | F04 | Preservado como futuro; no trasladar cristal destructivo. |
| §7: cantidad y capacidad | Compra/venta de dados, reserva y ampliación sin máximo. | COBERTURA | Superado para versión actual de cinco dados fijos. |
| §8: vaso | Cuero inicial y espacio reservado; otros vasos elegibles por logros. | 01, 11, 13, F03 | Cuero actual; otras reglas pospuestas. |
| §8: stickers | Categoría, par/sobrantes compartido, recompra sin máximo al mismo precio. | 09, 11–13 | Reglas confirmadas; magnitudes D02. |
| §9: monedas iniciales | Seis pasivas y dos de un uso, cinco espacios y una ranura aparte. | 10–13 | Ya disponibles; adaptación pendiente. |
| §9: activas/cooldown | Manos o rivales, una carga, persistencia, no afectar grupos bloqueados. | F01, 17 | Reglas preservadas; catálogo pendiente D03. |
| §9: copias y ranuras | Habilitadora, copias persistentes, cooldown independiente, exceso de consumibles. | F01 | Reglas preservadas; detalles pendientes. |
| §9: logros/hitos | Moneda desbloqueada habilita tienda, beneficios por vaso/Matrix, reutilizables. | F03 | Pospuesto expresamente. |
| §10 y prototipo: economía | Premio base, manos, exceso, intereses marginales sobre saldo previo. | 00, 08, 14, 18, 20 | Demo implementada; curva de campaña D07. |
| Prototipo: tienda | Cuatro monedas, dos componentes, dos números, sticker+pack, vaso reservado. | 11–13 | Diseño vigente, reemplaza cuatro secciones antiguas de dos ofertas. |
| §10: stock/renovación | Vacío al comprar, renovación por sección, costo compartido y reinicio por visita. | 11–12 | Confirmado. |
| §10: compra/aplicación | Validación, selección, aplicación inmediata y sustitución sin reserva. | 12–13 | Confirmado; transacciones son propuesta técnica. |
| §10: packs | Elegir 1/3 o recibir 2, sin duplicados dentro, poseídos suben nivel. | 09, 12, 15 | Confirmado. |
| §11: ambientes | Día, tarde, noche, cierre, espacio, agujero negro, cielo. | 18–19 | Integración técnica completada; mate siempre por usuario; acabado final D10. |
| §11: simulación | ASCII verde, objetos físicos conservados, sin infierno. | F02 | Posterior. |
| §12: jefes | Tres candidatos por nivel 1–6, Dios con tres reglas, objetivos fijos. | 17–18 | Estructura confirmada; catálogo D07. |
| §12: suspensión | Desactivación temporal con recuperación; activas siguen recargando. | 17, F01 | Adaptación a carcasas actuales necesita D09. |
| §13: interfaz | Tres zonas, libreta lápiz/azul, detalle, inspección, recorrido sin saltos. | 13–14 | Confirmado con propuestas visuales señaladas. |
| §13: menú principal | Nueva, Continuar, Colección, Opciones, Salir. | 14–15, F03 | Propuesta mínima; Colección cuando haya contenido. |
| §14: arte | Pixel art legible, volumen, club, conceptos como referencias no reglas. | 13, 19 | Dirección preservada. |
| §15: audio/animación | Cuero/dados/club, reacción de jefes, acelerar y reducir estímulos. | 19, F02 | Cuatro categorías sintetizadas y opciones integradas; mezcla final pendiente. |
| §16: accesibilidad/guardado | Legibilidad, símbolos, controles, preferencias, estado y azar persistentes. | 13, 15, 19 | Integrados y probados; preferencias separadas de partida; revisión humana pendiente. |
| §17: orden de desarrollo | Prototipo → tramo → completo. | README de pasos | Sustituido por este plan detallado de dependencias. |
| §18: aceptación | Pruebas de reglas, recorrido, UI y diseño. | Cada ficha, 16, 20 | Cubierto; excluir casos históricos incompatibles. |
| §19: abiertos/riesgos | Balance, catálogos, costos, guardado, narrativa, alcance. | DECISIONES D01–D13 | Cada decisión tiene momento de resolución. |
| §20: procedencia/ilustraciones | Fuentes e imágenes conceptuales no fijan reglas ni cantidades. | 00, 13, 19 | Preservado en fuentes y reglas vigentes. |

## Reglas superadas que no deben implementarse por accidente

- Dos tiradas del original → tres tiradas base.
- Trío/póker con relleno → selección exacta de tres/cuatro dados.
- Generala servida gana automáticamente → base 100 provisional, más dados y mejoras.
- Puntajes elevados al cuadrado → suma de grupos; el bono de repetición histórico es inalcanzable con cinco dados.
- Capacidad creciente, compra/venta de dados y derrota por quedarse sin dados → cinco dados fijos durante la versión actual.
- Cristal destruido y usos seguros → carcasa resquebrajada, riesgo desde primera puntuación en grupo y reparación opcional.
- Límite de dos componentes → tres espacios, uno por familia.
- Renovar toda la tienda o familias fijas por espacio → renovar una sección con tipos sorteados de nuevo.
- Cuatro secciones antiguas de dos ofertas → distribución nueva 4/2/2/(1+pack), vaso reservado.
- Cooldown por dados o tiempo → solo manos jugadas o rivales vencidos.
- Infierno/diablo → simulación y CMD en fase posterior.

## Límite de cobertura

El plan conserva lo pospuesto sin aprobar catálogos, magnitudes ni fechas nuevas. Todo efecto futuro necesita su propia definición antes de habilitarlo. La cobertura de diseño no equivale a evidencia de funcionamiento; las pruebas se registran al cerrar cada ficha.

