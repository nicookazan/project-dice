# Monedas nuevas — catálogo (D03)

**Estado: primera tanda implementada (C07–C51, U01–U08) con la arquitectura de [PLAN-MONEDAS-NUEVAS.md](PLAN-MONEDAS-NUEVAS.md).** Los efectos viven en `scripts/coins.gd` como datos (`effects`) y los evalúa `scripts/coin_effects.gd`; sumar una moneda es escribir una fila, sin tocar `rules.gd` ni `game.gd`. Todos los valores, precios y probabilidades siguen **provisionales** (D01/D02/D04 pendientes) hasta la simulación de balance (fase 9, no hecha). El arte es provisional: las monedas nuevas muestran una moneda en blanco con su abreviatura.

## Decisiones aplicadas al implementar

- **Mult de mano** (C17, C36, C39, C40, C41, C48, C50…): suma a cada grupo que sea combinación, nunca a los sobrantes. Con trío + par se aplica dos veces.
- **Puntos de mano** (C18, C37, C38, C42, C49): fila plana propia, sin multiplicar (como la fila DEBUG). Los puntos por dado y por combinación sí se multiplican.
- **Por dado** (C22–C24, C29–C34): los puntos cuentan en los cinco dados; el mult (C22–C24, C35) solo en dados dentro de una combinación.
- **Crecientes** (C48–C51): el contador avanza al cerrar el evento y rinde desde el siguiente; la previsión no modifica el estado; un jefe que suspende la moneda no frena el contador.
- **C18:** `strength` 40 y `grace`; cada tirada resta los dados tirados; la primera tirada tras comprarla no resta. A 0 se quita del inventario, se registra el evento `coin_broken` y el mensaje avisa. Suspendida por jefe: ni aporta ni se desgasta.
- **C19:** el saldo puede llegar a −$10 en compras y renovaciones de tienda; vender paga $1. Las reparaciones ya admitían deuda sin límite (comportamiento previo, sin cambios).
- **C45:** −20 % con redondeo al más cercano (4→3, 6→5, 9→7, 14→11) en ofertas y renovaciones. El contador de renovación sube sobre el precio base.
- **C21 / U06:** una renovación gratis por visita; no sube el contador de su sección. U06 suma una más.
- **C43 / C44:** capacidad calculada (`Coins.capacity`). No se puede vender una moneda de ranura si quedarían más monedas que ranuras. La suspensión por jefe no reduce la capacidad.
- **C25:** conjuntos 1234, 2345, 3456 y 4561; base 20 (servida 25); el quinto dado es sobrante.
- **C26:** solo el dado que sale 1. Al armar el grupo se elige la asignación que da la mejor categoría y, a igualdad, la mayor suma de caras; en empate total, los números más bajos. Se guarda en `group.assigned` (id de dado → número), por lo que previsión, anotación y guardado coinciden. El número imitado cuenta para puntos del dado, mejoras globales, paridad y monedas por número. Optimiza el grupo, no la mano completa.
- **C27 / U08:** relanzar un solo dado no gasta tirada pero cuenta como tirada hecha (la mano deja de ser servida). Se usa automáticamente si hay una fuente disponible (C27 primero, después un token de U08). C27 se renueva cada mano; el token de U08 también se descarta al terminar la mano.
- **C28:** un par también cuenta como doble par para las monedas de categoría (no cambia su base ni los stickers).
- **C46:** la marca `shell_saved` vive en el dado; el sorteo de rotura se consume siempre. **C47:** mitad de costo por gema, redondeo hacia arriba. **U07:** solo en la fase de reparación; la gema elegida más cara sale gratis.
- **U01** pasó a 1 y 4 (id `boost`); U03 es 2 y 5; U04 es 3 y 6. Los impulsos se acumulan (`Game.impulses`).
- **U05:** flag de mano que se limpia al anotar; entra como factor ×2 en cada grupo con combinación.
- **Tienda:** sorteo por etapas (tipo 75/25 → rareza → moneda uniforme, datos en `shop_tables.coin_type_weights` y `coin_rarity_weights`). Las etapas con una sola opción no consumen azar; las vacías se renormalizan.
- **Guardado v7** con migración idempotente desde v6 (impulsos en lista, `shell_saved` por dado, contadores nuevos y tablas de tienda).

## Pendiente
Arte final de las monedas nuevas (fase 8), simulación de balance (fase 9), sesión humana de juego (D11) y actualizar a mano el tablero de Notion.

Notación: **+x/+y** = x puntos / y multiplicador. Los decimales se conservan y se redondea una sola vez al total de mano (0,5 hacia arriba). Los puntos de las monedas por dado cuentan **los cinco dados**, sobrantes incluidos, igual que Pares/Impares.

## Rarezas y probabilidades (provisional)

| Rareza | Probabilidad por oferta | Precio | Reventa |
|---|---|---|---|
| Común | 60 % | 4 | 2 |
| Rara | 28 % | 6 | 3 |
| Épica | 9 % | 9 | 4 |
| Legendaria | 3 % | 14 | 7 |

**La rareza de cada moneda es un punto de partida.** Su asignación final queda a cargo de Claude durante las pruebas de balance: se corre una simulación por moneda, se mide cuánto aporta y cuán fácil rompe el juego, y se sube o baja la rareza (o se ajusta el valor) según el resultado. Cada cambio se registra acá.

Un uso: Común 70 %, Rara 25 %, Épica 5 %; precio 2 / 3 / 5; reventa 1 / 1 / 2. Se mantiene la exclusión de pasivas ya poseídas. Excepción de reventa: Moneda de oro (C19).

## Pasivas

### Mult por combinación (+1 mult; completan C01–C04)

| Código | Moneda | Rareza |
|---|---|---|
| C07 | Par: +1 mult a cada par | Común |
| C08 | Doble par: +1 mult | Común |
| C09 | Trío: +1 mult | Común |

### Puntos por combinación (+x puntos al anotar esa combinación)

| Código | Moneda | Puntos | Rareza |
|---|---|---|---|
| C10 | Par | +10 | Común |
| C11 | Doble par | +14 | Común |
| C12 | Trío | +12 | Común |
| C13 | Escalera | +16 | Común |
| C14 | Full | +18 | Común |
| C15 | Póker | +22 | Común |
| C16 | Generala | +30 | Rara |

Bases actuales: Par 5, Doble par 15, Trío 10, Escalera 20, Full 30, Póker 40, Generala 50.

### Generales

| Código | Moneda | Efecto | Rareza |
|---|---|---|---|
| C17 | +1 mult | +1 mult plano a toda mano | Rara |
| C18 | Moneda gastada | Entra con **+40 puntos**; cada dado relanzado le resta 1 (ver reglas). A 0 se rompe y desaparece | Rara |
| C19 | Moneda de oro | Cuesta 10. Permite comprar hasta saldo **−10**. Se vende por **1** | Rara |
| C20 | Tirada permanente | +1 tirada por mano (4 en vez de 3) | Legendaria |
| C21 | Renovación gratis | La primera renovación de cada visita a la tienda es gratis; el resto se pagan | Común |

**C18.** Resta 1 por **cada dado que se tira**, incluidos los 5 de la primera tirada de cada mano. Única excepción: la **primera tirada de la primera mano del primer encuentro luego de comprar la moneda** no resta, para que el +40 inicial sea utilizable. En los demás rivales, la primera tirada sí resta. La pérdida es permanente entre manos y encuentros (el estado vive en la instancia y se guarda). Al llegar a 0 se rompe y libera la ranura.

**C19.** El saldo puede ser negativo. La deuda no tiene intereses ni vencimiento; se paga con ganancias futuras. Vender la moneda paga 1, así que nunca sale a mano: es crédito a propósito. Hay que mostrar el saldo negativo en la interfaz.

**C21.** "Una renovación gratis" es **una por visita en total**, no por sección: renovar una sección la gasta y las otras tres pagan su contador normal.

### Por tipo de dado (+1 punto / +0,5 mult **por dado**)

| Código | Moneda | Cuenta dados con | Rareza |
|---|---|---|---|
| C22 | Dados de metal | cuerpo de acero o cobre | Rara |
| C23 | Dados elementales | cualquier elemento (fuego, agua, electricidad, tierra, viento) | Rara |
| C24 | Gemas | cualquier gema (esmeralda, rubí, zafiro, diamante) | Rara |

Se propuso +1/+1; queda en **+1/+0,5** hasta probar. Con cinco dados del mismo tipo: +5 puntos y +2,5 mult.

### Cambian una regla

| Código | Moneda | Efecto | Rareza |
|---|---|---|---|
| C25 | Escaleras de 4 | La escalera se arma con 4 dados; el quinto queda **afuera** (sobrante) | Épica |
| C26 | Comodín | El **dado 1** funciona como comodín en los grupos y **vale el número que imita** (en un trío de 6 con un 1, ese 1 vale 6); brilla al activarse | Épica |
| C27 | Relanzo libre | Una vez por mano, relanzar **un solo dado** no gasta tirada | Épica |
| C28 | Par doble *(experimental)* | Un par cuenta también como doble par | Rara |

C26 y C28 son para probar cómo se usan. C27 salía "muy roto" en versión libre; con el límite de una vez por mano queda Épica. Si sigue roto, subir a Legendaria.

### Por número

| Código | Moneda | Efecto | Rareza |
|---|---|---|---|
| C29–C34 | Uno … Seis | +5 puntos por cada dado con ese número | Común |
| C35 | Seises | +1 mult por cada 6 | Rara |

**Temporales:** si resultan rotas se quitan. Referencia: Pares da +2 por dado par (~+6 por mano); +5 por un número da ~+4 de media pero con más varianza.

### Por ritmo de tiradas

| Código | Moneda | Efecto | Rareza |
|---|---|---|---|
| C36 | Primera tirada | +1 mult si anotás en la primera tirada de la mano | Rara |
| C37 | Tiradas sin usar | +5 puntos por cada tirada que no usaste | Común |
| C38 | Última tirada | +20 puntos si anotás gastando la última tirada | Común |

Son condicionales: **no crecen** durante la partida.

### Por posición o estado

| Código | Moneda | Efecto | Rareza |
|---|---|---|---|
| C39 | Segunda mano | +1 mult en la segunda mano del encuentro | Común |
| C40 | Termo | +0,5 mult por cada nivel de sticker en el termo (suma de todos los niveles) | Rara |
| C41 | Colección | +1 mult por cada moneda equipada | Rara |
| C42 | Interés | +1 punto por cada 5 de saldo (saldo negativo cuenta 0) | Común |

### Infraestructura

| Código | Moneda | Efecto | Rareza |
|---|---|---|---|
| C43 | Bolsillo | Capacidad de pasivas +2 (ocupa una; neto +1) | Rara |
| C44 | Bolsillo chico | Capacidad de un uso +1 (ocupa una ranura de pasivas) | Rara |
| C45 | Descuento | Precios de tienda −20 % | Rara |

Sin moneda de reventa (descartada).

### Gemas

| Código | Moneda | Efecto | Rareza |
|---|---|---|---|
| C46 | Gema templada | La **primera** rotura de cada gema se ignora | Rara |
| C47 | Joyero | Reparar gemas cuesta la mitad | Común |

**C46 — vender y recomprar.** La marca "ya usé mi rotura gratis" se guarda en la **gema del dado**, no en la moneda. Así vender y recomprar la moneda no la renueva; cada gema se salva una sola vez por partida.

### Que crecen durante la partida

Guardan progreso en el `state` de su instancia, que sobrevive entre manos y encuentros y se guarda. Si se vende y se recompra, vuelve a cero.

| Código | Moneda | Efecto | Rareza |
|---|---|---|---|
| C48 | Veterana | +0,5 mult permanente por cada encuentro ganado con ella equipada | Rara |
| C49 | Acumulada | +3 puntos permanentes por cada mano anotada con ella equipada | Común |
| C50 | Racha | +0,5 mult por cada mano seguida con combinación; se pierde toda al anotar "sin combinación" | Rara |
| C51 | Cazajefes | +1 mult permanente por cada jefe vencido con ella equipada | Épica |

## De un uso

| Código | Moneda | Efecto | Rareza |
|---|---|---|---|
| U01 | Impulso 1 y 4 | **Reemplaza** al Impulso 1 y 3 actual. +3 puntos por cada 1 y 4 hasta el fin del encuentro | Común |
| U03 | Impulso 2 y 5 | ídem para 2 y 5 | Común |
| U04 | Impulso 3 y 6 | ídem para 3 y 6 | Común |
| U05 | Doble mult | Duplica el mult de la mano actual | Rara |
| U06 | Renovación gratis | Una renovación de tienda sin costo | Común |
| U07 | Reparar gema | Repara una gema | Común |
| U08 | Relanzo libre | Relanza un dado sin gastar tirada (una vez) | Común |

Contextos de uso: U01 y U03–U05 y U08 solo en `play`; U06 solo en tienda; U07 en tienda o reparación.

**Migración de U01:** el id `boost`, sus textos, el arte, los tests (`coin_tests.gd`, `run_tests.gd`) y el guardado v6 hablan de "1 y 3". Al cambiarlo hay que actualizar todo eso y migrar los guardados que tengan la moneda.

## Descartado

Cambiar la cara de un dado a elección (ya existe con la compra de dados). Moneda de reventa.

## Pendientes de decisión

1. **C18:** ¿"el resto de primeras manos" incluye la segunda mano del mismo primer combate? Se asumió que sí resta (solo una tirada gratis en toda la vida de la moneda).
2. **Rarezas/probabilidades/precios y valores de las crecientes:** todo provisional hasta cerrar D01/D02/D04.
3. **Previsión:** C25, C26 y C28 cambian el agrupamiento; la previsión de puntos debe coincidir con la anotación. Con C26 hay que decidir qué número toma el comodín cuando varias combinaciones son posibles (se asume el que maximiza el puntaje).
4. **Notion:** este documento es local; el PRD de Notion hay que actualizarlo a mano.

Resueltos: U01 se reemplaza por Impulso 1 y 4; el comodín vale el número que imita.

## Actualización: rarezas de la etapa de monedas (5 de noviembre de 2026)

Cambios de rareza aprobados por el autor. Precio y reventa salen de la rareza (Común $4 / $2, Rara $6 / $3). Siguen provisionales hasta el ítem 7.

| Moneda | Código | Antes | Ahora |
|---|---|---|---|
| Puntos de generala | C16 | Rara | Común |
| Dados de metal | C22 | Rara | Común |
| Dados elementales | C23 | Rara | Común |
| Gemas | C24 | Rara | Común |
| Seises | C35 | Rara | Común |
| Renovación gratis | C21 | Común | Rara |
| Tiradas sin usar | C37 | Común | Rara |
| Última tirada | C38 | Común | Rara |
| Segunda mano | C39 | Común | Rara |
| Interés | C42 | Común | Rara |

Las tablas de más arriba conservan la rareza original de cada moneda; esta tabla manda. Plan completo: [fichas MON0–MON9](pasos/README.md) y decisiones D15.
