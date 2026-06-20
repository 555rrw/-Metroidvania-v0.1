extends RefCounted
class_name SourceArchive

const REPOS: Array[String] = [
	"Hollow-Knight-Imitation",
	"Metroidvania-System",
	"godot-platformer-2d",
	"CloneProject_HollowKnight",
	"GodotHollowKnightController",
]

static func scan() -> Dictionary:
	var summary: Dictionary = {}
	for repo in REPOS:
		var stats := {
			"files": 0,
			"bytes": 0,
			"extensions": {},
		}
		_scan_dir("res://cloned_repos/%s" % repo, stats)
		summary[repo] = stats
	return summary

static func totals(summary: Dictionary) -> Dictionary:
	var stats := {
		"repos": summary.size(),
		"files": 0,
		"bytes": 0,
	}
	for repo in summary:
		stats.files += int(summary[repo].files)
		stats.bytes += int(summary[repo].bytes)
	return stats

static func _scan_dir(path: String, stats: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var item := dir.get_next()
	while not item.is_empty():
		if item == ".git":
			item = dir.get_next()
			continue

		var full_path := path.path_join(item)
		if dir.current_is_dir():
			_scan_dir(full_path, stats)
		else:
			stats.files += 1
			var file := FileAccess.open(full_path, FileAccess.READ)
			if file:
				stats.bytes += file.get_length()
			var ext := item.get_extension().to_lower()
			if ext.is_empty():
				ext = "<none>"
			stats.extensions[ext] = int(stats.extensions.get(ext, 0)) + 1
		item = dir.get_next()
