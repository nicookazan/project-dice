# Libreta frontal y objetos a la derecha — 28 de octubre de 2026

Decisiones del usuario: la información necesaria del encuentro se reúne en la libreta; los botones mantienen su diseño y ubicación por ahora. El nombre del juego y «Ver termo» no aparecen durante el juego. La libreta es un panel frontal de la interfaz a la izquierda, sin perspectiva ni versión física en la mesa.

La libreta contiene puntos y objetivo, mano, tiradas disponibles, dinero, nivel y rival, anuncio o condición del jefe, grupos y cálculos consultables, total previsto o anotado, selección, avisos de acciones y estado. Los detalles largos y los grupos se pueden desplazar. La semilla y el carácter provisional se consultan al pasar el cursor por el panel. Los cálculos conservan su acceso al detalle completo.

Termo y mate están a la derecha junto al vaso. El termo queda atrás, el mate a su izquierda y el vaso pequeño adelante, con aproximadamente la mitad de la altura del termo. Se actualizaron las zonas de clic y el origen del lanzamiento. Se conserva la disposición anterior de la tienda.

**Pendiente por decisión expresa del usuario:** en un pase posterior, los stickers comprados y asignados se verán sobre el termo. Este cambio no implementa su colocación visual. La consulta de los stickers existentes sigue disponible al tocar el termo.

## Revisión

`tests/notebook_review.gd` captura inicio, grupos y jefe. Imágenes en `test-results/libreta-frontal-inicio.png`, `test-results/libreta-frontal-grupos.png` y `test-results/libreta-frontal-jefe.png`. Las pruebas de interfaz comprueban la ubicación de los datos, la ausencia de título y botón visible y el acceso al termo reubicado.

Suite final: 2155 comprobaciones, cero fallos.

## Recurso y procedencia

Recurso nuevo: `assets/art/environment-v2/mesa-libreta-frontal-v1.png`. Edición con Imagegen integrada, conservando los originales. Se usan `mesa-proporciones-v3.png` como destino de edición y `vaso-cuero-negro-mesa-v2.png` como referencia del vaso. La libreta y los textos se renderizan con controles nativos de Godot.

Prompt completo:

> Use case: precise-object-edit. Image 1 is the edit target pixel-art game background; image 2 is reference for the approved upright black leather cup. Preserve the entire room, table framing, three burgundy gold-bordered felt play areas, hand and cloud, perspective, palette and pixel-art quality. Remove ALL objects on the left: thermos, mate gourd, straw, notebook, pencil and their shadows; reconstruct empty wooden tabletop and room behind them. Group the same stainless steel thermos, wooden mate with silver bombilla, and upright black leather dice cup together in the RIGHTMOST felt section. Layout in logical 1440x900 coordinates: tall thermos behind at x1230..1340 y170..455; mate to its left at x1115..1220 y355..485, bombilla up to y290; smaller upright black leather cup with green felt inside and gold stitching in FRONT at x1250..1380 y435..580. Thermos is tallest, cup about HALF thermos height, mate shorter than cup. The cup stands on its base, opening up. Keep all three props strictly right of x1100. Left and middle felt sections entirely empty. Do not introduce any notebook, text, stickers, UI, dice or new objects. Maintain exact composition, framing and aspect ratio. Finished game background plate, no text anywhere.
