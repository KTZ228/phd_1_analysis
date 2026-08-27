import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patheffects as pe
plt.style.use('seaborn-v0_8')
import os
import string
#from titlecase import titlecase


def paired_raincloud(
        df,
        columns,
        labels=None,
        ylabel_name='Label',
        plot_name=None,
        colours=None,
        hline=None,
        flip=None,
        connect_pairs=True,
        figsize=None,
        plot_title=True,
        jitter_width=0.04,
        show_mean=True,
        mean_size=80,
        save=True,
        output_dir='.',
        show=True,
        logarithmic_scale=False,
        font_scale=1.0,
):
    """
    Create a paired raincloud plot (box + half/full violin + scatter) for an
    arbitrary number of paired groups, with optional connecting lines between
    paired samples and per-group control over violin orientation.

    Parameters
    ----------
    df : pandas.DataFrame
        DataFrame containing numeric values for all groups. Rows with NaN in
        any column that participates in a connection are dropped to preserve
        sample-level pairing.
    columns : list of str or int
        Column names or positional indices to plot in order. Length determines
        the number of raincloud groups.
    labels : list of str, optional
        X-axis tick labels. If None, uses the column names.
    output_dir : str, optional
        Directory where the plot PDF will be saved.
    ylabel_name : str, optional
        Y-axis label.
    plot_name : str, optional
        Base filename (no extension). If None, joins the labels with underscores.
    colours : list of str, optional
        One colour per group. If None, uses a default palette and cycles as needed.
    hline : float, optional
        If provided, draws a horizontal dashed red reference line at this y-value.
    flip : str or list of str, optional
        Controls violin orientation per group. Per-entry options:
            'left', 'right', 'none'
        Or pass the keyword 'outward' for first-left/last-right with middles
        full. See module docstring for details.
    connect_pairs : bool or list of tuple, optional
        Controls which groups get connecting lines between paired samples.
            - True  (default): connect adjacent groups (0-1, 1-2, ..., n-2-n-1).
            - False: draw no connecting lines; each group plotted independently.
            - list of (i, j) tuples: connect only the specified group index
              pairs (0-based, referring to position in `columns`).
              Example: [(0, 1), (2, 3)] connects col 0↔1 and col 2↔3 only.
        When connections are drawn, the same edges are used to connect the
        mean dots. NaN handling: rows with NaN in any column that participates
        in a connection are dropped; columns not involved are pulled
        independently.
    figsize : tuple, optional
    plot_title : bool, optional
    jitter_width : float, optional
    show_mean : bool, optional
    mean_size : float, optional
    save, show : bool, optional
    logarithmic_scale : bool, optional

    Returns
    -------
    fig, ax : matplotlib Figure and Axes
    """
    # --- Resolve columns ------------------------------------------------------
    resolved = [df.columns[c] if isinstance(c, int) else c for c in columns]
    columns = resolved
    n_groups = len(columns)
    if n_groups < 1:
        raise ValueError("Provide at least one column.")

    # --- Labels ---------------------------------------------------------------
    if labels is None:
        labels = [str(c) for c in columns]
    if len(labels) != n_groups:
        raise ValueError("Length of `labels` must match number of columns.")

    # --- Colours --------------------------------------------------------------
    default_palette = ['#0066ff', '#ff3399', '#33cc33', '#ff9933',
                       '#9933cc', '#ffcc00', '#00cccc', '#cc3300']
    if colours is None:
        colours = [default_palette[i % len(default_palette)] for i in range(n_groups)]
    elif len(colours) != n_groups:
        raise ValueError(
            f"Provide exactly {n_groups} colours (got {len(colours)})."
        )

    # --- Flip handling --------------------------------------------------------
    valid_flip = {'left', 'right', 'none'}
    if flip is None:
        flips = ['left'] * n_groups
    elif isinstance(flip, str) and flip == 'outward':
        if n_groups == 1:
            flips = ['none']
        elif n_groups == 2:
            flips = ['left', 'right']
        else:
            flips = ['none'] * n_groups
            flips[0] = 'left'
            flips[-1] = 'right'
    elif isinstance(flip, str):
        if flip not in valid_flip:
            raise ValueError(f"flip must be one of {valid_flip} or 'outward'.")
        flips = [flip] * n_groups
    else:
        flips = list(flip)
        if len(flips) != n_groups:
            raise ValueError(
                f"`flip` list length ({len(flips)}) must match number of columns ({n_groups})."
            )
        for f in flips:
            if f not in valid_flip:
                raise ValueError(f"Each flip entry must be one of {valid_flip}.")

    # --- Resolve connect_pairs into a list of (i, j) index pairs --------------
    if connect_pairs is True:
        connection_pairs = [(i, i + 1) for i in range(n_groups - 1)]
    elif connect_pairs is False:
        connection_pairs = []
    else:
        connection_pairs = []
        for pair in connect_pairs:
            if len(pair) != 2:
                raise ValueError(
                    f"Each entry in connect_pairs must be a 2-tuple, got {pair!r}."
                )
            i, j = int(pair[0]), int(pair[1])
            if not (0 <= i < n_groups and 0 <= j < n_groups):
                raise ValueError(
                    f"Pair indices ({i}, {j}) out of range for {n_groups} groups."
                )
            if i == j:
                raise ValueError(f"Pair indices must differ, got ({i}, {j}).")
            connection_pairs.append((i, j))

    # --- Data extraction ------------------------------------------------------
    if connection_pairs:
        # Union-Find to group indices into independent connected components
        parent = {}

        def find(x):
            parent.setdefault(x, x)
            while parent[x] != x:
                x = parent[x]
            return x

        def union(a, b):
            ra, rb = find(a), find(b)
            if ra != rb:
                parent[ra] = rb

        for i, j in connection_pairs:
            union(i, j)

        components = {}
        for i in {idx for pair in connection_pairs for idx in pair}:
            components.setdefault(find(i), []).append(i)

        combined = [None] * n_groups
        for comp_indices in components.values():
            comp_cols = [columns[i] for i in comp_indices]
            comp_df = df[comp_cols].dropna()
            for i in comp_indices:
                combined[i] = comp_df[columns[i]].values

        for i, col in enumerate(columns):
            if combined[i] is None:
                combined[i] = df[col].dropna().values
        n_samples_paired = None  # no longer a single global value; see below
    else:
        combined = [df[c].dropna().values for c in columns]
        n_samples_paired = None

    # --- Figure ---------------------------------------------------------------
    if figsize is None:
        figsize = (max(5, 2 + 1.8 * n_groups), 5 if n_groups <= 2 else 6)
    fig, ax = plt.subplots(figsize=figsize)

    positions = np.arange(1, n_groups + 1, dtype=float)

    violin_offset = 0.14
    scatter_offset = 0.14
    violin_positions = []
    scatter_positions = []
    for i, f in enumerate(flips):
        p = positions[i]
        if f == 'left':
            violin_positions.append(p - violin_offset)
            scatter_positions.append(p + scatter_offset)
        elif f == 'right':
            violin_positions.append(p + violin_offset)
            scatter_positions.append(p - scatter_offset)
        else:
            violin_positions.append(p)
            scatter_positions.append(p)

    # --- Boxplots -------------------------------------------------------------
    bp = ax.boxplot(
        combined,
        patch_artist=True,
        vert=True,
        widths=0.1 if n_groups <= 2 else 0.15,
        positions=positions,
        boxprops=dict(facecolor='white', edgecolor='black'),
        capprops=dict(color='black'),
        whiskerprops=dict(color='black'),
        flierprops=dict(color='black', markeredgecolor='black', markersize=3),
        medianprops=dict(color='black'),
    )
    for patch, fc in zip(bp['boxes'], colours):
        patch.set_facecolor(fc)
        patch.set_alpha(0.6)

    # --- Violins --------------------------------------------------------------
    vp = ax.violinplot(
        combined,
        points=300,
        positions=violin_positions,
        widths=0.3,
        showmeans=False,
        showextrema=False,
        showmedians=False,
        vert=True,
    )
    for idx, body in enumerate(vp['bodies']):
        body.set_color(colours[idx])
        body.set_alpha(0.6)
        verts = body.get_paths()[0].vertices
        m = np.mean(verts[:, 0])
        if flips[idx] == 'left':
            verts[:, 0] = np.clip(verts[:, 0], -np.inf, m)
        elif flips[idx] == 'right':
            verts[:, 0] = np.clip(verts[:, 0], m, np.inf)

    # --- Scatter positions ----------------------------------------------------
    xs_all = []
    for i, base_x in enumerate(scatter_positions):
        size = len(combined[i])
        jitter = np.random.uniform(-jitter_width, jitter_width, size=size)
        xs_all.append(np.full(size, base_x) + jitter)

    # --- Connecting lines (drawn beneath scatter) -----------------------------
    if connection_pairs:
        for (i, j) in connection_pairs:
            n_pair = min(len(combined[i]), len(combined[j]))
            for k in range(n_pair):
                ax.plot(
                    [xs_all[i][k], xs_all[j][k]],
                    [combined[i][k], combined[j][k]],
                    color='grey', alpha=0.25, linewidth=0.6, zorder=1,
                )

    # --- Scatter on top -------------------------------------------------------
    scatter_size = 15 if n_groups <= 2 else 25
    for j in range(n_groups):
        ax.scatter(xs_all[j], combined[j], s=scatter_size,
                   c=colours[j], alpha=0.45, zorder=2, edgecolors='none')

    # --- Mean + SE overlay (drawn on top of everything) -----------------------
    if show_mean:
        means = np.array([np.nanmean(v) for v in combined])
        sems = np.array([
            np.nanstd(v, ddof=1) / np.sqrt(np.sum(~np.isnan(v)))
            if np.sum(~np.isnan(v)) > 1 else 0.0
            for v in combined
        ])
        mean_xs = np.array(scatter_positions)

        # Mean line(s) follow the same edges as the individual connections
        for (i, j) in connection_pairs:
            ax.plot(
                [mean_xs[i], mean_xs[j]],
                [means[i], means[j]],
                color='black', linewidth=2.0, alpha=1.0, zorder=5,
            )

        ax.errorbar(
            mean_xs, means, yerr=sems,
            fmt='none', ecolor='black',
            elinewidth=1.8, capsize=5, capthick=1.8,
            alpha=1.0, zorder=5,
        )

        ax.scatter(
            mean_xs, means,
            s=mean_size, c='white',
            edgecolors='black', linewidths=1.5,
            zorder=6,
        )

    # --- Reference line -------------------------------------------------------
    if hline is not None:
        ax.axhline(y=hline, color='r', linestyle='--')

    # --- Aesthetics -----------------------------------------------------------
    base = plt.rcParams['font.size']  # typically 10
    ax.set_xticks(positions)
    ax.set_xticklabels(labels)
    tick_fs = (8 if n_groups > 4 else base) * font_scale
    ax.tick_params(axis='x', which='major', labelsize=tick_fs)
    ax.tick_params(axis='y', which='major', labelsize=base * font_scale)
    ax.set_ylabel(ylabel_name, fontsize=base * font_scale)
    if logarithmic_scale:
        ax.set_yscale('log')
    if plot_title:
        ax.set_title(plot_name, fontsize=base * 1.2 * font_scale)
    plt.tight_layout()

    # --- Save & show ----------------------------------------------------------
    if save:
        if plot_name is None:
            plot_name = "_".join(labels)
        os.makedirs(output_dir, exist_ok=True)
        fig.savefig(os.path.join(output_dir, f"{plot_name}.pdf"))
    if show:
        plt.show()

    return fig, ax


def lineplot_se(
        df,
        x_col,
        y_col,
        subject_col,
        condition_col=None,
        conditions=None,
        labels=None,
        ylabel_name='Label',
        xlabel_name=None,
        plot_name=None,
        colours=None,
        hline=None,
        se_method='between',
        n_boot=2000,
        ci=68,
        bin_edges=None,
        n_bins=None,
        figsize=None,
        plot_title=True,
        line_width=2.0,
        band_alpha=0.25,
        show_markers=False,
        marker_size=4,
        trend=None,
        trend_width=2.5,
        trend_alpha=1.0,
        trend_colour=None,
        show_trend_stats=False,
        legend_outside=False,
        save=True,
        output_dir='.',
        show=True,
        random_state=None,
        font_scale=1.0,
):
    """
    Line plot with shaded SE band. Takes long-format (trial-level) data and
    handles the two-stage aggregation internally: collapse within subject
    first, then aggregate across subjects. This keeps the between-subject
    SE honest (no inflated n from treating trials as independent).

    Parameters
    ----------
    df : pandas.DataFrame
        Long-format dataframe. Must contain at least `x_col`, `y_col`,
        `subject_col`, and (if used) `condition_col`. Trial-level rows are
        fine — within-subject aggregation happens inside.
    x_col : str
        Column to use for the x-axis (e.g. 'trial', 'block', 'session').
    y_col : str
        Column to use for the y-axis (the dependent measure, e.g. 'win-stay').
    subject_col : str
        Column identifying subjects. Used for the two-stage aggregation.
    condition_col : str, optional
        If given, one line is drawn per unique level (e.g. 'response' to
        split win-stay by previous response). If None, a single line.
    conditions : list, optional
        Explicit order/subset of condition levels. Defaults to sorted unique.
    labels : list of str, optional
        Legend labels per condition. Defaults to str(condition).
        Title-cased via string.capwords on use.
    ylabel_name, xlabel_name : str, optional
        Axis labels. Title-cased via string.capwords on use. `xlabel_name`
        defaults to `x_col`.
    plot_name : str, optional
        Base filename (no extension) for saving, and (if `plot_title=True`)
        also the figure title (title-cased via string.capwords).
        If None, defaults to f"{y_col}_by_{x_col}".
    colours : list of str, optional
        One colour per condition. Cycles a default palette if None.
    hline : float, optional
        Horizontal dashed reference line at this y-value.
    se_method : {'between', 'within', 'bootstrap'}
        'between'   : SE of subject-level means at each x (default).
                      Standard between-subject error band.
        'within'    : Cousineau-Morey normalised within-subject SE.
                      Use when bands should reflect within-subject
                      differences (e.g. for visual comparison of two
                      conditions in a repeated-measures design).
        'bootstrap' : Percentile CI from resampling subjects with
                      replacement. Width controlled by `ci`.
    n_boot : int
        Number of bootstrap resamples. Ignored unless se_method='bootstrap'.
    ci : float
        Percentile width for bootstrap, in percent. 68 ≈ ±1 SE, 95 ≈ ±2 SE.
    bin_edges : array-like, optional
        Bin edges for x. If given, x is replaced by the midpoint of the bin
        each row falls into. Useful for noisy trial-by-trial data.
    n_bins : int, optional
        Number of equal-width bins. Alternative to `bin_edges`.
    figsize : tuple, optional
    plot_title : bool, optional
        If True (default), set the figure title from `plot_name`.
    line_width, band_alpha : aesthetics
    show_markers : bool
        Overlay markers at each x-position.
    marker_size : float
    trend : str, list of str, or None, optional
        Overlay polynomial trend(s) per condition, fit to the group mean
        trajectory. Accepts:
            - None         : no trend (default)
            - 'linear'     : linear fit (dashed)
            - 'quadratic'  : quadratic fit (dash-dot)
            - 'both'       : shortcut for ['linear', 'quadratic']
            - list, e.g. ['linear', 'quadratic']
        Trend lines are drawn above all data with a white halo for
        visibility. R² is descriptive only — for inferential trend testing
        on subject-level data, fit a mixed model with random slopes.
    trend_width, trend_alpha : aesthetics for the trend line (dashed).
    trend_colour : str, list of str, or None, optional
        Override the trend line colour. If None (default), each trend uses
        the colour of its condition. Pass a single colour string to apply
        one colour to all trend lines (e.g. 'black' for publication style),
        or a list of one colour per condition for per-condition overrides.
    show_trend_stats : bool
        If True, annotate R² (and coefficients) for each fitted trend in a
        text box in the upper-left corner of the axes.
    legend_outside : bool
        If True, place the legend to the right of the axes (publication
        style). Save uses bbox_inches='tight' so it isn't clipped.
    save, show, output_dir : output control
    random_state : int, optional
        Seed for bootstrap reproducibility.

    Returns
    -------
    fig, ax : matplotlib Figure and Axes
    """
    # --- Validate ------------------------------------------------------------
    valid_se = {'between', 'within', 'bootstrap'}
    if se_method not in valid_se:
        raise ValueError(f"se_method must be one of {valid_se}.")

    valid_trends = {'linear': 1, 'quadratic': 2}
    # Normalise `trend` to a list of (name, degree) pairs in fit order.
    if trend is None:
        trend_specs = []
    elif trend == 'both':
        trend_specs = [('linear', 1), ('quadratic', 2)]
    elif isinstance(trend, str):
        if trend not in valid_trends:
            raise ValueError(
                f"trend must be one of {set(valid_trends)}, 'both', a list, or None."
            )
        trend_specs = [(trend, valid_trends[trend])]
    else:
        trend_specs = []
        for t in trend:
            if t not in valid_trends:
                raise ValueError(
                    f"Each trend entry must be one of {set(valid_trends)}, got {t!r}."
                )
            trend_specs.append((t, valid_trends[t]))

    # Linestyle per polynomial degree.
    trend_linestyles = {1: '--', 2: '-.'}

    needed = [x_col, y_col, subject_col]
    if condition_col is not None:
        needed.append(condition_col)
    missing = [c for c in needed if c not in df.columns]
    if missing:
        raise KeyError(f"Missing columns in df: {missing}")

    data = df[needed].dropna(subset=[x_col, y_col, subject_col]).copy()

    # --- Optional binning of x -----------------------------------------------
    if bin_edges is not None and n_bins is not None:
        raise ValueError("Pass either `bin_edges` or `n_bins`, not both.")
    if n_bins is not None:
        bin_edges = np.linspace(data[x_col].min(), data[x_col].max(), n_bins + 1)
    if bin_edges is not None:
        edges = np.asarray(bin_edges, dtype=float)
        mids = 0.5 * (edges[:-1] + edges[1:])
        idx = np.clip(
            np.searchsorted(edges, data[x_col].values, side='right') - 1,
            0, len(mids) - 1,
        )
        data[x_col] = mids[idx]

    # --- Condition handling --------------------------------------------------
    single_line = condition_col is None
    if single_line:
        data['_cond'] = '_single'
        condition_col = '_cond'
        conditions = ['_single']
    elif conditions is None:
        conditions = sorted(data[condition_col].dropna().unique().tolist())

    n_cond = len(conditions)

    if labels is None:
        labels = ['' if c == '_single' else str(c) for c in conditions]
    elif len(labels) != n_cond:
        raise ValueError("`labels` length must match number of conditions.")
    labels = [string.capwords(l) for l in labels]

    default_palette = ['#0066ff', '#ff3399', '#33cc33', '#ff9933',
                       '#9933cc', '#ffcc00', '#00cccc', '#cc3300']
    if colours is None:
        colours = [default_palette[i % len(default_palette)] for i in range(n_cond)]
    elif len(colours) != n_cond:
        raise ValueError(f"Provide exactly {n_cond} colours (got {len(colours)}).")

    # Resolve trend_colour: None → use condition colour; str → broadcast;
    # list → one per condition.
    if trend_colour is None:
        trend_colours = list(colours)
    elif isinstance(trend_colour, str):
        trend_colours = [trend_colour] * n_cond
    else:
        trend_colours = list(trend_colour)
        if len(trend_colours) != n_cond:
            raise ValueError(
                f"Provide exactly {n_cond} trend_colours (got {len(trend_colours)})."
            )

    # --- Stage 1: collapse within subject ------------------------------------
    # One value per (subject, condition, x) cell, regardless of how many
    # trials contributed. This is what keeps the SE honest.
    per_subject = (
        data.groupby([subject_col, condition_col, x_col], dropna=False)[y_col]
            .mean()
            .reset_index()
    )

    # --- Cousineau-Morey normalisation (if requested) ------------------------
    if se_method == 'within':
        subj_means = per_subject.groupby(subject_col)[y_col].transform('mean')
        grand_mean = per_subject[y_col].mean()
        per_subject = per_subject.assign(
            _norm=per_subject[y_col] - subj_means + grand_mean
        )
        # Morey factor sqrt(k / (k - 1)); k = number of cells per subject.
        k = per_subject.groupby(subject_col)[y_col].transform('count')
        per_subject = per_subject.assign(_morey=np.sqrt(k / (k - 1)))

    # --- Figure --------------------------------------------------------------
    if figsize is None:
        figsize = (6, 4)
    fig, ax = plt.subplots(figsize=figsize)

    rng = np.random.default_rng(random_state)

    trend_annotations = []

    # --- Stage 2: aggregate across subjects, per condition -------------------
    for c_idx, cond in enumerate(conditions):
        sub = per_subject[per_subject[condition_col] == cond]
        if sub.empty:
            continue

        if se_method == 'between':
            agg = (sub.groupby(x_col)[y_col]
                      .agg(['mean', 'sem'])
                      .reset_index()
                      .sort_values(x_col))
            xs = agg[x_col].values
            ms = agg['mean'].values
            err = agg['sem'].values
            lo, hi = ms - err, ms + err

        elif se_method == 'within':
            agg = (sub.groupby(x_col)
                      .agg(mean=(y_col, 'mean'),
                           sem_norm=('_norm', 'sem'),
                           morey=('_morey', 'mean'))
                      .reset_index()
                      .sort_values(x_col))
            xs = agg[x_col].values
            ms = agg['mean'].values
            err = agg['sem_norm'].values * agg['morey'].values
            lo, hi = ms - err, ms + err

        else:  # bootstrap
            xs_sorted = np.sort(sub[x_col].unique())
            subj_ids = sub[subject_col].unique()
            mat = (sub.pivot_table(index=subject_col, columns=x_col,
                                   values=y_col, aggfunc='mean')
                      .reindex(index=subj_ids, columns=xs_sorted)
                      .values)
            xs = xs_sorted
            ms = np.nanmean(mat, axis=0)
            n_subj = mat.shape[0]
            boots = np.empty((n_boot, mat.shape[1]))
            for b in range(n_boot):
                idx = rng.integers(0, n_subj, size=n_subj)
                boots[b] = np.nanmean(mat[idx], axis=0)
            half = (100 - ci) / 2.0
            lo = np.nanpercentile(boots, half, axis=0)
            hi = np.nanpercentile(boots, 100 - half, axis=0)

        ax.fill_between(xs, lo, hi, color=colours[c_idx],
                        alpha=band_alpha, linewidth=0, zorder=1)
        ax.plot(xs, ms, color=colours[c_idx], linewidth=line_width,
                label=labels[c_idx], zorder=2)
        if show_markers:
            ax.plot(xs, ms, 'o', color=colours[c_idx],
                    markersize=marker_size, zorder=3)

        # --- Trend overlay(s) ------------------------------------------------
        # Fit on the group-mean trajectory (xs, ms) — one point per x.
        # Each trend gets a distinct linestyle and is drawn above all data
        # with a white halo so it stays visible against any colour beneath.
        for trend_name, trend_deg in trend_specs:
            x_fit = np.asarray(xs, dtype=float)
            y_fit = np.asarray(ms, dtype=float)
            mask = ~(np.isnan(x_fit) | np.isnan(y_fit))
            x_fit, y_fit = x_fit[mask], y_fit[mask]
            if len(x_fit) > trend_deg and np.ptp(x_fit) > 0:
                coeffs = np.polyfit(x_fit, y_fit, trend_deg)
                x_dense = np.linspace(x_fit.min(), x_fit.max(), 200)
                y_dense = np.polyval(coeffs, x_dense)
                ax.plot(
                    x_dense, y_dense,
                    color=trend_colours[c_idx],
                    linestyle=trend_linestyles[trend_deg],
                    linewidth=trend_width,
                    alpha=trend_alpha,
                    zorder=20,
                )

                if show_trend_stats:
                    y_pred = np.polyval(coeffs, x_fit)
                    ss_res = np.sum((y_fit - y_pred) ** 2)
                    ss_tot = np.sum((y_fit - np.mean(y_fit)) ** 2)
                    r2 = 1 - ss_res / ss_tot if ss_tot > 0 else np.nan
                    # Coeffs are returned highest-power first.
                    if trend_deg == 1:
                        b, c = coeffs
                        eq = f"y = {b:+.3g}x {c:+.3g}"
                    else:
                        a, b, c = coeffs
                        eq = f"y = {a:+.3g}x² {b:+.3g}x {c:+.3g}"
                    cond_prefix = (labels[c_idx] + ' ') if not single_line else ''
                    trend_annotations.append(
                        f"{cond_prefix}{trend_name}: {eq}  (R²={r2:.3f})"
                    )

    # --- Reference line + aesthetics -----------------------------------------
    if hline is not None:
        ax.axhline(y=hline, color='r', linestyle='--')

    if trend_annotations:
        ax.text(
            0.02, 0.98, '\n'.join(trend_annotations),
            transform=ax.transAxes, va='top', ha='left',
            fontsize=8,
            bbox=dict(facecolor='white', alpha=0.75,
                      edgecolor='lightgrey', boxstyle='round,pad=0.3'),
            zorder=10,
        )

    base = plt.rcParams['font.size']  # typically 10
    ax.set_xlabel(string.capwords(xlabel_name if xlabel_name is not None else x_col),
                  fontsize=base * font_scale)
    ax.set_ylabel(string.capwords(ylabel_name), fontsize=base * font_scale)
    ax.tick_params(axis='both', which='major', labelsize=base * font_scale)

    # Resolve plot_name once (used for title and/or filename).
    if plot_name is None:
        plot_name = f"{y_col}_by_{x_col}"

    if plot_title:
        ax.set_title(string.capwords(plot_name), fontsize=base * 1.2 * font_scale)
    if not single_line:
        if legend_outside:
            ax.legend(frameon=False, loc='upper left',
                      bbox_to_anchor=(1.02, 1), borderaxespad=0,
                      fontsize=base * font_scale)
        else:
            ax.legend(frameon=False, fontsize=base * font_scale)
    plt.tight_layout()

    # --- Save & show ---------------------------------------------------------
    if save:
        os.makedirs(output_dir, exist_ok=True)
        save_kwargs = {'bbox_inches': 'tight'} if legend_outside else {}
        fig.savefig(os.path.join(output_dir, f"{plot_name}.pdf"), **save_kwargs)
    if show:
        plt.show()

    return fig, ax


def plot_average_performance(df, output_dir, plot_name, window_size=6, fit_linear=True, fit_quadratic=True):
    """
    Plot the rolling average performance over trials with optional linear and quadratic trendlines.

    Parameters:
    -----------
    df : pandas.DataFrame
        DataFrame containing 'trial' and 'objectively_correct_boolean' columns
    window_size : int, optional
        Size of the rolling window for averaging (default: 10)
    fit_linear : bool, optional
        If True, fits and displays a linear trendline (default: True)
    fit_quadratic : bool, optional
        If True, fits and displays a quadratic trendline (default: True)
    """

    # Sort by trial number to ensure correct order for rolling average
    df_sorted = df.sort_values('trial')

    # Calculate rolling average
    # Group by trial first in case there are multiple observations per trial
    trial_means = df_sorted.groupby('trial')['objectively_correct_boolean'].mean().reset_index()
    trial_means = trial_means.sort_values('trial')

    # Apply rolling window
    trial_means['rolling_avg'] = trial_means['objectively_correct_boolean'].rolling(
        window=window_size, center=True, min_periods=1
    ).mean()

    # Extract x and y values for plotting
    x = trial_means['trial'].values
    y = trial_means['rolling_avg'].values

    # Create the plot
    plt.figure(figsize=(12, 7))

    # Plot the rolling average performance
    plt.plot(x, y,
             marker='o', linestyle='-', linewidth=2, markersize=4,
             label=f'Rolling average (window={window_size})', alpha=0.7, color='dodgerblue')

    # Dictionary to store R-squared values
    r_squared_values = {}

    # Fit and plot linear trendline
    if fit_linear:
        # Fit a linear polynomial (degree=1)
        lin_coefficients = np.polyfit(x, y, 1)
        lin_polynomial = np.poly1d(lin_coefficients)

        # Generate smooth x values for plotting the trendline
        x_smooth = np.linspace(x.min(), x.max(), 100)
        y_smooth_lin = lin_polynomial(x_smooth)

        # Plot the linear trendline
        plt.plot(x_smooth, y_smooth_lin,
                 linestyle='--', linewidth=2.5, color='green',
                 label=f'Linear trend: {lin_coefficients[0]:.2e}x + {lin_coefficients[1]:.3f}',
                 alpha=0.8)

        # Calculate R-squared for the linear fit
        y_pred_lin = lin_polynomial(x)
        ss_res_lin = np.sum((y - y_pred_lin) ** 2)
        ss_tot = np.sum((y - np.mean(y)) ** 2)
        r_squared_lin = 1 - (ss_res_lin / ss_tot)
        r_squared_values['Linear'] = r_squared_lin

    # Fit and plot quadratic trendline
    if fit_quadratic:
        # Fit a quadratic polynomial (degree=2)
        quad_coefficients = np.polyfit(x, y, 2)
        quad_polynomial = np.poly1d(quad_coefficients)

        # Generate smooth x values for plotting the trendline
        x_smooth = np.linspace(x.min(), x.max(), 100)
        y_smooth_quad = quad_polynomial(x_smooth)

        # Plot the quadratic trendline
        plt.plot(x_smooth, y_smooth_quad,
                 linestyle='--', linewidth=2.5, color='red',
                 label=f'Quadratic trend: {quad_coefficients[0]:.2e}x² + {quad_coefficients[1]:.2e}x + {quad_coefficients[2]:.3f}',
                 alpha=0.8)

        # Calculate R-squared for the quadratic fit
        y_pred_quad = quad_polynomial(x)
        ss_res_quad = np.sum((y - y_pred_quad) ** 2)
        ss_tot = np.sum((y - np.mean(y)) ** 2)
        r_squared_quad = 1 - (ss_res_quad / ss_tot)
        r_squared_values['Quadratic'] = r_squared_quad

    # Add R-squared values to the plot
    text_y_pos = 0.95
    for model, r2 in r_squared_values.items():
        plt.text(0.05, text_y_pos, f'{model} R² = {r2:.4f}',
                 transform=plt.gca().transAxes,
                 bbox=dict(boxstyle='round', facecolor='white', alpha=0.8),
                 verticalalignment='top', fontsize=10)
        text_y_pos -= 0.06

    # Customize the plot
    plt.xlabel('Trial number', fontsize=12)
    plt.ylabel('Accuracy (objective)', fontsize=12)
    plt.title(plot_name, fontsize=14, fontweight='bold')
    plt.grid(True, alpha=0.3)

    # Add a horizontal line at 0.5 for reference (chance level if binary)
    plt.axhline(y=0.5, color='gray', linestyle='--', alpha=0.5, label='Chance level')

    plt.legend(loc='best', fontsize=9)

    # Set y-axis limits to [0, 1] since we're dealing with proportions
    plt.ylim(0, 1)

    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, f"{plot_name}.pdf"))
    plt.show()

    # Return results based on what was fitted
    results = {
        'rolling_avg_data': trial_means[['trial', 'rolling_avg']],
        'window_size': window_size
    }
    if fit_linear:
        results['linear_coef'] = lin_coefficients
        results['linear_r2'] = r_squared_lin
    if fit_quadratic:
        results['quadratic_coef'] = quad_coefficients
        results['quadratic_r2'] = r_squared_quad

    return results