"""Build original editable Godot houses; no external mesh assets required."""
from pathlib import Path
import math
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models/nordic_houses'
TEXTURES = {
    'red': 'environment/materials/nordic_wood_v1/red_painted_siding.png',
    'oak': 'environment/materials/nordic_wood_v1/dark_oak_panels.png',
    'pine': 'environment/materials/nordic_wood_v1/light_pine_planks.png',
    'plaster': 'environment/materials/nordic_surfaces_v2/cream_plaster.png',
    'stone': 'environment/materials/nordic_surfaces_v2/ruin_masonry.png',
    'roof': 'environment/materials/nordic_v1/red_roof.png',
}

def vec(v):
    return 'Vector3(' + ', '.join(f'{x:.6f}' for x in v) + ')'

def build(name, width, depth, height, wall, porch=False):
    resources, nodes = [], []
    for key, path in TEXTURES.items():
        resources.append(f'[ext_resource type="Texture2D" path="res://assets/sprites/{path}" id="{key}"]')
    for key in TEXTURES:
        resources.append(f'[sub_resource type="StandardMaterial3D" id="{key}"]\nalbedo_texture = ExtResource("{key}")\ntexture_filter = 0\nroughness = 1.0')
    for key, color in [('trim', (0.83,0.79,0.66)), ('glass',(0.25,0.43,0.46)), ('brass',(0.65,0.46,0.2)), ('dark',(0.16,0.20,0.22))]:
        resources.append(f'[sub_resource type="StandardMaterial3D" id="{key}"]\nalbedo_color = Color({color[0]}, {color[1]}, {color[2]}, 1)\nroughness = 0.85')
    nodes.append(f'[node name="{name}" type="Node3D"]')
    def box(label, size, pos, material, rotation=(0,0,0), prism=False):
        label = re.sub(r'[^A-Za-z0-9_]', '_', label)
        mid = 'mesh_' + label
        resources.append(f'[sub_resource type="{"PrismMesh" if prism else "BoxMesh"}" id="{mid}"]\nsize = {vec(size)}')
        nodes.append(f'[node name="{label}" type="MeshInstance3D" parent="."]\nposition = {vec(pos)}\nrotation = {vec(rotation)}\nmesh = SubResource("{mid}")\nmaterial_override = SubResource("{material}")')
    box('Foundation',(width+.12,.35,depth+.12),(0,.175,0),'stone')
    box('Walls',(width,height,depth),(0,.35+height/2,0),wall)
    eave=.35+height
    rise=1.55 if not porch else 1.8
    box('Gable',(width,rise,depth),(0,eave+rise/2,0),wall,prism=True)
    slope=math.atan2(rise,width/2)
    half=width/2+.30
    length=half/math.cos(slope)
    for sign in [-1,1]:
        box('Roof'+str(sign),(length,.16,depth+.65),(sign*half/2,eave+rise-half/2*math.tan(slope),0),'roof',(0,0,-sign*slope))
        box('Eave'+str(sign),(.16,.22,depth+.7),(sign*half,eave-.12,0),'trim')
        for z in [-depth/2-.34,depth/2+.34]:
            box('Barge'+str(sign)+str(z),(length,.14,.14),(sign*half/2,eave+rise-half/2*math.tan(slope),z),'trim',(0,0,-sign*slope))
    box('Ridge',(.20,.18,depth+.72),(0,eave+rise+.08,0),'dark')
    for x in [-width/2,width/2]:
        for z in [-depth/2,depth/2]:
            box('Corner'+str(x)+str(z),(.18,height+.12,.18),(x,.35+height/2,z),'trim')
    front=depth/2
    box('DoorFrame',(1.28,2.18,.16),(0,1.42,front+.08),'trim')
    box('Door',(1.04,1.98,.12),(0,1.39,front+.18),'oak')
    box('DoorInset',(.72,.65,.04),(0,1.85,front+.26),'pine')
    box('Handle',(.09,.09,.08),(.36,1.29,front+.28),'brass')
    box('Threshold',(1.45,.18,.35),(0,.27,front+.16),'stone')
    def window(label,x,y,z,rot=0):
        # A local window assembly allows identical framing on side walls.
        parent='Window'+re.sub(r'[^A-Za-z0-9_]', '_', label)
        nodes.append(f'[node name="{parent}" type="Node3D" parent="."]\nposition = {vec((x,y,z))}\nrotation = {vec((0,rot,0))}')
        for part,size,pos,mat in [('Frame',(1.15,1.25,.12),(0,0,0),'trim'),('Glass',(.94,1.04,.06),(0,0,.09),'glass'),('Mullion',(.07,1.04,.06),(0,0,.14),'trim'),('Cross',(.94,.07,.06),(0,0,.14),'trim'),('Sill',(1.32,.13,.28),(0,-.66,.05),'oak')]:
            mid=parent+part
            resources.append(f'[sub_resource type="BoxMesh" id="{mid}"]\nsize = {vec(size)}')
            nodes.append(f'[node name="{part}" type="MeshInstance3D" parent="{parent}"]\nposition = {vec(pos)}\nmesh = SubResource("{mid}")\nmaterial_override = SubResource("{mat}")')
    for x in [-width*.30,width*.30]: window(str(x),x,1.95,front+.06)
    for sign in [-1,1]: window('Side'+str(sign),sign*(width/2+.06),1.95,0,sign*math.pi/2)
    window('Back',0,1.95,-front-.06,math.pi)
    box('AtticFrame',(.66,.74,.12),(0,eave+.50,front+.08),'trim')
    box('AtticGlass',(.46,.54,.06),(0,eave+.50,front+.16),'glass')
    if wall=='plaster':
        box('FacadeBeam',(width,.16,.14),(0,eave-.08,front+.10),'oak')
        for x in [-width*.16,width*.16]: box('Upright'+str(x),(.12,height,.14),(x,.35+height/2,front+.10),'oak')
    box('Chimney',(.55,1.6,.65),(-width*.25,eave+rise*.72,-depth*.25),'stone')
    box('ChimneyCap',(.73,.17,.83),(-width*.25,eave+rise*.72+.83,-depth*.25),'dark')
    if porch:
        box('PorchDeck',(width*.7,.28,1.35),(0,.14,front+.67),'pine')
        box('PorchCanopy',(width*.75,.13,1.6),(0,2.65,front+.65),'roof',(-.12,0,0))
        for x in [-width*.30,width*.30]: box('PorchPost'+str(x),(.14,2.3,.14),(x,1.4,front+1.15),'oak')
    resources.append(f'[sub_resource type="BoxShape3D" id="collision"]\nsize = {vec((width,height+.35,depth))}')
    nodes += ['[node name="Body" type="StaticBody3D" parent="."]\ncollision_layer = 1\ncollision_mask = 0', f'[node name="CollisionShape3D" type="CollisionShape3D" parent="Body"]\nposition = {vec((0,(height+.35)/2,0))}\nshape = SubResource("collision")',f'[node name="Entrance" type="Marker3D" parent="."]\nposition = {vec((0,0,front+(1.6 if porch else .85)))}']
    text='[gd_scene format=3]\n\n'+'\n\n'.join(resources+nodes)+'\n'
    (OUT/f'{name}.tscn').write_text(text,encoding='utf-8')

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    build('CasaRoja',5.6,4.2,2.8,'red')
    build('CasaEntramado',5.8,4.2,3.2,'plaster')
    build('CasaPorche',5.8,4.6,2.9,'oak',True)
    print('Generated three original house scenes')
