extends Node

signal reloadList

var builds = {
	0:"dev",
	1:"stage",
	2:"homolog",
	3:"prod"
}

var userEmail: String
var userIp: String
@export var fullAppList: Array

func OnReadySetup() -> Array[Entities.App]:
	DbController.SetupDatabase()
	SetupUserData()
	return LoadAppsData()

func SetupUserData() -> void:
	var data = DbController.GetUser()
	if !data:
		return
	
	userEmail = data.get("email")
	userIp = data.get("ip")

func LoadAppsData() -> Array[Entities.App]:
	var appsData = DbController.GetAll()
	fullAppList = SetupAppsData(appsData)
	
	return fullAppList

func SetupAppsData(data: Array) -> Array[Entities.App]:
	var appList:Array[Entities.App] = []
	for item in data:
		var app = DbController.FormatAppData(item)
		app.frontIsRunning = false
		app.backIsRunning = false
		app.build = 1
		if app.backendPath or app.frontendPath: ## TODO: gambiarra, arrumar depois quando implementar o uso dos secrets
			app.canRunDev = true
			app.canRunStage = true
			app.canRunHomolog = true
			app.canRunProd = true
		appList.append(app)
	
	return appList

func GetAppsData() -> Array:
	return fullAppList

func GetApp(id: int) -> Entities.App:
	var app = fullAppList.filter(func(item): return item.rowid == id).front()
	return app

func UpdateAppControls(app: Variant) -> void:
	var index = fullAppList.find(app)
	fullAppList.set(index, app)

func AddNewItem(app: Entities.App) -> void:
	fullAppList.append(app)
	reloadList.emit()
