@echo off
setlocal

:: Set the source directory containing the images
set "sourceDir=C:\path\to\your\images"

:: Set the destination path for the Teams background
set "destPath=%APPDATA%\Microsoft\Teams\Backgrounds\Uploads\background.jpg"

:: Count the number of image files in the source directory
for /f %%A in ('dir /b /a-d "%sourceDir%\*.jpg" ^| find /c /v ""') do set fileCount=%%A

:: Generate a random number between 1 and the number of files
set /a randomIndex=%random% %% fileCount + 1

:: Select a random file
for /f "tokens=*" %%F in ('dir /b /a-d "%sourceDir%\*.jpg"') do (
    set /a currentIndex+=1
    if %currentIndex%==%randomIndex% (
        set "randomFile=%%F"
        goto :copyFile
    )
)

:copyFile
:: Copy the selected file to the destination, overwriting if it exists
copy /y "%sourceDir%\%randomFile%" "%destPath%"

endlocal
