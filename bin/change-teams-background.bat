@echo off
:: Background Image Requirements:
:: Resolution: Use images with a resolution of at least 1920 x 1080 pixels. RAMSAC.COM
:: Aspect Ratio: Maintain a 16:9 aspect ratio to prevent distortion. RAMSAC.COM
:: File Format: Acceptable formats include PNG and JPEG. PNG is recommended to avoid potential orientation issues associated with some JPEG files. HUDDLET.COM
:: File Size: Ensure the image file size is between 100 KB and 2 MB.
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
