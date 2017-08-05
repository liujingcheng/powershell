
param($AutoPubDirPath, $ConfigFilePath, $OutPutFilePath, $PubType)

Function RemoveApiTarget([string] $classpath) {
    $targetDirs = Get-ChildItem -Path $classpath -Directory
    foreach ($dir in $targetDirs) {
        Remove-Item -Path $dir.FullName -Recurse
    }
}

Function BuildApi([string] $srcpath, [string] $classpath, [string] $libPath,[string] $apiBuildLogPath) {

    RemoveApiTarget($classpath)

    Copy-Item -Path $srcpath.Replace("\src", "\conf\bpmn")  $classpath -Recurse -Force

    D:\autopub\rm-utf-bom\RemoveUtfBom.exe $srcpath #去BOM头

    $tempSrcPath = $srcpath.Replace("\src", "\temp")
    $libPath = $libPath + "\*;" + $classpath;
    $firstSrcFile = $tempSrcPath + "\com\canyou\CanYouConfig.java";
    javac -encoding "UTF-8" -sourcepath $tempSrcPath -classpath $libPath -d $classpath  $firstSrcFile 

    $srcs = Get-ChildItem -Path $tempSrcPath -Recurse -Include *.java  | ForEach-Object {$_.FullName.Replace($tempSrcPath, "").Replace(".java", "")}
    $classes = Get-ChildItem -Path $classpath  -Recurse  -Include *.class -Exclude '*$*' | ForEach-Object {$_.FullName.Replace($classpath, "").Replace(".class", "")}
    
    if (($classes -eq $null) -or $classes.Length -eq 0) {
        Write-Host "没取到编绎完成的class文件"
        return
    }

    $srcs.Length
    $classes.Length

    $missedPaths = New-Object -TypeName System.Collections.ArrayList
    foreach ($src in $srcs) {
        if (!$classes.Contains($src)) {
            $dirPath = $src.Substring(0, $src.LastIndexOf('\'))
            if (!$missedPaths.Contains($dirPath)) {
                $missedPaths.Add($dirPath)
                $srcFilePath = $tempSrcPath + $dirPath + "\*.java"
                $srcFilePath
                javac -encoding "UTF-8" -sourcepath $tempSrcPath -classpath $libPath -d $classpath  $srcFilePath 
            }
        }
    }
    
    $srcs = Get-ChildItem -Path $tempSrcPath -Recurse -Include *.java  | ForEach-Object {$_.FullName.Replace($tempSrcPath, "").Replace(".java", "")}
    $classes = Get-ChildItem -Path $classpath  -Recurse  -Include *.class -Exclude '*$*' | ForEach-Object {$_.FullName.Replace($classpath, "").Replace(".class", "")}
    $srcs.Length
    $classes.Length
    foreach ($src in $srcs) {
        if (!$classes.Contains($src)) {
            $src
        }
    }
    Remove-Item -Path $tempSrcPath -Recurse -Force
    Remove-Variable srcs, classes, missedPaths
}
Function GitPullApi([string] $apiGitPath, [string] $gitBranch) {
    $originBranch = "origin/" + $gitBranch
    Set-Location -Path $apiGitPath
    git reset --hard head
    git fetch origin $gitBranch
    git checkout  $originBranch
}
Function GitPullWpf([string] $wpfGitPath, [string] $gitBranch) {
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

    & $msBuildPath  $slnPath  /t:Rebuild  /M:8 /p:Configuration=Release  /fl  "/flp:FileLogger,Microsoft.Build.Engine;apiBuildlogFile=Build.log;errorsonly;Encoding=UTF-8"
}

Function PublishApi([string] $localTargetPath, [string] $remoteTargetPath, [string] $computerName, [string] $serviceName) {

    $srcDirs = Get-ChildItem -Path $localTargetPath -Directory
    if (($srcDirs -eq $null) -or $srcDirs.Length -lt 4) {
        Write-Host "要拷贝的class文件目录数小于4，不正确"
        return
    }

    RemoveApiTarget($remoteTargetPath)
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

Function PublishWpf([string]  $wpfUpdateXmlExecPath, [string] $wpfLocalPath, [string] $wpfRemotePath, [string] $filesHasToCopyPath, [string] $excludeFilesPath) {
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
    & $wpfUpdateXmlExecPath ($wpfLocalPath + "\UpdateList.xml") $filesHasToCopyPath
    Copy-Item -Path ($wpfLocalPath + "\UpdateList.xml") ($wpfRemotePath + "\UpdateList.xml") -Force
}

Function AutoPubApi([string] $autoPubDirPath, [string] $configFileName) {
    $startTime = Get-Date
    ("开始时间：" + $startTime)

    Set-Location -Path $autoPubDirPath
    $configs = Get-Content -Path $configFileName
    GitPullApi $configs[4] $configs[5]
    BuildApi $configs[1] $configs[0] $configs[2] $configs[3] | Out-File -FilePath $configs[3]
    PublishApi $configs[0] $configs[17] $configs[18] $configs[19]
    
    $endTime = Get-Date
    ("结束时间：" + $endTime)
    $totalMinutes = ($endTime - $startTime).TotalMinutes
    ("共耗时：" + $totalMinutes)
}

Function AutoPubWpf([string] $autoPubDirPath, [string] $configFileName) {
    $startTime = Get-Date
    ("开始时间：" + $startTime)

    Set-Location -Path $autoPubDirPath
    $configs = Get-Content -Path $configFileName
    GitPullWpf $configs[9] $configs[5]
    AddLicenses $configs[6] $configs[7] $configs[8]
    BuildWpf $configs[10] $configs[11]
    PublishWpf  $configs[12] $configs[13] $configs[14] $configs[15] $configs[16] 

    $endTime = Get-Date
    ("结束时间：" + $endTime)
    $totalMinutes = ($endTime - $startTime).TotalMinutes
    ("共耗时：" + $totalMinutes)
}

if (!($PubType -eq $null) -and $PubType.Contains("api")) {
    AutoPubApi $AutoPubDirPath $ConfigFilePath | Out-File -FilePath $OutPutFilePath
}
if (!($PubType -eq $null) -and $PubType.Contains("wpf")) {
    AutoPubWpf $AutoPubDirPath $ConfigFilePath | Out-File -FilePath $OutPutFilePath
}

#AutoPubApi D:\autopub config\pub-demo.config | Out-File -FilePath D:\autopub\log\demo-api-pub-log.txt
#AutoPubWpf $AutoPubDirPath $ConfigFilePath | Out-File -FilePath $OutPutFilePath