extends ResourceFormatLoader

class_name CircFormatLoader

func get_recognized_extensions() -> PoolStringArray:
	return PoolStringArray(["circ"])

func get_resource_type(_path: String) -> String:
	return "Resource"

func handles_type(typename: String) -> bool:
	return typename == "Resource" 

func load(path: String, _original_path: String):
	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		# Cannot read the binary res file. End up with null return value
		var res: Resource = file.get_var()
		file.close()
		return res
	else:
		return ERR_FILE_NOT_FOUND
