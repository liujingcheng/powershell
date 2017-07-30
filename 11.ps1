#对比两个目录的文件差异
Function DirDiff($path1, $path2) {
    $path1
    $classes = Get-ChildItem -Path $path1  -Recurse  -Include *.class -Exclude '*$*' -Name
    $classes2 = Get-ChildItem -Path $path2  -Recurse  -Include *.class -Exclude '*$*' -Name
    foreach ($c2 in $classes2) {
        if (!$classes.Contains($c2)) {
            $c2
            
        }
    }
}

# DirDiff \\192.168.10.186\Canyou\publish-ApiDemo\publish\WEB-INF\classes D:\autopub\source\slerp_api\target\classes
# DirDiff \\192.168.10.186\Canyou\publish-ApiPreview\publish\WEB-INF\classes D:\autopub\source\preview\slerp_api\target\classes
DirDiff \\192.168.10.186\Canyou\publish-sltest\publish\WEB-INF\classes D:\autopub\source\test\slerp_api\target\classes


