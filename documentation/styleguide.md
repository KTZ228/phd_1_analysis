# Styleguide
Whenever you're working on scripts for yourself it doesn't really matter what coding style you use.
When contributing to a shared project however, it becomes much more important to keep the coding style consistent since it can quickly turn into a convoluted mess when every collaborator does their own thing.
If you have any suggestions on how to improve the coding style (of which there are probably a lot since I'm not a software engineer either) please let me know.

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

## Matlab
- Whenever building a function, ensure that the input arguments are checked. Like this:
```
function convert_final_to_MNI_simnibs(path_to_input_img, m2m_folder, path_to_output_img, parameters)
arguments
    path_to_input_img string
    m2m_folder string
    path_to_output_img string
    parameters struct
end
```
- Some input arguments can be changed to options if these can be left at default for some of the time. You can see a new iteration of the previous example below:
```
function convert_final_to_MNI_simnibs(path_to_input_img, m2m_folder, path_to_output_img, parameters, options)
arguments
    path_to_input_img string
    m2m_folder string
    path_to_output_img string
    parameters struct
    options.interpolation_order = 1
end
```
When calling this function, normal input arguments are fed in order while optional arguments have to be named specifically like this:
```
convert_final_to_MNI_simnibs(path_to_input_img, m2m_folder, path_to_output_img, parameters, 'interpolation_order', 0)
```

## Python
- Similarly to Matlab, you would assign each separate action to its own function.
  - Unlike matlab, a single file can contain multiple functions. The main function and 'helper' functions that should only be used in that script
  - If you need to use these 'helper' functions more often, turn it into a separate main function.

### Building a function
- Some additional parameters need to be added to ensure that the function is not run when importing it.
- This is done by defining the main function in a script.

#### Example
Below, a function is shown that accepts two input variables and prints them to the console.
```python
def print_session_info(subject_id, session_number):
    print(subject_id)
    print(session_number)
```
But when you want to import it using `from experiment import print_session_info`, python complains about 'missing 2 required positional arguments'. This is caused by python trying to run the script on import. So we want to differentiate between importing and running a script.

The way to solve this is by adding extra components to your script.
Below, we have changed the function name to `main`. This, in combination with the block at the bottom, can help python differentiate between importing and running the script.
What basically happens here is that the script checks if the name of the script and the '__main__' handle are equal. Since this is only true if the script is run but not if it is imported, `main()` will subsequently only be called when running this script explicitly.
```python
def main(subject_id, session_number):
    print(subject_id)
    print(session_number)

if __name__ == '__main__':
    main()
```
Now, the script can be run using:
```python
from experiment import print_session_info
print_session_info.main(subject_id, session_number)
```

### Checking your input
