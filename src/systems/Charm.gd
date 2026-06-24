# -- Identity ---------------------------------------------------------------
## 護符資源定義
extends Resource
class_name Charm

# -- Exports ---------------------------------------------------------------
@export var id: StringName
@export var display_name: String
@export var notch_cost: int
@export var description: String
@export var icon: Texture2D
