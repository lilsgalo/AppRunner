extends Window
class_name AddAppWindow

var appName: String

#back
var backPath: String = ""
var selectingBack: bool = false
var backValid: bool = true

#front
var frontPath: String = ""
var selectingFront: bool = false
var frontValid: bool = true

var error: String

func UpdateBackPath(path: String) -> void:
	backPath = path
	%BackPathInput.text = path

func UpdateFrontPath(path: String) -> void:
	frontPath = path
	%FrontPathInput.text = path

## Atualiza o estado de validação dos paths da nova aplicação
## Recebe se o estado é valido ou não ([param value]) e
## se o valor sendo atualizado é a rota do back ou não ([param back])
func UpdateValidState(value: bool, back: bool = false) -> void:
	if back:
		backValid = value
	else:
		frontValid = value

func FormatInputForCreate(secretsId: String, refFolder: String) -> Entities.App.CreateInput:
	var input = Entities.App.CreateInput.new()
	input.name = appName.to_lower()
	input.backend_path = backPath
	input.frontend_path = frontPath
	input.secrets_id = secretsId
	input.ref_folder = refFolder
	return input

func _on_name_input_text_changed(newText: String) -> void:
	appName = newText

func _on_back_file_btn_pressed() -> void:
	%FileDialog.visible = true
	selectingBack = true

func _on_front_file_btn_pressed() -> void:
	%FileDialog.visible = true
	selectingFront = true

func _on_file_dialog_dir_selected(dir: String) -> void:
	if !dir:
		return
	
	if selectingBack:
		if !FileManager.ValidateBackendPath(dir):
			UpdateValidState(false, true)
		else:
			UpdateBackPath(dir)
			backValid = true
		selectingBack = false
	else:
		if !FileManager.ValidateFrontendPath(dir):
			frontValid = false
		else:
			UpdateFrontPath(dir)
			frontValid = true
		selectingFront = false

func _on_save_btn_pressed() -> void:
	if appName.is_empty():
		error = "Name must have value"
		Utils.Log(error, Utils.Type.Error)
		return
	
	if !backValid or !frontValid:
		error = "One or both paths are invalid"
		Utils.Log(error, Utils.Type.Error)
		return
	
	var secretsId = ""
	var refFolder = FileManager.CreateRefFolder(appName)
	if backPath:
		secretsId = FileManager.GetSecretsId(backPath)
		FileManager.CopySecretsFile(secretsId, appName)
	
	var input = FormatInputForCreate(secretsId, refFolder)
	var appId = DbController.Create(input)
	var app = Entities.App.Create(appId, appName, backPath, frontPath, secretsId, refFolder)
	Global.AddNewItem(app)
	
	close_requested.emit()

func _on_close_requested() -> void:
	if !backPath.is_empty():
		backPath = ''
		%BackPathInput.clear()
	if !frontPath.is_empty():
		frontPath = ''
		%FrontPathInput.clear()
	if !appName.is_empty():
		appName = ''
		%NameInput.clear()
	self.hide()
