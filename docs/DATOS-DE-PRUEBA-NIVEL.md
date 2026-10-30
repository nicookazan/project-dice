# Datos de prueba del primer nivel — v1

Perfil `nivel-corto-prueba-v1`, elegido para validar el paso 16 el 26 de octubre de 2026. **Provisional: no resuelve el balance final D01/D02/D04.** Se activa solo mediante `Validar-nivel.cmd` o `-- --validation-profile`. El juego normal conserva sus tablas anteriores. Guardado separado: `%APPDATA%/DiosNoJuegaALosDados/saves/validacion-nivel-v1.json`. El perfil se identifica en menú, anuncio y mesa; no aumenta plata inicial ni cambia objetivos 40 → 70 → 110, reglas, cantidad de dados, tiradas o manos.

Los datos se fijan aquí antes de ejecutar la sesión de validación. Fuente de código: `scripts/validation_profile.gd`.

## D01 — números

| Rareza | Global explícito | Local explícito | Precio | Peso de rareza |
|---|---:|---:|---:|---:|
| Común | +1 | +2 | $2 | 4 |
| Rara | +4 | +5 | $3 | 2 |
| Épica | +6 | +9 | $4 | 1 |
| Legendaria | +9 | +13 | $5 | 0,5 |

Los globales respetan rangos existentes; los locales son magnitudes explícitas de este perfil, no rangos globales trasladados. Se incluyen resultados 1–6. Cambio de cara: $2, común, peso 1 por número. Global y local: peso 1 por combinación de tipo/número/rareza. El generador primero elige rareza y después candidato elegible con su peso; no son probabilidades globales equiprobables entre todas las filas.

## D02 — stickers

| Tipo | Puntos por nivel | Suma al multiplicador por nivel | Precio individual |
|---|---:|---:|---:|
| Par y sobrantes | 2 | 0,25 | $3 |
| Trío | 3 | 0,5 | $4 |
| Escalera | 0 | 1 | $5 |
| Full | 4 | 0,75 | $6 |
| Póker | 5 | 1,25 | $7 |
| Generala | 7 | 1,5 | $8 |

Se reutilizan incrementos explícitos de las pruebas anteriores, sin declararlos aprobados para el juego final. Peso individual 1 por tipo. Packs: elegir 1 entre 3 distintos o recibir 2 distintos, $5 por pack y peso 1 por modalidad. Pool con los seis tipos. Se mantienen los dos lugares de stickers: individual + pack. Recompra sube nivel sin duplicar espacio; precio individual base constante. Doble par no recibe sticker ni bono de servida inventado.

## D04 — componentes, monedas y ofertas

- Acero/cobre: $3 cada uno, peso 1 por candidato.
- Fuego/agua/electricidad/tierra/viento: $3 cada uno, peso 1.
- Esmeralda/zafiro/rubí/diamante intactos: $4 cada uno, peso 1. Riesgos y reparación usan reglas existentes, no cambian.
- Ocho monedas existentes: precios/reventa anteriores ($4/$2 pasivas y $2/$1 consumibles), peso 1 por candidato; no cupos garantizados por tipo. Equipadas se excluyen de nuevas generaciones.
- Renovación compartida empieza en $1 y aumenta por renovación efectiva; cuatro secciones renovables independientes y vaso reservado. Se conserva la política actual con reemplazo: pueden repetirse candidatos en diferentes lugares/renovaciones, cada oferta con identidad única. No es política comercial final aprobada.

## Escenarios de validación

Las rutas naturales no inyectan dados, plata ni stock; parten de menú y dados base. Los escenarios de cobertura usan resultados y cartera de laboratorio explícitos para comprar cada familia y forzar condiciones que no deben depender de una búsqueda aleatoria. Se registran aparte de las rutas naturales. Reanudar y repetir clics no debe cambiar pago, stock, riesgo ni selección.

El perfil optativo permite luego una sesión humana. Tiempo de compra, comprensión y diversión no pueden certificarse solo con pruebas automatizadas. D01/D02/D04 siguen pendientes para balance final.
