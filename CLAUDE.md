# CLAUDE.md — Dios no juega a los dados

Juego de dados roguelike basado en la generala. Godot 4.7.1 / GDScript, renderer GL Compatibility. Idioma del proyecto, docs y UI: **español rioplatense**. Responder y documentar en español.

## Qué es (resumen del PRD)

- Se tiran 5 dados (siempre cinco, sin compra de dados). 2 manos por encuentro, 3 tiradas por mano. Se arman grupos (par, doble par, trío, escalera, full, póker, generala), se anota y se acumulan puntos hasta el objetivo del encuentro.
- Los dados se mejoran con: material del cuerpo (acero, cobre), elemento (fuego, agua, electricidad, tierra, viento), material de los puntos (antes "carcasa": esmeralda, rubí, zafiro, diamante; se resquebrajan y se reparan), mejoras numéricas globales por número, cambio de caras.
- Stickers sobre el **termo** (antes en el vaso) potencian categorías; monedas (5 pasivas + 1 ranura de un uso); tienda de cuatro secciones con vendedor y maletín.
- Campaña: 7 niveles, 2 rivales + 1 jefe por nivel = 21 encuentros hasta Dios. Mate siempre (nunca cerveza). Nivel 8/CMD, vasos y metaprogreso están **diferidos** (F01–F04).

## Fuentes de verdad y precedencia

Notion ("DIOS NO JUEGA A LOS DADOS", id `404c28142b558067ab00ef1f23dbbecb`) es el origen de los PRD y del plan, pero **no es accesible desde Claude Code** (WebFetch solo devuelve "Notion"; no hay conector). Las copias locales fechadas son la referencia de trabajo:

1. `docs/REGLAS-VIGENTES.md` — reglas actuales; **manda sobre todo lo histórico**.
2. `docs/fuentes/PRD-PROTOTIPO-2026-10-25.md` — decisiones confirmadas (prevalecen sobre el PRD IA).
3. `docs/fuentes/PRD-IA-2026-10-25.md` — PRD escrito por IA, amplio; muchas reglas reemplazadas (ver `docs/pasos/COBERTURA.md`).
4. `docs/fuentes/PRD-ORIGINAL-2026-10-25.md` — PRD escrito a mano (idea original; contradice reglas actuales: 2 tiradas, más de 5 dados, etc.).
5. `docs/pasos/` — plan en 25 fichas (00–20, F01–F04) con dependencias; `docs/pasos/notion-manifest.json` mapea cada ficha a su página Notion; `docs/pasos/DECISIONES.md` registra D01–D13.
6. `ESTADO.md` e historial por paso; un contrato por sistema en `docs/*.md` (PUNTUACION-Y-EVENTOS, GEMAS, METALES, TIENDA-POR-SECCIONES, etc.).

Si cambia el alcance de una ficha, actualizar ficha local **y** avisar al usuario que el tablero de Notion debe actualizarse a mano (no hay sincronización). No crear PRD nuevos que compitan con los actuales. Para traer contenido nuevo de Notion, pedirle al usuario que lo pegue o exporte a `docs/fuentes/`.

## Estado (al 2026-10-31)

Pasos 00–18 completos en alcance técnico; 19 (presentación/arte) reabierto para pase artístico; **20 (balance, pruebas finales, ejecutable Windows) listo para empezar**. Pendientes que no se deben dar por resueltos: D01/D02/D04 (datos comerciales), D07 (catálogo de jefes/objetivos), D10 (arte/texto/sonido finales), D11 (balance/duración), sesión humana de juego. Los datos de campaña son **provisionales** y deben verse como tales. Suite reciente: ~2195 comprobaciones, cero fallos (verificar corriendo, no confiar en el número).

## Estructura

- `scripts/rules.gd` reglas puras (categorías, puntuación, economía); `game.gd` estado y transiciones; `main.gd` UI/mesa/tienda (~1600 líneas); `campaign.gd`, `boss_rules.gd`, `shop.gd`, `purchases.gd`, `stickers.gd`, `coins.gd`, `gems.gd`, `materials.gd`, `elements.gd`, `number_upgrades.gd`, `dice_state.gd`, `save_*.gd`, `presentation_*.gd`.
- `tests/run_tests.gd` agrega las suites `*_tests.gd`; `tests/*_review.gd` generan capturas (requieren GPU, **sin** `--headless`) en `test-results/` (ignorado por Git).
- `assets/art/` arte y prompts de procedencia; `ART-PROMPTS.md` índice. Plan de renovación del pixel art: `docs/PLAN-ARTE-PIXEL.md`; el arte nuevo (`assets/art/pixel-v3/`) se genera por código en `tools/art/` (scripts de Godot; los de la tienda son Python 3.13 con Pillow, numpy y scipy) y los dados (`PROTEGIDOS.sha256`) no se tocan. Al pasar arte existente se respeta su dibujo (se limpia, no se rediseña) y el autor aprueba bocetos antes de integrar.

## Comandos

- Jugar: `Jugar.cmd` (Windows, busca `Godot*_win64.exe` en el Escritorio) / `./Jugar.command` (Mac) / abrir `project.godot` y F5.
- Tests: `Probar.cmd`, o `<godot_console> --headless --path . --script res://tests/run_tests.gd` (exit ≠ 0 si falla; escribe `test-results/tests.json`).
- Revisión visual: `godot --path . --script res://tests/<nombre>_review.gd`.
- Modos: "Nueva partida debug" (daño y plata infinitos), `Nivel-corto.cmd` (40→70→110), `Validar-nivel.cmd` (perfil de prueba v1).

## Convenciones de trabajo

- Ejecutar **una ficha por vez**: leerla, confirmar dependencias, implementar, correr la suite, revisar UI cuando cambie, registrar resultado y límites en `ESTADO.md` y en el contrato del sistema.
- Datos antes que código: precios, pesos, objetivos y rangos viven en tablas explícitas; no hardcodear balance. Valores de prueba ≠ balance aprobado.
- La previsión de puntos debe coincidir siempre con la anotación; el azar debe ser reproducible por semilla y exacto tras guardar/continuar (no re-sortear al cargar).
- Redondeo: decimales se conservan y se redondea una sola vez al total de mano (0,5 hacia arriba).
- Arte: respetar el pixel art existente y el diseño maestro de dados (`docs/DISENO-MAESTRO-DADOS.md`, imagen marfil frontal). No sustituir por geometría provisional. Registrar prompts/procedencia.
- Guardado versionado (hoy v6) con migraciones; nunca sobrescribir archivos inválidos. Guardados y preferencias van en `%APPDATA%/DiosNoJuegaALosDados/`, fuera de Git.
- No publicar ni distribuir externamente sin instrucción explícita. Rama principal: `main` (única de larga vida); cada cambio va en `feature/<nombre>` con PR contra `main`.
- Fuera de alcance salvo pedido: compra/venta de dados, más de 5 dados, destrucción del dado, usos seguros de cristal, dos tiradas por mano, victoria automática por generala servida, nivel 8/CMD.

## Agentes disponibles (en `~/.claude/agents`)

`godot-architect` (arquitectura/GDScript), `game-designer` (reglas, balance), `producer` (sprints/scope), `qa-analyst` (test plans, regresión), `pixel-artist`, `sound-designer`, `creative-director`, `technical-director`, `level-designer`.
