extends HBoxContainer

signal runFrontend(id: int, build: int)
signal runBackend(id: int, build: int)
signal edit(id: int, build: int)
signal delete(id: int, build: int)

var app: Entities.App

var styleRunning: StyleBoxFlat = StyleBoxFlat.new()
var styleStopped: StyleBoxFlat = StyleBoxFlat.new()

func _ready() -> void:
	styleRunning.bg_color = "#2a5b32"
	styleStopped.bg_color = "#940e08"

func SetProjectInfo(p_app: Entities.App) -> void:
	app = p_app
	SetFrontState(app.frontIsRunning)
	SetBackState(app.backIsRunning)
	%NameLabel.text = app.name.to_upper()
	
	%EditBtn.disabled = true
	%DeleteBtn.disabled = true
	if app.backendPath.is_empty():
		%RunBackBtn.disabled = true
	if app.frontendPath.is_empty():
		%RunFrontBtn.disabled = true
	if !app.canRunDev:
		%RunDevBtn.disabled = true
	if !app.canRunStage:
		%RunStageBtn.disabled = true
	if !app.canRunHomolog:
		%RunHomologBtn.disabled = true
	if !app.canRunProd:
		%RunProdBtn.disabled = true

## Atualiza os dados da aplicação ao editar
## TODO: precisa implementar a edição. Ao editar tem que editar as variáveis de controle do app
## e habilitar/desabilitar o botão de acordo com os arquivos de secret que o usuário tem
## na pasta de refs do sistema e de acordo com os paths que ele adicionou quando criou o app.
## Se ele só adicionou um path para o back, só pode rodar o back
## e se só adicionou path para o front, só pode rodar o front.
func UpdateProjectInfo() -> void:
	pass

func SetCurrentBuild(build: int) -> void:
	app.build = build

func SetFrontState(value: bool) -> void:
	app.frontIsRunning = value
	if value:
		%RunFrontBtn.text = "Parar front"
		%RunFrontBtn.add_theme_stylebox_override("normal", styleRunning)
		%RunFrontBtn.add_theme_stylebox_override("hover", styleRunning)
	else:
		%RunFrontBtn.text = "Rodar front"
		%RunFrontBtn.add_theme_stylebox_override("normal", styleStopped)
		%RunFrontBtn.add_theme_stylebox_override("hover", styleStopped)

func SetBackState(value: bool) -> void:
	app.backIsRunning = value
	if value:
		%RunBackBtn.text = "Parar back"
		%RunBackBtn.add_theme_stylebox_override("normal", styleRunning)
		%RunBackBtn.add_theme_stylebox_override("hover", styleRunning)
	else:
		%RunBackBtn.text = "Rodar back"
		%RunBackBtn.add_theme_stylebox_override("normal", styleStopped)
		%RunBackBtn.add_theme_stylebox_override("hover", styleStopped)

func GetRowId() -> int:
	return app.rowid

func GetBackendPID() -> int:
	return app.backPID

func GetFrontendPID() -> int:
	return app.frontPID

#region on btns pressed
func _on_run_option_button_item_selected(index: int) -> void:
	SetCurrentBuild(index)

func _on_run_back_btn_pressed() -> void:
	runBackend.emit(app.rowid, app.build)

func _on_run_front_btn_pressed() -> void:
	runFrontend.emit(app.rowid, app.build)

func _on_edit_btn_pressed() -> void:
	edit.emit(app.rowid, app.build)

func _on_delete_btn_pressed() -> void:
	delete.emit(app.rowid, app.build)
#endregion
