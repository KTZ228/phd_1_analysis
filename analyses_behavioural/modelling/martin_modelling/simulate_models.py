import os
import pandas as pd
import numpy as np
from scipy.special import expit

def simulate_hybrid_speakup(lambda_, weight, kappa, beta, bias_val, df):
    np.random.seed(42)  # or any other integer
    n_trials = df.shape[0]
    nq = 2  # Number of cues
    actions = np.zeros((n_trials, nq), dtype=int)
    outcomes = np.zeros((n_trials, nq), dtype=int)
    Q = np.zeros((nq, 2))
    Apost = lambda_ * (1 - lambda_) * 2
    beta = beta
    bb = np.array([bias_val, -bias_val])
    cumulative_reward = 0.0
    output = []

    for t, row in df.iterrows():
        stim_name = row['stimuli_name']
        cue_type = 0 if "Happy" in stim_name else 1

        # Softmax action selection based on Q-values
        Q_diff = Q[cue_type, 0] - Q[cue_type, 1]
        z = beta * Q_diff + bb[cue_type]
        p_push = expit(np.clip(z, -6, 6))
        action = 1 if np.random.rand() < p_push else 2

        # Determine reward
        prob = row['probability_condition']
        reward_prob = 0.8 if (prob == 80 and action == 1) or (prob == 20 and action == 2) else 0.2
        is_reward = np.random.rand() < reward_prob
        rew = 1 if is_reward else -1

        actions[t, cue_type] = action
        outcomes[t, cue_type] = rew

        # Kalman-style update
        a = action - 1
        A = lambda_[cue_type] * Apost[cue_type]
        kalman = weight[cue_type] * A + (1 - weight[cue_type])
        delta = rew - Q[cue_type, a]
        delta = np.clip(delta, -2.0, 2.0)

        Q[cue_type, a] += kappa[cue_type] * kalman * delta
        Q[cue_type, 1 - a] -= kappa[cue_type] * kalman * delta
        Q[cue_type] = np.clip(Q[cue_type], -1.0, 1.0)
        Apost[cue_type] = A + (1 - lambda_[cue_type]) * (delta ** 2)

        # Opponent cue update
        cue_opp = cue_type ^ 1
        Q[cue_opp, a] -= kappa[cue_opp] * kalman * delta
        Q[cue_opp, 1 - a] += kappa[cue_opp] * kalman * delta
        Q[cue_opp] = np.clip(Q[cue_opp], -1.0, 1.0)

        # Reward tracking
        reward_amount = 0.1 if rew == 1 else -0.1
        cumulative_reward += reward_amount
        cumulative_reward = np.round(cumulative_reward, 1)
        response = 'up' if action == 1 else 'down'

        output.append({
            'trial': row['trial'],
            'response': response,
            'objectively_correct': (prob == 80 and response == 'up') or (prob == 20 and response == 'down'),
            'subjectively_correct': rew == 1,
            'stimuli_type': row['stimuli_type'],
            'probability_condition': prob,
            'face_type': row['face_type'],
            'stimuli_name': stim_name,
            'reward_amount': cumulative_reward
        })

    return pd.DataFrame(output)

def get_simulation_params(subject_row, model_idx):
    """ Get simulation parameters based on the model index.
    Args:
        subject_row (pd.Series): A row from the DataFrame containing model parameters.
        model_idx (int): The index of the model to simulate. Can be 1, 2, or 3.
    Returns:
        tuple: A tuple containing lambda_, weight, kappa, beta, and bias_val
    """
    if model_idx == 1:
        lambda_ = np.array([0.0, 0.0])
        weight = np.array([0.0, 0.0])
        kappa = np.array([subject_row['model1_alpha']] * 2)
        beta = subject_row['model1_beta']
        bias_val = subject_row['model1_bias']

    elif model_idx == 2:
        lambda_val = subject_row['model2_lambda']
        lambda_ = np.array([lambda_val, lambda_val])
        weight_val = subject_row['model2_weight']
        weight = np.array([weight_val, weight_val])
        kappa_val = subject_row['model2_kappa']
        kappa = np.array([kappa_val, kappa_val])
        beta = subject_row['model2_beta']
        bias_val = subject_row['model2_bias']

    elif model_idx == 3:
        lambda_val = subject_row['model3_lambda']
        lambda_ = np.array([lambda_val, lambda_val])
        weight = np.array([subject_row['model3_weight1'], subject_row['model3_weight2']])
        kappa_val = subject_row['model3_kappa']
        kappa = np.array([kappa_val, kappa_val])
        beta = subject_row['model3_beta']
        bias_val = subject_row['model3_bias']

    else:
        raise ValueError(f"Model {model_idx} not supported.")

    return lambda_, weight, kappa, beta, bias_val

# sequence_folder = r'/project/3025011.01/data/sub-16/ses-03/rl/'
# file = f"parameters_per_stimuli_sub-16_session-01.csv"
# sequence_dir = os.path.join(sequence_folder, file)

# # Load trials
# df = pd.read_csv(sequence_dir, sep=";")

# # filter first debiasing trials out of df
# df = df[~((df.index % 452 < 8))].copy()
# df.reset_index(drop=True, inplace=True)

# lambda_ = np.array([0, 0])
# weight = np.array([0, 0])
# kappa = np.array([0.99, 0.99])
# inverse_temp = -0.5
# bias_val = 0.8

# sim_df = simulate_hybrid_speakup(lambda_, weight, kappa, inverse_temp, bias_val, df=df)

# print(sim_df.to_string(index=False))

# We are reading the file with all the parameter fits from our model fitting

base_dir = r'/project/3025011.01/derivatives/rlt/analysis/' # new path for csv files
file_name = r'fit_results_all_subjects_100iter_m3.csv'  # replace with your actual file name
file_path = os.path.join(base_dir, file_name)
model_params_df = pd.read_csv(file_path, sep=",")

# we need a new root directory for the sequences
root_dir = r'/project/3025011.01/data'

# Store all the simulation results
simulated_results = []

# Loop through each subject
for _, subject_row in model_params_df.iterrows():
    subject_id = f"{int(subject_row['subject']):02d}" # Ensure subject_id is two digits

    # Build file path
    file_path = os.path.join(
        root_dir,
        f"sub-{subject_id}",
        "ses-03",
        "rl",
        f"parameters_per_stimuli_sub-{subject_id}_session-01.csv"
    )

    # Check if file exists
    if not os.path.exists(file_path):
        print(f"Missing trial file for subject {subject_id}, skipping.")
        continue

    # Load the task sequence for this subject
    df_trials = pd.read_csv(file_path, sep=";")
    df_trials = df_trials[~((df_trials.index % 452 < 8))].copy()  # filter first debiasing trials out
    df_trials.reset_index(drop=True, inplace=True)

    # Run simulation for models 1, 2, 3
    for model_idx in [1, 2, 3]:
        lambda_, weight, kappa, beta, bias_val = get_simulation_params(subject_row, model_idx)
        print(f"Simulating subject {subject_id} with model {model_idx}")
        print(f"Parameters: lambda_={lambda_}, weight={weight}, kappa={kappa}, beta={beta}, bias_val={bias_val}")
        sim_df = simulate_hybrid_speakup(lambda_, weight, kappa, beta, bias_val, df_trials)
        sim_df['subject'] = subject_id
        sim_df['model'] = model_idx

        simulated_results.append(sim_df)

# Combine all into a single DataFrame
all_simulations_df = pd.concat(simulated_results, ignore_index=True)
output_path = "/project/3025011.01/derivatives/rlt/analysis/all_model_simulations.csv"
all_simulations_df.to_csv(output_path, index=False)

# print(all_simulations_df.to_string(index=False))
