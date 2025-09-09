import os
import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import expit
import sys
import traceback
from joblib import Parallel, delayed
import multiprocessing
import helpers
import platform

# Run with sbatch hpc_model_fit_array.sh
# sbatch Documents/phd_1_analysis/analyses_behavioural/modelling/martin_modelling/vkf_model_fitting_hpc.sh

# go three directories up from here:
root = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..', '..')
)
sys.path.insert(0, root)
import utils
from pathlib import Path

# -------- CONFIGURATION --------
if platform.system() == 'Darwin':
    BASE_DIR = r'/Volumes/project/3025011.02/raw/'
    SAVE_DIR = r'/Volumes/project/3025011.02/pre-processed/modelling'
else:
    BASE_DIR = r'/project/3025011.02/raw/'
    SAVE_DIR = r'/project/3025011.02/pre-processed/modelling'

n_random_starting_combinations = 50  # Number of random starting number combinations that will be tried
cpu_cores_to_utilise = min(64, multiprocessing.cpu_count())

# Create output directory
os.makedirs(SAVE_DIR, exist_ok=True)

# -------- FITTING FUNCTIONS --------
def load_subject_data(subject_id, session=1):
    # Ensure homogeneity in data import by using the import_functions
    df = utils.import_functions.main(
        BASE_DIR, [subject_id], [session]
    )

    # Remap variables
    df['reward'] = df['subjectively_correct'].map({
        True: 1, 'True': 1,
        False: -1, 'False': -1
    })
    df['action_code'] = df['response'].map({'down': 1, 'up': 2})
    df['stim_code'] = df['stimuli_type'].map({2: 0, 1: 1}) # happy = 0, angry = 1

    return df

def format_data(df):
    n_trials = df['trial'].nunique()
    n_cues = 2
    actions = np.zeros((n_trials, n_cues), dtype=int)
    outcomes = np.zeros((n_trials, n_cues))
    volatilities = np.empty(n_trials, dtype=object)
    for t, (_, row) in enumerate(df.iterrows()):
        c = int(row['stim_code'])
        actions[t, c] = int(row['action_code'])
        outcomes[t, c] = float(row['reward'])
        volatilities[t] = str(row['volatility'])
    return {'choice': actions, 'outcome': outcomes, 'volatility': volatilities}, n_trials

def fit_model_null(data):
    def neg_log_likelihood(params):
        try:
            ll = helpers.initialise_model_null(params, data)
            if not np.isfinite(ll):  # catch NaNs or inf
                return np.inf
            return -ll
        except Exception as e:
            print(f"⚠️ Optimization error: {e}")
            return np.inf

    bounds = [
        (-1, 1),  # q00
        (-1, 1),  # q01
        (-1, 1),  # q10
        (-1, 1),  # q11
        (-5, 4.6),  # log(beta)
        (-100, 100),  # bias
    ]

    def run_single_fit():
        init = np.random.uniform(low=[-1, -1, -1, -1, -5, -1], high=[1, 1, 1, 1, 4.6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        return result

    results = Parallel(n_jobs=cpu_cores_to_utilise)(
        delayed(run_single_fit)() for _ in range(n_random_starting_combinations)
    )
    best_result = min(results, key=lambda r: r.fun if r.success and np.isfinite(r.fun) else np.inf)
    
    return best_result.x, -best_result.fun

def fit_model_1(data):
    def neg_log_likelihood(params):
        try:
            ll = helpers.initialise_model_m1(params, data)
            if not np.isfinite(ll):  # catch NaNs or inf
                return np.inf
            return -ll
        except Exception as e:
            print(f"⚠️ Optimization error: {e}")
            return np.inf
    bounds = [
        (-5, 4.6),    # inverse temperature (beta)
        (-6, 6),   # kappa (inverse sigmoid to static learning rate)
        (-100, 100)     # bias
    ]
    
    def run_single_fit():
        init = np.random.uniform(low=[-5, -6, -1], high=[4.6, 6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        return result

    results = Parallel(n_jobs=cpu_cores_to_utilise)(
        delayed(run_single_fit)() for _ in range(n_random_starting_combinations)
    )
    best_result = min(results, key=lambda r: r.fun if r.success and np.isfinite(r.fun) else np.inf)
    
    return best_result.x, -best_result.fun



def fit_model_2(data):
    def neg_log_likelihood(params):
        try:
            ll, *_ = helpers.initialise_model_m2(params, data)
            if not np.isfinite(ll):  # catch NaNs or inf
                return np.inf
            return -ll
        except Exception as e:
            print(f"⚠️ Optimization error: {e}")
            return np.inf
    # Define bounds for the parameters
    bounds = [
        (-5, 4.6),   # beta
        (-6, 6),   # lambda
        (-6, 6),   # weight
        (-6, 6),   # kappa
        (-100, 100)     # bias
    ]
    def run_single_fit():
        init = np.random.uniform(low=[-5, -6, -6, -6, -1], high=[4.6, 6, 6, 6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        return result

    results = Parallel(n_jobs=cpu_cores_to_utilise)(
        delayed(run_single_fit)() for _ in range(n_random_starting_combinations)
    )
    best_result = min(results, key=lambda r: r.fun if r.success and np.isfinite(r.fun) else np.inf)

    return best_result.x, -best_result.fun

def fit_model_3(data):
    def neg_log_likelihood(params):
        try:
            ll, *_ = helpers.initialise_model_m3(params, data)
            if not np.isfinite(ll):
                return np.inf
            return -ll
        except Exception as e:
            print(f"⚠️ Optimization error: {e}")
            return np.inf

    bounds = [
        (-5, 4.6),    # beta
        (-6, 6),      # lambda
        (-6, 6),      # weight1
        (-6, 6),      # weight2
        (-6, 6),      # kappa
        (-100, 100)   # bias
    ]

    def run_single_fit():
        init = np.random.uniform(low=[-5, -6, -6, -6, -6, -1], high=[4.6, 6, 6, 6, 6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        return result

    results = Parallel(n_jobs=cpu_cores_to_utilise)(
        delayed(run_single_fit)() for _ in range(n_random_starting_combinations)
    )
    best_result = min(results, key=lambda r: r.fun if r.success and np.isfinite(r.fun) else np.inf)

    return best_result.x, -best_result.fun

def fit_model_4(data):
    def neg_log_likelihood(params):
        try:
            ll = helpers.initialise_model_m4(params, data)
            if not np.isfinite(ll):  # catch NaNs or inf
                return np.inf
            return -ll
        except Exception as e:
            print(f"⚠️ Optimization error: {e}")
            return np.inf
    bounds = [
        (-5, 4.6),    # inverse temperature (beta)
        (-6, 6),   # kappa for stable (inverse sigmoid to static learning rate)
        (-6, 6),   # kappa for volatile
        (-100, 100)     # bias
    ]
    def run_single_fit():
        init = np.random.uniform(low=[-5, -6, -6, -1], high=[4.6, 6, 6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        return result

    results = Parallel(n_jobs=cpu_cores_to_utilise)(
        delayed(run_single_fit)() for _ in range(n_random_starting_combinations)
    )
    best_result = min(results, key=lambda r: r.fun if r.success and np.isfinite(r.fun) else np.inf)

    return best_result.x, -best_result.fun


def fit_model_vkf_lesioned(data):
    """
    Fit the Volatile Kalman Filter model, lesioned version.

    This is the model as described in Piray & Daw (2020).
    """

    def neg_log_likelihood(params):
        try:
            # Call the VKF model
            ll, *_ = helpers.initialise_model_vkf_lesioned(params, data)
            if not np.isfinite(ll):
                return np.inf
            return -ll
        except Exception as e:
            print(f"⚠️ Optimization error: {e}")
            return np.inf

    bounds = [
        (1e-6, 10000),  # v_initial
        (0, 10000),  # Omega
        (-5, 4.6),  # log(softmax_temperature)
        (-100, 100)  # bias
    ]

    def run_single_fit():
        # Random initialization within bounds
        init = np.random.uniform(low=[1e-6, 0, -5, -1], high=[100, 100, 4.6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        return result

    # Multiple fits in parallel to avoid local minima
    results = Parallel(n_jobs=cpu_cores_to_utilise)(
        delayed(run_single_fit)() for _ in range(n_random_starting_combinations)
    )

    # Select the best result based on the lowest negative log-likelihood
    best_result = min(results, key=lambda r: r.fun if r.success and np.isfinite(r.fun) else np.inf)
    # best_result.x contains the input for the vkf_update function for the best fit
    # -best_result.fun is the log-likelihood of the best fit

    # Now run the model once more with best_result parameters to get trial-by-trial data
    loglik, k_array, m_array, w_array, w_covariance_array, v_array = helpers.initialise_model_vkf_lesioned(best_result.x, data)

    return best_result.x, -best_result.fun, k_array, m_array, w_array, w_covariance_array, v_array


def fit_model_vkf(data):
    """
    Fit the Volatile Kalman Filter model.

    This is the model as described in Piray & Daw (2020).
    """

    def neg_log_likelihood(params):
        try:
            # Call the VKF model
            ll, *_ = helpers.initialise_model_vkf(params, data)
            if not np.isfinite(ll):
                return np.inf
            return -ll
        except Exception as e:
            print(f"⚠️ Optimization error: {e}")
            return np.inf

    bounds = [
        (1e-6, 10000),  # v_initial
        (0, 10000),  # Omega
        (1e-6, 1),  # Lambda
        (-5, 4.6),  # log(softmax_temperature)
        (-100, 100)  # bias
    ]

    def run_single_fit():
        # Random initialization within bounds
        init = np.random.uniform(low=[1e-6, 0, 1e-6, -5, -1], high=[100, 100, 1, 4.6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        return result

    # Multiple fits in parallel to avoid local minima
    results = Parallel(n_jobs=cpu_cores_to_utilise)(
        delayed(run_single_fit)() for _ in range(n_random_starting_combinations)
    )

    # Select the best result based on the lowest negative log-likelihood
    best_result = min(results, key=lambda r: r.fun if r.success and np.isfinite(r.fun) else np.inf)
    # best_result.x contains the input for the vkf_update function for the best fit
    # -best_result.fun is the log-likelihood of the best fit

    # Now run the model once more with best_result parameters to get trial-by-trial data
    loglik, k_array, m_array, w_array, w_covariance_array, v_array = helpers.initialise_model_vkf(best_result.x, data)

    return best_result.x, -best_result.fun, k_array, m_array, w_array, w_covariance_array, v_array


# -------- MAIN EXECUTION --------
if __name__ == '__main__':
    subject_id = int(sys.argv[1].zfill(3))  # from SLURM array
    session = int(sys.argv[2].zfill(2))
    print(f'Trying to locate data for sub-{subject_id:03d} session-{session:02d}')
    print(f'You have {multiprocessing.cpu_count()} CPU cores available')

    try:
        df = load_subject_data(subject_id, session)
        data, n_trials = format_data(df)

        print(f"⏳ Fitting sub-{subject_id:03d} session-{session:02d}")
        params0, ll0 = fit_model_null(data)
        params1, ll1 = fit_model_1(data)
        params2, ll2 = fit_model_2(data)
        params3, ll3 = fit_model_3(data)
        params4, ll4 = fit_model_4(data)
        params_vkf_lesioned, ll_vkf_lesioned, k_array_lesioned, m_array_lesioned, w_array_lesioned, w_covariance_array_lesioned, v_array_lesioned = fit_model_vkf_lesioned(data)
        params_vkf_binary, ll_vkf_binary, k_array, m_array, w_array, w_covariance_array, v_array = fit_model_vkf(data)
        print(f"✅ Finished sub-{subject_id:03d} session-{session:02d}")
        print(data)
        result = {
            'subject': subject_id,
            'session': session,
            'trials': n_trials,
            'model0_ll': ll0,
            'model0_q_happy_pull': params0[0],  # q00
            'model0_q_happy_push': params0[1],  # q01
            'model0_q_angry_pull': params0[2],  # q10
            'model0_q_angry_push': params0[3],  # q11
            'model0_beta': np.exp(params0[4]),  # exponentiate the inverse temperature
            'model0_bias': params0[5],  # bias
            'model1_ll': ll1,
            'model1_beta': np.exp(params1[0]), # exponentiate the inverse temperature
            'model1_alpha': expit(params1[1]), # sigmoid to convert kappa to learning rate
            'model1_bias': params1[2],
            'model2_ll': ll2,
            'model2_beta': np.exp(params2[0]), # exponentiate the inverse temperature
            'model2_lambda': expit(params2[1]), # exponentiate lambda
            'model2_weight': expit(params2[2]), # exponentiate weight
            'model2_kappa': expit(params2[3]), # exponentiate kappa
            'model2_bias': params2[4], # bias
            'model3_ll': ll3,
            'model3_beta': np.exp(params3[0]),  # exponentiate the inverse temperature
            'model3_lambda': expit(params3[1]),  # exponentiate lambda  
            'model3_weight1': expit(params3[2]),  # exponentiate weight1
            'model3_weight2': expit(params3[3]),  # exponentiate weight
            'model3_kappa': expit(params3[4]),  # exponentiate kappa
            'model3_bias': params3[5],  # bias
            'model4_ll': ll4,
            'model4_beta': np.exp(params4[0]), # exponentiate the inverse temperature
            'model4_kappa1': expit(params4[1]), # sigmoid to convert kappa to learning rate
            'model4_kappa2': expit(params4[2]),
            'model4_bias': params4[3],
            'model5_ll': ll_vkf_lesioned,
            'model5_k_initial': params_vkf_lesioned[0],
            'model5_m_initial': params_vkf_lesioned[1],
            'model5_w_initial': params_vkf_lesioned[2],
            'model5_lambda': expit(params_vkf_lesioned[3]),
            'model5_beta': np.exp(params_vkf_lesioned[4]),
            'model5_bias': params_vkf_lesioned[5],
            'model6_ll': ll_vkf_binary,
            'model6_k_initial': params_vkf_binary[0],
            'model6_m_initial': params_vkf_binary[1],
            'model6_w_initial': params_vkf_binary[2],
            'model6_lambda': expit(params_vkf_binary[3]),
            'model6_beta': np.exp(params_vkf_binary[4]),
            'model6_bias': params_vkf_binary[5]
        }

        # Save model summaries to CSV
        filename_and_path = os.path.join(SAVE_DIR, 'model_fit', f'model_fit_sub-{subject_id:03d}_session-{session:02d}.csv')
        if not os.path.exists(os.path.dirname(filename_and_path)):
            os.makedirs(os.path.dirname(filename_and_path))
        pd.DataFrame([result]).to_csv(filename_and_path, index=False, sep=';')
        print(f"✅ Finished sub-{subject_id:03d} session-{session:02d} and saved to {filename_and_path}")

        # Now save the trial-by-trial estimates for the VKF model
        vkf_trial_data = []
        for trial in range(n_trials):
            # Identify which cue was active
            active_cue = np.where(data['choice'][trial] > 0)[0][0]
            # Save the trial data
            vkf_trial_data.append({
                'subject_id': subject_id,
                'session_number': session,
                'trial': trial,
                'stimuli_type': active_cue + 1,
                'learning_rate': k_array[trial + 1, active_cue] if not np.isnan(k_array[trial + 1, active_cue]) else None,
                'volatility_estimate': np.exp(v_array[trial + 1, active_cue]) if not np.isnan(v_array[trial + 1, active_cue]) else None, # Both of these include the initial value at t=0
                'q-value': m_array[trial + 1, active_cue] if not np.isnan(m_array[trial + 1, active_cue]) else None
            })

        # Save trial data to CSV
        vkf_trial_df = pd.DataFrame(vkf_trial_data)
        filename_and_path = os.path.join(SAVE_DIR, 'trial_estimates', f'trial_estimates_vkf_sub-{subject_id:03d}_session-{session:02d}.csv')
        if not os.path.exists(os.path.dirname(filename_and_path)):
            os.makedirs(os.path.dirname(filename_and_path))
        vkf_trial_df.to_csv(filename_and_path, index=False, sep=';')

    # Catch any errors during processing and log them extensively
    except Exception as e:
        # Get and format the full traceback
        exc_type, exc_value, exc_traceback = sys.exc_info()
        full_traceback = ''.join(traceback.format_exception(exc_type, exc_value, exc_traceback))

        # Get just the line number and function where error occurred
        tb_lines = traceback.format_tb(exc_traceback)
        error_location = tb_lines[-1].strip() if tb_lines else "Unknown location"

        # Enhanced error message
        error_msg = f"❌ Error processing sub-{subject_id:03d} session-{session:02d}:\n"
        error_msg += f"Error Type: {type(e).__name__}\n"
        error_msg += f"Error Message: {str(e)}\n"
        error_msg += f"Location: {error_location}\n"

        print(error_msg)
        print("Full traceback:")
        print(full_traceback)

        # Save detailed error information to file
        filename_and_path = os.path.join(SAVE_DIR, 'fitting_errors',f'model_fit_sub-{subject_id:03d}_session-{session:02d}_error.txt')
        if not os.path.exists(os.path.dirname(filename_and_path)):
            os.makedirs(os.path.dirname(filename_and_path))

        with open(filename_and_path, 'w') as f:
            f.write(f"Error processing sub-{subject_id:03d} session-{session:02d}\n")
            f.write(f"Timestamp: {pd.Timestamp.now()}\n")
            f.write(f"Error Type: {type(e).__name__}\n")
            f.write(f"Error Message: {str(e)}\n")
            f.write(f"Location: {error_location}\n\n")
            f.write("Full Traceback:\n")
            f.write(full_traceback)
            f.write(f"Script: {__file__}\n")
            
