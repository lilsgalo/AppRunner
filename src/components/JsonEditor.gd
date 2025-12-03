extends Window
class_name JsonEditor

#var appName: String
var root: TreeItem

func _ready() -> void:
	%Tree.columns = 2
	%Tree.set_column_title(0, "Key")
	%Tree.set_column_title(1, "Value")
	%Tree.set_column_titles_visible(false)
	%Tree.hide_root = true
	
	%Tree.set_column_expand(0, false)
	%Tree.set_column_expand(1, true)
	%Tree.set_column_custom_minimum_width(0, 300)
	
	%Tree.show()
	%CodeEdit.hide()

func SetJsonEditorContent(appName: String, parsedFile: Variant, fileContent: String) -> void:
	#appName = p_appName
	title = "Editando: %s" % appName.capitalize()
	%CodeEdit.text = fileContent
	SetTreeContent(parsedFile)

func SetTreeContent(parsedFile: Variant) -> void:
	%Tree.clear()
	root = %Tree.create_item()
	root.set_metadata(0, typeof(parsedFile))
	HandleData(root, parsedFile)

func SetCodeTextContent() -> void:
	var data = ReconstructData(root)
	%CodeEdit.text = JSON.stringify(data, "\t", false)

func HandleData(parent: TreeItem, data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY:
		for key in data.keys():
			var value = data[key]
			var item = %Tree.create_item(parent)
			item.set_text(0, str(key))
			ConfigureItem(item, value)
			
			if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
				item.set_metadata(0, typeof(value))
				HandleData(item, value)
				
	elif typeof(data) == TYPE_ARRAY:
		for i in range(data.size()):
			var value = data[i]
			var item = %Tree.create_item(parent)
			item.set_text(0, str(i))
			ConfigureItem(item, value)
			
			if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
				item.set_metadata(0, typeof(value))
				HandleData(item, value)

func ConfigureItem(item: TreeItem, value: Variant) -> void:
	item.set_selectable(0, false)
	item.set_editable(0, false)
	
	if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
		item.set_text(1, "")
		item.set_editable(1, false)
		item.set_selectable(1, false)
	else:
		item.set_text(1, str(value))
		item.set_editable(1, true)
		item.set_selectable(1, true)

func ReconstructData(parent: TreeItem) -> Variant:
	var type = parent.get_metadata(0)
	var children = parent.get_children()
	if type == TYPE_ARRAY:
		var arr = []
		for child in children:
			arr.append(GetItemValue(child))
		return arr
	else:
		var dict = {}
		for child in children:
			dict[child.get_text(0)] = GetItemValue(child)
		return dict

func GetItemValue(item: TreeItem) -> Variant:
	if item.get_child_count() > 0:
		return ReconstructData(item)
	
	var type = item.get_metadata(0)
	if type == TYPE_ARRAY:
		return []
	elif type == TYPE_DICTIONARY:
		return {}
	
	return ParseString(item.get_text(1))

func ParseString(value: String) -> Variant:
	var json = JSON.new()
	var output = json.parse(value)
	if output == OK and typeof(json.data) != TYPE_STRING:
		return json.data
	return value

func _on_tree_item_edited() -> void:
	SetCodeTextContent()

func _on_code_edit_text_changed() -> void:
	var parsedFile = ParseString(%CodeEdit.text)
	SetTreeContent(parsedFile)

func _on_tree_btn_pressed() -> void:
	%Tree.show()
	%CodeEdit.hide()

func _on_text_btn_pressed() -> void:
	%Tree.hide()
	%CodeEdit.show()

func _on_save_btn_pressed() -> void:
	print("save")

func _on_close_requested() -> void:
	self.hide()
