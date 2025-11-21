import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import os


def paired_raincloud_2_groups(
    df,
    column_1,
    column_2,
    labels=None,
    output_dir='.',
    ylabel_name='Label',
    plot_name=None,
    colours=['#0066ff', '#ff3399'],
    hline=None
):
    """
    Create a paired box+violin+scatter plot with lines connecting paired samples.

    Parameters
    ----------
    df : pandas.DataFrame
        DataFrame containing paired numeric values.
    column_1, column_2 : str or int
        Column name or index of the two series to plot.
    labels : list of str, optional
        Two labels for the x‑axis ticks. If None, uses the column names.
    output_dir : str, optional
        Directory where the plot PDF will be saved (default: current directory).
    ylabel_name : str, optional
        Label for the y‑axis (default: 'Label').
    plot_name : str, optional
        Base filename (without extension). If None, uses "{column_1}_{column_2}".
    colours : list of str, optional
        Colors for the two groups (default: ['#0066ff', '#ff3399']).
    """
    # Resolve column names if given by index
    if isinstance(column_1, int):
        column_1 = df.columns[column_1]
    if isinstance(column_2, int):
        column_2 = df.columns[column_2]

    # Prepare data
    data1 = df[column_1].dropna().tolist()
    data2 = df[column_2].dropna().tolist()
    combined = [data1, data2]

    # Default labels
    if labels is None:
        labels = [str(column_1), str(column_2)]

    # Check if 2 colours are provided
    if len(colours) != 2:
        raise ValueError("Provide exactly 2 colours for the two groups.")

    # Create figure
    fig, ax = plt.subplots(figsize=(7, 5))

    # Boxplot
    bp = ax.boxplot(
        combined,
        patch_artist=True,
        vert=True,
        widths=0.1,
        positions=[1, 2],
        boxprops=dict(facecolor='white', edgecolor='black'),
        capprops=dict(color='black'),
        whiskerprops=dict(color='black'),
        flierprops=dict(color='black', markeredgecolor='black'),
        medianprops=dict(color='black'),
    )
    for patch, fc in zip(bp['boxes'], colours):
        patch.set_facecolor(fc)
        patch.set_alpha(0.6)

    # Half violins
    vp = ax.violinplot(
        combined,
        points=500,
        positions=[0.86, 2.14],
        widths=0.3,
        showmeans=False,
        showextrema=False,
        showmedians=False,
        vert=True
    )
    for idx, body in enumerate(vp['bodies']):
        body.set_color(colours[idx])
        body.set_alpha(0.6)
        m = np.mean(body.get_paths()[0].vertices[:, 0])
        verts = body.get_paths()[0].vertices
        if idx == 0:
            verts[:, 0] = np.clip(verts[:, 0], -np.inf, m)
        else:
            verts[:, 0] = np.clip(verts[:, 0], m, np.inf)

    # Compute scatter x-positions with jitter
    xs_all = []
    centers = [1.14, 1.86]
    for i, vals in enumerate(combined):
        base_x = centers[i]
        jitter = np.random.uniform(-0.04, 0.04, size=len(vals))
        xs = np.full(len(vals), base_x) + jitter
        xs_all.append(xs)

    # Connecting lines (drawn beneath)
    for i in range(min(len(xs_all[0]), len(xs_all[1]))):
        ax.plot(
            [xs_all[0][i], xs_all[1][i]],
            [combined[0][i], combined[1][i]],
            color='grey', alpha=0.5, linewidth=0.7
        )

    # Scatter on top of lines
    for i, vals in enumerate(combined):
        ax.scatter(xs_all[i], vals, s=5, c=colours[i], alpha=1)

    if hline is not None:
        ax.axhline(y=hline, color='r', linestyle='--')

    ax.set_xticks([1, 2])
    ax.set_xticklabels(labels)
    ax.set_ylabel(ylabel_name)
    plt.tight_layout()

    # Save
    if plot_name is None:
        plot_name = f"{column_1}_{column_2}"
    os.makedirs(output_dir, exist_ok=True)
    fig.savefig(os.path.join(output_dir, f"{plot_name}.pdf"))
    plt.show()
    return


def paired_raincloud_4_groups(
    df,
    columns,
    labels=None,
    output_dir='.',
    ylabel_name='Label',
    plot_name=None,
    colours=['#0066ff', '#ff3399', '#33cc33', '#ff9933'],
    plot_title=None,
    plot_full_width=True
):
    """
    Create a paired raincloud plot (box+half-violin+scatter) for four paired groups,
    connecting each sample across all four conditions.

    Parameters
    ----------
    df : pandas.DataFrame
        DataFrame containing numeric values for all four groups. Rows with any NaN
        across the specified columns are dropped to ensure consistent pairing.
    columns : list of str or int
        List of four column names or indices to plot in order.
    labels : list of str, optional
        Labels for the x-axis ticks. If None, uses the column names.
    output_dir : str, optional
        Directory where the plot PDF will be saved (default: current directory).
    ylabel_name : str, optional
        Label for the y‑axis (default: 'Label').
    plot_name : str, optional
        Base filename (without extension). If None, uses "_".join(columns).
    colours : list of str, optional
        Colors for the four groups. Defaults to a blue-pink palette.
    plot_title : str, optional
    """
    # Resolve column names if given by index
    resolved = []
    for col in columns:
        if isinstance(col, int):
            resolved.append(df.columns[col])
        else:
            resolved.append(col)
    columns = resolved

    # Drop rows with any missing values across these columns to maintain pairing
    paired_df = df[columns].dropna()

    # Extract data lists
    combined = [paired_df[col].values for col in columns]

    # Default labels
    if labels is None:
        labels = [str(col) for col in columns]

    # Check if 4 colours are provided
    if len(colours) != 4:
        raise ValueError("Provide exactly 4 colours for the four groups.")

    # Create figure
    if plot_full_width:
        fig, ax = plt.subplots(figsize=(12, 6))
    else:
        fig, ax = plt.subplots(figsize=(7, 6))
    n_groups = 4
    positions = np.arange(1, n_groups + 1)
    violin_positions = positions - 0.2
    scatter_positions = positions + 0.2

    # Boxplots
    bp = ax.boxplot(
        combined,
        patch_artist=True,
        vert=True,
        widths=0.15,
        positions=positions,
        boxprops=dict(facecolor='white', edgecolor='black'),
        capprops=dict(color='black'),
        whiskerprops=dict(color='black'),
        flierprops=dict(color='black', markeredgecolor='black'),
        medianprops=dict(color='black'),
    )
    for patch, fc in zip(bp['boxes'], colours):
        patch.set_facecolor(fc)
        patch.set_alpha(0.6)

    # Half violins
    vp = ax.violinplot(
        combined,
        points=200,
        positions=violin_positions,
        widths=0.3,
        showmeans=False,
        showextrema=False,
        showmedians=False,
        vert=True
    )
    for idx, body in enumerate(vp['bodies']):
        body.set_color(colours[idx])
        body.set_alpha(0.6)
        verts = body.get_paths()[0].vertices
        m = np.mean(verts[:, 0])
        verts[:, 0] = np.clip(verts[:, 0], -np.inf, m)

    # Scatter with jitter and connecting lines
    xs_all = []
    for pos in scatter_positions:
        jitter = np.random.uniform(-0.05, 0.05, size=len(paired_df))
        xs_all.append(np.full(len(paired_df), pos) + jitter)

    # Draw lines connecting each sample across all groups
    for i in range(len(paired_df)):
        xs = [xs_all[j][i] for j in range(n_groups)]
        ys = [combined[j][i] for j in range(n_groups)]
        ax.plot(xs, ys, color='grey', alpha=0.5, linewidth=0.7)

    # Draw scatter on top
    for j in range(n_groups):
        ax.scatter(xs_all[j], combined[j], s=15, c=colours[j], alpha=1)

    # Aesthetics
    if not plot_full_width:
        ax.tick_params(axis='x', which='major', labelsize=8)
    ax.set_xticks(positions)
    ax.set_xticklabels(labels)
    ax.set_ylabel(ylabel_name)
    plt.tight_layout()

    if plot_title:
        #plt.title(plot_title, fontsize=24)
        print('plotting is turned off')

    # Save
    if plot_name is None:
        plot_name = "_".join(labels)
    os.makedirs(output_dir, exist_ok=True)
    fig.savefig(os.path.join(output_dir, f"{plot_name}.pdf"))
    plt.show()
    return


def paired_raincloud_8_groups(
        df,
        columns,
        labels=None,
        output_dir='.',
        ylabel_name='Label',
        plot_name=None,
        colours=None,
        pair_groups=True,
        figsize=(16, 6)
):
    """
    Create a paired raincloud plot (box+half-violin+scatter) for eight groups,
    with optional pairing between consecutive groups (0-1, 2-3, 4-5, 6-7).

    Parameters
    ----------
    df : pandas.DataFrame
        DataFrame containing numeric values for all eight groups. Rows with any NaN
        across the specified columns are dropped to ensure consistent pairing.
    columns : list of str or int
        List of eight column names or indices to plot in order.
    labels : list of str, optional
        Labels for the x-axis ticks. If None, uses the column names.
    output_dir : str, optional
        Directory where the plot PDF will be saved (default: current directory).
    ylabel_name : str, optional
        Label for the y‑axis (default: 'Label').
    plot_name : str, optional
        Base filename (without extension). If None, uses "_".join(columns).
    colours : list of str, optional
        Colors for the eight groups. If None, uses a default palette.
    pair_groups : bool, optional
        If True, draws lines connecting pairs (0-1, 2-3, 4-5, 6-7).
        If False, draws lines connecting all 8 groups for each sample.
    figsize : tuple, optional
        Figure size as (width, height). Default is (16, 6).
    """
    # Resolve column names if given by index
    resolved = []
    for col in columns:
        if isinstance(col, int):
            resolved.append(df.columns[col])
        else:
            resolved.append(col)
    columns = resolved

    # Check we have 8 columns
    if len(columns) != 8:
        raise ValueError("Provide exactly 8 columns for the eight groups.")

    # Drop rows with any missing values across these columns to maintain pairing
    paired_df = df[columns].dropna()

    # Extract data lists
    combined = [paired_df[col].values for col in columns]

    # Default labels
    if labels is None:
        labels = [str(col) for col in columns]

    # Default colours - using a palette that distinguishes paired groups
    if colours is None:
        # Each pair gets variations of the same base color
        colours = [
            '#0066ff', '#0099ff',  # Blues (pair 0-1)
            '#ff3399', '#ff66b3',  # Pinks (pair 2-3)
            '#33cc33', '#66ff66',  # Greens (pair 4-5)
            '#ff9933', '#ffb366'  # Oranges (pair 6-7)
        ]

    # Check if 8 colours are provided
    if len(colours) != 8:
        raise ValueError("Provide exactly 8 colours for the eight groups.")

    # Create figure
    fig, ax = plt.subplots(figsize=figsize)
    n_groups = 8
    positions = np.arange(1, n_groups + 1)

    # Adjust spacing between pairs
    pair_spacing = 0.3
    adjusted_positions = []
    for i in range(n_groups):
        pair_idx = i // 2
        base_pos = i + 1 + pair_idx * pair_spacing
        adjusted_positions.append(base_pos)
    positions = np.array(adjusted_positions)

    violin_positions = positions - 0.15
    scatter_positions = positions + 0.15

    # Boxplots
    bp = ax.boxplot(
        combined,
        patch_artist=True,
        vert=True,
        widths=0.12,
        positions=positions,
        boxprops=dict(facecolor='white', edgecolor='black'),
        capprops=dict(color='black'),
        whiskerprops=dict(color='black'),
        flierprops=dict(color='black', markeredgecolor='black'),
        medianprops=dict(color='black'),
    )
    for patch, fc in zip(bp['boxes'], colours):
        patch.set_facecolor(fc)
        patch.set_alpha(0.6)

    # Half violins
    vp = ax.violinplot(
        combined,
        points=200,
        positions=violin_positions,
        widths=0.25,
        showmeans=False,
        showextrema=False,
        showmedians=False,
        vert=True
    )
    for idx, body in enumerate(vp['bodies']):
        body.set_color(colours[idx])
        body.set_alpha(0.6)
        verts = body.get_paths()[0].vertices
        m = np.mean(verts[:, 0])
        verts[:, 0] = np.clip(verts[:, 0], -np.inf, m)

    # Scatter with jitter and connecting lines
    xs_all = []
    for pos in scatter_positions:
        jitter = np.random.uniform(-0.04, 0.04, size=len(paired_df))
        xs_all.append(np.full(len(paired_df), pos) + jitter)

    # Draw lines connecting samples
    if pair_groups:
        # Connect pairs: 0-1, 2-3, 4-5, 6-7
        for pair_start in range(0, n_groups, 2):
            pair_end = pair_start + 1
            for i in range(len(paired_df)):
                xs = [xs_all[pair_start][i], xs_all[pair_end][i]]
                ys = [combined[pair_start][i], combined[pair_end][i]]
                ax.plot(xs, ys, color='grey', alpha=0.4, linewidth=0.6)
    else:
        # Connect all 8 groups for each sample
        for i in range(len(paired_df)):
            xs = [xs_all[j][i] for j in range(n_groups)]
            ys = [combined[j][i] for j in range(n_groups)]
            ax.plot(xs, ys, color='grey', alpha=0.3, linewidth=0.5)

    # Draw scatter on top
    for j in range(n_groups):
        ax.scatter(xs_all[j], combined[j], s=12, c=colours[j], alpha=1, zorder=5)

    # Add vertical lines to separate pairs (optional visual aid)
    for pair_idx in range(1, 4):  # Add lines after pairs 0-1, 2-3, 4-5
        separator_pos = (positions[pair_idx * 2 - 1] + positions[pair_idx * 2]) / 2
        ax.axvline(x=separator_pos, color='lightgray', linestyle='--', alpha=0.3, linewidth=0.8)

    # Aesthetics
    ax.set_xticks(positions)
    ax.set_xticklabels(labels, rotation=45 if max(len(str(l)) for l in labels) > 10 else 0,
                       ha='right' if max(len(str(l)) for l in labels) > 10 else 'center')
    ax.set_ylabel(ylabel_name)
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.grid(axis='y', alpha=0.2, linestyle='--')
    plt.tight_layout()

    # Save
    if plot_name is None:
        plot_name = "_".join(labels[:4]) + "_etc"  # Shortened to avoid overly long filenames
    os.makedirs(output_dir, exist_ok=True)
    fig.savefig(os.path.join(output_dir, f"{plot_name}.pdf"))
    plt.show()
    return fig, ax


def paired_scatter_violin_box_2x2(
    df,
    columns,
    session_col,
    labels=None,
    subject_col=None,
    output_dir='.',
    ylabel_name='Value',
    plot_name=None,
    colours=None,
    scatter_offset=0.3
):
    """
    Create a 2x2 grid of plots for four variables, each showing half-violin, boxplot, and scatter (paired) across sessions,
    with scatter and line plots offset horizontally relative to box and violin.

    Parameters
    ----------
    df : pandas.DataFrame
        DataFrame containing at least `session_col` and the four variables in `columns`.
    columns : list of str or int
        Four column names or indices to plot (order: top-left, top-right, bottom-left, bottom-right).
    session_col : str or int
        Column name or index for the session grouping on the x-axis.
    labels : list of str, optional
        Custom titles for each subplot; length must match `columns`. If None, uses column names.
    subject_col : str or int, optional
        Column name or index for subject IDs. If provided, draws lines connecting points within each subplot.
    output_dir : str, optional
        Directory to save the PDF (default: current directory).
    ylabel_name : str, optional
        Label for the y-axis on left-column subplots.
    plot_name : str, optional
        Base filename (without extension). Defaults to 'paired_violin_box'.
    colours : list of str, optional
        Colors for each of the four subplots. If None, uses default cycle.
    scatter_offset : float, optional
        Horizontal shift applied only to scatter and line positions relative to violins/boxes.
    """
    # Resolve column names if indices
    cols = []
    for col in columns:
        cols.append(df.columns[col] if isinstance(col, int) else col)
    session = df.columns[session_col] if isinstance(session_col, int) else session_col
    subject = (df.columns[subject_col] if isinstance(subject_col, int)
               else subject_col) if subject_col is not None else None

    if len(cols) != 4:
        raise ValueError("Provide exactly 4 columns for a 2x2 layout.")

    # Drop NaNs and reset index to track original rows
    required = cols + [session] + ([subject] if subject else [])
    data_df = df.dropna(subset=required).reset_index()

    # Prepare sessions and base positions
    sessions = sorted(data_df[session].unique())
    base_pos = np.arange(len(sessions))

    # Labels
    if labels is None:
        labels = cols
    elif len(labels) != 4:
        raise ValueError("'labels' must have four elements matching 'columns'.")

    # Colours
    if colours is None:
        colours = plt.rcParams['axes.prop_cycle'].by_key()['color'][:4]
    elif len(colours) != 4:
        raise ValueError("'colours' must have four elements.")

    # Create 2x2 grid
    fig, axes = plt.subplots(2, 2, figsize=(12, 10), sharey=True)
    axes = axes.flatten()

    # To record jittered x per original row index for scatter
    jitter_maps = {i: {} for i in range(4)}

    # Plot each subplot
    for idx, ax in enumerate(axes):
        col = cols[idx]
        color = colours[idx]
        # Prepare list of values per session
        all_vals = []
        for bi, base in enumerate(base_pos):
            sess = sessions[bi]
            session_df = data_df[data_df[session] == sess]
            vals = session_df[col].values
            all_vals.append(vals)

            # Scatter with offset
            n = len(vals)
            jitter = np.random.uniform(-0.1, 0.1, size=n)
            xs = base + jitter + scatter_offset
            # record original row index mapping
            for orig_idx, x in zip(session_df['index'], xs):
                jitter_maps[idx][orig_idx] = x
            ax.scatter(xs, vals, c=color, alpha=0.7, s=20)

        # Boxplot (no offset)
        ax.boxplot(
            all_vals,
            positions=base_pos,
            widths=0.15,
            patch_artist=True,
            boxprops=dict(facecolor=color, edgecolor='black', alpha=0.6),
            medianprops=dict(color='black'), whiskerprops=dict(color='black'),
            capprops=dict(color='black'), flierprops=dict(color='black', markeredgecolor='black')
        )
        # Half-violin (no offset)
        vp = ax.violinplot(
            all_vals,
            positions=base_pos - 0.2,
            widths=0.3,
            showmeans=False, showextrema=False, showmedians=False
        )
        for body in vp['bodies']:
            body.set_color(color)
            body.set_alpha(0.6)
            verts = body.get_paths()[0].vertices
            m = np.mean(verts[:, 0])
            verts[:, 0] = np.clip(verts[:, 0], -np.inf, m)

        # Connect subject lines within subplot with same scatter offset
        if subject:
            for subj_id, group in data_df.groupby(subject):
                grp = group.sort_values(session)
                xs_line = [jitter_maps[idx].get(orig) for orig in grp['index']]
                ys_line = grp[col].values
                if len(xs_line) > 1:
                    ax.plot(xs_line, ys_line, color='grey', alpha=0.5, linewidth=0.8)

        # Aesthetics
        ax.set_title(labels[idx])
        ax.set_xticks(base_pos)
        ax.set_xticklabels(sessions)
        if idx % 2 == 0:
            ax.set_ylabel(ylabel_name)

    plt.tight_layout()

    # Save
    if plot_name is None:
        plot_name = 'paired_violin_box'
    os.makedirs(output_dir, exist_ok=True)
    fig.savefig(os.path.join(output_dir, f"{plot_name}.pdf"))
    plt.show()
    return


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