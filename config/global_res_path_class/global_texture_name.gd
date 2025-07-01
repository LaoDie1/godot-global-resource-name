# Global Resource Name Config
extends BaseGlobalResourcePathConfig


# override
static func _scan_dir() -> String:
	return "res://src/texture/"

# override
static func _filter(file_name_list: Array) -> Array:
	return file_name_list
