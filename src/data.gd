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
		"inputs": ["A","B","Select"],
		"outputs": ["Y"],
		"tt": [
			[0,0,0,0],
			[0,0,1,0],
			[0,1,0,0],
			[0,1,1,1],
			[1,0,0,1],
			[1,0,1,0],
			[1,1,0,1],
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
		"inputs": ["J","CK", "K"],
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
	},
	"REG":
	{
		"inputs": ["D","LD","CK","R"],
		"outputs": ["Q"],
		"tt": [
			["0xf",0,0,0,"X"],
			["0xf",1,0,0,"L"],
			["0xf",1,1,0,"0xf"],
			["0xf",0,0,0,"0xf"],
			["0xf",0,0,1,0],
			["0xf",0,1,0,0],
			["0xffff",1,0,0,0,"!"],
			["0xffff",1,"+",0,"0xffff"]
		],
		"title": "Register",
		"long_title": "",
		"desc": "The Register stores the value at D when LD is high on a rising edge of the clock. A high on R resets the output."
	},
	"COUNTER":
	{
		"inputs": ["D","INC","LD","CK","R"],
		"outputs": ["Q"],
		"tt": [
			["0xf",0,0,0,0,"X"],
			["0xf",0,1,0,0,"L"],
			["0xf",0,1,"+",0,"0xf"],
			["0xf",1,0,0,0,"0xf","!"],
			["0xf",1,0,"+",0,"0x10"],
			["0xf",1,0,0,0,"0x10","!"],
			["0xf",1,0,"+",0,"0x11"],
			["0xf",0,0,0,0,"0x11","!"],
			["0xf",0,0,"+",0,"0x11"],
			["0xffff",0,0,0,1,0]
		],
		"title": "Counter",
		"long_title": "",
		"desc": "The Counter increments its output when the INC pin is high on rising clock edges. It stores the value at D when LD is high on a rising edge of the clock. A high on R resets the output. With LD and INC low, the output is preserved."
	},
	"SHIFTREG":
	{
		"inputs": ["D","SI","EN","LD","CK","R"],
		"outputs": ["Q"],
		"tt": [
			["0xff",0,0,1,0,0,"X"],
			["0xff",0,0,1,1,0,"0xff"],
			["0xff",0,1,0,0,0,"0xff","!"],
			["0xff",0,1,0,"+",0,"0x7f"],
			["0xff",0,1,0,0,0,"0x7f","!"],
			["0xff",0,1,0,"+",0,"0x3f"],
			["0xff",1,1,0,0,0,"0x3f","!"],
			["0xff",1,1,0,"+",0,"0x9f"],
			["0xff",0,0,0,0,0,"0x9f","!"],
			["0xff",0,0,0,"+",0,"0x9f"],
			["0xff",0,0,0,0,1,0],
		],
		"title": "Shift Register",
		"long_title": "",
		"desc": "The Shift Register shifts bits to the right when EN is high on rising clock edges. A 1 is shifted in from the left when SI is high. It stores the value at D when LD is high on a rising edge of the clock. A high on R resets the output. With LD and EN low, the output is preserved."
	},
	"ALU":
	{
		"inputs": ["A","B","F0","F1","F2"],
		"outputs": ["Y","Cout","Zero","Over","Sign"],
		"tt": [
			[3,6,0,0,0,3,0,0,0,0], # a
			[3,6,1,0,0,6,0,0,0,0], # b
			[3,6,0,1,0,4,0,0,0,0], # a + 1
			[3,6,1,1,0,7,0,0,0,0], # b + 1
			[3,6,0,0,1,9,0,0,0,0], # a + b
			[63,4,1,0,1,59,0,0,0,0], # a - b
			["0xff","0x56",0,1,1,"0x56",0,0,0,0], # a & b
			["0xd0","0x0c",1,1,1,"0xdc",0,0,0,0], # a | b
			["0x7fff",6,0,1,0,"0x8000",0,0,1,1], # a + 1
			[3,"0x7fff",1,1,0,"0x8000",0,0,1,1], # b + 1
			["0x7ff0","0x10",0,0,1,"0x8000",0,0,1,1], # a + b
			["0x8000",1,1,0,1,"0x7fff",0,0,1,0], # a - b
			["0xffff",6,0,1,0,"0x0000",1,1,0,0], # a + 1
			
		],
		"title": "Aritmetic and Logic Unit (16 bit)",
		"long_title": "",
		"desc": "The Aritmetic anf Logic Unit performs one of 8 operations on the A and B inputs to produce an output Y. The Function inputs determine the function and there are various status outputs."
	},
	"ROM":
	{
		"inputs": ["A","/OE"],
		"outputs": ["D"],
		"tt": [
			[0,0,1],
			[0,1,1],
			[255,1,1],
			[254,0,255]
		],
		"title": "Read Only Memory (ROM)",
		"long_title": "",
		"desc": "The ROM stores data referenced by an address. The data is output when the /OE pin is low. The contents of the memory are retained in the data for the circuit."
	},
	"RAM":
	{
		"inputs": ["A","Din","/OE","/W"],
		"outputs": ["Dout"],
		"tt": [
			[0,0,1,1,"X"],
			[0,33,1,0,0],
			[0,33,1,1,0],
			[0,7,0,1,33],
			[0,7,1,1,33],
			[1,"0x11",1,0,33],
			[1,"0x11",1,1,33],
			[1,"0x11",0,1,"0x11"],
			[255,255,0,1,0],
			[255,255,1,0,0],
			[255,255,1,1,0],
			[255,255,0,1,255],
		],
		"title": "Random Access Memory (RAM)",
		"long_title": "",
		"desc": "The RAM stores data temporarily as long as power is applied. The data is output when the /OE pin is low. Input data is written to the current address when the /W pin is low."
	}
}
