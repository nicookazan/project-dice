# Vaso de generala negro y verde

Petición del usuario del 28/10/2026: vaso de cuero negro por fuera, verde por dentro, siguiendo la fotografía adjunta.

Generado con Imagegen integrado, en modo edición. Se conservan el tamaño y la perspectiva de los vasos existentes; el exterior tiene grano de cuero negro, reflejos grises y costuras claras; el interior tiene fieltro verde con profundidad. Se elimina el sol dorado para seguir el acabado liso de la referencia.

Recursos finales:

- `vaso-cuero-negro-mesa-v1.png`, edición de `../club-table-v2.png`.
- `vaso-cuero-negro-tienda-v1.png`, edición de `../shop-table-v1.png`.

`scripts/backdrop.gd` utiliza únicamente las zonas del vaso de estas imágenes. Las proporciones nuevas del mate, termo y libreta siguen viniendo de `mesa-proporciones-v3.png`.

## Prompt de mesa

Use case: precise-object-edit. Image 1 is the edit target, a pixel art game background. Image 2 is a photographic reference for the new dice cup's materials. Edit ONLY the large leather generala dice cup lying sideways at the RIGHT of image 1. Preserve its EXACT size, location, silhouette, orientation, perspective and contact shadow. Change its brown exterior to BLACK LEATHER with visible subtle grain, slight creases, charcoal highlights, warm reflected light, and fine pale yellow stitching as in image 2. Change its dark brown interior to visibly GREEN FELT lining, emerald/forest green, with lighter green near the opening and deep green at the back to preserve depth. Remove the large gold sun emblem completely, leaving plain textured black leather. Keep the rim thick and black, and the fine stitched seams. Render entirely in the same crisp detailed pixel art as image 1. The green interior must be clearly legible and not look black. Preserve every pixel possible outside the cup: unchanged red velvet mats, gold borders, room, hand, clouds, notebook, mate and pencil. No added text, no dice, no logos. Preserve the original canvas aspect ratio and framing.

## Prompt de tienda

Use case: precise-object-edit. Image 1 is the edit target, a pixel art shop background. Image 2 is a photographic reference for the new dice cup's materials. Edit ONLY the leather generala dice cup lying sideways at the BOTTOM LEFT of image 1. Preserve its EXACT size, location, silhouette, orientation, perspective and contact shadow. Change its brown exterior to BLACK LEATHER with visible subtle grain, slight creases, charcoal highlights, warm reflected light, and fine pale yellow stitching as in image 2. Change its dark brown interior to visibly GREEN FELT lining, emerald/forest green, with lighter green near the opening and deep green at the back to preserve depth. Remove the large gold sun emblem completely, leaving plain textured black leather. Keep the rim thick and black, and the fine stitched seams. Render entirely in the same crisp detailed pixel art as image 1. The green interior must be clearly legible and not look black. Preserve every pixel possible outside the cup: unchanged red velvet mats, gold borders, room, hand, clouds, notebook, mate and pencil. No added text, no dice, no logos. Preserve original canvas aspect ratio and framing.
