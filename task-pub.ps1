Clear-Host
$start = Get-Date

$task_api_pub_preview = {D:\SourceCode\powershell\autopub.ps1 -AutoPubDirPath "D:\autopub" -ConfigFilePath "config\pub-test.config" -OutPutFilePath "D:\autopub\log\test-api-pub-log.txt" -PubType "api"}
$task_wpf_pub_preview = {D:\SourceCode\powershell\autopub.ps1 -AutoPubDirPath "D:\autopub" -ConfigFilePath "config\pub-test.config" -OutPutFilePath "D:\autopub\log\test-wpf-pub-log.txt" -PubType "wpf"}

$thread1 = [PowerShell]::Create()
$job1 = $thread1.AddScript($task_api_pub_preview).BeginInvoke()
 
$thread2 = [PowerShell]::Create()
$job2 = $thread2.AddScript($task_wpf_pub_preview).BeginInvoke()
do { Start-Sleep -Milliseconds 100 } until ($job1.IsCompleted -and $job2.IsCompleted)
 
$result1 = $thread1.EndInvoke($job1)
$result2 = $thread2.EndInvoke($job2)
 
$thread1.Runspace.Close()
$thread1.Dispose()
 
$thread2.Runspace.Close()
$thread2.Dispose()

$end = Get-Date
Write-Host -ForegroundColor Red ("共耗时：" + ($end - $start).TotalMinutes)
Write-Host '按任意键结束...' -NoNewline
$null = [Console]::ReadKey('?')

#D:\SourceCode\powershell\autopub.ps1 -AutoPubDirPath "D:\autopub" -ConfigFilePath "config\pub-test.config" -OutPutFilePath "D:\autopub\log\test-api-pub-log.txt" -PubType "api"
#D:\SourceCode\powershell\autopub.ps1 -AutoPubDirPath "D:\autopub" -ConfigFilePath "config\pub-test.config" -OutPutFilePath "D:\autopub\log\test-wpf-pub-log.txt" -PubType "wpf"


D:\SourceCode\powershell\autopub.ps1 -AutoPubDirPath "D:\autopub" -ConfigFilePath "config\pub-demo.config" -OutPutFilePath "D:\autopub\log\demo-api-pub-log.txt" -PubType "api"
D:\SourceCode\powershell\autopub.ps1 -AutoPubDirPath "D:\autopub" -ConfigFilePath "config\pub-demo.config" -OutPutFilePath "D:\autopub\log\demo-wpf-pub-log.txt" -PubType "wpf"