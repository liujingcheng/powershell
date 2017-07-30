function test-task ([string] $message) {
    $outstr = ((Get-Date).ToString() + $message)
    $outstr
    $outstr | Out-File -FilePath "D:\test-task.txt"
}

# test-task task1 

$task1 = { test-task task1 }
$thread1 = [PowerShell]::Create()
$job1 = $thread1.AddScript($task1).BeginInvoke()
 