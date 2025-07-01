extends Node2D


func _ready(): 
	pass
	
	# 你可以试着在 res://src/res 目录下添加 SpriteFrames 类型的资源文件
	# 或者在 res://src/texture 目录下添加 Texture2D 类型的资源文件
	# 这些配置全在 res://config/global_res_path_class 目录下的本里
	# 可直接使用 "Project>Tool>Add Global Resource Name Config Script" 菜单下快速添加配置脚本
	
	
	print(R.player)
	
	print(R.ResShader.new_shader)
	
	print(R.ResSpriteFrame.anim_a)
	print(R.ResSpriteFrame.test_sprite_frames)
	print(R.ResSpriteFrame.player_anim)
	
