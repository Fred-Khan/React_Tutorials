
# :computer: React Environment Setup Guide 

Before we dive into building interactive web apps, we need to set up the development environment on your computer. 

> :information_source: React relies on **Node.js** and **npm** (Node Package Manager) to manage dependencies and run build tools.

---

## :toolbox: What You'll Be Installing

| Tool      | Purpose                                                                 |
|-----------|-------------------------------------------------------------------------|
| **Node.js** | JavaScript runtime environment that lets you run JS code outside a browser |
| **npm**     | Package manager that comes with Node.js, used to install libraries like React |

---

## :white_check_mark: Part 1: Download & Install Node.js

1. Visit the official Node.js website: [https://nodejs.org](https://nodejs.org)  
2. Download the **LTS (Long-Term Support)** version — it’s more stable and recommended for most users.  
3. Choose the installer for your operating system:  

| OS      | Installer                                                                 |
|-----------|-------------------------------------------------------------------------|
| :computer: **Windows** | `.msi` file |
| :apple: **macOS**     | `.pkg` file |
| :penguin: **Linux**     | Follow distro-specific instructions |

> :bulb: The installer includes both **Node.js and npm**.

4. Run the installer and follow the setup instructions. During installation on **Windows**, you may see a screen like below. You may accept the default setting(s).


![Node.js Setup Wizard with 
  "Automatically install the necessary tools for Node.js" checkbox](assets/Tools_for_Native_Modules.png)

#### :information_source: (Optional Information) What does this  mean and do I need it?
- **TLDR**: If your **main goal is learning React**, you can safely **leave this box unticked**.
>This option is about installing **extra developer tools** that are not part of Node.js itself. These include:
>- **Python** (used by some Node.js packages during compilation)  
>- **Visual Studio Build Tools** (C++ compilers and libraries for Windows)  
>- **Windows Package Manager (choco)** to help automate installation  
>
>---
>
>### :white_check_mark: When to Tick the Box
>- You plan to use npm packages that require **native compilation** (e.g., `bcrypt`, `sharp`, `node-sass`).  
>- You want a **ready-to-go developer setup** without troubleshooting missing tools later.  
>- You don’t already have **Python** or **Visual Studio Build Tools** installed.  
>
>
>
>### :black_square_button: When to Leave It Unticked
>- You’re a **beginner focusing only on React** (React and most front-end libraries don’t need these tools).  
>- You want a **faster, lighter installation**.  
>- You already have the required build tools installed.  
>
>---
>
>### :balance_scale: Consequences of Each Choice
>
>| Choice | What Happens | Pros | Cons |
>|--------|--------------|------|------|
>| **Tick the box** | Installs Python, Visual Studio Build Tools, and configures your system | - Future-proof setup<br>- No errors when installing native modules | - Slower install<br>- Uses more disk space<br>- Installs tools you may never use |
>| **Leave it unticked** | Installs only Node.js and npm | - Quick and simple<br>- Perfect for React beginners | - Some npm packages may fail later<br>- You’ll need to install tools manually if required |
>
>
> [More information about Chocolatey](https://www.w3tutorials.net/blog/choco-nodejs/)

---

## :mag: Part 2: Verify Installation

5. After installation, open your terminal:

- **Windows**: Command Prompt or PowerShell  
- **macOS/Linux**: Terminal  

6. Run the following commands to check Node is installed correctly:

```bash
node --version
```
>Expected output (your version may be different):
>`v20.15.1`

7. Then check npm:

```bash
npm --version
```
>Expected output (your version may be different):
>`10.8.1`



> :white_check_mark: If you see version numbers, you’re good to go!  
> :x: If not, try restarting your terminal or reinstalling Node.js.

---

## :rocket: Part 3: Install your preferred IDE / Code Editor if you not already done so.

[Visual Studio Code](https://code.visualstudio.com/) is a free, lightweight editor with great support for JavaScript and React.

![Visual Studio Code with React](assets/VS_Code_React.png)

### :information_source: Tip: How to change Default Terminal in VS Code

1. Press `F1` (or `Cmd + Shift + P` on macOS)
2. Type: `Terminal: Select Default Profile`
3. Choose your preferred shell:
   - **Command Prompt** (Windows)
   - **Git Bash** (Windows)
   - **PowerShell** (Windows)
   - **bash** (Linux)   `
   - **zsh** (macOS)

Now every **new** terminal opens in your preferred shell.

---

## :checkered_flag: **Summary Checklist**

- [x] Installed Node.js & npm
- [x] Verified node & npm working as intended
- [x] Install preferred IDE / Code Editor

---

## **Resources**

- [Node.js Docs](https://nodejs.org/docs/latest/api/documentation.html)
- [VS Code](https://code.visualstudio.com)

---

[Next](./02-Scaffold_React_App.md)