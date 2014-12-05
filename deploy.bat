@ECHO OFF

echo Packaging game...
cd %~dp0
del bin\game.love
winrar a -afzip -ibck bin\game.love .
winrar a -afzip -ibck -r bin\game.love assets
winrar a -afzip -ibck -r bin\game.love game
winrar a -afzip -ibck -r bin\game.love lib
winrar a -afzip -ibck -r bin\game.love summon
winrar a -afzip -ibck -r bin\game.love yuishiki

echo Building windows...
copy /b platforms\windows\love.exe+bin\game.love bin\yuishiki-win.exe > nul

echo Building mac...
del bin\yuishiki-mac.zip > nul
copy bin\game.love platforms\mac\yuishiki.app\Contents\Resources > nul
winrar a -afzip -ibck -r bin\yuishiki-mac.zip platforms\mac > nul

echo Building android apk...
copy bin\game.love platforms\android\assets\  > nul
cd platforms\android
call ant -q debug > nul
cd %~dp0
copy platforms\android\bin\love_android_sdl2-debug.apk bin\yuishiki-and.apk > nul

echo Deploying android apk...
adb install -r bin\yuishiki-and.apk
