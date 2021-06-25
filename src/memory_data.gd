extends Resource

class_name MemoryData

export var mem_size: int setget set_mem_size
export var width: int
export var bytes: PoolIntArray

const mem_sizes = {
	32: "32",
	64: "64",
	128: "128",
	256: "256",
	512: "512",
	1024: "1K",
	2048: "2K",
	4096: "4K",
	8192: "8K"
}

func set_mem_size(idx):
	mem_size = get_mem_size(idx)
	bytes.resize(mem_size)
	for idx in mem_size:
		bytes[idx] = 0


func get_mem_size(idx):
	return mem_sizes.keys()[idx]
