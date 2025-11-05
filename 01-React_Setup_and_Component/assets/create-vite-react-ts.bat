@echo off
cls
echo This batch file will:
echo 1. Scaffold the React project.
echo 2. Change into the Project folder.
echo 3. Install dependencies.
echo 3. Attempt to open the Project in VS-Code.
echo.
echo Press to "CTRL + C" and "Y" to exit now or
pause
echo.
echo.
set /p projectName=Enter your project name: 

REM Create the Vite project and answer "no" to both prompts
echo n&echo n | npm create vite@latest %projectName% -- --template react-ts

REM Change into the project directory
cd %projectName%

REM Install dependencies
npm install && code .
