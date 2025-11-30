extends Control

var TableItem = preload("uid://0wgtaxeptis8")
var tableItemList: Array
var runningPids: Array[Dictionary]

func _ready() -> void:
	%TimerLabel.text = "Nenhuma aplicação rodando no momento"
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var content = Global.OnReadySetup()
	SetTableContent(content)
	Global.connect("reloadList", ReloadTableContent)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		%CloseBtn.pressed.emit()

func _process(_delta: float) -> void:
	if !%Timer.is_stopped():
		var counter = %Timer.wait_time - (%Timer.wait_time - %Timer.time_left)
		var time = type_convert(counter, TYPE_INT)
		%TimerLabel.text = "Verificando estado das aplicações em %ss" % str(time)

func SetTableContent(content: Array[Entities.App]) -> void:
	for item in content:
		var newItem = TableItem.instantiate()
		newItem.SetProjectInfo(item)
		newItem.add_to_group("Item")
		%TableContent.add_child(newItem)
		tableItemList.append(newItem)
	ConnectSignals()

func ReloadTableContent() -> void:
	DisconnectSignals()
	tableItemList = []
	var content = Global.GetAppsData()
	SetTableContent(content)

## Atualiza o estado de uma aplicação que foi encerrada por meios externos ou
## que foi encerrada pela funcionalidade de encerrar todos as aplicações
func UpdateAppState(id: int, pid: int) -> void:
	var app = Global.GetApp(id)
	var nodeRef = GetAppNodeRef(id)
	
	if app.backPID == pid:
		app.backIsRunning = false
		app.backPID = 0
		nodeRef.SetBackState(false)
	if app.frontPID == pid:
		app.frontIsRunning = false
		app.frontPID = 0
		nodeRef.SetFrontState(false)
	Global.UpdateAppControls(app)

## Atualiza os estados de todas as aplicações para [code]False[/code]
## Utilizada ao clicar no botão de encerrar todas as aplicações
func StopAllApps() -> void:
	for item in runningPids:
		var rowid = item.keys().front()
		var pid = item.get(rowid)
		FileManager.KillProcess(pid)
		UpdateAppState(rowid, pid)
	
	for item in runningPids:
		runningPids.erase(item)

## Verifica o estado das aplicações que foram iniciadas internamente
## Caso ela tenha sido encerrada por meios externos, o estado
## dessa aplicação é atualizadao no controle interno
func CheckRunningProcesses() -> void:
	var stoppedProcesses = []
	for i in range(runningPids.size()):
		var rowid = runningPids[i].keys().front()
		var pid = runningPids[i].get(rowid)
		if FileManager.ProcessIsRunning(pid) == false:
			UpdateAppState(rowid, pid)
			stoppedProcesses.append(runningPids[i])
			FileManager.RemoveProcess(pid)
	
	for item in stoppedProcesses:
		runningPids.erase(item)
	
	if !runningPids.is_empty():
		StartTimer()
		return
	%Timer.stop()
	%TimerLabel.text = "Nenhuma aplicação rodando no momento"

func GetAppNodeRef(id: int) -> Node:
	return tableItemList.filter(func(item): return item.GetRowId() == id).front()

func StartTimer(seconds: int = 5) -> void:
	%Timer.wait_time = seconds
	%Timer.start()

func _on_timer_timeout() -> void:
	CheckRunningProcesses()

#region table item btns
func _on_run_back_btn_pressed(id: int, _build: int) -> void:
	var app = Global.GetApp(id)
	var nodeRef = GetAppNodeRef(app.rowid)
	if app.backIsRunning:
		FileManager.KillProcess(app.backPID)
		runningPids.erase({app.rowid: app.backPID})
		app.backPID = 0
		app.backIsRunning = false
	else:
		app.backPID = FileManager.RunDotnetFile(app.backendPath)
		app.backIsRunning = true
		runningPids.append({app.rowid: app.backPID})
		if %Timer.is_stopped():
			StartTimer()
	nodeRef.SetBackState(app.backIsRunning)
	Global.UpdateAppControls(app)

func _on_run_front_btn_pressed(id: int, _build: int) -> void:
	var app = Global.GetApp(id)
	var nodeRef = GetAppNodeRef(app.rowid)
	if app.frontIsRunning:
		FileManager.KillProcess(app.frontPID)
		runningPids.erase({app.rowid: app.frontPID})
		app.frontPID = 0
		app.frontIsRunning = false
	else:
		app.frontPID = FileManager.RunAngularFile(app.frontendPath)
		app.frontIsRunning = true
		runningPids.append({app.rowid: app.frontPID})
		if %Timer.is_stopped():
			StartTimer()
	nodeRef.SetFrontState(app.frontIsRunning)
	Global.UpdateAppControls(app)

func _on_edit_btn_pressed(id: int, build: int) -> void:
	print('edit => id: %s, build: %s' % [id, build])

func _on_delete_btn_pressed(id: int, build: int) -> void:
	print('delete => id: %s, build: %s' % [id, build])
#endregion

#region control btns
func _on_add_item_btn_pressed() -> void:
	%AddAppModal.visible = true

func _on_stop_all_btn_pressed() -> void:
	StopAllApps()
	%Timer.stop()
#endregion

#region settings btns
func _on_settings_btn_pressed() -> void:
	print('settings')

func _on_back_btn_pressed() -> void:
	print('back')

func _on_forward_btn_pressed() -> void:
	print('forward')
#endregion

#region windows btns
func _on_minimize_btn_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _on_maximize_btn_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _on_tree_exiting() -> void:
	FileManager.KillAllProcesses()

func _on_close_btn_pressed() -> void:
	get_tree().quit()
#endregion

#region signal managers
func ConnectSignals() -> void:
	for item in tableItemList:
		item.connect("runBackend", _on_run_back_btn_pressed)
		item.connect("runFrontend", _on_run_front_btn_pressed)
		item.connect("edit", _on_edit_btn_pressed)
		item.connect("delete", _on_edit_btn_pressed)

func DisconnectSignals() -> void:
	for item in tableItemList:
		if item.is_connected("runBackend", _on_run_back_btn_pressed):
			item.disconnect("runBackend", _on_run_back_btn_pressed)
		if item.is_connected("runFrontend", _on_run_front_btn_pressed):
			item.disconnect("runFrontend", _on_run_front_btn_pressed)
		if item.is_connected("edit", _on_edit_btn_pressed):
			item.disconnect("edit", _on_edit_btn_pressed)
		if item.is_connected("delete", _on_delete_btn_pressed):
			item.disconnect("delete", _on_delete_btn_pressed)
		item.remove_from_group("Item")
		item.free()
#endregion
