
#对比两个目录的文件差异
Function DirDiff($path1, $path2) {
    $path1
    $classes = Get-ChildItem -Path $path1  -Recurse  -Name
    $classes2 = Get-ChildItem -Path $path2  -Recurse  -Name
    foreach ($c2 in $classes2) {
        if (!$classes.Contains($c2)) {
            "there's different"
            $c2            
        }
    }
}

# DirDiff \\192.168.10.186\Canyou\publish-ApiDemo\publish\WEB-INF\classes D:\autopub\source\slerp_api\target\classes
# DirDiff \\192.168.10.186\Canyou\publish-ApiPreview\publish\WEB-INF\classes D:\autopub\source\preview\slerp_api\target\classes
Clear-Host
DirDiff C:\Users\Administrator\Desktop\sldemo_ApiBuild_7_artifacts\target\classes D:\temp\classes
DirDiff D:\temp\classes C:\Users\Administrator\Desktop\sldemo_ApiBuild_7_artifacts\target\classes 


