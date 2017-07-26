#javac -encoding "UTF-8" -sourcepath D:\autopub\source\slerp_api\temp -classpath D:\autopub\lib\* -d D:\autopub\source\slerp_api\target\classes  D:\autopub\source\slerp_api\temp\com\canyou\CanYouConfig.java
Function RemoveApiTarget([string] $classpath) {
    $targetDirs = Get-ChildItem -Path $classpath -Directory
    foreach ($dir in $targetDirs) {
        Remove-Item -Path $dir.FullName -Recurse
    }
}

Function BuildApi([string] $srcpath, [string] $classpath, [string] $libPath, [string] $apiBuildlogFile) {

    RemoveApiTarget($classpath)

    Copy-Item -Path $srcpath.Replace("\src", "\conf\bpmn")  $classpath -Force

    D:\autopub\rm-utf-bom\RemoveUtfBom.exe $srcpath #去BOM头

    $null | Out-File -FilePath $apiBuildlogFile #先清空文件内容

    $tempSrcPath = $srcpath.Replace("\src", "\temp")
    $libPath = $libPath + "\*;" + $classpath;
    $firstSrcFile = $tempSrcPath + "\com\canyou\CanYouConfig.java";
    javac -encoding "UTF-8" -sourcepath $tempSrcPath -classpath $libPath -d $classpath  $firstSrcFile

    $srcs = Get-ChildItem -Path $tempSrcPath -Recurse -Include *.java  | ForEach-Object {$_.FullName.Replace($tempSrcPath, "").Replace(".java", "")}
    $classes = Get-ChildItem -Path $classpath  -Recurse  -Include *.class -Exclude '*$*' | ForEach-Object {$_.FullName.Replace($classpath, "").Replace(".class", "")}
    $srcs.Length
    $classes.Length
    $srcs.Length | Out-File -FilePath $apiBuildlogFile -Append
    $classes.Length | Out-File -FilePath $apiBuildlogFile -Append

    $missedPaths = New-Object -TypeName System.Collections.ArrayList
    foreach ($src in $srcs) {
        if (!$classes.Contains($src)) {
            $dirPath = $src.Substring(0, $src.LastIndexOf('\'))
            if (!$missedPaths.Contains($dirPath)) {
                $missedPaths.Add($dirPath)
                $srcFilePath = $tempSrcPath + $dirPath + "\*.java"
                $srcFilePath
                $srcFilePath | Out-File -FilePath $apiBuildlogFile -Append
                javac -encoding "UTF-8" -sourcepath $tempSrcPath -classpath $libPath -d $classpath  $srcFilePath
            }
        }
    }
    
    $srcs = Get-ChildItem -Path $tempSrcPath -Recurse -Include *.java  | ForEach-Object {$_.FullName.Replace($tempSrcPath, "").Replace(".java", "")}
    $classes = Get-ChildItem -Path $classpath  -Recurse  -Include *.class -Exclude '*$*' | ForEach-Object {$_.FullName.Replace($classpath, "").Replace(".class", "")}
    $srcs.Length
    $classes.Length
    $srcs.Length | Out-File -FilePath $apiBuildlogFile -Append
    $classes.Length | Out-File -FilePath $apiBuildlogFile -Append
    foreach ($src in $srcs) {
        if (!$classes.Contains($src)) {
            $src
            $src | Out-File -FilePath $apiBuildlogFile -Append
        }
    }
    Remove-Item -Path $tempSrcPath -Recurse -Force
    Remove-Variable srcs, classes, missedPaths
}
Function GitPull([string] $apiGitPath, [string] $wpfGitPath, [string] $gitBranch) {
    $originBranch = "origin/" + $gitBranch
    Set-Location -Path $apiGitPath
    git reset --hard head
    git fetch origin $gitBranch
    git checkout  $originBranch

    $originBranch = "origin/" + $gitBranch
    Set-Location -Path $wpfGitPath
    git reset --hard head
    git fetch origin $gitBranch
    git checkout  $originBranch
}

Function AddLicenses($licensePath, $destPath1, $destPath2) {
    $licenseContent = Get-Content -Path $licensePath
    $licenseContent | Out-File -FilePath $destPath1 -Append -Encoding ascii
    $licenseContent | Out-File -FilePath $destPath2 -Append -Encoding ascii
}

Function BuildWpf([string] $msBuildPath, [string] $slnPath) {
    #Invoke-Item -Path $msBuildPath 
    #$command = $msBuildPath + " " + $slnPath + ' /t:Rebuild  /M:8 /p:Configuration=Release  /fl  "/flp:FileLogger,Microsoft.Build.Engine;apiBuildlogFile=Build.log;errorsonly;Encoding=UTF-8"'
    #Invoke-Command -FilePath D:\autopub\build-wpf.ps1
    C:\"Program Files (x86)"\"Microsoft Visual Studio"\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe  $slnPath  /t:Rebuild  /M:8 /p:Configuration=Release  /fl  "/flp:FileLogger,Microsoft.Build.Engine;apiBuildlogFile=Build.log;errorsonly;Encoding=UTF-8"
}

Function PublishApi([string] $localTargetPath, [string] $remoteTargetPath, [string] $computerName, [string] $serviceName) {
    RemoveApiTarget($remoteTargetPath)

    $srcDirs = Get-ChildItem -Path $localTargetPath -Directory
    foreach ($dir in $srcDirs) {
        "拷贝目录" + $dir
        Copy-Item -Path $dir.FullName $remoteTargetPath -Recurse -Force
    }

    $service = Get-Service -ComputerName $computerName -Name $serviceName

    if ($service.CanStop -and $service.Status -eq 'Running') {
        Restart-Service -InputObject $(Get-Service -Computer $computerName -Name $serviceName)
        "服务已重启：" + $serviceName
    }
    if ($service.Status -eq 'Stopped') {
        Start-Service -InputObject $(Get-Service -Computer $computerName -Name $serviceName)
        "服务已启动：" + $serviceName
    }
}

Function PublishWpf([string]  $wpfAutoPubExePath, [string] $wpfLocalPath, [string] $wpfRemotePath, [string] $filesHasToCopyPath, [string] $excludeFilesPath) {
    $null | Out-File -FilePath  $filesHasToCopyPath  #先清空文件内容
    $remoteFiles = Get-ChildItem -Path $wpfRemotePath -Recurse -File | Where-Object -FilterScript {($_.FullName -notlike "*\Log\*") -and ($_.FullName -notlike "*\ComplicatedReportTemplate\*") -and ($_.FullName -notlike "*\TempUpdate\*")}
    $localFiles = Get-ChildItem -Path $wpfLocalPath -Recurse -File | Where-Object -FilterScript {($_.FullName -notlike "*\Log\*") -and ($_.FullName -notlike "*\ComplicatedReportTemplate\*") -and ($_.FullName -notlike "*\TempUpdate\*")}
    
    $excludeFileStrs = Get-Content -Path  $excludeFilesPath

    :outer
    foreach ($localFile in $localFiles) {
        $localFileSufix = $localFile.FullName.Replace($wpfLocalPath, "")
        foreach ($excludeFileStr in $excludeFileStrs) {
            if ($localFileSufix.Contains($excludeFileStr)) {
                continue outer
            }
        }

        $fileExist = New-Object -TypeName System.Boolean
        foreach ($remoteFile in $remoteFiles) {
            if ($remoteFile.FullName.Replace($wpfRemotePath, "").Equals($localFileSufix)) {
                $fileExist = $true
                if ($localFile.LastWriteTime -gt $remoteFile.LastWriteTime) {
                    $localFileSufix | Out-File -FilePath  $filesHasToCopyPath -Append
                }
            }
        }
        if ($fileExist -eq $false) {
            $localFileSufix | Out-File -FilePath  $filesHasToCopyPath -Append
        }
    }

    $filesHasToCopy = Get-Content -Path $filesHasToCopyPath
    foreach ($filePath in $filesHasToCopy) {
        [string] $srcPath = $wpfLocalPath + $filePath
        [string] $destPath = $wpfRemotePath + $filePath

        $dir = $destPath.Substring(0, $destPath.LastIndexOf("\"))
        if ((Test-Path $dir) -eq $false) {
            #文件夹不存在就创建
            New-Item -Path $dir -ItemType "directory"
        }

        Copy-Item -Path $srcPath $destPath -Force
        "拷贝文件到服务器：" + $filePath
    }

    Copy-Item -Path ($wpfRemotePath + "\UpdateList.xml") ($wpfLocalPath + "\UpdateList.xml") -Force
    D:\autopub\update-xml.exe ($wpfLocalPath + "\UpdateList.xml") $filesHasToCopyPath
    Copy-Item -Path ($wpfLocalPath + "\UpdateList.xml") ($wpfRemotePath + "\UpdateList.xml") -Force
}

Function AutoPub([string] $autoPubDirPath, [string] $configFileName) {
    Set-Location -Path $autoPubDirPath
    Clear-Host
    $startTime = Get-Date
    ("开始时间："+$startTime)
    $configs = Get-Content -Path $configFileName
    GitPull $configs[4] $configs[9] $configs[5]
    AddLicenses $configs[6] $configs[7] $configs[8]
    BuildWpf $configs[10] $configs[11]
    BuildApi $configs[1] $configs[0] $configs[2] $configs[3]
    PublishApi $configs[0] $configs[17] $configs[18] $configs[19]
    PublishWpf  $configs[12] $configs[13] $configs[14] $configs[15] $configs[16] 
    $endTime = Get-Date
    ("结束时间："+$endTime)
    $totalMinutes = ($endTime - $startTime).TotalMinutes
    ("共耗时：" + $totalMinutes)
    Write-Host '按任意键结束...' -NoNewline
    $null = [Console]::ReadKey('?')
}

# AutoPub D:\autopub pub-preview.config | Out-File -FilePath D:\autopub\pub-log-preview.txt
AutoPub D:\autopub pub-test.config | Out-File -FilePath D:\autopub\pub-log-test.txt
