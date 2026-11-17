"""Build modular 3D Nordic & DP-inspired ruin assets in assets/models/nordic_ruins/."""
from pathlib import Path
import math
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/models/nordic_ruins"

TEXTURES = {
    "masonry": "environment/materials/nordic_surfaces_v2/ruin_masonry.png",
    "fractured": "environment/materials/nordic_surfaces_v2/fractured_rock.png",
    "village": "environment/materials/nordic_v1/village_stone.png",
    "snow": "environment/materials/nordic_surfaces_v2/packed_snow.png",
    "timber": "environment/materials/nordic_wood_v1/mossy_old_timber.png",
}


def vec(v):
    return "Vector3(" + ", ".join(f"{x:.4f}" for x in v) + ")"


class SceneBuilder:
    def __init__(self, root_name: str):
        self.root_name = root_name
        self.resources = []
        self.nodes = []
        self._mesh_idx = 0
        self._shape_idx = 0

        for key, path in TEXTURES.items():
            self.resources.append(
                f'[ext_resource type="Texture2D" path="res://assets/sprites/{path}" id="tex_{key}"]'
            )

        # Materials matching the pale carved sandstone/limestone of the reference + Nordic moss/crimson
        mats = [
            ("stone_light", "tex_masonry", (0.86, 0.83, 0.75), 0.55),
            ("stone_mid", "tex_masonry", (0.76, 0.73, 0.65), 0.6),
            ("stone_dark", "tex_fractured", (0.52, 0.50, 0.45), 0.5),
            ("stone_moss", "tex_masonry", (0.56, 0.66, 0.52), 0.6),
            ("stone_cap", "tex_village", (0.82, 0.78, 0.68), 0.5),
            ("snow_cap", "tex_snow", (0.92, 0.95, 0.98), 0.6),
            ("crimson_rock", "tex_fractured", (0.46, 0.14, 0.16), 0.45),
            ("crimson_dark", "tex_masonry", (0.30, 0.09, 0.11), 0.5),
        ]
        for mid, tex_id, col, uv_scale in mats:
            self.resources.append(
                f'[sub_resource type="StandardMaterial3D" id="mat_{mid}"]\n'
                f"albedo_color = Color({col[0]}, {col[1]}, {col[2]}, 1)\n"
                f'albedo_texture = ExtResource("{tex_id}")\n'
                f"roughness = 0.95\n"
                f"uv1_triplanar = true\n"
                f"uv1_scale = {vec((uv_scale, uv_scale, uv_scale))}\n"
                f"texture_filter = 0"
            )

        # Emissive runic materials
        self.resources.append(
            '[sub_resource type="StandardMaterial3D" id="mat_rune_cyan"]\n'
            "albedo_color = Color(0.45, 0.88, 0.98, 1)\n"
            "emission_enabled = true\n"
            "emission = Color(0.35, 0.78, 0.95, 1)\n"
            "emission_energy_multiplier = 1.8\n"
            "roughness = 0.4"
        )
        self.resources.append(
            '[sub_resource type="StandardMaterial3D" id="mat_rune_crimson"]\n'
            "albedo_color = Color(0.95, 0.25, 0.22, 1)\n"
            "emission_enabled = true\n"
            "emission = Color(0.88, 0.18, 0.15, 1)\n"
            "emission_energy_multiplier = 2.0\n"
            "roughness = 0.4"
        )

        self.nodes.append(f'[node name="{root_name}" type="Node3D"]')

    def _clean(self, name: str) -> str:
        return re.sub(r"[^A-Za-z0-9_]", "_", name)

    def add_box(self, name: str, size, pos, mat: str, rot=(0, 0, 0), parent="."):
        self._mesh_idx += 1
        mid = f"box_{self._mesh_idx}_{self._clean(name)}"
        self.resources.append(
            f'[sub_resource type="BoxMesh" id="{mid}"]\nsize = {vec(size)}'
        )
        self.nodes.append(
            f'[node name="{self._clean(name)}" type="MeshInstance3D" parent="{parent}"]\n'
            f"position = {vec(pos)}\n"
            f"rotation = {vec(rot)}\n"
            f'mesh = SubResource("{mid}")\n'
            f'material_override = SubResource("mat_{mat}")'
        )

    def add_prism(self, name: str, size, pos, mat: str, rot=(0, 0, 0), left_to_right=0.5, parent="."):
        self._mesh_idx += 1
        mid = f"prism_{self._mesh_idx}_{self._clean(name)}"
        self.resources.append(
            f'[sub_resource type="PrismMesh" id="{mid}"]\n'
            f"left_to_right = {left_to_right:.2f}\n"
            f"size = {vec(size)}"
        )
        self.nodes.append(
            f'[node name="{self._clean(name)}" type="MeshInstance3D" parent="{parent}"]\n'
            f"position = {vec(pos)}\n"
            f"rotation = {vec(rot)}\n"
            f'mesh = SubResource("{mid}")\n'
            f'material_override = SubResource("mat_{mat}")'
        )

    def add_cylinder(self, name: str, top_r: float, bot_r: float, height: float, pos, mat: str, segs=8, rot=(0, 0, 0), parent="."):
        self._mesh_idx += 1
        mid = f"cyl_{self._mesh_idx}_{self._clean(name)}"
        self.resources.append(
            f'[sub_resource type="CylinderMesh" id="{mid}"]\n'
            f"top_radius = {top_r:.4f}\n"
            f"bottom_radius = {bot_r:.4f}\n"
            f"height = {height:.4f}\n"
            f"radial_segments = {segs}\n"
            f"rings = 1"
        )
        self.nodes.append(
            f'[node name="{self._clean(name)}" type="MeshInstance3D" parent="{parent}"]\n'
            f"position = {vec(pos)}\n"
            f"rotation = {vec(rot)}\n"
            f'mesh = SubResource("{mid}")\n'
            f'material_override = SubResource("mat_{mat}")'
        )

    def add_body_cylinder(self, radius: float, height: float, pos=(0, 0, 0)):
        self._shape_idx += 1
        sid = f"col_cyl_{self._shape_idx}"
        self.resources.append(
            f'[sub_resource type="CylinderShape3D" id="{sid}"]\n'
            f"radius = {radius:.4f}\n"
            f"height = {height:.4f}"
        )
        self.nodes.append(
            '[node name="Body" type="StaticBody3D" parent="."]\n'
            "collision_layer = 1\n"
            "collision_mask = 0"
        )
        self.nodes.append(
            f'[node name="CollisionShape3D" type="CollisionShape3D" parent="Body"]\n'
            f"position = {vec((pos[0], pos[1] + height * 0.5, pos[2]))}\n"
            f'shape = SubResource("{sid}")'
        )

    def add_body_boxes(self, boxes):
        self.nodes.append(
            '[node name="Body" type="StaticBody3D" parent="."]\n'
            "collision_layer = 1\n"
            "collision_mask = 0"
        )
        for i, (size, pos) in enumerate(boxes):
            self._shape_idx += 1
            sid = f"col_box_{self._shape_idx}"
            self.resources.append(
                f'[sub_resource type="BoxShape3D" id="{sid}"]\nsize = {vec(size)}'
            )
            self.nodes.append(
                f'[node name="CollisionShape3D_{i}" type="CollisionShape3D" parent="Body"]\n'
                f"position = {vec(pos)}\n"
                f'shape = SubResource("{sid}")'
            )

    def save(self):
        text = "[gd_scene format=3]\n\n" + "\n\n".join(self.resources + self.nodes) + "\n"
        (OUT / f"{self.root_name}.tscn").write_text(text, encoding="utf-8")


def add_fluted_plinth_and_shaft(sb: SceneBuilder, shaft_height: float):
    # Stepped octagonal/square plinth base (like DP Spear Pillar columns)
    sb.add_cylinder("PlinthBottom", 0.62, 0.66, 0.20, (0, 0.10, 0), "stone_mid", segs=8)
    sb.add_cylinder("PlinthMid", 0.50, 0.54, 0.18, (0, 0.29, 0), "stone_light", segs=8)
    sb.add_cylinder("PlinthCollar", 0.43, 0.46, 0.10, (0, 0.43, 0), "stone_dark", segs=8)

    base_y = 0.48
    # Main column core
    sb.add_cylinder(
        "ShaftCore",
        0.36,
        0.38,
        shaft_height,
        (0, base_y + shaft_height * 0.5, 0),
        "stone_light",
        segs=8,
    )
    # 8 vertical fluting ribs around the shaft
    for i in range(8):
        angle = i * (math.pi / 4.0)
        rx = math.cos(angle) * 0.355
        rz = math.sin(angle) * 0.355
        sb.add_box(
            f"Flute_{i}",
            (0.08, shaft_height, 0.08),
            (rx, base_y + shaft_height * 0.5, rz),
            "stone_mid" if i % 2 == 0 else "stone_light",
            rot=(0, -angle, 0),
        )
    return base_y + shaft_height


def build_pillars():
    # 1. PilarRoto_Bajo (1st column in ref image: short with diagonal shear + notch)
    sb = SceneBuilder("PilarRoto_Bajo")
    top_y = add_fluted_plinth_and_shaft(sb, 1.15)
    sb.add_prism("BrokenCrown1", (0.72, 0.42, 0.68), (0.02, top_y + 0.18, 0), "stone_mid", rot=(0, 0.3, 0), left_to_right=0.15)
    sb.add_box("BrokenChip", (0.36, 0.22, 0.52), (-0.16, top_y + 0.08, 0.06), "stone_dark", rot=(0.15, 0.2, -0.25))
    sb.add_body_cylinder(0.55, top_y + 0.35)
    sb.save()

    # 2. PilarRoto_PuntaBaja (2nd column in ref image: medium-low with sharp spear point)
    sb = SceneBuilder("PilarRoto_PuntaBaja")
    top_y = add_fluted_plinth_and_shaft(sb, 1.55)
    sb.add_prism("SharpPeak", (0.70, 0.62, 0.66), (0, top_y + 0.28, 0), "stone_light", rot=(0, 0.4, 0), left_to_right=0.5)
    sb.add_prism("SideShard", (0.45, 0.35, 0.45), (0.14, top_y + 0.12, -0.08), "stone_mid", rot=(0.1, -0.5, 0.2), left_to_right=0.2)
    sb.add_body_cylinder(0.55, top_y + 0.5)
    sb.save()

    # 3. PilarRoto_Medio (3rd column in ref image: medium with stepped notch top)
    sb = SceneBuilder("PilarRoto_Medio")
    top_y = add_fluted_plinth_and_shaft(sb, 1.85)
    sb.add_box("CrownStepHigh", (0.38, 0.42, 0.64), (-0.14, top_y + 0.18, 0), "stone_light")
    sb.add_prism("CrownSlope", (0.44, 0.36, 0.60), (0.10, top_y + 0.14, 0), "stone_mid", left_to_right=0.1)
    sb.add_body_cylinder(0.55, top_y + 0.4)
    sb.save()

    # 4. PilarRoto_PuntaAlta (4th column in ref image: tall with sharp pointed spire)
    sb = SceneBuilder("PilarRoto_PuntaAlta")
    top_y = add_fluted_plinth_and_shaft(sb, 2.15)
    sb.add_prism("TallPeak", (0.72, 0.74, 0.68), (0, top_y + 0.34, 0), "stone_light", rot=(0, -0.3, 0), left_to_right=0.45)
    sb.add_box("MossAccent", (0.48, 0.16, 0.48), (0.08, 0.55, 0.12), "stone_moss", rot=(0, 0.4, 0))
    sb.add_body_cylinder(0.55, top_y + 0.6)
    sb.save()

    # 5. PilarRoto_Alto (5th/6th column in ref image: tallest fluted column with fractured double crown)
    sb = SceneBuilder("PilarRoto_Alto")
    top_y = add_fluted_plinth_and_shaft(sb, 2.55)
    sb.add_prism("CrownLeft", (0.48, 0.48, 0.66), (-0.14, top_y + 0.22, 0), "stone_light", left_to_right=0.2)
    sb.add_prism("CrownRight", (0.44, 0.34, 0.62), (0.15, top_y + 0.15, 0.04), "stone_mid", left_to_right=0.8)
    sb.add_body_cylinder(0.55, top_y + 0.45)
    sb.save()


def build_broken_archway():
    # Iconic broken stone archway from the right side of the reference image:
    # Two 3-course square masonry piers on a shared stone slab base, with overhanging cracked capitals.
    sb = SceneBuilder("ArcoRuina_Doble")
    pier_x = 1.65

    # Flat threshold slab on the ground (thin enough to walk right over: 0.06m)
    sb.add_box("BaseSlab", (4.8, 0.06, 1.55), (0, 0.03, 0), "stone_dark")

    for side, sx in [("Left", -pier_x), ("Right", pier_x)]:
        # Pier plinth
        sb.add_box(f"{side}_Plinth", (1.22, 0.24, 1.22), (sx, 0.15, 0), "stone_mid")
        # 3 stacked stone courses with dark mortar joints
        y_cursor = 0.27
        for course in range(3):
            if course > 0:
                sb.add_box(f"{side}_Mortar_{course}", (0.92, 0.07, 0.92), (sx, y_cursor + 0.035, 0), "stone_dark")
                y_cursor += 0.07
            block_h = 0.62
            sb.add_box(
                f"{side}_Block_{course}",
                (1.04, block_h, 1.04),
                (sx, y_cursor + block_h * 0.5, 0),
                "stone_light" if course != 1 else "stone_cap",
            )
            # Vertical seam detail on front/back of middle course
            if course == 1:
                sb.add_box(f"{side}_Seam_{course}", (0.06, block_h + 0.02, 1.06), (sx, y_cursor + block_h * 0.5, 0), "stone_dark")
            y_cursor += block_h

        # Neck / Corbel block
        sb.add_box(f"{side}_Neck", (1.20, 0.22, 1.18), (sx, y_cursor + 0.11, 0), "stone_mid")
        y_cursor += 0.22

        # Overhanging cracked capital / half-lintel jutting toward the center
        inward = 0.34 if sx < 0 else -0.34
        sb.add_box(
            f"{side}_CapitalMain",
            (1.62, 0.56, 1.32),
            (sx + inward, y_cursor + 0.28, 0),
            "stone_cap",
        )
        # Beveled/broken inner lintel tip facing the gap
        tip_x = sx + (1.22 if sx < 0 else -1.22)
        sb.add_prism(
            f"{side}_BrokenTip",
            (0.55, 0.52, 1.26),
            (tip_x, y_cursor + 0.26, 0),
            "stone_mid",
            rot=(0, 0, 0.35 if sx < 0 else -0.35),
            left_to_right=0.2 if sx < 0 else 0.8,
        )
        # Weathered top slab + moss
        sb.add_box(
            f"{side}_CapitalTop",
            (1.42, 0.18, 1.20),
            (sx + inward * 0.7, y_cursor + 0.64, 0),
            "stone_light",
        )
        sb.add_box(
            f"{side}_Moss",
            (0.65, 0.12, 0.85),
            (sx + inward * 0.5, y_cursor + 0.74, 0.1),
            "stone_moss",
        )

    # Collision ONLY on the left and right piers so the central 2.1m opening is completely walkable!
    sb.add_body_boxes([
        ((1.15, 3.2, 1.15), (-pier_x, 1.6, 0)),
        ((1.15, 3.2, 1.15), (pier_x, 1.6, 0)),
    ])
    sb.save()


def build_ruin_walls():
    # Low weathered stone wall segment (4.0m wide) to frame the grey ruin rectangles on the map
    sb = SceneBuilder("MuroRuina_Tramo")
    sb.add_box("BasePlinth", (4.1, 0.26, 0.82), (0, 0.13, 0), "stone_dark")
    sb.add_box("LowerCourse", (3.95, 0.55, 0.68), (0, 0.53, 0), "stone_mid")
    # Broken upper blocks of varying heights
    blocks = [
        ("TopBlock_0", (1.15, 0.48, 0.64), (-1.32, 1.04, 0), "stone_light"),
        ("TopBlock_1", (0.95, 0.30, 0.64), (-0.20, 0.95, 0), "stone_cap"),
        ("TopBlock_2", (1.25, 0.52, 0.64), (1.02, 1.06, 0), "stone_light"),
        ("MossPatch", (0.85, 0.10, 0.70), (-0.20, 1.12, 0), "stone_moss"),
    ]
    for bname, bsize, bpos, bmat in blocks:
        sb.add_box(bname, bsize, bpos, bmat)
    sb.add_prism("BrokenEndL", (0.55, 0.38, 0.62), (-1.65, 1.45, 0), "stone_mid", left_to_right=0.25)
    sb.add_prism("BrokenEndR", (0.60, 0.42, 0.62), (1.28, 1.50, 0), "stone_mid", left_to_right=0.75)
    sb.add_body_boxes([((4.0, 1.6, 0.78), (0, 0.8, 0))])
    sb.save()


def build_pedestal_and_monolith():
    # Grand Nordic Altar/Pedestal for the Great Weapon / Important Item
    sb = SceneBuilder("Pedestal_Reliquia")
    sb.add_box("Step1", (2.6, 0.20, 2.2), (0, 0.10, 0), "stone_dark")
    sb.add_box("Step2", (2.0, 0.22, 1.65), (0, 0.31, 0), "stone_mid")
    sb.add_box("AltarBase", (1.25, 0.76, 0.95), (0, 0.80, 0), "stone_light")
    sb.add_box("AltarCrown", (1.42, 0.18, 1.08), (0, 1.27, 0), "stone_cap")
    sb.add_box("RuneInlayFront", (0.82, 0.42, 0.04), (0, 0.82, 0.48), "rune_cyan")
    sb.add_box("RuneInlayTop", (0.95, 0.04, 0.55), (0, 1.37, 0), "rune_cyan")
    sb.add_body_boxes([((1.8, 1.4, 1.4), (0, 0.7, 0))])
    sb.save()

    # Jagged Dark Crimson Boss Monolith (matching the 2 dark-red jagged spikes on the Paint map)
    sb = SceneBuilder("Monolito_Jefe")
    sb.add_cylinder("RockBase", 1.05, 1.25, 0.45, (0, 0.22, 0), "stone_dark", segs=7)
    sb.add_box("LowerSpike", (1.10, 1.55, 0.95), (-0.10, 1.10, 0), "crimson_dark", rot=(0.06, 0.15, 0.18))
    sb.add_box("MidSpike", (0.92, 1.65, 0.82), (-0.36, 2.35, 0.04), "crimson_rock", rot=(0.08, -0.10, 0.24))
    sb.add_prism("TopJaggedPeak", (0.88, 1.45, 0.78), (-0.64, 3.60, 0.08), "crimson_rock", rot=(0.05, 0.12, 0.28), left_to_right=0.2)
    sb.add_box("RuneVein1", (0.14, 1.35, 0.98), (-0.12, 1.15, 0), "rune_crimson", rot=(0.06, 0.15, 0.18))
    sb.add_box("RuneVein2", (0.12, 1.30, 0.86), (-0.38, 2.40, 0.04), "rune_crimson", rot=(0.08, -0.10, 0.24))
    sb.add_body_cylinder(0.85, 3.6)
    sb.save()


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    build_pillars()
    build_broken_archway()
    build_ruin_walls()
    build_pedestal_and_monolith()
    print("Generated 9 modular ruin scenes in", OUT)
