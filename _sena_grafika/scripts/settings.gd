## Settings
##
## Tiny persistent settings stored in user://ziedine.cfg: whether the tutorial
## was already shown, sound on/off, last chosen difficulty and the best score.
class_name Settings
extends RefCounted

const PATH := "user://ziedine.cfg"

static var _cfg: ConfigFile

static func _ensure() -> void:
	if _cfg != null:
		return
	_cfg = ConfigFile.new()
	_cfg.load(PATH)   # missing file is fine – defaults are used

static func get_value(key: String, default: Variant) -> Variant:
	_ensure()
	return _cfg.get_value("game", key, default)

static func set_value(key: String, value: Variant) -> void:
	_ensure()
	_cfg.set_value("game", key, value)
	_cfg.save(PATH)
