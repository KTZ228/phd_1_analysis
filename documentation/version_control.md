# Version control
Python and it's packages are notorious for creating unexpected incompatibility between packages caused by updates.
For this reason, it is good coding practice to 'freeze' the version of every package you are using for each project separately.
This is done by creating a 'virtual environment'.
When a project has a virtual environment, every new member can easily download the same version of each package, preventing incompatibility issues.
This guide will explain how to install Python and the virtual environment for the project.

## Python installation
Check what version of Python is described in the venv folder since you will have to install the same version.
Simply go to the Python site and download the installer for your operating system.

Make sure to enable `add Python 3.xx.x to the path` to ensure that the system can access this version of Python.

## Managing package versions
you can use different packages to manage virtual environments for other projects.
However, since we used `venv` to create and manage the virtual environment for this project, you will have to too.

### Installing the virtual environment and its packages using pipenv
Since this is an existing project, you will have to install the packages described in the `pipfile`.

One way to do this is by navigating to the folder using the terminal command `cd ~/Documents/phd_1_analysis`.
Subsequentially, you will need to create the environment using `pipenv install --python 3.8.18`.
These steps are the same for when you create a new project or install the packages of an existing project, so you can also use this command for your own work.
* Note that if you don't specify the Python version installed in the folder, pipenv will default to the global environment.

## Opening the project with the correct interpreter

### Using PyCharm or DataSpell
Open the project first.
Then, you will need to select the interpreter manually.
Go to the interpreter menu (bottom right) and add a new interpreter.
Go to the Virtualenv panel. Select an existing environment and set the location to the path of the project ending with `phd_1_analysis/venv`.
Next, check whether the correct version of python and its packages are installed in the 'python interpreter' menu. the Python version will be listed at the top.

### Using Sublime Text
Sublime text has a lot less fuss than IDE's, so they are better suited for more experienced programmers.
Here, we will set up a build system (interpreter) for Sublime that links directly to your project.

#### Installing package control
We need this to make new build files.
In Sublime, go to: Tools > Command Palette.
Type `Install Package Control` and press enter.

#### Make build file
An example of a build file is included in the documentation folder, you need to change the location on `cmd` to your environment's Python alias.
To find the location on your pc, go to the location of your project folder: `cd Documents/python_tests` and activate your environment by typing `pipenv shell`.
This will also present the location of the activation script (for me: `/Users/kenneth.van.der.zee/.local/share/virtualenvs/python_tests-cAsClIPH/bin/activate`).
You then copy most of this to the build file but replace the word `activate` at the end with `python`.
This should result in `/Users/kenneth.van.der.zee/.local/share/virtualenvs/python_tests-cAsClIPH/bin/python`.

The filename will be used in the build menu so make sure you give it a name linked to the project.

#### Move the build file
In order for Sublime to access it, build files have to be places in the dedicated folder.
To find this folder, go to: Tools > Build System > New Build System... 
A new build file will be created that we are not going to use other than to determine the default save location of build files.

You can find this location by trying to save this file and copying the folder location to the finder/explorer (the newly created file can be closed without saving).

Move the file you changed in the previous step to that folder.

#### Select and test build file
If done correctly you should be able to select the build file in the following menu:
Tools > Build System > phd_behavioural_1_environment

Create a simple hello world function to see if the build file was adjusted correctly.
(If the build file does not show up in the build system list, it is not placed in the correct folder or the extension might be missing)

# Happy coding!

## External links
https://realpython.com/python-virtual-environments-a-primer/