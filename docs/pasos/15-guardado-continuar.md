# 15 — Guardado versionado y continuar partida

Versión 1 · 25 de octubre de 2026.

**Entrega:** Nivel jugable. **Estado actual:** Completado el 26 de octubre de 2026 con 1083 comprobaciones aprobadas, cero fallos. D06 aplicada como decisión técnica de implementación; dependencia 14 completada.

**Depende de:** [14 — Menú y recorrido de un nivel completo](14-flujo-nivel-menu.md). **Decisiones vinculadas:** D06. Ver [DECISIONES.md](DECISIONES.md) para distinguir trabajo que puede avanzar de condiciones de cierre.

## Objetivo
Ficha de seguimiento: [15 en Notion](https://app.notion.com/p/404c28142b558196ba9ccf758b133923?pvs=204).

Reanudar exactamente la misma partida sin perder decisiones, volver a sortear ofertas ni duplicar recompensas.

## Fuente y alcance normativo
PRD IA §2 ruta del guardado y §16 accesibilidad/guardado (propuestas); requisito de reanudación. Las decisiones posteriores del prototipo prevalecen sobre los antecedentes. Arquitectura, orden de entregas y operaciones técnicas de esta ficha son propuesta de implementación, no nuevas reglas aprobadas.

## Trabajo a realizar
1. Redactar una decisión técnica breve con versión de formato, ubicación del archivo y momentos de escritura. D06 contiene estas decisiones; no presentarlas como reglas ya aprobadas.
2. Propuesta: guardar después de cada acción válida que cambia estado, al terminar su resolución; nunca en mitad del cálculo o animación. Así se conservan tiradas, agrupaciones, compras y packs pendientes.
3. Persistir fase, nivel/rival, puntos, manos/tiradas, caras y resultados, grupos y bloqueos, mejoras, contadores, roturas, inventario, plata, ofertas y vacíos, costo de renovación, elección de pack/reparación, recompensa ya aplicada y estado RNG completo.
4. Guardar IDs y datos simples, no referencias de nodos. Mantener la semilla y el estado actual del generador con precisión entera; no perder bits por conversiones numéricas.
5. Propuesta técnica: escritura temporal y reemplazo atómico con copia anterior recuperable. Validar versión y consistencia al cargar.
6. Ubicar el guardado dentro de la carpeta del usuario de Windows; nombre exacto por resolver. No depender de la carpeta de instalación, pues una futura consola CMD mostrará esta ruta.
7. Separar partida activa de futuras preferencias/progreso permanente. Al completar o perder, impedir que Continuar resucite una sesión cerrada.
8. Ante archivo corrupto o versión desconocida, dar una salida legible sin sobrescribir silenciosamente el único archivo recuperable.

## Criterios de aceptación
- Guardar/cargar una mano con un grupo bloqueado y otro dado en vaso conserva ambos.
- Continuar genera el mismo siguiente resultado y ofertas que una ejecución ininterrumpida con las mismas acciones.
- Reanudar después de cobrar no vuelve a acreditar plata; después de rotura no vuelve a sortearla.
- Pack abierto conserva sus candidatos y pago; reparación pendiente conserva la elección aún no ejecutada.
- Monedas gastadas, deudas y acumulaciones de acero/cobre sobreviven correctamente.
- Inyectar fallo de escritura permite recuperar una versión válida anterior.
- Archivo inválido o versión futura produce mensaje y no borra progreso automáticamente.
- Continuar solo está disponible con una partida válida en curso.

## Entregable
Servicio de persistencia, contrato versionado, pruebas de ida/vuelta por fases y botón Continuar conectado.

## Fuera de alcance
Sincronización en nube, cuentas, ranking, medidas anti-trampas y metaprogreso todavía sin catálogo.

## Cierre del paso

Guardado local v1, checkpoint posterior a cada cambio resuelto, respaldo verificado y reemplazo por renombrado. Ruta Windows: %APPDATA%/DiosNoJuegaALosDados/saves/partida-v1.json. Payload binario sin objetos dentro de sobre JSON versionado, para conservar RNG/semilla int64 exactos. Validación antes de cargar y sin reproducir operaciones de juego.

Continuar solo aparece con partida activa válida. Menú conserva la sesión; Abandonar partida la cierra con confirmación. Cerrar ventana permite Guardar y salir. Victoria/derrota/abandono dejan marcador cerrado que impide resucitar respaldos anteriores. Errores se informan con reintento. Principal corrupto con respaldo ofrece recuperación explícita conservando original; versión desconocida bloquea carga/escritura automática, sin borrar archivos. Nueva partida explícita archiva archivos anteriores.

Archivos: scripts/save_store.gd, scripts/save_validator.gd, scripts/main.gd, scripts/game.gd, project.godot; tests/save_tests.gd, tests/save_process_smoke.gd, tests/save_review.gd, tests/run_tests.gd y aislamiento de pruebas de interfaz previas. [Contrato técnico y evidencia](../GUARDADO-Y-CONTINUAR.md).

Pruebas: 1083 comprobaciones (978 anteriores + 105 nuevas), cero fallos. Ocho fases activas, int64 extremo, próxima tirada/stock idénticos, rotura/cobro/compra/pack/reparación una sola vez, decisiones pendientes, falla de escritura, recuperación y estados inválidos. Recorrido natural UI con autosave hasta victoria. Dos procesos separados prueban recuperación y tirada siguiente exactas. Siete capturas por resolución revisadas a 1280×800 y 1440×900. Las pruebas usan archivos aislados del jugador.

D06 es una elección de implementación documentada, sin atribuir aprobación previa. Actualiza D05: Menú conserva; Abandonar es explícito. Límites: local v1, sin nube/metaprogreso/migración de versiones desconocidas; sin garantía ante fallo físico antes de completar escritura. D01/D02/D04 conservan datos comerciales finales pendientes. Sigue 16 con datos de prueba explícitos y validación humana aún pendiente.

