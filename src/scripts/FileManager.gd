extends Node

var vsUserSecretsPath: String = "/Microsoft/UserSecrets/%s/secrets.json"
var refsPath: String = "res://src/refs/"

# Referências para arquivos de secrets
var assemblyPath: String = "/Properties/AssemblyInfo.cs"
var secretsPath: String = "/secrets"
var secretsRefPath: String = "current.json"

# Referências para verificação dos paths das aplicações
var projSuffix: String = ".csproj"
var packageJsonPath: String = "package.json"

# Comandos para rodar as aplicações
var dotnetCmd: String = "dotnet run"
var angularCmd: String = "ng s"

var apiNameRegex: String = "\\w+\\.Api"
var userSecretsRegex: String = '(?<=UserSecretsId\\(")[0-9a-fA-F-]{36}(?="\\))'

var runningProcesses: Array[int]

func CreateRefFolder(appName: String) -> String:
	appName = appName.to_lower()
	var ref = refsPath + appName
	
	var dir = DirAccess.open(refsPath)
	if !dir.get_directories().has(appName):
		dir.make_dir(appName)
	return ref

func CopySecretsFile(id: String, appName: String) -> void:
	appName = appName.to_lower()
	var ref = refsPath + appName
	var file = GetSecretsFile(id)

	var secrets = FileAccess.open("%s/%s" % [ref, secretsRefPath], FileAccess.WRITE)
	secrets.store_string(file.get_as_text())

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
	var result = regex.search(file).get_string()
	return result

func GetSecretsFile(id: String) -> FileAccess:
	var appData = OS.get_environment("APPDATA")
	var path = vsUserSecretsPath % id
	var file = FileAccess.open(appData + path, FileAccess.READ)
	return file

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
