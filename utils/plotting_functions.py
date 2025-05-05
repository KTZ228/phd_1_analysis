import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os


def paired_raincloud_2_groups(
    df,
    column_1,
    column_2,
    labels=None,
    output_dir='.',
    ylabel_name='Label',
    plot_name=None,
    colours=['#0066ff', '#ff3399']
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

    Returns
    -------
    fig, ax : matplotlib Figure and Axes
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

    # Scatter + connecting lines centered around [1.14, 1.86]
    xs_all = []
    centers = [1.14, 1.86]
    for i, vals in enumerate(combined):
        base_x = centers[i]
        jitter = np.random.uniform(-0.04, 0.04, size=len(vals))
        xs = np.full(len(vals), base_x) + jitter
        xs_all.append(xs)
        ax.scatter(xs, vals, s=5, c=colours[i])

    for i in range(min(len(xs_all[0]), len(xs_all[1]))):
        ax.plot(
            [xs_all[0][i], xs_all[1][i]],
            [combined[0][i], combined[1][i]],
            color='grey', alpha=0.5, linewidth=0.7
        )

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

