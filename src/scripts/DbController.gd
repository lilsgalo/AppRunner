extends Node

var userPath: String

var db: SQLite
var appsTable: String = "apps"
var userTable: String = "user"
var dbPath: String = "/db/data.db"

# Referências
var dbRefPath: String = "/db"
var dbFileName: String = "data.db"

func _ready() -> void:
	userPath = OS.get_user_data_dir() + "/user_config/"

func SetupDatabase() -> void:
	db = SQLite.new()
	db.path = userPath + dbPath
	db.open_db()
	
	var hasfile = DirAccess.get_files_at(userPath + dbRefPath).has(dbFileName)
	if hasfile:
		CreateAppsTable()
		CreateUserTable()


func CreateAppsTable() -> void:
	var table = {
		"rowid": {"data_type": "int", "primary_key": true},
		"name": {"data_type": "text"},
		"backend_path": {"data_type": "text"},
		"frontend_path": {"data_type": "text"},
		"secrets_id": {"data_type": "text"},
		"ref_folder": {"data_type": "text"}
	}
	
	var result = db.create_table("apps", table)
	if !result:
		Utils.Log("Não foi possível criar tabela de aplicações", Utils.Type.Error)

func CreateUserTable() -> void:
	var table = {
		"email": {"data_type": "text"},
		"ip": {"data_type": "text"}
	}
	
	var result = db.create_table("user", table)
	if !result:
		Utils.Log("Não foi possível criar tabela de usuário", Utils.Type.Error)

func Create(input: Entities.App.CreateInput) -> int:
	var data = {
		"name" = input.name,
		"backend_path" = input.backend_path,
		"frontend_path" = input.frontend_path,
		"secrets_id" = input.secrets_id,
		"ref_folder" = input.ref_folder
	}
	
	var result = db.insert_row(appsTable, data)
	if result:
		return db.last_insert_rowid
	Utils.Log("Ops! Aconteceu algo errado.", Utils.Type.Error)
	return -1

func UpdateApp(input: Entities.App.UpdateInput) -> void:
	var data = {
		"rowid" = input.rowid,
		"name" = input.name,
		"backend_path" = input.backend_path,
		"frontend_path" = input.frontend_path,
		"secrets_id" = input.secrets_id
	}
	
	var result = db.update_rows(appsTable, "rowid = %s" % input.rowid, data)
	if !result:
		Utils.Log("Ops! Aconteceu algo errado", Utils.Type.Error)

func DeleteApp(id: int) -> void:
	var result = db.delete_rows(appsTable, "rowid = %s" % id)
	if !result:
		Utils.Log("Ops! Aconteceu algo errado", Utils.Type.Error)

func GetById(id: int) -> Entities.App:
	var data = _GetById(appsTable, str(id), ["rowid, *"])
	if data:
		return FormatAppData(data.front())
	else:
		Utils.Log("GetById não retornou resultados", Utils.Type.Error)
		return null

func GetAll() -> Array:
	var data = db.select_rows(appsTable, "", ["*"])
	return data

func GetUser(id: int = 1) -> Dictionary:
	var data = _GetById(userTable, str(id), ["*"])
	if data:
		return data.front()
	Utils.Log("GetUser não retornou resultados", Utils.Type.Error)
	return {}

func FormatAppData(data: Dictionary) -> Entities.App:
	var app = Entities.App.Create(
		data.get("rowid"),
		data.get("name"),
		data.get("backend_path"),
		data.get("frontend_path"),
		data.get("secrets_id"),
		data.get("ref_folder")
	)
	
	return app

func _GetById(table: String, id: String, select: Array[String]) -> Array:
	return db.select_rows(table, "rowid = %s" % id, select)
