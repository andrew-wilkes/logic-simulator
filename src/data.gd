extends Node

var parts = {
	"NOT":
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
	"AND":
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
	"NAND":
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
	"OR":
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
	"NOR":
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
	"XOR":
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
	"MULT":
	{
		"inputs": ["Select","A","B"],
		"outputs": ["Y"],
		"tt": [
			[0,0,0,0],
			[0,0,1,0],
			[0,1,0,1],
			[0,1,1,1],
			[1,0,0,0],
			[1,0,1,1],
			[1,1,0,0],
			[1,1,1,1]
		],
		"title": "Multiplexer",
		"long_title": "",
		"desc": "A multiplexer selects one of several inputs."
	},
	"ADDER":
	{
		"inputs": ["A","B","Cin"],
		"outputs": ["Sum", "Cout"],
		"tt": [
			[0,0,0,0,0],
			[0,0,1,1,0],
			[0,1,0,1,0],
			[0,1,1,0,1],
			[1,0,0,1,0],
			[1,0,1,0,1],
			[1,1,0,0,1],
			[1,1,1,1,1]
		],
		"title": "Full Adder",
		"long_title": "",
		"desc": "A full adder adds together A, B, and carry inputs to give a sum and carry output."
	},
	"SRFLIPFLOP":
	{
		"inputs": ["S","R"],
		"outputs": ["Q", "/Q"],
		"tt": [
			[0,0,"X","X"],
			[1,0,1,0],
			[0,0,1,0],
			[0,1,0,1],
			[0,0,0,1],
			[1,1,0,0]
		],
		"title": "SR Flip-flop",
		"long_title": "",
		"desc": "The SR Flip-flop has Set and Reset inputs. Pulsing S high, sets Q high. Pulsing R high, resets Q. Both S and R being high is not a useful state."
	},
	"JKFLIPFLOP":
	{
		"inputs": ["J","CK", "R"],
		"outputs": ["Q", "/Q"],
		"tt": [
			[0,"X",0,"X","X"],
			[0,0,1,"L","L"],
			[0,"+",1,0,1],
			[1,0,0,0,1,"!"],
			[1,"+",0,1,0],
			[1,0,1,1,0,"!"],
			[1,"+",1,0,1],
			[1,0,1,0,1,"!"],
			[1,"+",1,1,0]
		],
		"title": "JK Flip-flop",
		"long_title": "",
		"desc": "The JK Flip-flop is like a clocked SR Flip-flop. Changes take place on the rising edge of the clock. If J is high, the output is Set. If K is high, the output is Reset. If both J and K are high, the output is Toggled."
	},
	"DLATCH":
	{
		"inputs": ["E","D"],
		"outputs": ["Q", "/Q"],
		"tt": [
			[0,0,"X","X"],
			[1,0,0,1],
			[0,0,0,1],
			[0,1,0,1],
			[1,1,1,0],
			[0,1,1,0],
			[0,0,1,0]
		],
		"title": "D Latch",
		"long_title": "",
		"desc": "The D Latch loads the data input value when E is high and stores it when E is low."
	},
	"DFLIPFLOP":
	{
		"inputs": ["S", "D", "CK", "R"],
		"outputs": ["Q"],
		"tt": [
			[0,"X",0,0,"L"],
			[1,"X",0,0,1],
			[0,0,0,0,1,"!"], # don't display this row
			[0,0,"+",0,0], # The rising edge
			[0,1,0,0,0,"!"], # D changed to 1
			[0,1,"+",0,1],
			[0,"X","X",1,0], # Reset
			[1,"X","X",0,1], # Set
			[1,"X","X",1,1]
		],
		"title": "D Flip-Flop",
		"long_title": "Edge-triggered D Flip-Flop with set and reset",
		"desc": "An Edge-triggered D Flip-Flop loads the input data on the rising edge of the clock input. Also, the SR inputs are used for setting the flip-flop to a desired state without giving it a clock pulse."
	}
}
