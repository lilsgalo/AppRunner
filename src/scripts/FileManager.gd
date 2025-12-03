extends Node

var Environments = {
	0:"dev",
	1:"stage",
	2:"homolog",
	3:"prod"
}

var userPath: String
var refsPath: String = "refs"
var vsUserSecretsPath: String = "/Microsoft/UserSecrets/%s/secrets.json"

# Referências para arquivos de secrets
var assemblyPath: String = "/Properties/AssemblyInfo.cs"
var secretsPath: String = "/secrets"
var secretsCurrentFileName: String = "current.json"
var secretsDevFileName: String = "dev.json"
var secretsStageFileName: String = "stage.json"

# Referências para verificação dos paths das aplicações
var projSuffix: String = ".csproj"
var packageJsonPath: String = "package.json"

# Comandos para rodar as aplicações
var dotnetCmd: String = "dotnet run"
var angularCmd: String = "ng s"

var apiNameRegex: String = "\\w+\\.Api"
var userSecretsRegex: String = '(?<=UserSecretsId\\(")[0-9a-fA-F-]{36}(?="\\))'

var runningProcesses: Array[int]

func _ready() -> void:
	userPath = OS.get_user_data_dir() + "/user_config/"

func CreateMainFolders() -> void:
	var dir = DirAccess.open(OS.get_user_data_dir())
	if !dir.get_directories().has("user_config"):
		dir.make_dir("user_config")
	CreateFolder("refs")
	CreateFolder("db")

func CreateRefFolder(appName: String) -> String:
	appName = appName.to_lower()
	var path = CreateFolder(appName, refsPath)
	return path

func CreateFolder(fileName: String, complementaryPath: String = "") -> String:
	var dir = DirAccess.open(userPath + complementaryPath)
	if !dir.get_directories().has(fileName):
		dir.make_dir(fileName)
	var path = userPath + complementaryPath + "/" + fileName
	return path

func CopySecretsFile(secretsId: String, refFolder: String) -> void:
	var vsFile = GetSecretsFile(secretsId)
	var current = FileAccess.open("%s/%s/%s/%s" % [userPath, refsPath, refFolder, secretsCurrentFileName], FileAccess.WRITE)
	var dev = FileAccess.open("%s/%s/%s/%s" % [userPath, refsPath, refFolder, secretsDevFileName], FileAccess.WRITE)
	var stage = FileAccess.open("%s/%s/%s/%s" % [userPath, refsPath, refFolder, secretsStageFileName], FileAccess.WRITE)
	current.store_string(vsFile.get_as_text())
	dev.store_string(vsFile.get_as_text())
	stage.store_string(vsFile.get_as_text())

func ValidateBackendPath(path: String) -> bool:
	var apiName = GetApiNameFromPath(path)
	var dir = DirAccess.get_files_at(path)
	return dir.has(apiName + projSuffix)

func ValidateFrontendPath(path: String) -> bool:
	var dir = DirAccess.get_files_at(path)
	return dir.has(packageJsonPath)

func GetApiNameFromPath(path: String) -> String:
	var regex = CompileRegex(apiNameRegex)
	var result = regex.search(path).get_string()
	return result

func GetSecretsId(path: String) -> String:
	var regex = CompileRegex(userSecretsRegex)
	var file = FileAccess.get_file_as_string(path + assemblyPath)
	if !file:
		Utils.Log("Failed to get AssemblyInfo.cs", Utils.Type.Error)
		return ""
	
	var result = regex.search(file).get_string()
	if result:
		return result
	return ""

func GetSecretsFile(id: String) -> FileAccess:
	var appData = OS.get_environment("APPDATA")
	var path = vsUserSecretsPath % id
	var file = FileAccess.open(appData + path, FileAccess.READ)
	if file:
		return file
	return null

func GetDefaultSecretsFile(rowid: int) -> Dictionary:
	var app = DbController.GetById(rowid)
	if !app:
		Utils.Log("Failed to get App. Attempted to get: RowId = %d" % rowid, Utils.Type.Error)
		return {}
	
	var dir = DirAccess.open(app.refFolder)
	if !dir:
		Utils.Log("Failed to get Application. Attempted to get: RefFolder = %s" % app.refFolder, Utils.Type.Error)
		return {}
	if !dir.get_files().has(secretsCurrentFileName):
		Utils.Log("Secrets file not found. Attempted to get: %s" % secretsCurrentFileName, Utils.Type.Error)
		return {}
	
	var file = FileAccess.open("%s/%s" % [app.refFolder, secretsCurrentFileName], FileAccess.READ)
	if !file:
		Utils.Log("Failed to get Secrets file not found. Attempted to get: %s/%s" % [app.refFolder, secretsCurrentFileName], Utils.Type.Error)
		return {}
	var fileContent = file.get_as_text()
	
	var json = JSON.new()
	var output = json.parse(fileContent)
	if output != OK:
		Utils.Log("Failed to parse Secrets file's content", Utils.Type.Error)
		return {}
	
	return {"appName": app.name, "parsedFile": json.data, "fileContent": fileContent}

func OpenJson(file: FileAccess) -> Variant:
	var parsedFile = JSON.parse_string(file.get_as_text())
	return parsedFile

func CompileRegex(expression: String) -> RegEx:
	var regex = RegEx.new()
	regex.compile(expression)
	return regex

func RunDotnetFile(path: String) -> int:
	return Run(path, dotnetCmd)

func RunAngularFile(path: String) -> int:
	return Run(path, angularCmd)

func Run(path: String, command: String) -> int:
	var windows_path: String = path.replace("/", "\\")
	
	var cmd_command: String = "cd /d \"%s\" && %s && pause" % [windows_path, command]
	var ps_script: String = "Start-Process cmd.exe -ArgumentList '/C %s' -PassThru | Select-Object -ExpandProperty Id" % cmd_command
	var output: Array = []
	
	var exitCode = OS.execute("powershell.exe", ["-Command", ps_script], output)
	if exitCode == 0 and !output.is_empty():
		var pid = output.front().strip_edges().to_int()
		runningProcesses.append(pid)
		return pid
	Utils.Log("Failed to get PID", Utils.Type.Error)
	return -1

func ProcessIsRunning(pid: int) -> bool:
	var ps_script: String = "Get-Process -Id %d -ErrorAction SilentlyContinue" % pid
	var output: Array = []
	
	var exitCode = OS.execute("powershell.exe", ["-Command", ps_script], output)
	if exitCode == 0 and !output.is_empty():
		return true
	return false

## Mata o processo do executável criado em [code]RunDotnetFile[/code] ou [code]RunAngularFile[/code]
func KillProcess(pid: int) -> void:
	var args: Array[String] = ["/F", "/T", "/PID", str(pid)]
	OS.create_process("taskkill", args)
	RemoveProcess(pid)

## Mata todos os executáveis rodando no momento
func KillAllProcesses() -> void:
	for pid in runningProcesses:
		KillProcess(pid)

func RemoveProcess(pid) -> void:
	runningProcesses.erase(pid)
