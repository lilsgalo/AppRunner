extends Node

var colors = {
	"verde-azul-legal": "#24cfa7"
}

var type = {
	Type.Info: "white",
	Type.Warning: "orange",
	Type.Error: "red",
	Type.Success: "green"
}

enum Type {
	Info,
	Warning,
	Error,
	Success
}

func Log(text: String, logType: Type = Type.Info, size: int = 12) -> void:
	var color = type[logType]
	print_rich("[color=%s][font_size=%d]%s[/font_size][/color]" % [color, size, text])

func LogVariant(value: Variant, _logType: Type = Type.Info, _size: int = 12) -> void:
	#var color = type[logType]
	
	#if typeof(value) == TYPE_DICTIONARY:
		#pass
	
	#print_rich("[color=%s][font_size=%d]" % [color, size] + value + "[/font_size][/color]")
	print_rich(value)
