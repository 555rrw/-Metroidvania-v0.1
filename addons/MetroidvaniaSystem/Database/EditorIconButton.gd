# -- Identity ---------------------------------------------------------------
@tool
extends Button

# -- Exports ---------------------------------------------------------------
@export var icon_name: String

# -- Internal Helpers ---------------------------------------------------------------
func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and not is_part_of_edited_scene():
		icon = get_theme_icon(icon_name, &"EditorIcons")
