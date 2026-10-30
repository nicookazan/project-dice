# 19 — Ambientes, narrativa breve, audio y accesibilidad

Versión 1 · 25 de octubre de 2026.

**Entrega:** Hasta Dios. **Estado actual:** Reabierto para pase artístico por revisión del usuario del 27 de octubre de 2026. Integración técnica probada con 2017 comprobaciones, cero fallos. Mano/nube originales restauradas; variantes de jefes, exteriores y Dios pendientes de acabado en el mismo pixel art. D10: mate siempre y conservar estilo existente. Textos, mezcla e identidades finales D07 siguen pendientes.

**Depende de:** [13 — Mesa, libreta, inspección y tienda jugable](13-interfaz-inspeccion.md), [18 — Progresión de siete niveles hasta Dios](18-campana-dios.md). **Decisiones vinculadas:** D10. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [19 en Notion](https://app.notion.com/p/404c28142b5581b1a4a8f96dca21fc36?pvs=204).

Comunicar el avance hacia Dios y los estados del juego con una presentación coherente y legible.

## Fuente y alcance normativo
PRD IA §2, §11–16; arte actual recuperado. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar

**Referencia de puntos ya aprobada:** `assets/art/dice-master-v1/puntos-gema-mate-aprobados.png`. Aplicar exactamente los cuatro acabados mates/opacos y apagados de rubí, zafiro, esmeralda y diamante, sin destellos. La imagen brillante previa queda superada. Esta parte de la dirección artística ya no está pendiente de aprobación; su implementación y estados derivados sí.

**Cambio de familia visual confirmado — 27 de octubre de 2026:** sustituir representación y término de carcasa por **material de los puntos**. Puntos negros en base y puntos de esmeralda/rubí/zafiro/diamante en sus mejoras; no convertir el cuerpo entero en gema. Conservar todos los efectos/riesgos/reparaciones y familias independientes. Señalar el daño en los puntos manteniendo su cantidad y legibilidad; actualizar ofertas, fichas y reparación. El diseño maestro del cuerpo permanece intacto. [Contrato vigente](../DISENO-MAESTRO-DADOS.md).

**Dirección de dados confirmada el 27 de octubre de 2026:** aplicar a todos los dados el [diseño maestro aprobado](../DISENO-MAESTRO-DADOS.md), también a ofertas e ilustraciones de tienda. Preservar geometría, perspectiva y paleta base al derivar materiales, gemas, elementos y roturas. La referencia está conservada; sustitución de sprites y variantes pendientes dentro de este pase artístico. No usar el atlas isométrico anterior como especificación de forma.
1. Preparar variaciones del mismo club y encuadre: día, tarde, noche, cierre con ventanas tapadas, espacio, agujero negro y cielo.
2. Mate siempre, en los siete ambientes, por decisión directa del usuario del 27 de octubre de 2026: «cambiamos a tener mate siempre». Reemplaza cerveza nocturna y continuidad anterior propuesta.
3. Mantener nube y mano en rivales comunes; manos diferenciadas con objetos/gestos para jefes 1–6; Dios como triángulo con ojo.
4. Relacionar cada representación de jefe con su regla del catálogo. No usar retratos de conceptos antiguos como identidad definitiva.
5. Añadir señales de selección, bloqueo, efecto, rotura, reparación, compra y anotación que no oculten el cálculo.
6. Preparar diálogos breves o gestos de jefes según su identidad: tono cotidiano/gracioso que se vuelve extraño y amenazante. Textos finales pendientes.
7. Audio por categorías: dados/cuero, club, ambiente y efectos. Incorporación gradual y opciones de volumen; sonidos concretos son propuesta.
8. Permitir acelerar animaciones y reducir destellos/movimiento; controles legibles y estados distinguibles sin depender solo del color.
9. Revisar recursos existentes antes de generar reemplazos. D10 registra inventario de arte, prioridades y aprobación visual necesaria.

## Criterios de aceptación
- El ambiente cambia después del jefe y nunca altera resultados o consume RNG de jugabilidad.
- Los siete niveles son reconocibles sin variar la ubicación de las acciones esenciales.
- Animación acelerada y reducida produce la misma partida.
- Dios tiene identidad de triángulo/ojo; cierre oculta exterior; espacio y agujero negro se distinguen.
- Todas las interacciones principales son legibles con textos largos y a resoluciones de prueba.
- Botones y señales de compra/rotura funcionan con sonido silenciado y sin depender solo del color.

## Entregable
Recursos integrados, lista de procedencia, opciones y capturas/vídeo de transiciones revisados. Documentar qué sigue provisional.

## Fuera de alcance
Cinemática de simulación, CMD y producción artística ilimitada; pertenecen a F02 o a iteraciones posteriores.

## Cierre del paso
Al completar, registrar archivos modificados, pruebas ejecutadas, demostración, decisiones resueltas y límites conocidos. Actualizar Estado en Notion solo con evidencia; crear esta ficha no equivale a implementarla.

### Evidencia de cierre — 27 de octubre de 2026

**Avance posterior — treinta caras:** seis números por acabado negro/rubí/zafiro/esmeralda/diamante generados, guardados en ambos PRD e integrados en mesa y tienda. Galería desde menú/Opciones; daño en un punto con R y suspensión S. Treinta recursos individuales y cinco láminas conservados. 2101 comprobaciones, cero fallos; seis capturas por resolución revisadas. [Contrato y catálogo](../CARAS-DE-DADOS.md). Resto del pase artístico pendiente.

**Avance posterior — tienda:** implementado el rediseño solicitado con la imagen del usuario como referencia: paño bordado de cuatro sectores, carteles, ofertas ilustradas, libreta, inventario y controles reales. 2025 comprobaciones, cero fallos; siete capturas por resolución revisadas. [Tienda, procedencia y prompts](../TIENDA-ESTILO.md). Continúa pendiente el resto del pase artístico; no se declara aprobación del nuevo resultado por el autor.

**Corrección posterior por revisión del usuario:** retiradas las manos geométricas y sus objetos por no respetar el estilo existente. Se reutilizan mano/nube originales del club para rivales y jefes 1–6. La diferenciación artística por jefe queda pendiente: debe producirse en el mismo pixel art, sin tomar esos marcadores como dirección aprobada. Exteriores y Dios conservan su condición provisional. La integración funcional aprobada por pruebas no equivale a cierre artístico.

- `scripts/backdrop.gd`: cuatro ventanas, siete exteriores, nube/mano y objetos por regla, triángulo/ojo de Dios; mate y cámara conservados.
- `presentation_state.gd`, `presentation_audio.gd`, `presentation_preferences.gd` y `main.gd`: frases/avisos, cuatro familias de audio original, silencio, volumen, velocidad, reducción de estímulos y contraste. Preferencias persistidas aparte del guardado.
- Suite completa: **2017 comprobaciones, cero fallos** (1959 anteriores + 58 nuevas). Partida natural por UI con semilla 3 idéntica en tres velocidades; snapshots incluyen azar, stock, recibos y puntuación. Compra, rotura y reparación emiten señales una sola vez.
- `tests/presentation_review.gd`: doce capturas por resolución y prueba real de reproducción/silencio, sin errores. Evidencias `test-results/<resolución>-presentacion-*.png`, WAV de dados e informe `presentation_demo`.
- [Contrato, inventario de procedencia y límites](../PRESENTACION-Y-ACCESIBILIDAD.md). D10 resuelta para bebida; propuestas de arte/texto/sonido listas para revisión, sin atribuir aprobación humana ni catálogo D07 final. Próximo: 20, balance y ejecutable.

