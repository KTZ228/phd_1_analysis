import argparse
import os
import subprocess
import time
from pathlib import Path
import nbformat

import papermill as pm

try:
    HERE = Path(__file__).resolve().parent
except NameError:
    HERE = Path("/Volumes/kenvdzee/Documents/phd_1_analysis/analysis_behavioural/standard parameters")
REPO_ROOT = HERE.parents[1]

included_subjects_list = [48]#[39, 48, 49, 52, 53, 54, 55, 57, 58, 60, 61, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 76, 77, 78, 79, 81, 82, 83, 85, 86, 87, 94,
                          #92, 95, 96, 99, 100, 101, 102, 103, 104, 105, 106]


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

    os.environ["PYTHONPATH"] = os.pathsep.join(
        p for p in [str(REPO_ROOT), os.environ.get("PYTHONPATH", "")] if p
    )
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
                },
                cwd=notebook.parent,
                log_output=True,
                request_save_on_cell_execute=False,
            )
            status = "included"
        except pm.PapermillExecutionError as err:
            if "Participant excluded" in str(err.evalue):
                status = "excluded"
                excluded.append(subject)
            else:
                status = f"CRASHED ({err.ename}: {err.evalue})"
                crashed.append(subject)

        if executed.exists():
            nb = nbformat.read(executed, as_version=4)
            for cell in nb.cells:
                if cell.cell_type == "code":
                    cell.outputs = [
                        o for o in cell.outputs
                        if not (o.output_type == "stream" and o.get("name") == "stderr")
                    ]
            clean = executed.with_name(executed.stem + ".ipynb")
            nbformat.write(nb, clean)

            subprocess.run([
                "jupyter", "nbconvert", str(clean),
                "--to", "html", "--no-input",
                "--output", f"sub-{subject}_summary_report",
                "--output-dir", str(outdir),
            ], check=True)
            clean.unlink()
        print(f"[{i}/{len(subjects)}] sub-{subject} {status}, {time.time() - start:.0f} s")

    print(f"Done. Excluded: {excluded or 'none'}. Crashed: {crashed or 'none'}")
    return excluded, crashed


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--subjects", type=int, nargs="+", default=None)
    args, _ = parser.parse_known_args()
    render_reports(args.subjects)