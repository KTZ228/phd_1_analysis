#!/usr/bin/env python3
"""
Collect first-level FEAT diagnostics across subjects, sessions, and
preprocessing variants for comparison.

For each .feat directory found under <derivdir>/sub-*/ses-*/func/, this
script extracts:
  - subject, session, preprocessing variant (suffix after ses-mriXX_)
  - degrees of freedom (stats/dof)
  - mean residual variance in the FEAT mask (stats/sigmasquareds.nii.gz)
  - mean residual variance in gray matter only (if a GM mask is provided)
  - temporal SNR of residuals in the mask (mean/SD of res4d over time)
  - per-contrast design efficiency (1 / diag((X'X)^-1 c'c)) read from
    design.mat and design.con

Output: a single CSV with one row per .feat directory.

Usage:
    python collect_feat_diagnostics.py \
        --derivdir /project/3025011.02/bids/derivatives/fsl \
        --out feat_diagnostics.csv

Optional:
    --gm-mask /path/to/MNI_GM_mask.nii.gz   # for GM-restricted residual variance
    --skip-tsnr                              # skip res4d tSNR (faster)
"""

import argparse
import csv
import os
import re
import sys
from glob import glob
from pathlib import Path

import numpy as np

try:
    import nibabel as nib
except ImportError:
    sys.exit("nibabel is required: pip install nibabel")


FEAT_RE = re.compile(r"(sub-\d+)_(ses-mri\d+)_?(.*)\.feat$")


def parse_feat_dirname(feat_path: Path):
    """Return (subject, session, variant) from a .feat directory name.

    The variant is whatever follows 'ses-mriXX_'. If nothing follows,
    variant is 'default'.
    """
    name = feat_path.name
    m = FEAT_RE.match(name)
    if not m:
        return None
    sub, ses, variant = m.group(1), m.group(2), m.group(3)
    if not variant:
        variant = "default"
    return sub, ses, variant


def read_dof(feat_dir: Path):
    dof_file = feat_dir / "stats" / "dof"
    if not dof_file.exists():
        return np.nan
    try:
        return float(dof_file.read_text().strip())
    except Exception:
        return np.nan


def mean_in_mask(img_path: Path, mask_path: Path):
    """Mean of a 3D image within a binary mask."""
    if not img_path.exists() or not mask_path.exists():
        return np.nan
    img = nib.load(str(img_path)).get_fdata()
    mask = nib.load(str(mask_path)).get_fdata() > 0
    if mask.shape != img.shape:
        return np.nan
    vals = img[mask]
    vals = vals[np.isfinite(vals)]
    if vals.size == 0:
        return np.nan
    return float(vals.mean())


def residual_tsnr(res4d_path: Path, mask_path: Path):
    """Mean over voxels of |mean(t)| / sd(t) for residuals inside mask.

    For residuals the mean should be ~0, so this is essentially
    1 / sd, scaled. We report mean(SD) instead which is more interpretable.
    Returns (mean_residual_sd, mean_abs_mean) so you can sanity-check.
    """
    if not res4d_path.exists() or not mask_path.exists():
        return np.nan, np.nan
    res = nib.load(str(res4d_path))
    mask = nib.load(str(mask_path)).get_fdata() > 0
    data = res.get_fdata()
    if data.shape[:3] != mask.shape:
        return np.nan, np.nan
    ts = data[mask]                         # voxels x time
    sd = ts.std(axis=1)
    mn = np.abs(ts.mean(axis=1))
    sd = sd[np.isfinite(sd)]
    mn = mn[np.isfinite(mn)]
    return (float(sd.mean()) if sd.size else np.nan,
            float(mn.mean()) if mn.size else np.nan)


def read_design_mat(mat_path: Path):
    """Read FSL design.mat into a numpy array."""
    if not mat_path.exists():
        return None
    rows = []
    in_matrix = False
    with mat_path.open() as f:
        for line in f:
            line = line.strip()
            if line.startswith("/Matrix"):
                in_matrix = True
                continue
            if in_matrix and line:
                try:
                    rows.append([float(x) for x in line.split()])
                except ValueError:
                    pass
    return np.array(rows) if rows else None


def read_design_con(con_path: Path):
    """Read FSL design.con. Returns (names, contrast_matrix)."""
    if not con_path.exists():
        return [], None
    names = []
    rows = []
    in_matrix = False
    with con_path.open() as f:
        for line in f:
            s = line.strip()
            if s.startswith("/ContrastName"):
                # /ContrastName1   cue>baseline
                parts = s.split(None, 1)
                names.append(parts[1] if len(parts) > 1 else "")
            elif s.startswith("/Matrix"):
                in_matrix = True
                continue
            elif in_matrix and s:
                try:
                    rows.append([float(x) for x in s.split()])
                except ValueError:
                    pass
    C = np.array(rows) if rows else None
    return names, C


def design_efficiency(X: np.ndarray, C: np.ndarray):
    """Efficiency per contrast: 1 / (c (X'X)^-1 c').

    Returns a 1D array, one value per contrast row in C.
    Higher = more efficient.
    """
    if X is None or C is None:
        return None
    try:
        XtX_inv = np.linalg.pinv(X.T @ X)
    except np.linalg.LinAlgError:
        return None
    eff = []
    for c in C:
        denom = float(c @ XtX_inv @ c.T)
        eff.append(1.0 / denom if denom > 0 else np.nan)
    return np.array(eff)


def process_feat(feat_dir: Path, gm_mask: Path = None, do_tsnr: bool = True):
    parsed = parse_feat_dirname(feat_dir)
    if parsed is None:
        return None
    sub, ses, variant = parsed

    mask = feat_dir / "mask.nii.gz"
    sigmasq = feat_dir / "stats" / "sigmasquareds.nii.gz"
    res4d = feat_dir / "stats" / "res4d.nii.gz"

    row = {
        "subject": sub,
        "session": ses,
        "variant": variant,
        "feat_dir": str(feat_dir),
        "dof": read_dof(feat_dir),
        "mean_sigmasq_mask": mean_in_mask(sigmasq, mask),
    }

    if gm_mask is not None:
        row["mean_sigmasq_gm"] = mean_in_mask(sigmasq, gm_mask)
    else:
        row["mean_sigmasq_gm"] = np.nan

    if do_tsnr:
        sd, abs_mn = residual_tsnr(res4d, mask)
        row["mean_residual_sd"] = sd
        row["mean_abs_residual_mean"] = abs_mn
    else:
        row["mean_residual_sd"] = np.nan
        row["mean_abs_residual_mean"] = np.nan

    # Design efficiency per contrast
    X = read_design_mat(feat_dir / "design.mat")
    names, C = read_design_con(feat_dir / "design.con")
    eff = design_efficiency(X, C)
    if eff is not None:
        for i, e in enumerate(eff, start=1):
            label = names[i - 1] if i - 1 < len(names) else f"con{i}"
            # sanitize label for column name
            label = re.sub(r"[^A-Za-z0-9]+", "_", label).strip("_")
            row[f"eff_{i}_{label}"] = e

    return row


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--derivdir", required=True,
                    help="Root FSL derivatives dir, e.g. /project/.../derivatives/fsl")
    ap.add_argument("--out", default="feat_diagnostics.csv",
                    help="Output CSV path")
    ap.add_argument("--gm-mask", default=None,
                    help="Optional gray matter mask in same space as FEAT outputs")
    ap.add_argument("--skip-tsnr", action="store_true",
                    help="Skip residual SD computation (faster, no res4d load)")
    args = ap.parse_args()

    derivdir = Path(args.derivdir)
    gm_mask = Path(args.gm_mask) if args.gm_mask else None

    pattern = str(derivdir / "sub-*" / "ses-*" / "func" / "*.feat")
    feat_dirs = sorted(Path(p) for p in glob(pattern))
    if not feat_dirs:
        sys.exit(f"No .feat directories found under {pattern}")

    print(f"Found {len(feat_dirs)} .feat directories")

    rows = []
    for i, fd in enumerate(feat_dirs, 1):
        print(f"[{i}/{len(feat_dirs)}] {fd.name}")
        try:
            row = process_feat(fd, gm_mask=gm_mask, do_tsnr=not args.skip_tsnr)
            if row is not None:
                rows.append(row)
        except Exception as e:
            print(f"  ! failed: {e}")

    if not rows:
        sys.exit("No rows extracted.")

    # Union of all keys (efficiency columns may differ across variants)
    all_keys = []
    seen = set()
    preferred = ["subject", "session", "variant", "feat_dir", "dof",
                 "mean_sigmasq_mask", "mean_sigmasq_gm",
                 "mean_residual_sd", "mean_abs_residual_mean"]
    for k in preferred:
        all_keys.append(k)
        seen.add(k)
    for r in rows:
        for k in r.keys():
            if k not in seen:
                all_keys.append(k)
                seen.add(k)

    with open(args.out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=all_keys)
        w.writeheader()
        for r in rows:
            w.writerow(r)

    print(f"Wrote {len(rows)} rows to {args.out}")


if __name__ == "__main__":
    main()