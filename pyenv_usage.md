THE FOUNDER’S GUIDE:
How to Install and Manage Multiple Python Versions on Linux
The expanded tutorial with concise explanations and screenshots

Image by Isabella and Louisa Fischer
“The condensed version of this article uses copy and paste code to help you get the outcome ASAP ⚡”

Open Terminal:
GNOME Terminal is the default terminal emulator for the Ubuntu desktop environment. It can run Bash commands, work with files, interact with other computers, and perform administrative tasks and configurations. It also features multiple tabs, user profiles, and custom startup commands.

Click “Activities” in the top-left corner
Enter “Terminal” into the search bar
Click “Terminal”

Check the Default Version:
The Version (V) option is used to check which version of Python is currently selected as the default version. It consists of three numbers separated by periods that represent the major, minor, and micro version number. It also displays an error message if Python isn’t already installed on the computer.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
python --version

Check the Executable File:
The Which command is used to identify the location of the executable file for the specified command name. It searches for the executable file in the list of directories from the PATH environment variable. It also displays the absolute path of the executable file if it exists in the one of the directories.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
which python

Open the Home Directory:
The Change Directory (cd) command is used to change the current working directory to the specified directory. It can navigate to absolute and relative paths that start from the root and current working directory, respectively. It can also navigate to paths stored in variables and environment variables.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
cd $HOME

Install Git:
Git is a program that’s used to track changes that are made to the source code over time. It can handle projects of all sizes and allows multiple teams and people to make changes to the same repository. It can also restore the source code to a previous version from the entire history of the repository.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
sudo apt-get install --yes git

Clone the Pyenv Repository:
Pyenv is a program that’s used for Python version management on macOS and Linux. It can install multiple Python versions, specify the version that’s used system-wide, and specify the version that’s used in specific directories. It can also create and manage virtual environments using specific versions.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
git clone https://github.com/pyenv/pyenv.git ~/.pyenv

Open the Bash Configuration File:
The Shell Configuration File is a script that’s automatically executed when a shell is opened by the user. It contains code that’s used to change the look of the shell, run scripts and commands, create aliases, and load environment variables. It also creates a separate configuration file for the different shells.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
gedit .bashrc

Edit the Bash Configuration File:
Bourne Again Shell (Bash) is a command-line shell and scripting language that’s used to automate administrative tasks and configure system settings. It can be used to automate practically anything in the operating system. It has also been the default shell for most Linux-based operating systems.

Copy the code from below these instructions
Paste the code into Text Editor
Click “Save”
# Pyenv environment variables
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
# Pyenv initialization
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

Restart Bash:
The Exec (e) command is used to execute the specified command that’s provided as an argument. It destroys the current process and replaces it with the specified command without creating a new process. It can also restart the shell to reload the configuration file into the environment.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
exec $SHELL

Update the Source List and Source List Directory:
The Update command is used to ensure the list of available packages is up to date. It downloads a package list from the repositories on the system which contains information about new and upgradable packages. It only updates information about the packages and doesn’t actually upgrade the packages.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
sudo apt-get update --yes

Install the Pyenv Dependencies:
The Dependency is an additional binary package that a particular binary package needs to work properly. It can require multiple dependencies to build almost any program that’s distributed by package managers. It also gets downloaded and installed automatically by some package managers.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
sudo apt-get install --yes libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libgdbm-dev lzma lzma-dev tcl-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev wget curl make build-essential python-openssl

View the Python Versions:
The List (l) flag is used to display the Python versions that are available in Pyenv. It includes final versions that are released from Python, Anaconda, PyPy, Jython, and Stackless. This includes all the major, minor, and micro versions but it doesn’t include alpha, beta, or release candidate versions.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
pyenv install --list

Install Python:
Python is an object-oriented language that’s known for its simple syntax, code readability, flexibility, and scalability. It mostly gets used to develop web and software applications. It also has become one of the most popular languages for artificial intelligence, machine learning, and data science.

Find the version from below these instructions
Copy the provided command
Paste the command into Terminal
Press “Enter”
Repeat
Python 3.5:
pyenv install 3.5.4
Python 3.6:
pyenv install 3.6.8
Python 3.7:
pyenv install 3.7.9
Python 3.8:
pyenv install 3.8.6
Python 3.9:
pyenv install 3.9.0

Set the Default Version for the Computer:
The Global command is used in Pyenv to specify the default Python version for the entire system. It creates a text file in the Pyenv directory that stores the specified version. This is used by Pyenv to activate the default version but it gets overwritten by the local Pyenv text file and environment variable.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
pyenv global 3.8.6

Create the Temporary Directory:
The Make Directory (mkdir) command is used to create new directories. It can specify one or more relative or absolute paths with the name of the new directories to be created. It can also be used with the “Parents” flag to create parent directories as needed without overwriting a path that already exists.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
mkdir temporary

Open the Temporary Directory:
The Change Directory (cd) command is used to change the current working directory to the specified directory. It can navigate to absolute and relative paths that start from the root and current working directory, respectively. It can also navigate to paths stored in variables and environment variables.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
cd temporary

Set the Default Version for the Directory:
The Local command is used in Pyenv to specify the default Python version for the current directory. It creates a text file in the current directory that stores the specified version. This is automatically detected by Pyenv which activates the Python version in the current directory and subdirectories.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
pyenv local 3.6.8

Check the Default Version:
The Version (V) option is used to check which version of Python is currently selected as the default version. It consists of three numbers separated by periods that represent the major, minor, and micro version number. It also displays an error message if Python isn’t already installed on the computer.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
python --version

Open the Parent Directory:
The Change Directory (cd) command is used to change the current working directory to the specified directory. It can navigate to absolute and relative paths that start from the root and current working directory, respectively. It can also navigate to paths stored in variables and environment variables.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
cd ..

Check the Default Version:
The Version (V) option is used to check which version of Python is currently selected as the default version. It consists of three numbers separated by periods that represent the major, minor, and micro version number. It also displays an error message if Python isn’t already installed on the computer.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
python --version

Open the Temporary Directory:
The Change Directory (cd) command is used to change the current working directory to the specified directory. It can navigate to absolute and relative paths that start from the root and current working directory, respectively. It can also navigate to paths stored in variables and environment variables.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
cd temporary

Create the Virtual Environment:
The Virtual Environment is an isolated Python installation directory that has its own interpreter, site-packages, and scripts. It mostly gets used to prevent version conflicts between dependencies from different projects. It also gets used to meet dependency requirements of different programs from GitHub.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
python -m venv venv36

Activate the Virtual Environment:
The Activate script is used to start the virtual environment. It prepends the virtual environment path to the PATH environment variable which sets the new Python interpreter and package manager as the default version. It also sets packages to install in the virtual environment installation directory.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
source ./venv36/bin/activate

Check the Default Version:
The Version (V) option is used to check which version of Python is currently selected as the default version. It consists of three numbers separated by periods that represent the major, minor, and micro version number. It also displays an error message if Python isn’t already installed on the computer.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
python --version

Check the Executable File:
The Which command is used to identify the location of the executable file for the specified command name. It searches for the executable file in the list of directories from the PATH environment variable. It also displays the absolute path of the executable file if it exists in the one of the directories.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
which python

Deactivate the Virtual Environment:
The Deactivate command is used to stop the virtual environment. It removes the virtual environment path from the PATH environment variable which sets the last Python interpreter and package manager as the default version. It also sets packages to install in the system Python installation directory.

Copy the command from below these instructions
Paste the command into Terminal
Press “Enter”
deactivate

