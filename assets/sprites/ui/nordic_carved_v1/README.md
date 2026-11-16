# Interfaz Nordic Carved v1

Kit generado con image_gen integrada a partir de la referencia de madera tallada del usuario. Cinco PNG RGBA originales: button_normal, button_hover, button_pressed, menu_panel e inventory_slot.

Madera carbón azulada, incisiones nórdicas simplificadas, acentos salvia y bronce; centros despejados para tipografía marfil. Las imágenes no contienen rótulos.

## Uso

Asignar nordic_menu_theme.tres al Theme de un Control raíz. Incluye Button normal/hover/pressed/disabled/focus, Panel y PanelContainer. InventorySlot es una variación de PanelContainer. Fuente existente: BridgeParapet. Configurar Texture Filter = Nearest en el Control raíz.

Abrir NordicMenuPreview.tscn y ejecutar F6: muestra texto editable y botones con estados interactivos; Continuar aparece deshabilitado como ejemplo. Los botones no ejecutan acciones de gameplay. El menú existente permanece sin cambios.

Las imágenes se escalan completas, sin recortes ni nine-slice: mantener botones aproximadamente 3–4:1, panel 4:3 y casilla 1:1. Recomendación inicial: botones 340x83 o mayores, panel 700x525, casillas 80x80 o mayores. Las tallas cambian ligeramente entre estados. El foco de teclado/gamepad usa un contorno adicional; deshabilitado usa modulación del normal. La casilla tiene centro transparente para superponerla sobre un fondo oscuro.

## Prompts exactos

Herramienta integrada image_gen. transparent_background=true. Referencia visual: imagen de madera tallada adjunta por el usuario.

Use case: stylized-concept. Asset type: production 2D game UI skin, one isolated component. The attached image is a STYLE REFERENCE ONLY: borrow charcoal blue weathered carved wood and restrained Nordic interlaced incisions, do not reproduce the photograph or large rune wheel. Adapt to Whispers of the North, a cozy mysterious Nordic fairy-tale 2.5D pixel-art game with muted sage, slate, walnut and terracotta palette. Clean deliberately simplified pixel-art shapes, square stepped edges, sparse large wood-grain marks, matte surface, no photographic fine grain, no 3D perspective. Front-on perfectly flat UI component, symmetrical rectangular silhouette, subtle squared bevel. Restrict decorative incised knotwork to outer border and small corners. Very dark calm flat central area, high readability for ivory text added later. No text, letters, runes, logos, watermarks, symbols in center, mockup or additional objects. Genuine transparent background outside shape, no outer shadow or glow, tight crop with only 4px transparent padding. Entire component visible. Palette charcoal #202c32, blue-gray #3c5057, wood #51483f, restrained sage #93a68a, ivory #e9dfc5.

### button_normal

Component: One horizontal menu button approximately 4:1 width to height. Dark carved wood, thin slate bevel, tiny interlaced carved corner accents. Central 75% width completely quiet and empty. Resting unselected state.

### button_hover

Component: One horizontal menu button approximately 4:1 width to height. Dark carved wood, thin sage-green highlight bevel and softly brighter carved corner accents, no outer glow. Central 75% width completely quiet and empty. Highlighted selected state. Same silhouette as a plain rectangular carved-wood normal button.

### button_pressed

Component: One horizontal menu button approximately 4:1 width to height. Dark carved wood, inset recessed dark bevel with a narrow muted warm bronze inner rim, tiny interlaced carved corner accents. Central 75% width completely quiet and empty. Pressed state, same simple rectangular silhouette.

### menu_panel

Component: One large rectangular menu panel 4:3 width to height. Thin carved charcoal wooden frame, delicate interlaced corner carvings, small understated symmetrical arch-like incisions along top border recalling the reference carving. Center 85% is nearly uniform dark charcoal blue with barely perceptible wood texture for menu content. No central illustration. Compact 5% thick frame.

### inventory_slot

Component: One square inventory item slot. Restrained dark carved wooden border, small incised angular corner joins, slate bevel, almost flat charcoal center completely empty to receive an item icon. Simple unobtrusive sibling component of a Nordic wooden menu.

