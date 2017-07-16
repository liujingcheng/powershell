#javac -encoding "UTF-8" -sourcepath D:\autopub\source\slerp_api\temp -classpath D:\autopub\lib\* -d D:\autopub\source\slerp_api\target\classes  D:\autopub\source\slerp_api\temp\com\canyou\CanYouConfig.java
Function RemoveApiTarget([string] $classpath) {
    $targetDirs = Get-ChildItem -Path $classpath -Directory
    foreach ($dir in $targetDirs) {
        Remove-Item -Path $dir.FullName -Recurse -Force
    }
}

Function BuildApi([string] $srcpath, [string] $classpath, [string] $libPath) {
    D:\autopub\rm-utf-bom\RemoveUtfBom.exe $srcpath

    $tempSrcPath = $srcpath.Replace("\src", "\temp")
    $libPath = $libPath + "\*;" + $classpath;
    $firstSrcFile = $tempSrcPath + "\com\canyou\CanYouConfig.java";
    javac -encoding "UTF-8" -sourcepath $tempSrcPath -classpath $libPath -d $classpath  $firstSrcFile

    $srcs = Get-ChildItem -Path $tempSrcPath -Recurse -Directory  | ForEach-Object {$_.FullName.Replace($tempSrcPath, "")}
    $classes = Get-ChildItem -Path $classpath  -Recurse  -Directory | ForEach-Object {$_.FullName.Replace($classpath, "")}

    $srcs.Length
    $classes.Length
    $counter = 0
    foreach ($src in $srcs) {
        if (!$classes.Contains($src)) {
            $counter++
            $counter
            $src
            $srcFilePath = $tempSrcPath + $src + "\*.java"
            javac -encoding "UTF-8" -sourcepath $tempSrcPath -classpath $libPath -d $classpath  $srcFilePath
        }
    }

    $srcs = Get-ChildItem -Path $tempSrcPath -Recurse -Include *.java  | ForEach-Object {$_.FullName.Replace($tempSrcPath, "").Replace(".java", "")}
    $classes = Get-ChildItem -Path $classpath  -Recurse  -Include *.class -Exclude '*$*' | ForEach-Object {$_.FullName.Replace($classpath, "").Replace(".class", "")}
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
}

RemoveApiTarget D:\autopub\source\slerp_api\target\classes
BuildApi D:\autopub\source\slerp_api\src D:\autopub\source\slerp_api\target\classes D:\autopub\lib


