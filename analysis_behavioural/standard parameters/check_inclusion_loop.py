import subprocess
from pathlib import Path

import papermill as pm

included_subjects_list = [39, 48, 49, 52, 53, 54, 55, 57, 58, 60, 61, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 76, 77, 78, 79, 81, 82, 83, 85, 86, 87, 88, 92, 94, 95]


def render_reports(subjects=None, notebook="check_inclusion.ipynb", outdir=f'/Volumes/kenvdzee/Documents/phd_1_analysis/plots/TUS/summary_reports/'):
    """Execute the notebook per subject and save a code-free HTML report for each.

    subjects: a single ID (39), a list ([39, 48]), or None for the full list.
    Returns the list of subjects that failed.
    """
    if subjects is None:
        subjects = included_subjects_list
    elif isinstance(subjects, int):
        subjects = [subjects]

    notebook = Path(notebook)
    outdir = Path(outdir)
    executed_dir = outdir / "executed"
    executed_dir.mkdir(parents=True, exist_ok=True)

    failed = []
    for subject in subjects:
        executed = executed_dir / f"{notebook.stem}_sub-{subject}.ipynb"
        try:
            pm.execute_notebook(
                notebook, executed,
                parameters={"unique_subject_ids": list(subject)},
                cwd=notebook.parent,
            )
        except pm.PapermillExecutionError as err:
            print(f"sub-{subject} failed: {err.ename}: {err.evalue}")
            failed.append(subject)
            continue

        subprocess.run([
            "jupyter", "nbconvert", str(executed),
            "--to", "html", "--no-input",
            "--output", f"sub-{subject}_summary_report",
            "--output-dir", str(outdir),
        ], check=True)
        print(f"sub-{subject} saved")

    print(f"Done. Failed: {failed or 'none'}")
    return failed