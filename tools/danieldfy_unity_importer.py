#!/usr/bin/env python3
"""
Build a deterministic import report for DanielDFY/Hollow-Knight-Imitation.

The source project is Unity YAML. This tool does not try to execute Unity code.
It extracts scene objects, sprite/script GUID references, transforms, and collider
signals, then maps them to this Godot project's existing scenes/scripts.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


# -- Constants ---------------------------------------------------------------
UNITY_CLASS_NAMES = {
    "1": "GameObject",
    "4": "Transform",
    "50": "Rigidbody2D",
    "61": "BoxCollider2D",
    "70": "CapsuleCollider2D",
    "95": "Animator",
    "114": "MonoBehaviour",
    "212": "SpriteRenderer",
    "1001": "PrefabInstance",
}

SCRIPT_TO_GODOT = {
    "Deadly": "res://src/objects/Spikes.tscn",
    "DragPlayer": "res://src/objects/MovingPlatform.tscn",
    "EnemyController": "res://src/enemies/Enemy.gd",
    "FallingTrap": "res://src/objects/FallingTrap.tscn",
    "GlobalController": "res://src/world/Game.gd",
    "GunnerController": "res://src/enemies/Gunner.tscn",
    "HealthDisplay": "res://src/ui/HUD.gd",
    "HUD": "res://src/ui/HUD.gd",
    "HUDLoader": "res://src/ui/HUD.tscn",
    "Menu": "res://src/ui/MainMenu.tscn",
    "MovingTrap": "res://src/objects/MovingPlatform.tscn",
    "NextLevel": "res://src/objects/Portal.tscn",
    "Obstacle": "res://src/objects/TriggerDoor.tscn",
    "PatrolController": "res://src/enemies/Crawlid.tscn",
    "PlayerController": "res://src/player/Player.tscn",
    "Projectile": "res://src/enemies/GunnerProjectile.tscn",
    "Switch": "res://src/objects/SwitchTrigger.tscn",
    "Trap": "res://src/objects/FallingTrap.tscn",
    "UnstablePlatform": "res://src/objects/UnstablePlatform.tscn",
}

NAME_HINT_TO_GODOT = [
    ("unstable", "res://src/objects/UnstablePlatform.tscn"),
    ("moving", "res://src/objects/MovingPlatform.tscn"),
    ("spike", "res://src/objects/Spikes.tscn"),
    ("saw", "res://src/objects/SawTrap.tscn"),
    ("trigger", "res://src/objects/SwitchTrigger.tscn"),
    ("switch", "res://src/objects/SwitchTrigger.tscn"),
    ("door", "res://src/objects/TriggerDoor.tscn"),
    ("projectile", "res://src/enemies/GunnerProjectile.tscn"),
    ("enemy2", "res://src/enemies/Gunner.tscn"),
    ("enemy", "res://src/enemies/Crawlid.tscn"),
    ("platform", "StaticBody2D platform"),
    ("floor", "StaticBody2D platform"),
    ("ceiling", "StaticBody2D platform"),
    ("wall", "StaticBody2D wall"),
]

SCENE_UNITS_TO_PIXELS = 20.0
SCENE_BASELINE_Y = 650.0
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png"}


# -- Data Models ---------------------------------------------------------------
@dataclass
class Component:
    file_id: str
    class_id: str
    class_name: str
    game_object_id: str | None = None
    script_guid: str | None = None
    sprite_guid: str | None = None
    local_position: dict[str, float] | None = None
    local_scale: dict[str, float] | None = None
    father_id: str | None = None
    sorting_order: int = 0
    raw_text: str = ""


@dataclass
class SceneObject:
    file_id: str
    name: str = ""
    transform: Component | None = None
    sprites: list[Component] = field(default_factory=list)
    colliders: list[Component] = field(default_factory=list)
    scripts: list[str] = field(default_factory=list)
    script_paths: list[str] = field(default_factory=list)
    other_components: list[str] = field(default_factory=list)
    mapped_to: str = ""
    map_reason: str = ""
    world_position: dict[str, float] | None = None
    world_scale: dict[str, float] | None = None


# -- Resource Registry ---------------------------------------------------------------
class ResourceRegistry:
    def __init__(self) -> None:
        self._paths: dict[tuple[str, str], str] = {}
        self._items: list[tuple[str, str, str]] = []

    def add(self, resource_type: str, path: str) -> str:
        key = (resource_type, path)
        if key in self._paths:
            return self._paths[key]
        resource_id = "res_" + str(len(self._items) + 1)
        self._paths[key] = resource_id
        self._items.append((resource_type, path, resource_id))
        return resource_id

    def render(self) -> list[str]:
        return [
            '[ext_resource type="{}" path="{}" id="{}"]'.format(resource_type, path, resource_id)
            for resource_type, path, resource_id in self._items
        ]


# -- Unity YAML Parsing ---------------------------------------------------------------
def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="replace")


def parse_inline_vector(raw: str) -> dict[str, float] | None:
    match = re.search(r"\{x:\s*([-0-9.]+),\s*y:\s*([-0-9.]+),\s*z:\s*([-0-9.]+)\}", raw)
    if not match:
        return None
    return {"x": float(match.group(1)), "y": float(match.group(2)), "z": float(match.group(3))}


def parse_ref(raw: str, key: str) -> str | None:
    match = re.search(rf"{re.escape(key)}:\s*\{{fileID:\s*(-?\d+)", raw)
    return match.group(1) if match else None


def parse_guid_ref(raw: str, key: str) -> str | None:
    match = re.search(rf"{re.escape(key)}:\s*\{{fileID:\s*-?\d+,\s*guid:\s*([0-9a-f]+)", raw)
    return match.group(1) if match else None


def parse_int_value(raw: str, key: str, default: int = 0) -> int:
    match = re.search(rf"^\s*{re.escape(key)}:\s*(-?\d+)\s*$", raw, re.MULTILINE)
    return int(match.group(1)) if match else default


def parse_unity_yaml(path: Path) -> tuple[dict[str, SceneObject], list[Component]]:
    text = read_text(path)
    marker = re.compile(r"^--- !u!(\d+) &(-?\d+)\s*$", re.MULTILINE)
    matches = list(marker.finditer(text))
    objects: dict[str, SceneObject] = {}
    components: list[Component] = []

    for idx, match in enumerate(matches):
        class_id, file_id = match.group(1), match.group(2)
        start = match.end()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        body = text[start:end]
        class_name = UNITY_CLASS_NAMES.get(class_id, "UnityClass" + class_id)

        if class_id == "1":
            name_match = re.search(r"^\s*m_Name:\s*(.*)$", body, re.MULTILINE)
            name = name_match.group(1).strip() if name_match else ""
            objects[file_id] = SceneObject(file_id=file_id, name=name)
            continue

        component = Component(
            file_id=file_id,
            class_id=class_id,
            class_name=class_name,
            game_object_id=parse_ref(body, "m_GameObject"),
            script_guid=parse_guid_ref(body, "m_Script"),
            sprite_guid=parse_guid_ref(body, "m_Sprite"),
            local_position=parse_inline_vector(re.search(r"m_LocalPosition:.*", body).group(0))
            if re.search(r"m_LocalPosition:.*", body)
            else None,
            local_scale=parse_inline_vector(re.search(r"m_LocalScale:.*", body).group(0))
            if re.search(r"m_LocalScale:.*", body)
            else None,
            father_id=parse_ref(body, "m_Father"),
            sorting_order=parse_int_value(body, "m_SortingOrder", 0),
            raw_text=body,
        )
        components.append(component)

    for component in components:
        go_id = component.game_object_id
        if not go_id or go_id not in objects:
            continue

        scene_object = objects[go_id]
        if component.class_name == "Transform":
            scene_object.transform = component
        elif component.class_name == "SpriteRenderer":
            scene_object.sprites.append(component)
        elif component.class_name.endswith("Collider2D"):
            scene_object.colliders.append(component)
        elif component.class_name == "MonoBehaviour":
            scene_object.other_components.append(component.class_name)
        else:
            scene_object.other_components.append(component.class_name)

    return objects, components


# -- Transform Mapping ---------------------------------------------------------------
def apply_world_transforms(objects: dict[str, SceneObject], components: list[Component]) -> None:
    transforms = {component.file_id: component for component in components if component.class_name == "Transform"}
    memo: dict[str, tuple[dict[str, float], dict[str, float]]] = {}

    def local_pos(transform: Component) -> dict[str, float]:
        return transform.local_position or {"x": 0.0, "y": 0.0, "z": 0.0}

    def local_scale(transform: Component) -> dict[str, float]:
        return transform.local_scale or {"x": 1.0, "y": 1.0, "z": 1.0}

    def resolve(transform: Component) -> tuple[dict[str, float], dict[str, float]]:
        if transform.file_id in memo:
            return memo[transform.file_id]

        pos = dict(local_pos(transform))
        scale = dict(local_scale(transform))
        if transform.father_id and transform.father_id in transforms:
            parent_pos, parent_scale = resolve(transforms[transform.father_id])
            pos = {
                "x": parent_pos["x"] + pos["x"] * parent_scale["x"],
                "y": parent_pos["y"] + pos["y"] * parent_scale["y"],
                "z": parent_pos["z"] + pos["z"] * parent_scale["z"],
            }
            scale = {
                "x": parent_scale["x"] * scale["x"],
                "y": parent_scale["y"] * scale["y"],
                "z": parent_scale["z"] * scale["z"],
            }

        memo[transform.file_id] = (pos, scale)
        return pos, scale

    for scene_object in objects.values():
        if not scene_object.transform:
            continue
        scene_object.world_position, scene_object.world_scale = resolve(scene_object.transform)


# -- Asset And Object Mapping ---------------------------------------------------------------
def build_guid_index(root: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for meta_path in root.rglob("*.meta"):
        text = read_text(meta_path)
        match = re.search(r"^guid:\s*([0-9a-f]+)\s*$", text, re.MULTILINE)
        if not match:
            continue
        asset_path = str(meta_path.with_suffix("")).replace("\\", "/")
        result[match.group(1)] = asset_path
    return result


def attach_script_names(objects: dict[str, SceneObject], components: list[Component], guid_index: dict[str, str]) -> None:
    for component in components:
        if component.class_name != "MonoBehaviour" or not component.game_object_id:
            continue
        scene_object = objects.get(component.game_object_id)
        if not scene_object:
            continue
        script_path = guid_index.get(component.script_guid or "", "")
        script_name = Path(script_path).stem if script_path else "unknown_script_" + str(component.script_guid)
        scene_object.scripts.append(script_name)
        if script_path:
            scene_object.script_paths.append(script_path)


def classify_object(scene_object: SceneObject) -> None:
    for script in scene_object.scripts:
        if script in SCRIPT_TO_GODOT:
            scene_object.mapped_to = SCRIPT_TO_GODOT[script]
            scene_object.map_reason = "script:" + script
            return

    name_lower = scene_object.name.lower()
    for needle, target in NAME_HINT_TO_GODOT:
        if needle in name_lower:
            scene_object.mapped_to = target
            scene_object.map_reason = "name:" + needle
            return

    if scene_object.colliders and scene_object.sprites:
        scene_object.mapped_to = "StaticBody2D/Sprite2D"
        scene_object.map_reason = "sprite+collider"
    elif scene_object.sprites:
        scene_object.mapped_to = "Sprite2D decoration"
        scene_object.map_reason = "sprite"
    elif scene_object.colliders:
        scene_object.mapped_to = "StaticBody2D collider"
        scene_object.map_reason = "collider"


def unity_to_godot_position(pos: dict[str, float] | None) -> tuple[float, float]:
    if not pos:
        return (0.0, SCENE_BASELINE_Y)
    return (pos.get("x", 0.0) * SCENE_UNITS_TO_PIXELS, SCENE_BASELINE_Y - pos.get("y", 0.0) * SCENE_UNITS_TO_PIXELS)


def unity_to_godot_scale(scale: dict[str, float] | None) -> tuple[float, float]:
    if not scale:
        return (1.0, 1.0)
    return (scale.get("x", 1.0), scale.get("y", 1.0))


def sanitize_node_name(raw: str, fallback: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_]+", "_", raw.strip())
    cleaned = cleaned.strip("_")
    if not cleaned:
        cleaned = fallback
    if cleaned[0].isdigit():
        cleaned = "N_" + cleaned
    return cleaned[:60]


def godot_texture_path_for_unity_asset(asset_path: str, workspace_root: Path) -> str | None:
    normalized = asset_path.replace("\\", "/")
    marker = "/Assets/Resources/Images/"
    if marker not in normalized:
        return None

    relative = normalized.split(marker, 1)[1]
    mirror_candidate = workspace_root / "assets" / "sprites" / "danieldfy" / "Images" / relative
    if mirror_candidate.exists():
        return "res://" + mirror_candidate.relative_to(workspace_root).as_posix()

    relative = relative.replace("platfrom/", "platform/")
    relative = relative.replace("switch & obstacle/trigger & door.png", "switch/trigger_door.png")
    relative = relative.replace("attack effects/attack effects.png", "attack_effects.png")
    candidate = workspace_root / "assets" / "sprites" / "hollow_imitation" / relative
    if candidate.exists():
        return "res://" + candidate.relative_to(workspace_root).as_posix()

    attack_candidate = workspace_root / "assets" / "sprites" / relative
    if attack_candidate.exists():
        return "res://" + attack_candidate.relative_to(workspace_root).as_posix()

    return None


def object_texture_path(scene_object: SceneObject, guid_index: dict[str, str], workspace_root: Path) -> str | None:
    for sprite in scene_object.sprites:
        if not sprite.sprite_guid:
            continue
        asset_path = guid_index.get(sprite.sprite_guid)
        if not asset_path:
            continue
        texture_path = godot_texture_path_for_unity_asset(asset_path, workspace_root)
        if texture_path:
            return texture_path
    return None


def shape_size_for(scene_object: SceneObject) -> tuple[float, float]:
    name = scene_object.name.lower()
    if "wall" in name:
        return (48.0, 360.0)
    if "ceiling" in name:
        return (180.0, 36.0)
    if "floor" in name or "platform" in name:
        return (180.0, 32.0)
    if "door" in name:
        return (64.0, 170.0)
    if "spike" in name:
        return (180.0, 42.0)
    return (96.0, 96.0)


def scene_target_is_instance(target: str) -> bool:
    return target.startswith("res://") and target.endswith(".tscn")


# -- Godot Scene Generation ---------------------------------------------------------------
def render_generated_object(
    scene_object: SceneObject,
    index: int,
    resources: ResourceRegistry,
    guid_index: dict[str, str],
    workspace_root: Path,
    subresources: list[tuple[str, tuple[float, float]]],
) -> list[str]:
    node_name = sanitize_node_name(scene_object.name, "ImportedObject_" + str(index))
    x, y = unity_to_godot_position(scene_object.world_position)
    scale_x, scale_y = unity_to_godot_scale(scene_object.world_scale)
    target = scene_object.mapped_to
    lines: list[str] = []

    if scene_target_is_instance(target):
        resource_id = resources.add("PackedScene", target)
        lines.append('[node name="{}" parent="ImportedObjects" instance=ExtResource("{}")]'.format(node_name, resource_id))
        lines.append("position = Vector2({:.3f}, {:.3f})".format(x, y))
        if target.endswith("AbilityGate.tscn"):
            lines.append('required_ability = &"imported_gate_placeholder"')
        return lines

    texture_path = object_texture_path(scene_object, guid_index, workspace_root)
    if target == "Sprite2D decoration" and texture_path:
        texture_id = resources.add("Texture2D", texture_path)
        lines.append('[node name="{}" type="Sprite2D" parent="ImportedObjects"]'.format(node_name))
        lines.append("position = Vector2({:.3f}, {:.3f})".format(x, y))
        lines.append("scale = Vector2({:.3f}, {:.3f})".format(scale_x, scale_y))
        lines.append("z_index = {}".format(scene_object.sprites[0].sorting_order if scene_object.sprites else 0))
        lines.append("texture_filter = 0")
        lines.append('texture = ExtResource("{}")'.format(texture_id))
        lines.append("metadata/source_map_reason = " + json.dumps(scene_object.map_reason))
        return lines

    if target in {"StaticBody2D platform", "StaticBody2D wall", "StaticBody2D/Sprite2D", "StaticBody2D collider"}:
        size = shape_size_for(scene_object)
        shape_id = "ImportedShape_" + str(len(subresources) + 1)
        subresources.append((shape_id, size))
        lines.append('[node name="{}" type="StaticBody2D" parent="ImportedObjects"]'.format(node_name))
        lines.append("position = Vector2({:.3f}, {:.3f})".format(x, y))
        lines.append("collision_layer = 5")
        lines.append("collision_mask = 0")
        if texture_path:
            texture_id = resources.add("Texture2D", texture_path)
            lines.append("")
            lines.append('[node name="Sprite2D" type="Sprite2D" parent="ImportedObjects/{}"]'.format(node_name))
            lines.append("texture_filter = 0")
            lines.append("scale = Vector2({:.3f}, {:.3f})".format(scale_x, scale_y))
            lines.append("z_index = {}".format(scene_object.sprites[0].sorting_order if scene_object.sprites else 0))
            lines.append('texture = ExtResource("{}")'.format(texture_id))
        else:
            width, height = size
            lines.append("")
            lines.append('[node name="ColorRect" type="ColorRect" parent="ImportedObjects/{}"]'.format(node_name))
            lines.append("offset_left = {:.3f}".format(-width / 2.0))
            lines.append("offset_top = {:.3f}".format(-height / 2.0))
            lines.append("offset_right = {:.3f}".format(width / 2.0))
            lines.append("offset_bottom = {:.3f}".format(height / 2.0))
            lines.append("color = Color(0.18, 0.22, 0.24, 0.35)")
        lines.append("")
        lines.append('[node name="CollisionShape2D" type="CollisionShape2D" parent="ImportedObjects/{}"]'.format(node_name))
        lines.append('shape = SubResource("{}")'.format(shape_id))
        return lines

    lines.append('[node name="{}" type="Node2D" parent="ImportedObjects"]'.format(node_name))
    lines.append("position = Vector2({:.3f}, {:.3f})".format(x, y))
    lines.append("metadata/source_map_reason = " + json.dumps(scene_object.map_reason))
    return lines


def generate_godot_scene(
    scene_path: Path,
    output_path: Path,
    source_root: Path,
    guid_index: dict[str, str],
    workspace_root: Path,
) -> dict[str, Any]:
    objects, components = parse_unity_yaml(scene_path)
    apply_world_transforms(objects, components)
    attach_script_names(objects, components, guid_index)
    mapped_objects: list[SceneObject] = []
    for scene_object in objects.values():
        classify_object(scene_object)
        if scene_object.mapped_to:
            mapped_objects.append(scene_object)

    resources = ResourceRegistry()
    room_instance_id = resources.add("Script", "res://addons/MetroidvaniaSystem/Scripts/RoomInstance.gd")
    subresources: list[tuple[str, tuple[float, float]]] = []
    body_lines: list[str] = []

    scene_name = sanitize_node_name(scene_path.stem, "ImportedScene")
    body_lines.append('[node name="{}" type="Node2D"]'.format("DanielDFY_" + scene_name))
    body_lines.append("metadata/source_scene = " + json.dumps(str(scene_path.relative_to(source_root)).replace("\\", "/")))
    body_lines.append("")
    body_lines.append('[node name="RoomInstance" type="Node2D" parent="."]')
    body_lines.append('script = ExtResource("{}")'.format(room_instance_id))
    body_lines.append("")
    body_lines.append('[node name="Background" type="ColorRect" parent="."]')
    body_lines.append("z_index = -20")
    body_lines.append("offset_right = 2800.0")
    body_lines.append("offset_bottom = 720.0")
    body_lines.append("color = Color(0.035, 0.05, 0.06, 1)")
    body_lines.append("")
    body_lines.append('[node name="ImportedObjects" type="Node2D" parent="."]')

    for index, scene_object in enumerate(sorted(mapped_objects, key=lambda item: item.name.lower()), start=1):
        body_lines.append("")
        body_lines.extend(render_generated_object(scene_object, index, resources, guid_index, workspace_root, subresources))

    header = ["[gd_scene load_steps={} format=3]".format(1 + len(resources._items) + len(subresources)), ""]
    header.extend(resources.render())
    if subresources:
        header.append("")
        for shape_id, size in subresources:
            header.append('[sub_resource type="RectangleShape2D" id="{}"]'.format(shape_id))
            header.append("size = Vector2({:.3f}, {:.3f})".format(size[0], size[1]))
            header.append("")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(header + [""] + body_lines).rstrip() + "\n", encoding="utf-8")
    return {
        "source_scene": str(scene_path.relative_to(source_root)).replace("\\", "/"),
        "output_scene": str(output_path).replace("\\", "/"),
        "generated_object_count": len(mapped_objects),
    }


def generate_visual_layer(
    scene_path: Path,
    output_path: Path,
    source_root: Path,
    guid_index: dict[str, str],
    workspace_root: Path,
) -> dict[str, Any]:
    objects, components = parse_unity_yaml(scene_path)
    apply_world_transforms(objects, components)
    sprite_objects = []
    for scene_object in objects.values():
        if not scene_object.sprites:
            continue
        texture_path = object_texture_path(scene_object, guid_index, workspace_root)
        if texture_path:
            sprite_objects.append((scene_object, texture_path))

    resources = ResourceRegistry()
    body_lines = [
        '[node name="DanielDFY_{}_VisualLayer" type="Node2D"]'.format(sanitize_node_name(scene_path.stem, "Scene")),
        "metadata/source_scene = " + json.dumps(str(scene_path.relative_to(source_root)).replace("\\", "/")),
        "metadata/visual_only = true",
    ]

    for index, (scene_object, texture_path) in enumerate(
        sorted(sprite_objects, key=lambda item: item[0].name.lower()), start=1
    ):
        node_name = sanitize_node_name(scene_object.name, "Sprite_" + str(index))
        x, y = unity_to_godot_position(scene_object.world_position)
        scale_x, scale_y = unity_to_godot_scale(scene_object.world_scale)
        texture_id = resources.add("Texture2D", texture_path)
        z_index = scene_object.sprites[0].sorting_order if scene_object.sprites else 0
        body_lines.extend(
            [
                "",
                '[node name="{}" type="Sprite2D" parent="."]'.format(node_name),
                "position = Vector2({:.3f}, {:.3f})".format(x, y),
                "scale = Vector2({:.3f}, {:.3f})".format(scale_x, scale_y),
                "z_index = {}".format(z_index),
                "texture_filter = 0",
                'texture = ExtResource("{}")'.format(texture_id),
                "metadata/source_name = " + json.dumps(scene_object.name),
            ]
        )

    header = ["[gd_scene load_steps={} format=3]".format(1 + len(resources._items)), ""]
    header.extend(resources.render())
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(header + [""] + body_lines).rstrip() + "\n", encoding="utf-8")
    return {
        "source_scene": str(scene_path.relative_to(source_root)).replace("\\", "/"),
        "output_scene": str(output_path).replace("\\", "/"),
        "generated_sprite_count": len(sprite_objects),
    }


def is_gameplay_object(scene_object: SceneObject) -> bool:
    target = scene_object.mapped_to or ""
    if not target or target == "Sprite2D decoration" or target == "res://src/world/Game.gd":
        return False
    return bool(scene_object.colliders or scene_target_is_instance(target) or target.startswith("StaticBody2D"))


def generate_gameplay_layer(
    scene_path: Path,
    output_path: Path,
    source_root: Path,
    guid_index: dict[str, str],
    workspace_root: Path,
) -> dict[str, Any]:
    objects, components = parse_unity_yaml(scene_path)
    apply_world_transforms(objects, components)
    attach_script_names(objects, components, guid_index)
    gameplay_objects: list[SceneObject] = []
    for scene_object in objects.values():
        classify_object(scene_object)
        if is_gameplay_object(scene_object):
            gameplay_objects.append(scene_object)

    resources = ResourceRegistry()
    subresources: list[tuple[str, tuple[float, float]]] = []
    body_lines = [
        '[node name="DanielDFY_{}_GameplayLayer" type="Node2D"]'.format(sanitize_node_name(scene_path.stem, "Scene")),
        "metadata/source_scene = " + json.dumps(str(scene_path.relative_to(source_root)).replace("\\", "/")),
        "metadata/gameplay_only = true",
        "",
        '[node name="ImportedObjects" type="Node2D" parent="."]',
    ]

    for index, scene_object in enumerate(sorted(gameplay_objects, key=lambda item: item.name.lower()), start=1):
        body_lines.append("")
        body_lines.extend(render_generated_object(scene_object, index, resources, guid_index, workspace_root, subresources))

    header = ["[gd_scene load_steps={} format=3]".format(1 + len(resources._items) + len(subresources)), ""]
    header.extend(resources.render())
    if subresources:
        header.append("")
        for shape_id, size in subresources:
            header.append('[sub_resource type="RectangleShape2D" id="{}"]'.format(shape_id))
            header.append("size = Vector2({:.3f}, {:.3f})".format(size[0], size[1]))
            header.append("")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(header + [""] + body_lines).rstrip() + "\n", encoding="utf-8")
    return {
        "source_scene": str(scene_path.relative_to(source_root)).replace("\\", "/"),
        "output_scene": str(output_path).replace("\\", "/"),
        "generated_gameplay_count": len(gameplay_objects),
    }


# -- Reporting ---------------------------------------------------------------
def scene_report(scene_path: Path, source_root: Path, guid_index: dict[str, str]) -> dict[str, Any]:
    objects, components = parse_unity_yaml(scene_path)
    apply_world_transforms(objects, components)
    attach_script_names(objects, components, guid_index)
    for scene_object in objects.values():
        classify_object(scene_object)

    mapped = [obj for obj in objects.values() if obj.mapped_to]
    scripted = [obj for obj in objects.values() if obj.scripts]
    unmapped_scripted = [obj for obj in scripted if not obj.mapped_to]
    sprite_count = sum(1 for obj in objects.values() if obj.sprites)
    collider_count = sum(1 for obj in objects.values() if obj.colliders)

    by_target: dict[str, int] = {}
    for obj in mapped:
        by_target[obj.mapped_to] = by_target.get(obj.mapped_to, 0) + 1

    samples: list[dict[str, Any]] = []
    for obj in sorted(mapped, key=lambda item: item.name.lower())[:40]:
        pos = obj.world_position
        samples.append(
            {
                "name": obj.name,
                "position": pos,
                "scripts": obj.scripts,
                "mapped_to": obj.mapped_to,
                "reason": obj.map_reason,
            }
        )

    unknowns: list[dict[str, Any]] = []
    for obj in sorted(unmapped_scripted, key=lambda item: item.name.lower())[:30]:
        unknowns.append({"name": obj.name, "scripts": obj.scripts, "script_paths": obj.script_paths})

    return {
        "scene": str(scene_path.relative_to(source_root)).replace("\\", "/"),
        "object_count": len(objects),
        "component_count": len(components),
        "scripted_object_count": len(scripted),
        "sprite_object_count": sprite_count,
        "collider_object_count": collider_count,
        "mapped_object_count": len(mapped),
        "mapped_ratio": round(len(mapped) / len(objects), 3) if objects else 0.0,
        "mapped_by_target": dict(sorted(by_target.items())),
        "mapped_samples": samples,
        "unmapped_scripted": unknowns,
    }


def collect_asset_mirror_stats(source_root: Path, workspace_root: Path) -> dict[str, Any]:
    source_image_root = source_root / "Assets" / "Resources" / "Images"
    mirror_image_root = workspace_root / "assets" / "sprites" / "danieldfy" / "Images"
    mirror_display_path = (Path("assets") / "sprites" / "danieldfy" / "Images").as_posix()

    source_files = (
        sorted(path for path in source_image_root.rglob("*") if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS)
        if source_image_root.exists()
        else []
    )
    mirror_files = (
        sorted(path for path in mirror_image_root.rglob("*") if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS)
        if mirror_image_root.exists()
        else []
    )
    godot_import_files = sorted(mirror_image_root.rglob("*.import")) if mirror_image_root.exists() else []

    mirrored_relatives = {
        path.relative_to(mirror_image_root).as_posix().lower()
        for path in mirror_files
    }
    missing = [
        path.relative_to(source_image_root).as_posix()
        for path in source_files
        if path.relative_to(source_image_root).as_posix().lower() not in mirrored_relatives
    ]

    return {
        "source_image_root": str(source_image_root).replace("\\", "/"),
        "mirror_image_root": mirror_display_path,
        "source_image_count": len(source_files),
        "mirror_image_count": len(mirror_files),
        "godot_import_count": len(godot_import_files),
        "missing_count": len(missing),
        "missing": missing[:40],
    }


def render_markdown(
    source_root: Path,
    reports: list[dict[str, Any]],
    generated_scenes: list[dict[str, Any]] | None = None,
    visual_layers: list[dict[str, Any]] | None = None,
    gameplay_layers: list[dict[str, Any]] | None = None,
    asset_mirror: dict[str, Any] | None = None,
) -> str:
    lines = [
        "# DanielDFY Unity Import Report",
        "",
        "Source: `" + str(source_root).replace("\\", "/") + "`",
        "",
        "This report is generated from Unity YAML scenes/prefabs. It maps DanielDFY objects to existing Godot scenes/scripts so future copying is repeatable instead of hand-authored.",
        "",
    ]
    if asset_mirror:
        lines += [
            "## Source Asset Mirror",
            "",
            "- Source images: `{}` ({} image files)".format(
                asset_mirror["source_image_root"],
                asset_mirror["source_image_count"],
            ),
            "- Godot mirror: `{}` ({} image files, {} `.import` files)".format(
                asset_mirror["mirror_image_root"],
                asset_mirror["mirror_image_count"],
                asset_mirror["godot_import_count"],
            ),
            "- Missing mirrored source images: {}".format(asset_mirror["missing_count"]),
        ]
        if asset_mirror["missing"]:
            for missing in asset_mirror["missing"][:12]:
                lines.append("- missing `" + missing + "`")
        lines.append("")

    lines += [
        "## Summary",
        "",
        "| Scene | Objects | Scripts | Sprites | Colliders | Mapped | Ratio |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for report in reports:
        lines.append(
            "| {scene} | {object_count} | {scripted_object_count} | {sprite_object_count} | {collider_object_count} | {mapped_object_count} | {mapped_ratio:.0%} |".format(
                **report
            )
        )

    if generated_scenes:
        lines += ["", "## Generated Godot Blueprints", ""]
        for generated in generated_scenes:
            lines.append(
                "- `{source_scene}` -> `{output_scene}` ({generated_object_count} mapped objects)".format(**generated)
            )

    if visual_layers:
        lines += ["", "## Generated Visual Layers", ""]
        for generated in visual_layers:
            lines.append(
                "- `{source_scene}` -> `{output_scene}` ({generated_sprite_count} sprite nodes)".format(**generated)
            )

    if gameplay_layers:
        lines += ["", "## Generated Gameplay Layers", ""]
        for generated in gameplay_layers:
            lines.append(
                "- `{source_scene}` -> `{output_scene}` ({generated_gameplay_count} gameplay objects)".format(**generated)
            )

    lines += ["", "## Godot Target Counts", ""]
    for report in reports:
        lines += ["### " + report["scene"], ""]
        if report["mapped_by_target"]:
            for target, count in report["mapped_by_target"].items():
                lines.append("- `" + target + "`: " + str(count))
        else:
            lines.append("- none")

        lines += ["", "Mapped sample:", ""]
        for sample in report["mapped_samples"][:16]:
            pos = sample["position"] or {}
            pos_text = "x={:.2f}, y={:.2f}".format(pos.get("x", 0.0), pos.get("y", 0.0)) if pos else "n/a"
            script_text = ", ".join(sample["scripts"]) if sample["scripts"] else "-"
            lines.append(
                "- `{}` -> `{}` ({}, scripts: {})".format(
                    sample["name"],
                    sample["mapped_to"],
                    pos_text,
                    script_text,
                )
            )

        if report["unmapped_scripted"]:
            lines += ["", "Unmapped scripted objects:", ""]
            for unknown in report["unmapped_scripted"][:12]:
                lines.append("- `{}` scripts={}".format(unknown["name"], ", ".join(unknown["scripts"])))
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


# -- CLI ---------------------------------------------------------------
def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        type=Path,
        default=Path("cloned_repos/Hollow-Knight-Imitation/Hollow Knight"),
        help="Unity project root containing Assets/",
    )
    parser.add_argument("--report", type=Path, default=Path("docs/danieldfy_unity_import_report.md"))
    parser.add_argument("--json", type=Path, default=Path(".scratch/danieldfy_unity_import_report.json"))
    parser.add_argument(
        "--godot-output-dir",
        type=Path,
        default=Path(""),
        help="Optional output directory for generated Godot blueprint .tscn files.",
    )
    parser.add_argument(
        "--visual-output-dir",
        type=Path,
        default=Path(""),
        help="Optional output directory for generated visual-only Godot .tscn layers.",
    )
    parser.add_argument(
        "--gameplay-output-dir",
        type=Path,
        default=Path(""),
        help="Optional output directory for generated gameplay-only Godot .tscn layers.",
    )
    args = parser.parse_args()

    workspace_root = Path.cwd()
    source_root = args.source
    assets_root = source_root / "Assets"
    scenes_root = assets_root / "Scenes"
    if not scenes_root.exists():
        raise SystemExit("Unity scenes not found: " + str(scenes_root))

    guid_index = build_guid_index(assets_root)
    scene_paths = sorted(scenes_root.glob("*.unity"))
    reports = [scene_report(path, source_root, guid_index) for path in scene_paths]

    generated_scenes: list[dict[str, Any]] = []
    if str(args.godot_output_dir):
        for scene_path in scene_paths:
            output_name = "DanielDFY_" + sanitize_node_name(scene_path.stem, "Scene") + "_Imported.tscn"
            output_path = args.godot_output_dir / output_name
            generated_scenes.append(generate_godot_scene(scene_path, output_path, source_root, guid_index, workspace_root))

    visual_layers: list[dict[str, Any]] = []
    if str(args.visual_output_dir):
        for scene_path in scene_paths:
            output_name = "DanielDFY_" + sanitize_node_name(scene_path.stem, "Scene") + "_VisualLayer.tscn"
            output_path = args.visual_output_dir / output_name
            visual_layers.append(generate_visual_layer(scene_path, output_path, source_root, guid_index, workspace_root))

    gameplay_layers: list[dict[str, Any]] = []
    if str(args.gameplay_output_dir):
        for scene_path in scene_paths:
            output_name = "DanielDFY_" + sanitize_node_name(scene_path.stem, "Scene") + "_GameplayLayer.tscn"
            output_path = args.gameplay_output_dir / output_name
            gameplay_layers.append(generate_gameplay_layer(scene_path, output_path, source_root, guid_index, workspace_root))

    asset_mirror = collect_asset_mirror_stats(source_root, workspace_root)

    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(
        render_markdown(source_root, reports, generated_scenes, visual_layers, gameplay_layers, asset_mirror),
        encoding="utf-8",
    )

    args.json.parent.mkdir(parents=True, exist_ok=True)
    args.json.write_text(
        json.dumps(
            {
                "source": str(source_root),
                "asset_mirror": asset_mirror,
                "scenes": reports,
                "generated_scenes": generated_scenes,
                "visual_layers": visual_layers,
                "gameplay_layers": gameplay_layers,
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    print(
        "IMPORT_REPORT_OK report={} json={} scenes={} generated={}".format(
            args.report, args.json, len(reports), len(generated_scenes)
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
