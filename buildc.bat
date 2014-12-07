@ECHO OFF
echo Packaging game...

set bin=bin
set tmp=%bin%\tmp

cd %~dp0
call :Clear
call :Compile
call :Archive
call :Windows
call :Mac
call :Android
call :Love
call :Clean
goto :End

:Clear
rmdir %bin% /S /Q
mkdir %bin%
mkdir %tmp%
exit /B

:Compile
echo|set /p= "> Compiling with luajit..."
:: create temporary copy of the code
robocopy .        %tmp%          *.lua >nul
robocopy game     %tmp%\game     /S /E >nul
robocopy lib      %tmp%\lib      /S /E >nul
robocopy summon   %tmp%\summon   /S /E >nul
robocopy yuishiki %tmp%\yuishiki /S /E >nul

:: compile lua files (overwrites)
for /r %tmp% %%x in (*.lua) do luajit -b "%%x" "%%x"
echo done
exit /B

:Archive
echo|set /p= "> Creating game archive..."
winrar a -afzip -ibck -r %bin%\game.love assets
winrar a -afzip -ibck -r -ep1 %bin%\game.love %tmp%\*
echo done
exit /B

:Windows
echo|set /p= "> Building windows..."
copy /b platforms\windows\love.exe+%bin%\game.love %bin%\yuishiki-win.exe > nul
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

:Clean
rmdir %tmp% /S /Q
exit /B

:End
echo BUILD COMPLETED
