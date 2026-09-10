"""Minimal .rbxlx (Roblox XML place) writer.

Emits anchored Parts into Workspace. Deliberately supports only what the city
generator needs — primitive Parts with position, size, color, material, and
transparency — because the headless publish path forbids CSG unions,
SurfaceAppearance, EditableMesh, and baked terrain anyway.

The output can be opened directly in Studio or merged into a Rojo build.
"""

from __future__ import annotations

import html
import itertools
from dataclasses import dataclass, field

_referent = itertools.count(1)


def _ref() -> str:
    return f"RBX{next(_referent):08d}"


@dataclass
class PointLight:
    """A light parented to a Part. Night cities are lit BY the city — this is
    how streetlights, neon glow, and the House of Sol's warm door read."""

    color: tuple[int, int, int] = (255, 235, 200)
    brightness: float = 2.0
    range: float = 40.0

    def to_xml(self) -> str:
        r, g, b = self.color
        return f"""   <Item class="PointLight" referent="{_ref()}">
    <Properties>
     <string name="Name">PointLight</string>
     <bool name="Enabled">true</bool>
     <bool name="Shadows">false</bool>
     <float name="Brightness">{self.brightness}</float>
     <float name="Range">{self.range}</float>
     <Color3 name="Color">
      <R>{r / 255:.4f}</R><G>{g / 255:.4f}</G><B>{b / 255:.4f}</B>
     </Color3>
    </Properties>
   </Item>"""


@dataclass
class Part:
    name: str
    position: tuple[float, float, float]
    size: tuple[float, float, float]
    color: tuple[int, int, int] = (163, 162, 165)
    material: str = "Concrete"
    transparency: float = 0.0
    anchored: bool = True
    lights: list[PointLight] = field(default_factory=list)

    def to_xml(self) -> str:
        px, py, pz = self.position
        sx, sy, sz = self.size
        r, g, b = self.color
        # Color3uint8 is packed as (r<<16)|(g<<8)|b; Roblox reads the low 24 bits.
        packed = (r << 16) | (g << 8) | b
        name = html.escape(self.name)
        return f"""  <Item class="Part" referent="{_ref()}">
   <Properties>
    <string name="Name">{name}</string>
    <bool name="Anchored">{str(self.anchored).lower()}</bool>
    <token name="Material">{_MATERIALS.get(self.material, 816)}</token>
    <Color3uint8 name="Color3uint8">{packed}</Color3uint8>
    <float name="Transparency">{self.transparency}</float>
    <Vector3 name="size">
     <X>{sx}</X><Y>{sy}</Y><Z>{sz}</Z>
    </Vector3>
    <CoordinateFrame name="CFrame">
     <X>{px}</X><Y>{py}</Y><Z>{pz}</Z>
     <R00>1</R00><R01>0</R01><R02>0</R02>
     <R10>0</R10><R11>1</R11><R12>0</R12>
     <R20>0</R20><R21>0</R21><R22>1</R22>
    </CoordinateFrame>
   </Properties>
{chr(10).join(l.to_xml() for l in self.lights)}
  </Item>"""


# Roblox Material enum tokens (the ones the generator uses).
_MATERIALS = {
    "Plastic": 256,
    "Concrete": 816,
    "Brick": 848,
    "Cobblestone": 880,
    "Sand": 1296,
    "Asphalt": 1376,
    "Glass": 1568,
    "Neon": 288,
    "Wood": 512,
    "Metal": 1088,
    "Fabric": 1312,
}


@dataclass
class Place:
    parts: list[Part] = field(default_factory=list)

    def add(self, part: Part) -> None:
        self.parts.append(part)

    def count(self) -> int:
        return len(self.parts)

    def to_xml(self) -> str:
        body = "\n".join(p.to_xml() for p in self.parts)
        return f"""<roblox version="4">
 <Item class="Folder" referent="{_ref()}">
  <Properties>
   <string name="Name">GeneratedCity</string>
  </Properties>
{body}
 </Item>
</roblox>
"""

    def write(self, path: str) -> None:
        with open(path, "w", encoding="utf-8") as f:
            f.write(self.to_xml())
