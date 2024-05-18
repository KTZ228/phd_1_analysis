# Version control
Python and it's packages are notorious for creating unexpected compatibility issues between one-another caused by updates.
For this reason, it is good coding practice to 'freeze' the version of every package you are using for each project.
You can keep track of this by creating a 'virtual environment'.
What makes this environment different from a simple list containing all packages and their respected versions is that every new member can easily download the same version of all packages at once just by loading the virtual environment.
This guide will explain how to install Python and the existing virtual environment for the project.

## Python installation
For this project, we are going to use Python 3.10.14. Make sure to download this exact version from the Python website.

When installing with the installer, make sure to enable `add Python 3.10.14 to the path` to ensure that every part of your computer can access this version of Python.

## Managing package versions
You can use different packages to manage virtual environments for other projects.
However, since I used `venv` to create and manage the virtual environment for this project, you will have to too.

### Installing this project's venv
To do this, you first have to make a virtual environment. The steps that you have to go through are 'create it' and 'activate it', both of which are described [here](https://realpython.com/python-virtual-environments-a-primer/) for your respective OS.
When the environment is correctly activated, you should see `venv` at the beginning of the next command line. Make sure that the environment is activated before completing the next step!!

After that, you can install all the dependencies of the project by telling pip that you want to install everything from the requirements file by typing `python3 -m pip install -r requirements.txt` for Mac and Linux or `py -m pip install -r requirements.txt` for Windows.
For some more documentation, you can check [this article](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/).

## Opening the project using PyCharm/DataSpell
I personally prefer these compared to conda or VScode since they're made purely for Python development. Radboud has licences for these products so just create an account using your uni mail.

We will need to complete some additional steps to ensure that these IDE's use the virtual environment instead of the global python install.

- Start by opening the project.
- Then, select the interpreter manually by going to the interpreter menu (bottom right) and add a new interpreter.
- Then, go to the Virtualenv panel. Select an existing environment and set the location to the path of the project ending with `phd_1_analysis/venv`.
- Next, check whether the correct version of python and its packages are installed in the 'python interpreter' menu. The Python version that is listed should be the same as the version you installed before.

# Happy coding!