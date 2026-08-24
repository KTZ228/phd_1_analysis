import os
import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import expit
from joblib import Parallel, delayed
import multiprocessing
import helpers
import utils

# -------- CONFIGURATION --------
BASE_DIR = r'/volumes/project/3025011.02/raw/' # r'\\fileserver.dccn.nl\project\3025011.01\data' UPDATE this to the full local or mounted path
SAVE_DIR = r'/Volumes/project/3025011.02/pre-processed/modelling' # r'\\fileserver.dccn.nl\project\3025011.01\derivatives\rlt\analysis'
SUBJECTS = [5, 10, 11, 14]  # or use os.listdir(BASE_DIR) to grab all or ["01", "02", ...] for specific subjects
unique_sessions = [1]

N_REPEATS = 1000  # For the LH optimization, how many times to repeat the fitting process for each subject
UNIQUE_SUBJECT_IDS = SUBJECTS
N_JOBS = min(16, multiprocessing.cpu_count())

# Create output directory
os.makedirs(SAVE_DIR, exist_ok=True)

# -------- FITTING FUNCTIONS --------
def load_subject_data(sub_id):
    sub_dir = f"sub-{sub_id:003}"
    experiment_output_path = os.path.join(BASE_DIR, sub_dir)
    recent_results = utils.analysis_functions.list_files_with_date_and_subject_id(
        experiment_output_path, [sub_id], unique_sessions
    )
    df = utils.analysis_functions.combine_result_files(recent_results)
    df = df[~((df.index % 452 < 8)) & (df['objectively_correct'] != "Late")].copy()
    df = df[(df['response'].isin(['down', 'up'])) & df['objectively_correct'].isin(['True', 'False'])].copy()
    df['reward'] = df['subjectively_correct'].map({
        True: 1, 'True': 1,
        False: -1, 'False': -1
    })
    df['action_code'] = df['response'].map({'down': 1, 'up': 2})
    df['stim_code'] = df['stimuli_type'].map({2: 0, 1: 1}) # happy = 0, angry = 1
    # print(f"Loaded data for subject {sub_id} with {len(df)} trials.")
    df = utils.analysis_functions.check_volatility(df)
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
    return {'choice': actions, 'outcome': outcomes, 'volatility': volatilities}

def fit_model_null(data):
    def neg_log_likelihood(params):
        try:
            ll = helpers.model_null_speakup(params, data)
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

    best_result = None
    best_nll = np.inf
    for _ in range(N_REPEATS):
        init = np.random.uniform(low=[-1, -1, -1, -1, -5, -1], high=[1, 1, 1, 1, 4.6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        if result.fun < best_nll:
            best_result = result
            best_nll = result.fun
    return best_result.x, -best_result.fun

def fit_model_1(data):
    def neg_log_likelihood(params):
        try:
            ll = helpers.model_m1_speakup(params, data)
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
    best_result = None
    best_nll = np.inf
    for _ in range(N_REPEATS):
        init = np.random.uniform(low=[-5, -6, -1], high=[4.6, 6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        if result.fun < best_nll:
            best_result = result
            best_nll = result.fun
    return best_result.x, -best_result.fun



def fit_model_2(data):
    def neg_log_likelihood(params):
        try:
            ll, *_ = helpers.model_m2_speakup(params, data)
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
    # Initialize the best result and best negative log likelihood
    best_result = None
    best_nll = np.inf
    # Perform multiple random initializations to find the best fit
    for _ in range(N_REPEATS):
        init = np.random.uniform(low=[-5, -6, -6, -6, -1], high=[4.6, 6, 6, 6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        if result.fun < best_nll:
            best_result = result
            best_nll = result.fun
    return best_result.x, -best_result.fun

def fit_model_3(data):
    def neg_log_likelihood(params):
        try:
            ll, *_ = helpers.model_m3_speakup(params, data)
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

    best_result = None
    best_nll = np.inf

    for _ in range(N_REPEATS):
        init = np.random.uniform(low=[-5, -6, -6, -6, -6, -1], high=[4.6, 6, 6, 6, 6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        if result.fun < best_nll:
            best_result = result
            best_nll = result.fun

    return best_result.x, -best_result.fun

def fit_model_4(data):
    def neg_log_likelihood(params):
        try:
            ll = helpers.model_m1_speakup(params, data)
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
    best_result = None
    best_nll = np.inf
    for _ in range(N_REPEATS):
        init = np.random.uniform(low=[-5, -6, -6, -1], high=[4.6, 6, 6, 1])
        result = minimize(neg_log_likelihood, init, bounds=bounds, method='L-BFGS-B')
        if result.fun < best_nll:
            best_result = result
            best_nll = result.fun
    return best_result.x, -best_result.fun

def fit_subject(sub):
    try:
        df = load_subject_data(sub)
        data = format_data(df)	    
        print(f"⏳ Fitting subject {sub}")
        params0, ll0 = fit_model_null(data) 
        params1, ll1 = fit_model_1(data)
        params2, ll2 = fit_model_2(data)	    
        params3, ll3 = fit_model_3(data)
        params4, ll4 = fit_model_4(data)
        print(f"✅ Finished subject {sub}")
        return {
            'subject': sub,
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
            'model1_bias': params4[3],
            
        }
	
    except Exception as e:
        print(f"⚠️ Error with subject {sub}: {e}")
        return None




if __name__ == '__main__':
    results = Parallel(n_jobs=N_JOBS)(delayed(fit_subject)(sub) for sub in SUBJECTS)
    df = pd.DataFrame([r for r in results if r is not None])
    df.to_csv(os.path.join(SAVE_DIR, 'fit_results_all_subjects.csv'), index=False)
    print("✅ All fits completed and results saved.")