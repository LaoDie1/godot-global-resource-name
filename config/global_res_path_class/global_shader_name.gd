# Global Resource Name Config
extends BaseGlobalResourcePathConfig

# override
static func _get_group_name() -> String:
	# 可省略。如果这个为空，则默认不添加 class 分类
	return "ResShader"

# override
static func _scan_dir() -> String:
	return "res://src/shader/"

# override
static func _filter(file_name_list: Array) -> Array:
	return file_name_list.filter(
		func(file: String):
			var res = load(_scan_dir().path_join(file))
			return res is Shader
	)
