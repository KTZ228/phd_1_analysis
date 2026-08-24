import os
import pandas as pd
import numpy as np
import re

preprocessed_model_fit_folder = f'/Volumes/project/3025011.02/pre-processed/modelling'
model_fit_pattern = re.compile(r'^model-fit_sub-\d{3}_ses-\d{2}\.csv$')

model_fit_combined = []
# Iterate through files in the folder
for file_name in os.listdir(preprocessed_model_fit_folder):
    if model_fit_pattern.match(file_name):
        path = os.path.join(preprocessed_model_fit_folder, file_name)
        model_fit = pd.read_csv(path)
        model_fit_combined.append(model_fit)

model_fit_combined = pd.concat(model_fit_combined, ignore_index=True)
print(model_fit_combined)

# Define number of trials per subject (why is this hardcoded?)
n_trials = 667

# Automatically detect models
models = [col.split('_')[0] for col in model_fit_combined.columns if '_ll' in col]
models = sorted(set(models))

# Initialize dictionaries for AIC/BIC
for model in models:
    # Count the number of parameters per model
    param_cols = [col for col in model_fit_combined.columns if col.startswith(model + '_') and col != model + '_ll']
    k = len(param_cols)

    # Get negative log-likelihoods
    ll = model_fit_combined[f'{model}_ll']
    #ll = -neg_ll  # Convert to positive log-likelihood

    # Calculate AIC and BIC
    model_fit_combined[f'{model}_AIC'] = 2 * k - 2 * ll
    model_fit_combined[f'{model}_BIC'] = k * np.log(n_trials) - 2 * ll

# Example: show AIC/BIC differences between model1 and model2
model_fit_combined['delta_AIC_model1_vs_model0'] = model_fit_combined['model1_AIC'] - model_fit_combined['model0_AIC']
model_fit_combined['delta_AIC_model2_vs_model0'] = model_fit_combined['model2_AIC'] - model_fit_combined['model0_AIC']
model_fit_combined['delta_AIC_model2_vs_model1'] = model_fit_combined['model2_AIC'] - model_fit_combined['model1_AIC']
model_fit_combined['delta_AIC_model3_vs_model0'] = model_fit_combined['model3_AIC'] - model_fit_combined['model0_AIC']
model_fit_combined['delta_AIC_model3_vs_model1'] = model_fit_combined['model3_AIC'] - model_fit_combined['model1_AIC']
model_fit_combined['delta_AIC_model3_vs_model2'] = model_fit_combined['model3_AIC'] - model_fit_combined['model2_AIC']
model_fit_combined['delta_BIC_model1_vs_model0'] = model_fit_combined['model1_BIC'] - model_fit_combined['model0_BIC']
model_fit_combined['delta_BIC_model2_vs_model0'] = model_fit_combined['model2_BIC'] - model_fit_combined['model0_BIC']
model_fit_combined['delta_BIC_model2_vs_model1'] = model_fit_combined['model2_BIC'] - model_fit_combined['model1_BIC']
model_fit_combined['delta_BIC_model3_vs_model0'] = model_fit_combined['model3_BIC'] - model_fit_combined['model0_BIC']
model_fit_combined['delta_BIC_model3_vs_model1'] = model_fit_combined['model3_BIC'] - model_fit_combined['model1_BIC']
model_fit_combined['delta_BIC_model3_vs_model2'] = model_fit_combined['model3_BIC'] - model_fit_combined['model2_BIC']

# Save or view
print(model_fit_combined[['subject'] + [col for col in model_fit_combined.columns if 'AIC' in col or 'BIC' in col]])
model_fit_combined.to_csv(f'{preprocessed_model_fit_folder}/model_fit_comparison.csv', index=False)