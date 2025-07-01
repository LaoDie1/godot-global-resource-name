#============================================================
#    Global Res Name
#============================================================
# - author: zhangxuetu
# - datetime: 2025-07-02 02:43:51
# - version: 4.4.1.stable
#============================================================
@tool
extends EditorPlugin


const GLOBAL_RESOURCE_CLASS_PATH = "res://config/_global_res_path_class.gd"
const Global_RESOURCE_CLASS_CONFIG_DIR = "res://config/global_res_path_class"
const TOOL_NAME = "Add Global Resource Name Config Script"

var update_timer : Timer
var updating : bool = false


func _enter_tree():
	if not DirAccess.dir_exists_absolute(Global_RESOURCE_CLASS_CONFIG_DIR):
		DirAccess.make_dir_recursive_absolute(Global_RESOURCE_CLASS_CONFIG_DIR)
		EditorInterface.get_resource_filesystem().scan()
	
	add_tool_menu_item(TOOL_NAME, create_new_config_script)
	
	# 更新脚本代码计时器
	update_timer = Timer.new()
	update_timer.autostart = false
	update_timer.wait_time = 1.0
	update_timer.timeout.connect(_update)
	add_child.call_deferred(update_timer)
	update_timer.one_shot = true
	
	EditorInterface.get_base_control().get_tree().root.files_dropped.connect(
		func(files):
			if not updating:
				update_timer.start()
	)
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(
		func():
			if not updating:
				update_timer.start()
	)
	EditorInterface.get_file_system_dock().files_moved.connect(
		func(old_file: String, new_file: String):
			if not updating:
				update_timer.start()
	)
	EditorInterface.get_file_system_dock().file_removed.connect(
		func(file: String):
			if not updating:
				update_timer.start()
	)


func _exit_tree():
	remove_tool_menu_item(TOOL_NAME)


var global_script_data_dict : Dictionary = {}
func _update():
	if not DirAccess.dir_exists_absolute(Global_RESOURCE_CLASS_CONFIG_DIR):
		DirAccess.make_dir_recursive_absolute(Global_RESOURCE_CLASS_CONFIG_DIR)
		EditorInterface.get_resource_filesystem().scan()
	
	updating = true
	
	# 配置脚本列表
	var global_script_list : Array[GDScript] = []
	var base_script : Script = BaseGlobalResourcePathConfig as GDScript
	var gd_script_path: String
	for file in DirAccess.get_files_at(Global_RESOURCE_CLASS_CONFIG_DIR):
		if file.get_extension() == "gd":
			gd_script_path = Global_RESOURCE_CLASS_CONFIG_DIR.path_join(file)
			if ResourceLoader.exists(gd_script_path):
				var script := load(gd_script_path) as Script
				if script.get_base_script() == base_script:
					global_script_list.append(script)
	
	# 更新脚本信息
	var tmp_script_data_dict : Dictionary = {}
	for script:Script in global_script_list:
		var scan_dir : String = script._scan_dir()
		if not DirAccess.dir_exists_absolute(scan_dir):
			push_error("不存在 %s 目录，请重写 %s 脚本的配置" % [scan_dir, script.resource_path] )
		var data : Dictionary = {}
		data["scan_dir"] = scan_dir
		data["group_name"] = script._get_group_name()
		if scan_dir == "" or not DirAccess.dir_exists_absolute(scan_dir):
			if scan_dir != "": #没有配置路径，则代表还刚创建
				# 不存在扫描的路径时，记录更新
				data["files"] = []
				tmp_script_data_dict[script] = data
		else:
			data["files"] = script._filter(Array(ResourceLoader.list_directory(scan_dir)).filter(_filter_dir))
			var last_data : Dictionary = global_script_data_dict.get(script, {})
			if last_data.is_empty() or last_data.hash() != data.hash():
				# 和上次的数据不一致时，记录更新
				tmp_script_data_dict[script] = data
	
	# 如果有删除的配置文件，则进行更新
	var need_update : bool = false
	for script:Script in global_script_data_dict:
		if not is_instance_valid(script) or not ResourceLoader.exists(script.resource_path):
			need_update = true
			break
	
	if not tmp_script_data_dict.is_empty() or need_update:
		print_debug("开始更新全局资源名类列表")
		for script:GDScript in global_script_data_dict:
			if ResourceLoader.exists(script.resource_path):
				var data = global_script_data_dict[script]
				if DirAccess.dir_exists_absolute(data["scan_dir"]) and not tmp_script_data_dict.has(script):
					tmp_script_data_dict[script] = data
		global_script_data_dict = tmp_script_data_dict
		print(global_script_data_dict)
		
		# 变量列表
		var group_to_data_dict : Dictionary = {}
		for data in global_script_data_dict.values():
			group_to_data_dict.get_or_add(data["group_name"], {}).merge(data)
		
		# 字符缩进
		var indent_type : int = EditorInterface.get_editor_settings() \
			.get_setting("text_editor/behavior/indent/type")
		const INDENT_TYPE_TABS = 0
		const INDENT_TYPE_SPACES = 1
		var indent_str : String = ""
		if indent_type == INDENT_TYPE_TABS:
			indent_str = "\t"
		elif indent_type == INDENT_TYPE_SPACES:
			var indent_size : int = EditorInterface.get_editor_settings() \
				.get_setting("text_editor/behavior/indent/size")
			indent_str = " ".repeat(indent_size)
		
		# 生成并更新全局类脚本
		var script_var_list_code : String = ""
		for group_name:String in group_to_data_dict:
			var data: Dictionary = group_to_data_dict[group_name]
			var scan_path: String = data["scan_dir"]
			var v_name: String
			var v_name_dict : Dictionary = {}
			if group_name == "":
				# 属性项
				for f: String in data["files"]:
					v_name = f.validate_filename().get_basename()
					if not v_name_dict.has(v_name):
						v_name_dict[v_name] = null
						script_var_list_code += "const %s = \"%s\"\n" % [
							v_name, 
							scan_path.path_join(f)
						]
			else:
				# 类名
				script_var_list_code += "class %s:\n" % data["group_name"]
				if data["files"].is_empty():
					script_var_list_code += "%spass\n" % indent_str
				# 属性项
				for f: String in data["files"]:
					v_name = f.validate_filename().get_basename()
					if not v_name_dict.has(v_name):
						v_name_dict[v_name] = null
						script_var_list_code += "%sconst %s = \"%s\"\n" % [
							indent_str,
							v_name, 
							scan_path.path_join(f)
						]
			script_var_list_code += "\n\n"
		
		# 保存资源
		var script : GDScript
		if FileAccess.file_exists(GLOBAL_RESOURCE_CLASS_PATH):
			script = load(GLOBAL_RESOURCE_CLASS_PATH)
		else:
			script = GDScript.new()
		script.source_code = """# Global Resource Class Path
# 这是一个自动创建的脚本，它会自动更新里面的代码，如果你手动修改了这个脚本的容，那么它会在下次自
# 动更新时，覆盖掉你修改的内容
class_name R

""" + script_var_list_code
		script.reload()
		if not DirAccess.dir_exists_absolute(GLOBAL_RESOURCE_CLASS_PATH.get_base_dir()):
			DirAccess.make_dir_recursive_absolute(GLOBAL_RESOURCE_CLASS_PATH.get_base_dir())
		var err := ResourceSaver.save(script, GLOBAL_RESOURCE_CLASS_PATH)
		EditorInterface.get_resource_filesystem().update_file(GLOBAL_RESOURCE_CLASS_PATH)
		print_debug("更新 Global Resource Class 脚本完成：", err, "  ", error_string(err))
	
	set_deferred("updating", false)

func _filter_dir(file: String) -> bool:
	return not file.ends_with("/")

## 创建新的配置脚本
func create_new_config_script():
	updating = true
	
	if not DirAccess.dir_exists_absolute(Global_RESOURCE_CLASS_CONFIG_DIR):
		DirAccess.make_dir_recursive_absolute(Global_RESOURCE_CLASS_CONFIG_DIR)
		EditorInterface.get_resource_filesystem().scan()
	
	var script_file_name_template : String = "new_global_res_script_name_config_%02d.gd"
	var script_path: String
	var idx : int = 0
	while true:
		script_path = Global_RESOURCE_CLASS_CONFIG_DIR.path_join(script_file_name_template % idx)
		if not FileAccess.file_exists(script_path):
			break
		idx += 1
	
	var script = GDScript.new()
	script.source_code = """# Global Resource Name Config
extends BaseGlobalResourcePathConfig

# override
static func _get_group_name() -> String:
	# 可省略。如果这个为空，则默认不添加 class 分类
	return ""

# override
static func _scan_dir() -> String:
	return ""

# override
static func _filter(file_name_list: Array) -> Array:
	return file_name_list
"""
	var err = ResourceSaver.save(script, script_path)
	print_debug("创建全局资源名配置脚本结束：", err, "  ", error_string(err))
	set_deferred("updating", false)
