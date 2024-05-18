# Update packages
### Install new packages
If you need to install new packages, you always need to install them inside the virtual environment. Which can be done by doing the following:

```
cd Documents/phd_1_analysis
source venv/bin/activate

python -m pip install pandas
pip freeze --local > requirements.txt

deactivate
```

Note that the 'pip freeze' command is there to create a new requirements file or update the existing one. You should do this to ensure that all other members of the team use the same version of your package.