extends HBoxContainer

signal runFrontend(id: int, env: int)
signal runBackend(id: int, env: int)
signal edit(id: int, env: int)
signal delete(id: int, env: int)

var app: Entities.App

var styleRunning: StyleBoxFlat = StyleBoxFlat.new()
var styleStopped: StyleBoxFlat = StyleBoxFlat.new()

var playIconBlack = preload("uid://dj24uprdinwkg")
var playIconWhite = preload("uid://u3fwlj6k4ho0")
var pauseIconBlack = preload("uid://b710an1ha8fca")
var pauseIconWhite = preload("uid://dqbrpu8nlti0w")

func _ready() -> void:
	styleRunning.bg_color = "#2a5b32"
	styleStopped.bg_color = "#940e08"

func SetProjectInfo(p_app: Entities.App) -> void:
	app = p_app
	SetFrontState(app.frontIsRunning)
	SetBackState(app.backIsRunning)
	%NameLabel.text = app.name.to_upper()
	
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

func SetCurrentEnvironment(env: int) -> void:
	app.env = env

func SetFrontState(value: bool) -> void:
	app.frontIsRunning = value
	if value:
		%RunFrontBtn.icon = pauseIconWhite
	else:
		%RunFrontBtn.icon = playIconWhite

func SetBackState(value: bool) -> void:
	app.backIsRunning = value
	if value:
		%RunBackBtn.icon = pauseIconWhite
	else:
		%RunBackBtn.icon = playIconWhite

func GetRowId() -> int:
	return app.rowid

func GetBackendPID() -> int:
	return app.backPID

func GetFrontendPID() -> int:
	return app.frontPID

#region on btns pressed
func _on_run_option_button_item_selected(index: int) -> void:
	SetCurrentEnvironment(index)

func _on_run_back_btn_pressed() -> void:
	runBackend.emit(app.rowid, app.env)

func _on_run_front_btn_pressed() -> void:
	runFrontend.emit(app.rowid, app.env)

func _on_edit_btn_pressed() -> void:
	edit.emit(app.rowid, app.env)

func _on_delete_btn_pressed() -> void:
	delete.emit(app.rowid, app.env)
#endregion
