extends Resource

class_name MemoryData

export var mem_size: int setget set_mem_size
export var width: int
export var bytes: PoolIntArray
export var rom: bool = true

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

func set_mem_size(v):
	mem_size = v
	bytes.resize(mem_size)
	erase()


func erase():
	for idx in mem_size:
		bytes[idx] = 0


func set_indexed_mem_size(idx):
	set_mem_size(mem_sizes.keys()[idx])


func get_mem_size_str():
	return mem_sizes[mem_size]
