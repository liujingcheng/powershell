﻿#javac -encoding "UTF-8" -sourcepath D:\autopub\source\slerp_api\temp -classpath D:\autopub\lib\* -d D:\autopub\source\slerp_api\target\classes  D:\autopub\source\slerp_api\temp\com\canyou\CanYouConfig.java
Function RemoveApiTarget([string] $classpath) {
    $targetDirs = Get-ChildItem -Path $classpath -Directory
    foreach ($dir in $targetDirs) {
        Remove-Item -Path $dir.FullName -Recurse -Force
    }
}

Function BuildApi([string] $srcpath, [string] $classpath, [string] $libPath, [string]$logFile) {
    Remove-Item -Path $logFile -Force
    D:\autopub\rm-utf-bom\RemoveUtfBom.exe $srcpath

    $tempSrcPath = $srcpath.Replace("\src", "\temp")
    $libPath = $libPath + "\*;" + $classpath;
    $firstSrcFile = $tempSrcPath + "\com\canyou\CanYouConfig.java";
    javac -encoding "UTF-8" -sourcepath $tempSrcPath -classpath $libPath -d $classpath  $firstSrcFile

    $srcs = Get-ChildItem -Path $tempSrcPath -Recurse -Include *.java  | ForEach-Object {$_.FullName.Replace($tempSrcPath, "").Replace(".java", "")}
    $classes = Get-ChildItem -Path $classpath  -Recurse  -Include *.class -Exclude '*$*' | ForEach-Object {$_.FullName.Replace($classpath, "").Replace(".class", "")}
    $srcs.Length
    $classes.Length
    $srcs.Length | Out-File -FilePath $logFile
    $classes.Length | Out-File -FilePath $logFile -Append

    $missedPaths = New-Object -TypeName System.Collections.ArrayList
    foreach ($src in $srcs) {
        if (!$classes.Contains($src)) {
            $dirPath = $src.Substring(0, $src.LastIndexOf('\'))
            if (!$missedPaths.Contains($dirPath)) {
                $missedPaths.Add($dirPath)
                $srcFilePath = $tempSrcPath + $dirPath + "\*.java"
                $srcFilePath
                $srcFilePath | Out-File -FilePath $logFile -Append
                javac -encoding "UTF-8" -sourcepath $tempSrcPath -classpath $libPath -d $classpath  $srcFilePath
            }
        }
    }
    
    $srcs = Get-ChildItem -Path $tempSrcPath -Recurse -Include *.java  | ForEach-Object {$_.FullName.Replace($tempSrcPath, "").Replace(".java", "")}
    $classes = Get-ChildItem -Path $classpath  -Recurse  -Include *.class -Exclude '*$*' | ForEach-Object {$_.FullName.Replace($classpath, "").Replace(".class", "")}
    $srcs.Length
    $classes.Length
    $srcs.Length | Out-File -FilePath $logFile -Append
    $classes.Length | Out-File -FilePath $logFile -Append
    foreach ($src in $srcs) {
        if (!$classes.Contains($src)) {
            $src
            $src | Out-File -FilePath $logFile -Append
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
    #$command = $msBuildPath + " " + $slnPath + ' /t:Rebuild  /M:8 /p:Configuration=Release  /fl  "/flp:FileLogger,Microsoft.Build.Engine;logfile=Build.log;errorsonly;Encoding=UTF-8"'
    #Invoke-Command -FilePath D:\autopub\build-wpf.ps1
    C:\"Program Files (x86)\MSBuild"\12.0\Bin\MSBuild.exe  $slnPath  /t:Rebuild  /M:8 /p:Configuration=Release  /fl  "/flp:FileLogger,Microsoft.Build.Engine;logfile=Build.log;errorsonly;Encoding=UTF-8"
}

Function Publish([string] $ip, [string] $serviceName, [string]  $wpfAutoPubExePath, [string] $wpfLocalPath, [string] $wpfRemotePath) {
    #Restart-Service -InputObject $(Get-Service -Computer $ip -Name $serviceName)
    #D:\autopub\wpf-pub\AutoPublish-preview\AutoPublish.exe
    $remoteFiles = Get-ChildItem -Path $wpfRemotePath -Recurse
    $localFiles = Get-ChildItem -Path $wpfLocalPath -Recurse
    $remoteFileNames = $remoteFiles | ForEach-Object {$_.FullName.Replace($wpfRemotePath, "")}
    $localFileNames = $localFiles | ForEach-Object {$_.FullName.Replace($wpfLocalPath, "")}
    foreach ($localFile in $localFiles) {
        
    }
}

$configs = Get-Content -Path D:\autopub\pub.config
#GitPull $configs[4] $configs[9] $configs[5]
#AddLicenses $configs[6] $configs[7] $configs[8]
#BuildWpf $configs[10] $configs[11]
#RemoveApiTarget $configs[0]
#BuildApi $configs[1] $configs[0] $configs[2] $configs[3]
Publish 192.168.10.186 ApiPreview $configs[12] $configs[13] $configs[14]

