import argparse
import os
import subprocess
import time
from pathlib import Path
import nbformat

import papermill as pm

# FIXED: locate files from this script, not from wherever the console was started
try:
    HERE = Path(__file__).resolve().parent
except NameError:  # pasted into a console
    HERE = Path("/Volumes/kenvdzee/Documents/phd_1_analysis/analysis_behavioural/standard parameters")  # CHECK: your local path
REPO_ROOT = HERE.parents[1]

#included_subjects_list = [39, 48, 49, 52, 53, 54, 55, 57, 58, 60, 61, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 76, 77, 78, 79, 81, 82, 83, 85, 86, 87, 88, 92, 94, 95]
included_subjects_list = [52, 53]


def render_reports(subjects=None,
                   notebook=HERE / "check_inclusion.ipynb",
                   outdir="/Volumes/kenvdzee/Documents/phd_1_analysis/plots/TUS/summary_reports/"):
    """Execute the notebook per subject and save a code-free HTML report for each.

    subjects: a single ID (39), a list ([39, 48]), or None for the full list.
    Returns (excluded, crashed) lists of subject IDs.
    """
    if subjects is None:
        subjects = included_subjects_list
    elif isinstance(subjects, int):
        subjects = [subjects]

    notebook = Path(notebook)
    outdir = Path(outdir)
    executed_dir = outdir / "executed"
    executed_dir.mkdir(parents=True, exist_ok=True)

    # FIXED: the kernel papermill starts must be able to `import utils` from the repo root
    os.environ["PYTHONPATH"] = os.pathsep.join(
        p for p in [str(REPO_ROOT), os.environ.get("PYTHONPATH", "")] if p
    )
    # FIXED: force inline figures, so plots end up in the notebook and the HTML
    os.environ["MPLBACKEND"] = "module://matplotlib_inline.backend_inline"

    excluded, crashed = [], []
    for i, subject in enumerate(subjects, start=1):
        print(f"[{i}/{len(subjects)}] sub-{subject} started")
        start = time.time()
        executed = executed_dir / f"{notebook.stem}_sub-{subject}.ipynb"
        try:
            pm.execute_notebook(
                notebook, executed,
                parameters={
                    "unique_subject_ids": [subject],
                    "included_subjects_list": included_subjects_list,  # FIXED: was missing
                },  # FIXED: was list(subject)
                cwd=notebook.parent,
                log_output=True,
            )
            status = "included"
        except pm.PapermillExecutionError as err:
            # FIXED: the last cell raises on purpose for excluded participants
            if "Participant excluded" in str(err.evalue):
                status = "excluded"
                excluded.append(subject)
            else:
                status = f"CRASHED ({err.ename}: {err.evalue})"
                crashed.append(subject)

        # FIXED: drop warnings (stderr) from the HTML copy only; errors are kept
        if executed.exists():
            nb = nbformat.read(executed, as_version=4)
            for cell in nb.cells:
                if cell.cell_type == "code":
                    cell.outputs = [
                        o for o in cell.outputs
                        if not (o.output_type == "stream" and o.get("name") == "stderr")
                    ]
            clean = executed.with_name(executed.stem + "_clean.ipynb")
            nbformat.write(nb, clean)

            subprocess.run([
                "jupyter", "nbconvert", str(clean),
                "--to", "html", "--no-input",
                "--output", f"sub-{subject}_summary_report",
                "--output-dir", str(outdir),
            ], check=True)
            clean.unlink()  # remove the temporary copy
        print(f"[{i}/{len(subjects)}] sub-{subject} {status}, {time.time() - start:.0f} s")

    print(f"Done. Excluded: {excluded or 'none'}. Crashed: {crashed or 'none'}")
    return excluded, crashed


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--subjects", type=int, nargs="+", default=None)
    args, _ = parser.parse_known_args()  # FIXED: ignores PyCharm's console arguments
    render_reports(args.subjects)