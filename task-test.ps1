function test-task ([string] $message) {
    $outstr = ((Get-Date).ToString() + $message)
    $outstr
    $outstr | Out-File -FilePath "D:\test-task.txt"
}

# test-task task1 

$JavaBuildScriptPath="xxx"

$task1 = { $JavaBuildScriptPath  | Out-File -FilePath "D:\test-task-1.txt"}
$thread1 = [PowerShell]::Create()
$job1 = $thread1.AddScript($task1).BeginInvoke()
 