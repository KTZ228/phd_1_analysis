#!/usr/bin/env python3
"""Fit the Stan models in this project with CmdStanPy.

Examples
--------
Fit one model::

    python python_script/run_fit_models.py --model rw_transfer

Fit every registered model sequentially (usually prefer the SLURM array)::

    python python_script/run_fit_models.py --model all
"""

from __future__ import annotations

import argparse
import logging
import os
import pickle
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

import numpy as np


@dataclass(frozen=True)
class ModelSpec:
    stan_file: str
    data_keys: tuple[str, ...]


BASE_KEYS = ("ns", "nt", "sub_list", "choice", "cue", "outcome")
DDM_KEYS = BASE_KEYS + ("cong", "rt", "outlier", "minrt", "maxrt")

MODEL_REGISTRY: dict[str, ModelSpec] = {
    "rw_sep": ModelSpec("stan_file/rw_sep.stan", BASE_KEYS),
    "rw_transfer": ModelSpec("stan_file/rw_transfer.stan", BASE_KEYS),
    "rw_transfer_dual_lr": ModelSpec(
        "stan_file/rw_transfer_dual_lr.stan", BASE_KEYS + ("vol",)
    ),
    "vkf_bias_intercept": ModelSpec(
        "stan_file/vkf_bias_intercept.stan", BASE_KEYS + ("cong",)
    ),
    "vkf_bias_lambda": ModelSpec(
        "stan_file/vkf_bias_lambda.stan", BASE_KEYS + ("cong",)
    ),
    "vkf_bias_intercept_ddm_drift_cue": ModelSpec(
        "stan_file/vkf_bias_intercept_ddm_drift_cue.stan", DDM_KEYS
    ),
    "vkf_bias_intercept_ddm_start_cue": ModelSpec(
        "stan_file/vkf_bias_intercept_ddm_start_cue.stan", DDM_KEYS
    ),
    "vkf_bias_intercept_ddm_drift_start_cue": ModelSpec(
        "stan_file/vkf_bias_intercept_ddm_drift_start_cue.stan", DDM_KEYS
    ),
    "vkf_bias_scale": ModelSpec(
        "stan_file/vkf_bias_scale.stan", BASE_KEYS + ("cong",)
    ),
    "vkf_transfer_1": ModelSpec("stan_file/vkf_transfer_1.stan", BASE_KEYS),
    "vkf_transfer_2": ModelSpec("stan_file/vkf_transfer_2.stan", BASE_KEYS),
    "vkf_transfer_3": ModelSpec("stan_file/vkf_transfer_3.stan", BASE_KEYS),
    "vkf_transfer_4": ModelSpec("stan_file/vkf_transfer_4.stan", BASE_KEYS),
    "vkf_transfer_5": ModelSpec("stan_file/vkf_transfer_5.stan", BASE_KEYS),
}

PREDICTION_PARAMETERS: dict[str, tuple[str, ...]] = {
    "rw_sep": ("alpha", "tau", "bias0", "bias1", "ep"),
    "rw_transfer": ("alpha", "tau", "bias0", "bias1", "ep"),
    "rw_transfer_dual_lr": (
        "alpha0",
        "alpha1",
        "tau0",
        "tau1",
        "bias0",
        "bias1",
        "ep",
    ),
    "vkf_transfer_1": ("lam", "v0", "omega", "tau", "bias0", "bias1", "ep"),
    "vkf_transfer_2": ("lam", "v0", "omega", "tau", "bias0", "bias1", "ep"),
    "vkf_transfer_3": (
        "lam",
        "v0",
        "omega",
        "tau0",
        "tau1",
        "bias0",
        "bias1",
        "ep",
    ),
    "vkf_transfer_4": (
        "lam",
        "v0",
        "omega",
        "tau0",
        "tau1",
        "bias0",
        "bias1",
        "ep",
        "lr_ck",
        "w_ck",
    ),
    "vkf_transfer_5": (
        "lam",
        "v0",
        "omega",
        "tau0",
        "tau1",
        "bias0",
        "bias1",
        "ep",
        "lr_ck",
        "w_ck",
        "w_ck_v",
    ),
    "vkf_bias_intercept": (
        "lam",
        "v0",
        "omega",
        "tau0",
        "tau1",
        "bias0",
        "bias1",
        "ep",
        "lr_ck",
        "w_ck",
        "b0",
        "b1",
        "b2",
        "b3",
    ),
    "vkf_bias_scale": (
        "lam",
        "v0",
        "omega",
        "tau0",
        "tau1",
        "bias0",
        "bias1",
        "ep",
        "lr_ck",
        "w_ck",
        "b0",
        "b1",
        "b2",
        "b3",
    ),
    "vkf_bias_lambda": (
        "lam_raw",
        "v0",
        "omega",
        "tau0",
        "tau1",
        "bias0",
        "bias1",
        "ep",
        "lr_ck",
        "w_ck",
        "b1",
        "b2",
        "b3",
    ),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fit project Stan models with CmdStanPy and ArviZ."
    )
    parser.add_argument(
        "--workdir",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Project root containing stan_file/ and stan_fit.pkl.",
    )
    parser.add_argument(
        "--pkl",
        type=Path,
        default=Path("stan_fit.pkl"),
        help="Stan input pickle, relative to --workdir unless absolute.",
    )
    parser.add_argument(
        "--model",
        choices=(*MODEL_REGISTRY, "all"),
        default="rw_transfer",
        help="Model to fit, or 'all' to fit every registered model sequentially.",
    )
    parser.add_argument("--chains", type=int, default=2)
    parser.add_argument("--parallel-chains", type=int, default=2)
    parser.add_argument("--iter-warmup", type=int, default=5500)
    parser.add_argument("--iter-sampling", type=int, default=5000)
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument(
        "--outdir",
        type=Path,
        default=Path("fit_result"),
        help="Output directory, relative to --workdir unless absolute.",
    )
    parser.add_argument(
        "--clean-tmp",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Remove raw CmdStan CSV output after NetCDF, LOO, and summary are saved.",
    )
    parser.add_argument(
        "--one-step-ahead",
        action=argparse.BooleanOptionalAction,
        default=True,
        help=(
            "Replay observed trial histories with subject-level posterior-mean "
            "parameters and save one-step-ahead approach probabilities."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate paths and data contracts without compiling or sampling.",
    )
    return parser.parse_args()


def resolve_path(path: Path, workdir: Path) -> Path:
    return path.resolve() if path.is_absolute() else (workdir / path).resolve()


def load_fit_dict(path: Path, required_keys: tuple[str, ...]) -> dict[str, object]:
    with path.open("rb") as file:
        all_data = pickle.load(file)

    missing_keys = sorted(set(required_keys) - set(all_data))
    if missing_keys:
        raise KeyError(f"{path} is missing required keys: {missing_keys}")

    fit_dict = {key: all_data[key] for key in required_keys}
    nt = int(fit_dict["nt"])
    ns = int(fit_dict["ns"])

    subject_level_keys = {"minrt", "maxrt"}
    for key in required_keys:
        if key in {"ns", "nt"}:
            continue
        values = np.asarray(fit_dict[key])
        expected_size = ns if key in subject_level_keys else nt
        if values.ndim != 1 or values.size != expected_size:
            raise ValueError(
                f"{key!r} must be a one-dimensional array of length {expected_size}; "
                f"found shape {values.shape}."
            )

    sub_list = np.asarray(fit_dict["sub_list"])
    if sub_list.min() < 1 or sub_list.max() > ns:
        raise ValueError("sub_list values must be in the inclusive range [1, ns].")

    if {"rt", "outlier", "minrt", "maxrt"}.issubset(required_keys):
        rt = np.asarray(fit_dict["rt"], dtype=float)
        outlier = np.asarray(fit_dict["outlier"], dtype=int)
        minrt = np.asarray(fit_dict["minrt"], dtype=float)
        maxrt = np.asarray(fit_dict["maxrt"], dtype=float)
        if not np.isfinite(rt).all() or np.any(rt <= 0):
            raise ValueError("rt must contain finite values greater than zero.")
        if not set(np.unique(outlier)).issubset({0, 1}):
            raise ValueError("outlier must contain only 0 or 1.")
        if not np.all(minrt > 0.1) or not np.all(maxrt > minrt):
            raise ValueError(
                "Each subject-session must have 0.1 < minrt < maxrt for the DDM."
            )

    return fit_dict


def output_stem(model_name: str) -> str:
    job_id = os.environ.get("SLURM_JOB_ID")
    task_id = os.environ.get("SLURM_ARRAY_TASK_ID")
    suffix = ""
    if job_id:
        suffix = f"_{job_id}"
        if task_id:
            suffix += f"_{task_id}"
    return f"{model_name}{suffix}"


def expit(value: float) -> float:
    if value >= 0:
        return float(1 / (1 + np.exp(-value)))
    exp_value = np.exp(value)
    return float(exp_value / (1 + exp_value))


def softplus(value: float) -> float:
    return float(np.logaddexp(0.0, value))


def posterior_mean_parameters(fit: object, model_name: str) -> dict[str, np.ndarray]:
    """Return posterior means of the transformed subject-level parameters."""
    parameters: dict[str, np.ndarray] = {}
    for name in PREDICTION_PARAMETERS[model_name]:
        draws = np.asarray(fit.stan_variable(name))
        if draws.ndim != 2:
            raise ValueError(
                f"Expected posterior draws for {name!r} to have shape "
                f"(draws, subjects); found {draws.shape}."
            )
        parameters[name] = draws.mean(axis=0)
    return parameters


def replay_rw_separate(
    fit_dict: dict[str, object], parameters: dict[str, np.ndarray]
) -> np.ndarray:
    """Replay rw_sep.stan with observed choices and outcomes."""
    nt = int(fit_dict["nt"])
    probabilities = np.empty(nt)
    sub_list = np.asarray(fit_dict["sub_list"], dtype=int) - 1
    choice = np.asarray(fit_dict["choice"], dtype=int)
    cue = np.asarray(fit_dict["cue"], dtype=float)
    outcome = np.asarray(fit_dict["outcome"], dtype=float)

    q_happy = 0.5
    q_angry = 0.5
    previous_subject = -1

    for trial in range(nt):
        subject = sub_list[trial]
        if subject != previous_subject:
            q_happy = 0.5
            q_angry = 0.5
            previous_subject = subject

        q_current = q_happy if cue[trial] == 0.5 else q_angry
        probability = expit(
            parameters["tau"][subject] * (2 * q_current - 1)
            + parameters["bias0"][subject]
            + parameters["bias1"][subject] * cue[trial]
        )
        probabilities[trial] = (
            probability * (1 - parameters["ep"][subject])
            + 0.5 * parameters["ep"][subject]
        )

        reversed_outcome = (
            outcome[trial] * choice[trial]
            + (1 - outcome[trial]) * (1 - choice[trial])
        )
        if cue[trial] == 0.5:
            q_happy += parameters["alpha"][subject] * (
                reversed_outcome - q_happy
            )
        else:
            q_angry += parameters["alpha"][subject] * (
                reversed_outcome - q_angry
            )

    return probabilities


def replay_rw_transfer(
    fit_dict: dict[str, object],
    parameters: dict[str, np.ndarray],
    volatility_dependent: bool,
) -> np.ndarray:
    """Replay the single-Q transfer RW models with observed trial histories."""
    nt = int(fit_dict["nt"])
    probabilities = np.empty(nt)
    sub_list = np.asarray(fit_dict["sub_list"], dtype=int) - 1
    choice = np.asarray(fit_dict["choice"], dtype=int)
    cue = np.asarray(fit_dict["cue"], dtype=float)
    outcome = np.asarray(fit_dict["outcome"], dtype=float)
    vol = np.asarray(fit_dict["vol"], dtype=float) if volatility_dependent else None

    q_up = 0.5
    previous_subject = -1

    for trial in range(nt):
        subject = sub_list[trial]
        if subject != previous_subject:
            q_up = 0.5
            previous_subject = subject

        if volatility_dependent:
            assert vol is not None
            alpha = expit(
                parameters["alpha0"][subject]
                + parameters["alpha1"][subject] * vol[trial]
            )
            tau = softplus(
                parameters["tau0"][subject]
                + parameters["tau1"][subject] * vol[trial]
            )
        else:
            alpha = parameters["alpha"][subject]
            tau = parameters["tau"][subject]

        q_current = q_up if cue[trial] > 0 else 1 - q_up
        probability = expit(
            tau * (2 * q_current - 1)
            + parameters["bias0"][subject]
            + parameters["bias1"][subject] * cue[trial]
        )
        probabilities[trial] = (
            probability * (1 - parameters["ep"][subject])
            + 0.5 * parameters["ep"][subject]
        )

        approach_outcome = (
            outcome[trial] if choice[trial] == 1 else 1 - outcome[trial]
        )
        mapped_to_happy = approach_outcome if cue[trial] > 0 else 1 - approach_outcome
        q_up += alpha * (mapped_to_happy - q_up)

    return probabilities


def replay_vkf_shared(
    model_name: str,
    fit_dict: dict[str, object],
    parameters: dict[str, np.ndarray],
) -> np.ndarray:
    """Replay VKF models with one shared variance and volatility state."""
    nt = int(fit_dict["nt"])
    probabilities = np.empty(nt)
    sub_list = np.asarray(fit_dict["sub_list"], dtype=int) - 1
    choice = np.asarray(fit_dict["choice"], dtype=int)
    cue = np.asarray(fit_dict["cue"], dtype=float)
    outcome = np.asarray(fit_dict["outcome"], dtype=float)
    cong = np.asarray(fit_dict.get("cong"), dtype=float)

    has_choice_kernel = model_name not in {"vkf_transfer_1", "vkf_transfer_3"}
    dynamic_temperature = model_name != "vkf_transfer_1"
    uses_bias_lambda = model_name == "vkf_bias_lambda"
    uses_volatility_choice_kernel = model_name == "vkf_transfer_5"

    m_happy = 0.0
    m_angry = 0.0
    variance = 0.0
    latent_volatility = 0.0
    choice_kernel = 0.5
    previous_subject = -1

    for trial in range(nt):
        subject = sub_list[trial]
        if subject != previous_subject:
            m_happy = 0.0
            m_angry = 0.0
            variance = parameters["omega"][subject]
            latent_volatility = parameters["v0"][subject]
            choice_kernel = 0.5
            previous_subject = subject

        base_learning_rate = np.sqrt(variance + latent_volatility)
        outcome_valence = 0.5 if outcome[trial] > 0 else -0.5
        if model_name == "vkf_bias_intercept":
            learning_bias = (
                parameters["b0"][subject]
                + parameters["b1"][subject] * outcome_valence
                + parameters["b2"][subject] * cong[trial]
                + parameters["b3"][subject] * outcome_valence * cong[trial]
            )
            learning_rate = max(learning_bias + base_learning_rate, 1e-9)
        elif model_name == "vkf_bias_scale":
            learning_bias = softplus(
                parameters["b0"][subject]
                + parameters["b1"][subject] * outcome_valence
                + parameters["b2"][subject] * cong[trial]
                + parameters["b3"][subject] * outcome_valence * cong[trial]
            )
            learning_rate = learning_bias * base_learning_rate
        else:
            learning_rate = base_learning_rate

        if dynamic_temperature:
            tau = softplus(
                parameters["tau0"][subject]
                + parameters["tau1"][subject] * latent_volatility
            )
        else:
            tau = parameters["tau"][subject]

        kalman_gain = (
            (variance + latent_volatility)
            / (variance + latent_volatility + parameters["omega"][subject])
        )
        p_current = expit(m_happy if cue[trial] > 0 else m_angry)

        decision_value = (
            tau * (2 * p_current - 1)
            + parameters["bias0"][subject]
            + parameters["bias1"][subject] * cue[trial]
        )
        if has_choice_kernel:
            choice_weight = parameters["w_ck"][subject]
            if uses_volatility_choice_kernel:
                choice_weight += (
                    parameters["w_ck_v"][subject] * latent_volatility
                )
            decision_value += choice_weight * (2 * choice_kernel - 1)

        probability = expit(decision_value)
        probabilities[trial] = (
            probability * (1 - parameters["ep"][subject])
            + 0.5 * parameters["ep"][subject]
        )

        if has_choice_kernel:
            choice_kernel += parameters["lr_ck"][subject] * (
                choice[trial] - choice_kernel
            )

        reversed_outcome = (
            outcome[trial] if choice[trial] == 1 else 1 - outcome[trial]
        )
        prediction_error = reversed_outcome - p_current
        if cue[trial] > 0:
            m_happy += learning_rate * prediction_error
            m_angry -= learning_rate * prediction_error
        else:
            m_angry += learning_rate * prediction_error
            m_happy -= learning_rate * prediction_error

        new_variance = (variance + latent_volatility) * (1 - kalman_gain)
        covariance = (1 - kalman_gain) * variance
        volatility_error = (
            (learning_rate * prediction_error) ** 2
            + new_variance
            + variance
            - 2 * covariance
            - latent_volatility
        )
        if uses_bias_lambda:
            lambda_t = expit(
                parameters["lam_raw"][subject]
                + parameters["b1"][subject] * outcome_valence
                + parameters["b2"][subject] * cong[trial]
                + parameters["b3"][subject] * outcome_valence * cong[trial]
            )
        else:
            lambda_t = parameters["lam"][subject]
        latent_volatility = max(
            1e-9, latent_volatility + lambda_t * volatility_error
        )
        variance = max(1e-9, new_variance)

    return probabilities


def replay_vkf_two_channel(
    fit_dict: dict[str, object], parameters: dict[str, np.ndarray]
) -> np.ndarray:
    """Replay vkf_transfer_2.stan with separate cue-specific uncertainty."""
    nt = int(fit_dict["nt"])
    probabilities = np.empty(nt)
    sub_list = np.asarray(fit_dict["sub_list"], dtype=int) - 1
    choice = np.asarray(fit_dict["choice"], dtype=int)
    cue = np.asarray(fit_dict["cue"], dtype=float)
    outcome = np.asarray(fit_dict["outcome"], dtype=float)

    m_happy = 0.0
    m_angry = 0.0
    happy_variance = 0.0
    angry_variance = 0.0
    happy_volatility = 0.0
    angry_volatility = 0.0
    previous_subject = -1

    for trial in range(nt):
        subject = sub_list[trial]
        if subject != previous_subject:
            m_happy = 0.0
            m_angry = 0.0
            happy_variance = parameters["omega"][subject]
            angry_variance = parameters["omega"][subject]
            happy_volatility = parameters["v0"][subject]
            angry_volatility = parameters["v0"][subject]
            previous_subject = subject

        p_current = expit(m_happy if cue[trial] > 0 else m_angry)
        probability = expit(
            parameters["tau"][subject] * (2 * p_current - 1)
            + parameters["bias0"][subject]
            + parameters["bias1"][subject] * cue[trial]
        )
        probabilities[trial] = (
            probability * (1 - parameters["ep"][subject])
            + 0.5 * parameters["ep"][subject]
        )

        reversed_outcome = (
            outcome[trial] if choice[trial] == 1 else 1 - outcome[trial]
        )
        prediction_error = reversed_outcome - p_current
        happy_learning_rate = np.sqrt(happy_variance + happy_volatility)
        angry_learning_rate = np.sqrt(angry_variance + angry_volatility)

        if cue[trial] > 0:
            m_happy += happy_learning_rate * prediction_error
            m_angry -= angry_learning_rate * prediction_error
            kalman_gain = (
                (happy_variance + happy_volatility)
                / (
                    happy_variance
                    + happy_volatility
                    + parameters["omega"][subject]
                )
            )
            new_variance = (
                (happy_variance + happy_volatility) * (1 - kalman_gain)
            )
            covariance = (1 - kalman_gain) * happy_variance
            volatility_error = (
                (happy_learning_rate * prediction_error) ** 2
                + new_variance
                + happy_variance
                - 2 * covariance
                - happy_volatility
            )
            happy_volatility = max(
                1e-9,
                happy_volatility
                + parameters["lam"][subject] * volatility_error,
            )
            happy_variance = max(1e-9, new_variance)
        else:
            m_angry += angry_learning_rate * prediction_error
            m_happy -= happy_learning_rate * prediction_error
            kalman_gain = (
                (angry_variance + angry_volatility)
                / (
                    angry_variance
                    + angry_volatility
                    + parameters["omega"][subject]
                )
            )
            new_variance = (
                (angry_variance + angry_volatility) * (1 - kalman_gain)
            )
            covariance = (1 - kalman_gain) * angry_variance
            volatility_error = (
                (angry_learning_rate * prediction_error) ** 2
                + new_variance
                + angry_variance
                - 2 * covariance
                - angry_volatility
            )
            angry_volatility = max(
                1e-9,
                angry_volatility
                + parameters["lam"][subject] * volatility_error,
            )
            angry_variance = max(1e-9, new_variance)

    return probabilities


REPLAYERS: dict[
    str, Callable[[dict[str, object], dict[str, np.ndarray]], np.ndarray]
] = {
    "rw_sep": replay_rw_separate,
    "rw_transfer": lambda data, parameters: replay_rw_transfer(
        data, parameters, volatility_dependent=False
    ),
    "rw_transfer_dual_lr": lambda data, parameters: replay_rw_transfer(
        data, parameters, volatility_dependent=True
    ),
    "vkf_transfer_1": lambda data, parameters: replay_vkf_shared(
        "vkf_transfer_1", data, parameters
    ),
    "vkf_transfer_2": replay_vkf_two_channel,
    "vkf_transfer_3": lambda data, parameters: replay_vkf_shared(
        "vkf_transfer_3", data, parameters
    ),
    "vkf_transfer_4": lambda data, parameters: replay_vkf_shared(
        "vkf_transfer_4", data, parameters
    ),
    "vkf_transfer_5": lambda data, parameters: replay_vkf_shared(
        "vkf_transfer_5", data, parameters
    ),
    "vkf_bias_intercept": lambda data, parameters: replay_vkf_shared(
        "vkf_bias_intercept", data, parameters
    ),
    "vkf_bias_scale": lambda data, parameters: replay_vkf_shared(
        "vkf_bias_scale", data, parameters
    ),
    "vkf_bias_lambda": lambda data, parameters: replay_vkf_shared(
        "vkf_bias_lambda", data, parameters
    ),
}


def save_one_step_ahead_outputs(
    model_name: str,
    fit_dict: dict[str, object],
    parameters: dict[str, np.ndarray],
    outdir: Path,
    stem: str,
) -> None:
    """Save posterior-mean, one-step-ahead probabilities and a subject plot."""
    import pandas as pd

    probabilities = REPLAYERS[model_name](fit_dict, parameters)
    if probabilities.shape != (int(fit_dict["nt"]),):
        raise ValueError("One-step-ahead replay returned an invalid probability shape.")
    if not np.isfinite(probabilities).all() or np.any(
        (probabilities < 0) | (probabilities > 1)
    ):
        raise ValueError("One-step-ahead replay produced invalid probabilities.")

    trial_predictions = pd.DataFrame(
        {
            "trial_index": np.arange(1, int(fit_dict["nt"]) + 1),
            "sub_list": np.asarray(fit_dict["sub_list"], dtype=int),
            "cue": np.asarray(fit_dict["cue"], dtype=float),
            "choice": np.asarray(fit_dict["choice"], dtype=int),
            "outcome": np.asarray(fit_dict["outcome"], dtype=int),
            "p_approach": probabilities,
        }
    )
    trial_predictions["trial"] = (
        trial_predictions.groupby("sub_list").cumcount() + 1
    )
    trial_predictions["face"] = np.where(
        trial_predictions["cue"] > 0, "Happy", "Angry"
    )
    trial_path = outdir / f"{stem}_one_step_ahead.csv"
    trial_predictions.to_csv(trial_path, index=False)

    subject_predictions = (
        trial_predictions.groupby("sub_list", as_index=False)
        .agg(
            n_trials=("trial_index", "size"),
            mean_predicted_p_approach=("p_approach", "mean"),
            mean_observed_approach=("choice", "mean"),
        )
        .sort_values("sub_list")
    )
    subject_path = outdir / f"{stem}_one_step_ahead_by_subject.csv"
    subject_predictions.to_csv(subject_path, index=False)

    parameter_means = pd.DataFrame(
        {"sub_list": np.arange(1, len(next(iter(parameters.values()))) + 1), **parameters}
    )
    parameter_path = outdir / f"{stem}_posterior_mean_parameters.csv"
    parameter_means.to_csv(parameter_path, index=False)

    logging.info("Saved %s", trial_path)
    logging.info("Saved %s", subject_path)
    logging.info("Saved %s", parameter_path)

    # Keep Matplotlib cache files in the model output directory. This avoids
    # shared home-directory cache contention in parallel SLURM array jobs.
    os.environ.setdefault("MPLCONFIGDIR", str(outdir / ".matplotlib"))
    try:
        import matplotlib
        import seaborn as sns
    except ImportError as error:
        raise RuntimeError(
            "One-step-ahead CSV files were saved, but plotting requires "
            "matplotlib and seaborn in the CmdStanPy environment."
        ) from error

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    trial_means = (
        trial_predictions.groupby(["trial", "face"], as_index=False)
        .agg(
            n_subject_sessions=("sub_list", "nunique"),
            mean_predicted_p_approach=("p_approach", "mean"),
        )
        .sort_values(["face", "trial"])
    )

    sns.set_theme(style="darkgrid", context="notebook")
    figure, axis = plt.subplots(figsize=(12, 5))
    sns.lineplot(
        data=trial_means,
        x="trial",
        y="mean_predicted_p_approach",
        hue="face",
        palette={"Happy": "#d55e00", "Angry": "#0072b2"},
        errorbar=None,
        linewidth=2,
        ax=axis,
    )
    axis.set(
        title=f"{model_name}: mean one-step-ahead approach/avoid prediction",
        xlabel="Trial",
        ylabel="Mean predicted choice tendency",
        ylim=(-0.05, 1.05),
    )
    axis.set_yticks([0, 0.5, 1])
    axis.set_yticklabels(["Avoid", "0.5", "Approach"])
    axis.legend(title="Face")
    figure.tight_layout()
    plot_path = outdir / f"{stem}_one_step_ahead_by_trial.png"
    figure.savefig(plot_path, dpi=180)
    plt.close(figure)

    logging.info("Saved %s", plot_path)


def fit_one_model(
    model_name: str,
    spec: ModelSpec,
    workdir: Path,
    pkl_path: Path,
    outdir: Path,
    args: argparse.Namespace,
) -> None:
    import arviz as az
    from cmdstanpy import CmdStanModel

    stan_path = workdir / spec.stan_file
    if not stan_path.is_file():
        raise FileNotFoundError(f"Stan file not found: {stan_path}")

    fit_dict = load_fit_dict(pkl_path, spec.data_keys)
    stem = output_stem(model_name)
    raw_dir = outdir / "cmdstanpy_csv" / stem
    raw_dir.mkdir(parents=True, exist_ok=True)

    logging.info("Compiling %s", stan_path)
    model = CmdStanModel(stan_file=str(stan_path))
    logging.info(
        "Sampling %s: chains=%d, warmup=%d, sampling=%d",
        model_name,
        args.chains,
        args.iter_warmup,
        args.iter_sampling,
    )
    fit = model.sample(
        data=fit_dict,
        chains=args.chains,
        parallel_chains=args.parallel_chains,
        iter_warmup=args.iter_warmup,
        iter_sampling=args.iter_sampling,
        seed=args.seed,
        output_dir=str(raw_dir),
        show_progress=True,
        show_console=True,
    )

    if args.one_step_ahead and model_name in REPLAYERS:
        parameters = posterior_mean_parameters(fit, model_name)
        save_one_step_ahead_outputs(
            model_name=model_name,
            fit_dict=fit_dict,
            parameters=parameters,
            outdir=outdir,
            stem=stem,
        )
    elif args.one_step_ahead:
        logging.info(
            "One-step-ahead prediction is not defined for DDM model %s; skipping.",
            model_name,
        )

    idata = az.from_cmdstanpy(fit)
    netcdf_path = outdir / f"{stem}.netcdf"
    az.to_netcdf(idata, netcdf_path)
    logging.info("Saved %s", netcdf_path)

    loo = az.loo(idata, var_name="log_lik")
    loo_path = outdir / f"{stem}_loo.csv"
    loo.to_csv(loo_path)
    logging.info("Saved %s", loo_path)

    summary_path = outdir / f"{stem}_summary.csv"
    az.summary(idata).to_csv(summary_path)
    logging.info("Saved %s", summary_path)

    if args.clean_tmp:
        shutil.rmtree(raw_dir)
        logging.info("Removed raw CmdStan output %s", raw_dir)


def main() -> None:
    args = parse_args()
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    # ArviZ 0.21 emits INFO messages about optional split-out packages.
    # They are not import failures and should not clutter the SLURM error log.
    logging.getLogger("arviz").setLevel(logging.WARNING)

    workdir = args.workdir.resolve()
    pkl_path = resolve_path(args.pkl, workdir)
    outdir = resolve_path(args.outdir, workdir)
    model_names = list(MODEL_REGISTRY) if args.model == "all" else [args.model]

    if not pkl_path.is_file():
        raise FileNotFoundError(f"Stan input pickle not found: {pkl_path}")

    for model_name in model_names:
        spec = MODEL_REGISTRY[model_name]
        stan_path = workdir / spec.stan_file
        if not stan_path.is_file():
            raise FileNotFoundError(f"Stan file not found: {stan_path}")
        fit_dict = load_fit_dict(pkl_path, spec.data_keys)
        logging.info(
            "%s: %s; ns=%s, nt=%s; data keys=%s",
            model_name,
            stan_path.name,
            fit_dict["ns"],
            fit_dict["nt"],
            ", ".join(spec.data_keys),
        )

    if args.dry_run:
        logging.info("Dry run passed; no models were compiled or sampled.")
        return

    outdir.mkdir(parents=True, exist_ok=True)
    for model_name in model_names:
        fit_one_model(
            model_name,
            MODEL_REGISTRY[model_name],
            workdir,
            pkl_path,
            outdir,
            args,
        )


if __name__ == "__main__":
    main()
