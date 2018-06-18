
#对比两个目录的文件大小差异
Function DirFileLengthDiff($path1, $path2) {
    $files1 = Get-ChildItem -Path $path1  -Recurse  -File
    $files2 = Get-ChildItem -Path $path2  -Recurse  -File

    #寻找相同文件间大小差异
    foreach ($c1 in $files1) {
        foreach ($c2 in $files2) {
           if(($c1.FullName.replace($path1,"").equals($c2.FullName.replace($path2,""))) -and ($c1.Length -ne $c2.Length)){
            "there's different"
            $c1.Length
            $c2.Length
            $c1.FullName
            $c2.FullName
           }
        }
    }
}

#对比两个目录的文件名差异
Function DirFileNameDiff($path1, $path2) {
    $fileNames1 = Get-ChildItem -Path $path1  -Recurse  -FullName
    $fileNames2 = Get-ChildItem -Path $path2  -Recurse  -FullName
    foreach ($c2 in $fileNames2) {
        if (!$fileNames1.Contains($c2)) {
            "there's different"
            $c2            
        }
    }
}

# DirDiff \\192.168.10.186\Canyou\publish-ApiDemo\publish\WEB-INF\classes D:\autopub\source\slerp_api\target\classes
# DirDiff \\192.168.10.186\Canyou\publish-ApiPreview\publish\WEB-INF\classes D:\autopub\source\preview\slerp_api\target\classes
Clear-Host
DirFileLengthDiff D:\temp\classes1 D:\temp\classes2
DirFileNameDiff D:\temp\classes1 D:\temp\classes2


