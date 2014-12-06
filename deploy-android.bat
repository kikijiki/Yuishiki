@ECHO OFF
cd %~dp0
echo Deploying android apk...
adb install -r bin\yuishiki-and.apk
