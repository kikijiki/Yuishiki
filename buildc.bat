@ECHO OFF
echo Packaging game...

set bin=bin
set tmp=%bin%\tmp

cd %~dp0
call :Clear
call :Compile
call :Archive
call :Win32
call :Win64
call :Mac
call :Android
call :Love
call :Clean
call :Dropbox
goto :End

:Clear
rmdir %bin% /S /Q > nul 2>&1
mkdir %bin% > nul 2>&1
mkdir %tmp% > nul 2>&1
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

:Win32
echo|set /p= "> Building windows 32bit..."
copy /b platforms\win32\love.exe+%bin%\game.love %bin%\yuishiki.exe > nul
winrar a -afzip -ibck -ep1 %bin%\yuishiki-win32.zip %bin%\yuishiki.exe
winrar a -afzip -ibck -r -ep1 %bin%\yuishiki-win32.zip platforms\win32\*.dll
del %bin%\yuishiki.exe > nul 2>&1
echo done
exit /B

:Win64
echo|set /p= "> Building windows 64bit..."
copy /b platforms\win64\love.exe+%bin%\game.love %bin%\yuishiki.exe > nul
winrar a -afzip -ibck -ep1 %bin%\yuishiki-win64.zip %bin%\yuishiki.exe
winrar a -afzip -ibck -r -ep1 %bin%\yuishiki-win64.zip platforms\win64\*.dll
del %bin%\yuishiki.exe > nul 2>&1
echo done
exit /B

:Mac
echo|set /p= "> Building mac..."
del %bin%\yuishiki-mac.zip > nul 2>&1
copy %bin%\game.love platforms\mac\yuishiki.app\Contents\Resources > nul
winrar a -afzip -ibck -r %bin%\yuishiki-mac.zip platforms\mac > nul
del platforms\mac\yuishiki.app\Contents\Resources\*.love > nul 2>&1
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

:Dropbox
echo|set /p= "> Updating dropbox shared folder..."
robocopy.exe bin x:\dropbox\share\ys /NFL /NDL /NJH /NJS /nc /ns /np > nul 2>&1
echo done
exit /B

:End
echo BUILD COMPLETED
