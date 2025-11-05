#!/bin/bash
clear
echo This batch file will:
echo 1. Scaffold the React project
echo 2. Install dependencies
echo 3. Launch VS Code in the project folder

# Prompt for project name
read -p "Enter your project name: " projectName

# Create Vite project and answer "no" to both prompts
echo -e "n\nn" | npm create vite@latest "$projectName" -- --template react-ts

# Navigate into the project folder
cd "$projectName" || exit

# Install dependencies
npm install

# Open in Visual Studio Code
code .
