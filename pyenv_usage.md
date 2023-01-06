## THE FOUNDER’S GUIDE:
### How to Install and Manage Multiple Python Versions on Linux


-- Install Git:

$ sudo apt-get install --yes git

--Clone the Pyenv Repository:

$ git clone https://github.com/pyenv/pyenv.git ~/.pyenv

-- Open the Bash Configuration File:

$ gedit .bashrc

-- Edit the Bash Configuration File:

#### Copy the code from below these instructions
#### Paste the code into Text Editor
#### Click “Save”
'''
# Pyenv environment variables
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
# Pyenv initialization
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi
'''
-- Restart Bash:

$ exec $SHELL

-- Update the Source List and Source List Directory:

$ sudo apt-get update --yes

-- Install the Pyenv Dependencies:

$ sudo apt-get install --yes libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libgdbm-dev lzma lzma-dev tcl-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev wget curl make build-essential python-openssl

-- View the Python Versions:

$ pyenv install --list
'''
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
'''
-- Set the Default Version for the Computer:

$ pyenv global 3.8.6

-- Set the Default Version for the Directory:

$ pyenv local 3.6.8

-- Check the Default Version:

$ python --version


-- Create the Virtual Environment:

$ python -m venv venv36

-- Activate the Virtual Environment:

$ source ./venv36/bin/activate

-- Check the Default Version:

$ python --version

-- Check the Executable File:

$ which python

-- Deactivate the Virtual Environment:

$ deactivate

