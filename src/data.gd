extends Node

var parts = {
	"not":
	{
		"inputs": ["A1"],
		"outputs": ["Q"],
		"tt": [
			[0,1],
			[1,0]
		],
		"title": "NOT Gate",
		"long_title": "",
		"desc": "A NOT gate inverts its input"
	},
	"and":
	{
		"inputs": ["A1","A2"],
		"outputs": ["Q"],
		"tt": [
			[0,0,0],
			[0,1,0],
			[1,0,0],
			[1,1,1]
		],
		"title": "AND Gate",
		"long_title": "",
		"desc": "An AND gate has a 0 output if any of its inputs are 0."
	},
	"nand":
	{
		"inputs": ["A1","A2"],
		"outputs": ["Q"],
		"tt": [
			[0,0,1],
			[0,1,1],
			[1,0,1],
			[1,1,0]
		],
		"title": "NAND Gate",
		"long_title": "",
		"desc": "A NAND gate does the opposite of an AND gate."
	},
	"or":
	{
		"inputs": ["A1","A2"],
		"outputs": ["Q"],
		"tt": [
			[0,0,0],
			[0,1,1],
			[1,0,1],
			[1,1,1]
		],
		"title": "OR Gate",
		"long_title": "",
		"desc": "An OR gate has a 1 output if any of its inputs are 1."
	},
	"nor":
	{
		"inputs": ["A1","A2"],
		"outputs": ["Q"],
		"tt": [
			[0,0,1],
			[0,1,0],
			[1,0,0],
			[1,1,0]
		],
		"title": "NOR gate",
		"long_title": "",
		"desc": "A NOR gate does the opposite of an OR gate."
	},
	"xor":
	{
		"inputs": ["A1","A2"],
		"outputs": ["Q"],
		"tt": [
			[0,0,0],
			[0,1,1],
			[1,0,1],
			[1,1,0]
		],
		"title": "XOR gate",
		"long_title": "",
		"desc": "An exclusive OR gate outputs a 1 if its inputs differ."
	},
	"etdff":
	{
		"inputs": ["Clock", "D", "S", "R"],
		"outputs": ["Q"],
		"tt": [
			[0,"X",0,0,"L"],
			[1,"X",0,0,"L"],
			["+",0,0,0,0],
			["+",1,0,0,1],
			["X","X",1,0,1],
			["X","X",0,1,0],
			["X","X",1,1,1]
		],
		"title": "D Flip-Flop",
		"long_title": "Edge-triggered D Flip-Flop with set and reset",
		"desc": "A flip-flop can have extra inputs to set and reset it, just like the SR flip-flop in figu are used for setting the flip-flop to a desired state without giving it a clock pulse."
	}
}
