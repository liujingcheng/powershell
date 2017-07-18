#javac -encoding "UTF-8" -sourcepath D:\autopub\source\slerp_api\temp -classpath D:\autopub\lib\* -d D:\autopub\source\slerp_api\target\classes  D:\autopub\source\slerp_api\temp\com\canyou\CanYouConfig.java
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
    $srcs.Length | Out-File -FilePath $logFile -Append
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
Function PullApi([string] $gitPath, [string] $gitBranch) {
    $originBranch = "origin/" + $gitBranch
    $gitPath
    Set-Location -Path $gitPath
    git reset --hard head
    git fetch origin $gitBranch
    git checkout  $originBranch
}

Function AddLicenses($licensePath,$destPath1,$destPath2){
    Get-Content -Path $licensePath
}

$configs = Get-Content -Path D:\autopub\pub.config
PullApi $configs[4] $configs[5]
#RemoveApiTarget $configs[0]
#BuildApi $configs[1] $configs[0] $configs[2] $configs[3]


