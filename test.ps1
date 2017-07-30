Clear-Host
$msBuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"
$slnPath = "D:\autopub\source\preview\shenlianerp_main\ShenLianERPSystem\ShenLianERPSystem.sln"
$execArgs = " /t:Rebuild  /M:8 /p:Configuration=Release  /fl "
$execArgs = $execArgs + "`"/flp:FileLogger,Microsoft.Build.Engine;apiBuildlogFile=Build.log;errorsonly;Encoding=UTF-8`""

& $msBuildPath  $slnPath  /t:Rebuild  /M:8 /p:Configuration=Release  /fl  "/flp:FileLogger,Microsoft.Build.Engine;apiBuildlogFile=Build.log;errorsonly;Encoding=UTF-8"

# C:\"Program Files (x86)"\"Microsoft Visual Studio"\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe  $slnPath  /t:Rebuild  /M:8 /p:Configuration=Release  /fl  "/flp:FileLogger,Microsoft.Build.Engine;apiBuildlogFile=Build.log;errorsonly;Encoding=UTF-8"
