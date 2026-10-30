# Mejoras numéricas globales y cambios de cara

Decisión vigente del usuario, 30/10/2026: se elimina la mecánica de mejoras locales. Todas las mejoras de puntos de un número benefician a todos los dados de la partida.

## Puntos

`Game.global_points` guarda la mejora acumulada por número, con claves "1"–"6". Un resultado aporta el número visible más su mejora global, antes de monedas, materiales, elementos y gemas. El número visible sigue determinando combinaciones y paridad.

Ejemplo: con dados 4-4-1-2-3 y +3 al 4, ambos cuatros aportan 7. Su par suma base 5 + 14 = 19; los sobrantes suman 6 y la mano da 25. Otra compra +8 al 4 acumula un bono de 11 y ambos cuatros pasan a aportar 15.

Las mejoras perduran entre manos, encuentros y niveles, incluso cuando un número no aparece en las caras actuales. Nueva partida las reinicia. No existe un mapa numérico por dado ni una operación para comprar bonos locales.

## Operaciones

| Operación | Resultado |
|---|---|
| apply_global(points, number, amount) | Acumula el bono de ese número para todos los dados |
| change_face(dice, id, face_index, number) | Reemplaza una posición de cara; conserva el resultado histórico hasta otra tirada |
| global_offer(number, amount, rarity, price) | Valida número, rareza, magnitud y precio explícitos |
| global_ranges() | Devuelve una copia de los rangos |

Los cambios de cara siguen siendo una operación distinta con selección de dado/cara. No aportan un bono de puntos particular al dado.

## Tienda

Las ofertas numéricas son globales o cambios de cara. Las mejoras de puntos no piden elegir un dado. Se compran tocando la ilustración o su precio; el efecto se consulta al pasar por la ilustración.

Rangos vigentes: común +1–3, rara +4–5, épica +6–8 y legendaria +9–10. Precios y pesos comerciales siguen siendo provisionales. Los errores de tipo, objetivos inválidos y desbordes se rechazan antes de cambiar estado o cobrar.

## Guardados anteriores

El formato v6 convierte los bonos locales existentes en bonos globales sumados por número. Elimina los mapas antiguos de los dados. Las ofertas antiguas se convierten en globales y su magnitud se ajusta al rango de su rareza. Una selección local todavía sin pagar vuelve a la tienda, sin cargo. La historia ya anotada conserva sus resultados originales; no se recalcula.

## Verificación

La suite comprueba igualdad de bonos en todos los dados, identidad de las combinaciones, acumulación, composición con materiales/elementos/gemas, compra desde el objeto, rechazo de ofertas locales, migración de guardados y conservación de saldo/RNG.

Resultado del pase: **2179 comprobaciones, cero fallos**. Se retiraron las pruebas de la mecánica eliminada y se sustituyeron por cobertura global y de compatibilidad.
