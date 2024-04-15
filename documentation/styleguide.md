# Styleguide
Whenever you're working on scripts for yourself it doesn't really matter what coding style you use.
When contributing to a shared project however, it becomes much more important to keep the coding style consistent since a lack of consistency can quickly turn it into an unreadable mess.
If you have any suggestions on how to improve the coding style please let me know.

## General
- Build scripts that consist of multiple easy to understand and descriptive functions instead of one long script with your entire experiment or analysis.
- Limit the functionality of each function to only one thing.
    - If you expect to have to re-use snippets of code within a function you should turn it into its own function to increase readability and streamline the coding process.
- Use descriptive names for both your variables and functions (even if they might seem too long).
    - This greatly increases the readability of your code, making it easier for future interns/RA's to get into it.
        - The overall goal should be to make the code so easy to read that you should have to add as little comments as possible.
        - But still ensure enough comments are added so that someone not familiar with the project could still understand your function.
    - Use lower bars `_` in places where you would normally use a space.
    - Try not to use any capitals.
    - Put the type of variable at the end of a variable name.
        - Something like `isppa_map_mni_3D_matrix`.

## Issues
- If you find an issue, don't just work around it but either try to improve it so that it becomes more error prone or ask me (Kenneth) to do so.

## Python
For Python, we have adopted the widely used [pep8 style](https://realpython.com/python-pep8/#whitespace-in-expressions-and-statements).
IDE's such as PyCharm and DataSpell also give tips on how to adhere to this style.
In addition, [articles](https://realpython.com/documenting-python-code/) about documenting your code can also help you make your code easier to read for the next intern.
Lastly, if using docstrings, you should adhere to the NumPy format.