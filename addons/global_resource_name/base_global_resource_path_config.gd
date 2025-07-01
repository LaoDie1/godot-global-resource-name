#============================================================
#    Base Global Resource Path Config
#============================================================
# - author: zhangxuetu
# - datetime: 2025-07-01 22:11:30
# - version: 4.4.1.stable
#============================================================
## 用于配置 R 类名脚本的配置
class_name BaseGlobalResourcePathConfig


## 设置这个资源分类的子类名，在使用的时候即 [code]R.GroupName.ResourceFileName[/code]。
##如果返回为 [code]""[/code]，则在使用时为 [code]R.ResourceFileName[/code]
static func _get_group_name() -> String:
	return ""

## 扫描的资源列表目录，必须要返回正确的目录，否则不扫描这个目录
static func _scan_dir() -> String:
	return ""

## 设置要过滤的文件名。如果不过滤，则为当前扫描的目录下的所有文件。
static func _filter(file_name_list: Array) -> Array:
	return file_name_list
