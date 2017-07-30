
param($tempSrcPath, $libPath, $classpath, $srcFilePath)

javac -encoding "UTF-8" -sourcepath $tempSrcPath -classpath $libPath -d $classpath  $srcFilePath