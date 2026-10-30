# Compras, objetivos y reemplazos — contrato del paso 12

Implementado y probado el 26 de octubre de 2026. Las ofertas identificadas del paso 11 ahora producen transacciones completas. Se conservan D01/D02/D04 para precios, incrementos y probabilidades finales; las familias sin tablas comerciales se verifican mediante fixtures explícitos, sin habilitar valores inventados en la partida normal.

## Preparación y confirmación

Purchases.valid_offer valida la familia, sección y datos de la oferta. Purchases.prepare es pura: devuelve ok, code, message, cost y changes, o un error legible sin mutaciones. Valida saldo, capacidad, objetivo y operaciones numéricas sobre copias temporales. La deuda de reparación no permite compras a crédito, ni compras con saldo negativo.

Game.begin_purchase(section, offer_id) aplica de inmediato las compras sin objetivo (moneda, mejora global, sticker individual o pack). Para material, carcasa, elemento, mejora local o cara guarda pending_purchase con sección, identidad, oferta capturada y target, y entra en purchase_target sin cobrar ni vaciar stock.

set_purchase_target conserva la selección de uno de los cinco dados y, para cara, su índice de posición 0–5. purchase_preview devuelve el plan puro. confirm_purchase vuelve a localizar la oferta por ID y compara sus datos con los capturados, además de revalidar saldo y objetivo. Una oferta retirada o cambiada no se confirma. Durante la selección se bloquean renovación, salida, venta, uso de moneda y otras compras.

cancel_purchase vuelve a tienda y elimina la selección; conserva plata, dados, inventario, oferta y RNG. Una vez validado el plan, el commit aplica los cambios, descuenta el precio, vacía exclusivamente ese slot y registra un recibo en una operación sin esperas intermedias. Repetir confirmación o compra sobre el ID consumido no cobra ni aplica otra vez. No se vuelve a generar contenido.

purchase_receipts conserva oferta, precio pagado, objetivo y selección de sticker cuando corresponde. last_purchase_result guarda el último resultado exitoso. Los errores se devuelven sin mutar el juego; la interfaz muestra su mensaje. snapshot incluye estos campos y pending_purchase mediante copia profunda para el futuro guardado del paso 15. Otra visita limpia recibos del encuentro; los IDs de ofertas mantienen su secuencia de partida.

## Aplicación por familia

| Familia | Aplicación |
|---|---|
| Moneda | Instancia nueva, con validación de ranura/duplicados antes de pagar |
| Global | Acumula una vez en global_points para el número ofrecido |
| Local | Acumula una vez en el mapa del dado elegido |
| Cara | El jugador elige dado y posición; el número nuevo lo fija la oferta |
| Material | Sustituye solo material y limpia sus contadores steel_points/copper_multiplier |
| Elemento | Sustituye solo elemento y limpia sus contadores earth_points/wind_multiplier |
| Carcasa | Sustituye solo shell; la oferta exige intact=true y entrega shell_broken=false |
| Sticker/pack | Usa niveles y elección pendiente del motor de stickers |

El dado conserva su diccionario e ID estable. Cambiar una familia preserva caras, mejoras numéricas y las otras familias con sus contadores. No hay devolución ni reserva de la pieza sustituida. Una carcasa rota reemplazada no destruye el dado. Cambiar una cara no reescribe el resultado pasado ni las mejoras ligadas al número anterior. Un objetivo sin cambio de cara efectivo se rechaza sin cobrar.

## Paquetes y paneles

El individual aplica una mejora al tipo ofrecido. El paquete de dos aplica ambos tipos distintos de forma atómica. El paquete de elegir uno consume stock y cobra una sola vez, guardando opciones ya generadas, ID, origen shop y precio pagado en pending_sticker_pack. La fase sticker_choice bloquea nuevas transacciones y salida hasta elegir. Solo el elegido mejora; los descartados permanecen intactos y el recibo registra selected.

La UI provisional permite elegir dado, ver sus componentes actuales, elegir la cara por posición/número y confirmar o cancelar. El panel del pack pagado puede cerrarse y reabrirse; hacerlo no cobra, sortea, aplica candidatos ni devuelve la oferta. La misma API de elección conserva compatibilidad con los fixtures de paquetes del paso 09.

## Evidencia y límites

Al cierre del paso 12: **898 comprobaciones aprobadas, cero fallos:** 848 anteriores y 50 nuevas. tests/purchase_tests.gd cubre selección, cancelación, plan puro, snapshots, identidad del dado, conservación de capas, contadores de su propia familia, global/local/cara, precios cambiados, stock retirado, falta de saldo/ranura, deuda, duplicación, tres modalidades de sticker y recibos separados. tests/run_tests.gd prueba los paneles reales, confirmación doble y cierre/reapertura de un paquete ya pagado.

Informe purchases_demo en test-results/tests.json. Para repetir: Probar.cmd. Capturas revisadas: test-results/compra-reemplazo.png, compra-confirmada.png, compra-cara.png y compra-pack-eleccion.png, mediante tests/visual_review.gd. Implementación en scripts/purchases.gd, scripts/game.gd y scripts/main.gd.

Las tablas normales siguen ofreciendo las monedas provisionales; componentes/números/stickers requieren cerrar datos comerciales o cargar fixtures de prueba. No se habilita comprar/vender dados ni un sexto dado. El paso 13 completó la presentación e inspección del conjunto, conservando estos paneles y transacciones; guardado en disco en 15.
