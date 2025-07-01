# Global Resource Name Config
extends BaseGlobalResourcePathConfig

# override
static func _get_group_name() -> String:
	return "ResSpriteFrame"

# override
static func _scan_dir() -> String:
	return "res://src/sprite_frames/"

# override
static func _filter(file_name_list: Array) -> Array:
	return file_name_list.filter(
		func(file: String):
			if file.get_extension() == "tres":
				var res = load(_scan_dir().path_join(file))
				return res is SpriteFrames
			return false
	)
