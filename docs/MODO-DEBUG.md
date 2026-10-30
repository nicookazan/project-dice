# Nueva partida debug

30/10/2026. El menú ofrece «Nueva partida debug» junto a la opción normal.

- **Daño infinito:** después de tirar, anotar una mano válida completa como mínimo el objetivo del rival. La previsión y el resultado incluyen una fila «DEBUG · Daño infinito» con el aporte necesario; el total coincide con su desglose. Se puede avanzar por los siete niveles y los 21 encuentros con una mano por rival.
- **Plata infinita:** la libreta, la tienda y los paneles de compra muestran $∞. Comprar, renovar y reparar no requieren saldo ni lo descuentan. Se conservan las reglas de espacio de inventario, stock, objetivos de compra y elección de paquetes. Los precios y los contadores por sección siguen visibles para poder probarlos.
- **Identificación y continuidad:** aparece «DEBUG · DAÑO ∞ · PLATA ∞» durante la partida. El modo se guarda y «Continuar» lo restaura. Una nueva partida normal reinicia las ayudas. Ambas opciones usan el guardado habitual; si existe una partida activa, se pide la confirmación normal antes de reemplazarla y se conserva el archivo anterior como respaldo histórico.

No se almacenan números IEEE infinitos: el dinero ilimitado es una regla explícita y el daño agrega los puntos finitos necesarios para alcanzar cualquier objetivo. Esto conserva las validaciones, el desglose y la precisión del guardado.

Formato v5: incluye `debug_mode`. Los formatos v1–v4 migran como partidas normales, sin activar ayudas. Se conservan las migraciones anteriores y las rutas del guardado.

Pruebas: `tests/debug_mode_tests.gd` cubre previsión sin mutación, anotación única, compras dirigidas de precio muy alto, stickers, paquetes, renovación por sección, reparaciones, recarga real, confirmación del menú, vuelta al modo normal y campaña completa. `tests/debug_mode_review.gd` captura menú, inicio, mano, resultado y tienda a saldo cero.

Verificación final: **2185 comprobaciones, cero fallos**. Campaña completa de siete niveles y 21 encuentros; capturas revisadas a 1440×900 y 1280×800.
