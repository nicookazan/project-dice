extends RefCounted
## Recortes de las manos de jefe v4 (manos-clic-v4.png / manos-clic-atras-v4.png / manos-contorno-v4.png).
## GENERADO por tools/art/make_manos_clic_v4.py: no editar a mano.
## Una fila por jefe: `frames` cuadros de `size` px lógicos desde `sheet_y`; `origin` es dónde cae el recorte en la ventana
## grande (189×110; la mano en reposo en 45,17). El cuadro 0 es el reposo y el resto, la animación del clic.
const CLIPS := {
	"l1_kioskero": {"frames": 13, "size": Vector2i(46, 62), "sheet_y": 0, "origin": Vector2i(45, 17), "back": false, "ring_y": 0},
	"l1_payador": {"frames": 13, "size": Vector2i(61, 80), "sheet_y": 62, "origin": Vector2i(45, 17), "back": false, "ring_y": 128},
	"l1_palomas": {"frames": 18, "size": Vector2i(173, 102), "sheet_y": 142, "origin": Vector2i(15, 7), "back": false, "ring_y": 292},
	"l2_cebador": {"frames": 13, "size": Vector2i(128, 98), "sheet_y": 244, "origin": Vector2i(45, 0), "back": true, "ring_y": 500},
	"l2_chamuyero": {"frames": 14, "size": Vector2i(61, 71), "sheet_y": 342, "origin": Vector2i(45, 17), "back": false, "ring_y": 700},
	"l2_referi": {"frames": 13, "size": Vector2i(61, 50), "sheet_y": 413, "origin": Vector2i(45, 17), "back": true, "ring_y": 846},
	"l3_conde": {"frames": 15, "size": Vector2i(161, 83), "sheet_y": 463, "origin": Vector2i(16, 6), "back": false, "ring_y": 950},
	"l3_lobizon": {"frames": 14, "size": Vector2i(64, 53), "sheet_y": 546, "origin": Vector2i(46, 17), "back": false, "ring_y": 1120},
	"l4_tahur": {"frames": 13, "size": Vector2i(189, 93), "sheet_y": 599, "origin": Vector2i(0, 17), "back": true, "ring_y": 1230},
	"l4_patovica": {"frames": 13, "size": Vector2i(50, 73), "sheet_y": 692, "origin": Vector2i(45, 14), "back": true, "ring_y": 1420},
	"l4_payaso": {"frames": 13, "size": Vector2i(60, 73), "sheet_y": 765, "origin": Vector2i(47, 16), "back": false, "ring_y": 1570},
	"l5_visitante": {"frames": 14, "size": Vector2i(62, 93), "sheet_y": 838, "origin": Vector2i(44, 17), "back": true, "ring_y": 1720},
	"l5_farolero": {"frames": 13, "size": Vector2i(46, 71), "sheet_y": 931, "origin": Vector2i(45, 17), "back": false, "ring_y": 1910},
	"l5_computadora": {"frames": 13, "size": Vector2i(42, 76), "sheet_y": 1002, "origin": Vector2i(54, 0), "back": true, "ring_y": 2056},
	"l6_horizonte": {"frames": 13, "size": Vector2i(61, 93), "sheet_y": 1078, "origin": Vector2i(45, 17), "back": false, "ring_y": 2212},
	"l6_relojero": {"frames": 13, "size": Vector2i(46, 72), "sheet_y": 1171, "origin": Vector2i(45, 17), "back": false, "ring_y": 2402},
	"l6_durmiente": {"frames": 13, "size": Vector2i(150, 93), "sheet_y": 1243, "origin": Vector2i(20, 17), "back": true, "ring_y": 2550},
}
