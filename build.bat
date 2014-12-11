@ECHO OFF
echo Packaging game...

set bin=bin

cd %~dp0
call :Clear
call :Archive
call :Win32
call :Win64
call :Mac
call :Android
call :Love
goto :End

:Clear
rmdir %bin% /S /Q  > nul 2>&1
mkdir %bin%
exit /B

:Archive
echo|set /p= "> Creating game archive..."
winrar a -afzip -ibck    %bin%\game.love .
winrar a -afzip -ibck -r %bin%\game.love assets
winrar a -afzip -ibck -r %bin%\game.love game
winrar a -afzip -ibck -r %bin%\game.love lib
winrar a -afzip -ibck -r %bin%\game.love summon
winrar a -afzip -ibck -r %bin%\game.love yuishiki
echo done
exit /B

:Win32
echo|set /p= "> Building windows 32bit..."
copy /b platforms\win32\love.exe+%bin%\game.love %bin%\yuishiki.exe > nul
winrar a -afzip -ibck -ep1 %bin%\yuishiki-win32.zip %bin%\yuishiki.exe
winrar a -afzip -ibck -r -ep1 %bin%\yuishiki-win32.zip platforms\win32\*.dll
del %bin%\yuishiki.exe
echo done
exit /B

:Win64
echo|set /p= "> Building windows 64bit..."
copy /b platforms\win64\love.exe+%bin%\game.love %bin%\yuishiki.exe > nul
winrar a -afzip -ibck -ep1 %bin%\yuishiki-win64.zip %bin%\yuishiki.exe
winrar a -afzip -ibck -r -ep1 %bin%\yuishiki-win64.zip platforms\win64\*.dll
del %bin%\yuishiki.exe
echo done
exit /B

:Mac
echo|set /p= "> Building mac..."
del %bin%\yuishiki-mac.zip > nul 2>&1
copy %bin%\game.love platforms\mac\yuishiki.app\Contents\Resources > nul
winrar a -afzip -ibck -r %bin%\yuishiki-mac.zip platforms\mac > nul
echo done
exit /B

:Android
echo|set /p= "> Building android apk..."
copy %bin%\game.love platforms\android\assets\  > nul
pushd platforms\android
call ant -q debug > nul
popd
copy platforms\android\%bin%\love_android_sdl2-debug.apk %bin%\yuishiki-and.apk > nul
echo done
exit /B

:Love
echo|set /p= "> Building love package..."
move bin\game.love bin\yuishiki.love > nul
echo done
exit /B

:End
echo BUILD COMPLETED