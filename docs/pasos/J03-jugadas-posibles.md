# J03 — Jugadas posibles (M3)

Etapa de jugabilidad e interactividad · 4 de noviembre de 2026.

**Rama:** `feature/jugadas-posibles`. **Depende de:** J01, J02. **Estado actual:** Pendiente. **Decisiones vinculadas:** D14.

## Objetivo
Lista de jugadas posibles con su puntaje máximo, interactiva, sobre la tela izquierda.

## Fuente y alcance normativo
Plan de implementación en Notion (https://app.notion.com/p/40ec28142b55812da30cda3d6044f8b1) y bocetos aprobados por el autor (https://claude.ai/artifact/D74dybtbt4w1z4TfQn9zs9). Los valores de estilo salen de los bocetos y pueden ajustarse al verlos dentro del juego. Reglas comunes: la previsión coincide con la anotación; animaciones con azar aparte (nunca tocan semilla, estado ni guardado); respetan "Reducir movimiento" y la velocidad elegida; no dejan el juego trabado y se limpian al cambiar de pantalla; dados protegidos intactos.

## Trabajo a realizar
1. Nuevo `scripts/plays_panel.gd`. Cálculo que recorre combinaciones de dados libres y guarda la de más puntos por categoría (`possible_combinations()` hoy guarda la primera).
2. Título entre los adornos y filas de mayor a menor puntaje, alineadas al borde dorado. El mouse marca los dados; el clic arma el grupo; se muestra lo que sigue posible debajo de los grupos armados.
3. Con el mouse sobre un dado, la ficha va abajo de la lista.
4. Jefes: no listar categorías prohibidas; ocultar puntos si el jefe oculta la previsión.
5. Preferencia nueva en `presentation_preferences.gd`: clave en `DEFAULTS` y migración al cargar (la validación compara la cantidad de claves). Activada por defecto. Interruptor en `show_options()`.

## Criterios de aceptación
- Cada fila da el mismo total que anotar esa jugada.
- Clic arma el mismo grupo que hacerlo a mano.
- Las preferencias viejas cargan; la opción persiste.
- Peor caso sin pisarse: varios grupos, lista y ficha.
- El panel no aparece antes de tirar ni con la opción apagada.
- Suite completa sin fallos y revisión en el juego con capturas en `test-results/`.

## Fuera de alcance
T4 (vendedor enojado), monedas, tutorial, La Semilla, pantallas nuevas y balance.
