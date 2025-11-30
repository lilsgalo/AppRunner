extends Node

class App:
	# Info variables
	var rowid: int
	var name: String
	var backendPath: String
	var frontendPath: String
	var secretsId: String
	var refFolder: String
	
	# Control variables
	var frontIsRunning: bool
	var frontPID: int
	var backIsRunning: bool
	var backPID: int
	
	# Build control variables
	var build: int
	var canRunDev: bool
	var canRunStage: bool
	var canRunHomolog: bool
	var canRunProd: bool
	
	class CreateInput:
		var name: String
		var backend_path: String
		var frontend_path: String
		var secrets_id: String
		var ref_folder: String

	class UpdateInput:
		var rowid: int
		var name: String
		var backend_path: String
		var frontend_path: String
		var secrets_id: String
	
	static func Create(p_rowid: int, p_name: String, p_backendPath: String, p_frontendPath: String, p_secretsId: String, p_refFolder: String) -> App:
		var app = App.new()
		app.rowid = p_rowid
		app.name = p_name.to_lower()
		app.backendPath = p_backendPath
		app.frontendPath = p_frontendPath
		app.secretsId = p_secretsId
		app.refFolder = p_refFolder
		return app

class User:
	var email: String
	var ip: String
	
	static func Create() -> User:
		return User.new()
