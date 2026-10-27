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
        aspect_ratio=None,
        plot_title=True,
        jitter_width=0.04,
        show_mean=True,
        mean_size=80,
        mean_edgecolour='black',
        save=True,
        output_dir='.',
        show=True,
        logarithmic_scale=False,
        font_scale=1.0,
        positions=None,
        offsets=None,
        group_labels=None,
        group_separators=False,
        legend_labels=None,
        legend_title=None,
        legend_kwargs=None,
        capitalise_legend=True,
        show_box=True,
        show_violin=True,
        show_points=True,
        show_individual_lines=None,
        mean_colours=None,
        random_seed=None,
        group_label_fontsize=None,
        group_label_pad=6,
        group_prong_length=5,
        overlay_by=None,
        overlay_levels=None,
        overlay_offset=None,
        box_width=None,
        box_offsets=None,
        violin_alpha=None,
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
        the number of raincloud groups. All other per-column arguments
        (colours, flip, positions, legend_labels, ...) refer to this order.
    labels : list of str, optional
        X-axis tick labels. Either one per column, or one per unique x
        position (see `positions`). If None, uses the column names. When
        several columns share a position and one label per column is given,
        the distinct labels at that position are joined with ' / '.
    ylabel_name : str, optional
        Y-axis label.
    plot_name : str, optional
        Base filename (no extension). If None, joins the labels with underscores.
    colours : list of str, optional
        One colour per column. If None, uses a default palette and cycles as
        needed. Give pairs of columns the same colour (e.g.
        ['C0', 'C0', 'C1', 'C1']) and combine with `legend_labels` to get a
        legend per pair.
    hline : float, optional
        If provided, draws a horizontal dashed red reference line at this y-value.
    flip : str or list of str, optional
        Controls violin orientation per group. Per-entry options:
            'left', 'right', 'none'
        Or pass the keyword 'outward' for first-left/last-right with middles
        full.
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
        Figure size in inches. Overrides `aspect_ratio`.
    aspect_ratio : float, optional
        Width / height of the figure. Keeps the automatic height (5 inches
        for <= 2 positions, otherwise 6) and sets the width to
        height * aspect_ratio, so text keeps the same size relative to the
        figure height. E.g. 1.5 for 3:2, 16/9 for widescreen.
    plot_title : bool, optional
    jitter_width : float, optional
        Half-width of the horizontal jitter of the points.
    show_mean : bool, optional
        Draw the mean ± SE marker for each column.
    mean_size : float, optional
    mean_edgecolour : str, optional
        Outline colour of the coloured mean markers (also in the legend).
        Default 'black'; use 'white' for a white rim.
    save, show : bool, optional
    logarithmic_scale : bool, optional
    font_scale : float, optional

    Layout / overlay
    ----------------
    positions : list of float, optional
        X position of each column. Default is 1, 2, ..., n. Give columns the
        same position to overlay them, e.g. positions=[1, 2, 1, 2] draws
        columns 2 and 3 on top of columns 0 and 1. Use small offsets
        Tick labels are placed at the unique positions.
    offsets : list of float, optional
        Small per-column horizontal shift applied to every element of that
        column (box, violin, points, mean) but not to the tick. Use it to
        dodge overlaid columns, e.g. positions=[1, 2, 1, 2] with
        offsets=[0, 0, 0.08, 0.08]. Default: no shift.
    group_labels : list of levels, optional
        Extra levels of x-axis labels drawn below the tick labels, each with
        a bracket with short prongs pointing up at both ends. On the first
        level the bracket runs from the first to the last box it covers; on
        deeper levels it runs between the labels of the level above that it
        contains (falling back to the boxes if there are none). Each level is a list
        of (label, column_indices) tuples. The first level sits directly
        below the tick labels, the next one below that, etc. Example:
            group_labels=[
                [('UWD', [0, 1]), ('Control', [2, 3])],   # level 1
                [('Africa dataset', [0, 1, 2, 3])],       # level 2
            ]
    group_separators : bool, int or list of float, optional
        Vertical dotted lines separating groups.
            - False (default): none.
            - True: separate the spans of the first level in `group_labels`.
            - int k: separate the spans of level k of `group_labels`.
            - list of float: draw separators at these exact x positions.
    group_label_fontsize : float, optional
        Font size of the group labels. Default: the size of the x tick
        labels, which match the y-axis numbers, so all text on the x-axis
        uses the same size.
    group_label_pad : float, optional
        Distance in points between a bracket line and its text.
    group_prong_length : float, optional
        Length in points of the upward prongs at the ends of each bracket.
        Use 0 for a plain line.

    Legend
    ------
    legend_labels : list of str, optional
        One legend label per column (use None to leave a column out). One
        legend entry is made per unique (label, colour) combination, so
        pairs of columns with the same label and colour share one entry.
        Example: colours=['C0', 'C0', 'C1', 'C1'],
                 legend_labels=['UWD', 'UWD', 'Control', 'Control'].
    legend_title : str, optional
    capitalise_legend : bool, optional
        Capitalise the first letter of every legend label and of the legend
        title (default True). Only the first letter is changed, so labels
        you already wrote as 'UWD' or 'tACS' stay as they are.
    legend_kwargs : dict, optional
        Passed on to ax.legend (e.g. {'loc': 'upper left'} or
        {'bbox_to_anchor': (1.02, 1), 'loc': 'upper left'}).

    Element visibility
    ------------------
    show_box, show_violin, show_points : bool, optional
        Turn the boxplot, violin and individual datapoints on or off.
        Turning all three off leaves only the mean ± SE, which is useful
        when overlaying groups.
    show_individual_lines : bool, optional
        Draw the grey lines connecting individual paired samples. Defaults
        to the value of `show_points`.
    mean_colours : None, str or list of str, optional
        Colour of the mean marker, SE bars and mean connecting lines.
            - None (default): black while any of box/violin/points is shown;
              when all three are off, the column colours if `colours` was
              given, otherwise random colours.
            - 'group': always use the column colours from `colours`.
            - 'random': random, well-separated colours. If `legend_labels`
              is given, columns sharing a legend label share a colour.
            - any other str: that single colour for every column.
            - list of str: one colour per column.
        When all distribution elements are off, the legend uses these colours.
    random_seed : int, optional
        Seed for the jitter and for random colours, for reproducible plots.

    Overlaying by a grouping column
    -------------------------------
    overlay_by : str, optional
        Name of a column in `df` holding a grouping variable (e.g.
        'stimulation_condition' with values 'uwd' and 'control'). Each level
        is drawn on top of the others at the same x positions, with its own
        colour and legend entry. The rows of `df` are then expected to be
        one per subject per level, e.g. from
            df.pivot_table(index=['subject_id', 'stimulation_condition'], ...)
        All per-column arguments (`columns`, `labels`, `flip`, `positions`,
        `offsets`, `connect_pairs`, `group_labels`) keep referring to the
        columns as you list them, exactly as without overlaying. Pairing
        (connect_pairs) happens within each level.
        In this mode these arguments refer to levels instead of columns:
            - colours:       list (one per level) or dict {level: colour}
            - mean_colours:  defaults to the level colours (also when box,
                             violin or points are shown); str as usual
                             (e.g. 'black' to go back to black), or list /
                             dict per level
            - legend_labels: list or dict per level to rename the legend
                             entries (default: the level values), or False
                             for no legend
        `legend_title` defaults to the name of the `overlay_by` column, with
        underscores replaced by spaces.
    overlay_levels : list, optional
        Which levels of `overlay_by` to plot, and in which order (this order
        decides colours and legend order). Default: all levels, in category
        order for a categorical column, otherwise sorted.
    overlay_offset : float, optional
        Horizontal distance between the boxplots of neighbouring levels.
        Only the boxplots are moved apart; violins, points and means of all
        levels stay on top of each other. When the boxplots are hidden
        (show_box=False), the means get this shift instead. Default (None): the box width, so
        the boxes sit right next to each other. Use `offsets` if you want to
        shift every element of a column.
    box_width : float or list of float, optional
        Width of the boxplots, one value or one per column. Default: 0.1
        (<= 2 positions) or 0.15 times the spacing between positions. With
        `overlay_by`, this is the width of each level's box and defaults to
        the normal width divided by the number of levels.
    box_offsets : list of float, optional
        Extra horizontal shift per column for the boxplot only (on top of
        `offsets`). With `overlay_by` this is set from `overlay_offset`.
        With show_box=False the means are shifted by it instead.
    violin_alpha : float, optional
        Opacity of the violins. Default: 0.6, or 0.6 divided by the number
        of levels (minimum 0.15) with `overlay_by`.

    Returns
    -------
    fig, ax : matplotlib Figure and Axes
    """
    import matplotlib.colors as mcolors
    from matplotlib.lines import Line2D
    from matplotlib.patches import Patch
    from matplotlib.transforms import Affine2D, ScaledTranslation, blended_transform_factory

    rng = np.random.default_rng(random_seed)

    # --- Overlay by grouping column: expand into one column per level and ----
    # --- re-enter the function with ordinary per-column arguments -----------
    if overlay_by is not None:
        if overlay_by not in df.columns:
            raise ValueError(f"`overlay_by` column {overlay_by!r} not found in df.")
        base_cols = [df.columns[c] if isinstance(c, int) else c for c in columns]
        n_base = len(base_cols)

        if overlay_levels is None:
            g = df[overlay_by]
            if isinstance(g.dtype, pd.CategoricalDtype):
                levels = [c for c in g.cat.categories if (g == c).any()]
            else:
                levels = sorted(g.dropna().unique())
        else:
            levels = list(overlay_levels)
        n_levels = len(levels)
        if n_levels < 1:
            raise ValueError("No levels found to overlay.")

        def per_level(arg, name):
            # list (one per level) or dict {level: value} -> list in level order
            if isinstance(arg, dict):
                missing = [lv for lv in levels if lv not in arg]
                if missing:
                    raise ValueError(f"`{name}` dict is missing levels {missing}.")
                return [arg[lv] for lv in levels]
            arg = list(arg)
            if len(arg) != n_levels:
                raise ValueError(
                    f"With `overlay_by`, `{name}` needs one entry per level "
                    f"({n_levels}: {levels}), got {len(arg)}."
                )
            return arg

        def expand(per_col):
            # per base column -> repeated for every level
            return list(per_col) * n_levels

        # Data: one column per (base column, level), values only from that level's rows
        expanded = {}
        new_cols = []
        for lv in levels:
            mask = df[overlay_by] == lv
            for c in base_cols:
                name = f"{c} [{lv}]"
                expanded[name] = df[c].where(mask)
                new_cols.append(name)
        expanded_df = pd.DataFrame(expanded, index=df.index)

        # Per-level styling
        if colours is None:
            default_palette = ['#0066ff', '#ff3399', '#33cc33', '#ff9933',
                               '#9933cc', '#ffcc00', '#00cccc', '#cc3300']
            level_colours = [default_palette[k % len(default_palette)] for k in range(n_levels)]
        else:
            level_colours = per_level(colours, 'colours')
        if legend_labels is False:
            level_legend = None
        elif legend_labels is None:
            level_legend = [str(lv) for lv in levels]
        else:
            level_legend = per_level(legend_labels, 'legend_labels')
        if mean_colours is None:
            # Overlaid levels are told apart by colour, so the means follow the level colours
            new_mean_colours = 'group'
        elif isinstance(mean_colours, str):
            new_mean_colours = mean_colours
        else:
            new_mean_colours = [c for c in per_level(mean_colours, 'mean_colours') for _ in range(n_base)]

        # Per-column arguments repeated for every level
        base_positions = (np.arange(1, n_base + 1, dtype=float) if positions is None
                          else np.asarray(positions, dtype=float))
        base_offsets = np.zeros(n_base) if offsets is None else np.asarray(offsets, dtype=float)
        if len(base_positions) != n_base or len(base_offsets) != n_base:
            raise ValueError("`positions` and `offsets` need one entry per column.")
        new_offsets = expand(base_offsets)

        # Boxplots side by side: each level gets 1/n_levels of the normal width
        base_unique = np.unique(base_positions)
        base_spacing = np.min(np.diff(base_unique)) if len(base_unique) > 1 else 1.0
        if box_width is None:
            normal_width = (0.1 if len(base_unique) <= 2 else 0.15) * base_spacing
            level_box_width = normal_width / n_levels
            new_box_width = level_box_width
        elif np.isscalar(box_width):
            level_box_width = float(box_width)
            new_box_width = level_box_width
        else:
            if len(box_width) != n_base:
                raise ValueError("`box_width` needs one value or one per column.")
            level_box_width = float(np.max(box_width))
            new_box_width = expand(box_width)
        step = level_box_width if overlay_offset is None else float(overlay_offset)
        base_box_offsets = (np.zeros(n_base) if box_offsets is None
                            else np.asarray(box_offsets, dtype=float))
        new_box_offsets = []
        for k in range(n_levels):
            new_box_offsets += list(base_box_offsets + (k - (n_levels - 1) / 2) * step)

        new_violin_alpha = (violin_alpha if violin_alpha is not None
                            else max(0.15, 0.6 / n_levels))

        if labels is None:
            labels = [str(c) for c in base_cols]
        new_labels = expand(labels) if len(labels) == n_base else list(labels)

        if flip is None or isinstance(flip, str):
            new_flip = flip
        else:
            new_flip = expand(flip)

        if connect_pairs is True:
            base_pairs = [(i, i + 1) for i in range(n_base - 1)]
        elif connect_pairs is False:
            base_pairs = []
        else:
            base_pairs = [(int(i), int(j)) for i, j in connect_pairs]
        new_pairs = [(k * n_base + i, k * n_base + j)
                     for k in range(n_levels) for i, j in base_pairs]

        new_group_labels = None
        if group_labels:
            new_group_labels = [
                [(lab, [k * n_base + i for k in range(n_levels) for i in idxs])
                 for lab, idxs in level]
                for level in group_labels
            ]

        if plot_name is None:
            plot_name = "_".join(str(l) for l in labels)

        return paired_raincloud(
            expanded_df,
            columns=new_cols,
            labels=new_labels,
            ylabel_name=ylabel_name,
            plot_name=plot_name,
            colours=[c for c in level_colours for _ in range(n_base)],
            hline=hline,
            flip=new_flip,
            connect_pairs=new_pairs if new_pairs else False,
            figsize=figsize,
            aspect_ratio=aspect_ratio,
            plot_title=plot_title,
            jitter_width=jitter_width,
            show_mean=show_mean,
            mean_size=mean_size,
            mean_edgecolour=mean_edgecolour,
            save=save,
            output_dir=output_dir,
            show=show,
            logarithmic_scale=logarithmic_scale,
            font_scale=font_scale,
            positions=expand(base_positions),
            offsets=new_offsets,
            group_labels=new_group_labels,
            group_separators=group_separators,
            legend_labels=(None if level_legend is None
                           else [lab for lab in level_legend for _ in range(n_base)]),
            legend_title=(legend_title if legend_title is not None
                          else str(overlay_by).replace('_', ' ')),
            legend_kwargs=legend_kwargs,
            capitalise_legend=capitalise_legend,
            show_box=show_box,
            show_violin=show_violin,
            show_points=show_points,
            show_individual_lines=show_individual_lines,
            mean_colours=new_mean_colours,
            random_seed=random_seed,
            group_label_fontsize=group_label_fontsize,
            group_label_pad=group_label_pad,
            group_prong_length=group_prong_length,
            overlay_by=None,
            box_width=new_box_width,
            box_offsets=new_box_offsets,
            violin_alpha=new_violin_alpha,
        )

    # --- Resolve columns ------------------------------------------------------
    resolved = [df.columns[c] if isinstance(c, int) else c for c in columns]
    columns = resolved
    n_groups = len(columns)
    if n_groups < 1:
        raise ValueError("Provide at least one column.")

    # --- Positions ------------------------------------------------------------
    if positions is None:
        positions = np.arange(1, n_groups + 1, dtype=float)
    else:
        positions = np.asarray(positions, dtype=float)
        if len(positions) != n_groups:
            raise ValueError(
                f"`positions` length ({len(positions)}) must match number of columns ({n_groups})."
            )
    if offsets is None:
        offsets = np.zeros(n_groups)
    else:
        offsets = np.asarray(offsets, dtype=float)
        if len(offsets) != n_groups:
            raise ValueError(
                f"`offsets` length ({len(offsets)}) must match number of columns ({n_groups})."
            )
    element_positions = positions + offsets
    unique_positions = np.unique(positions)
    n_positions = len(unique_positions)
    if n_positions > 1:
        min_spacing = np.min(np.diff(unique_positions))
    else:
        min_spacing = 1.0

    # --- Labels ---------------------------------------------------------------
    if labels is None:
        labels = [str(c) for c in columns]
    if len(labels) == n_positions and n_positions != n_groups:
        tick_labels = list(labels)
    elif len(labels) == n_groups:
        tick_labels = []
        for p in unique_positions:
            at_p = [labels[i] for i in range(n_groups) if positions[i] == p]
            tick_labels.append(" / ".join(dict.fromkeys(at_p)))
    else:
        raise ValueError(
            f"Length of `labels` ({len(labels)}) must match the number of columns "
            f"({n_groups}) or the number of unique positions ({n_positions})."
        )

    # --- Colours --------------------------------------------------------------
    default_palette = ['#0066ff', '#ff3399', '#33cc33', '#ff9933',
                       '#9933cc', '#ffcc00', '#00cccc', '#cc3300']
    user_gave_colours = colours is not None
    if colours is None:
        colours = [default_palette[i % len(default_palette)] for i in range(n_groups)]
    elif len(colours) != n_groups:
        raise ValueError(
            f"Provide exactly {n_groups} colours (got {len(colours)})."
        )
    colours = list(colours)

    # --- Legend labels --------------------------------------------------------
    if legend_labels is not None and len(legend_labels) != n_groups:
        raise ValueError(
            f"`legend_labels` length ({len(legend_labels)}) must match number of columns ({n_groups})."
        )

    # --- Visibility -----------------------------------------------------------
    show_distribution = show_box or show_violin or show_points
    if show_individual_lines is None:
        show_individual_lines = show_points

    # --- Mean colours ---------------------------------------------------------
    def _random_colours():
        # Columns sharing a legend label share a colour; hues are evenly
        # spaced with a random offset so they stay distinguishable.
        if legend_labels is not None:
            keys = [legend_labels[i] if legend_labels[i] is not None else f"__col{i}"
                    for i in range(n_groups)]
        else:
            keys = list(range(n_groups))
        unique_keys = list(dict.fromkeys(keys))
        n_keys = len(unique_keys)
        hues = (np.arange(n_keys) / n_keys + rng.uniform(0, 1)) % 1.0
        hues = rng.permutation(hues)
        key_to_colour = {
            k: mcolors.to_hex(mcolors.hsv_to_rgb((h, 0.75, 0.85)))
            for k, h in zip(unique_keys, hues)
        }
        return [key_to_colour[k] for k in keys]

    if mean_colours is None:
        if show_distribution:
            mean_cols = ['black'] * n_groups
        elif user_gave_colours:
            mean_cols = list(colours)
        else:
            mean_cols = _random_colours()
    elif isinstance(mean_colours, str):
        if mean_colours == 'group':
            mean_cols = list(colours)
        elif mean_colours == 'random':
            mean_cols = _random_colours()
        else:
            mean_cols = [mean_colours] * n_groups
    else:
        mean_cols = list(mean_colours)
        if len(mean_cols) != n_groups:
            raise ValueError(
                f"`mean_colours` list length ({len(mean_cols)}) must match number of columns ({n_groups})."
            )
    mean_in_colour = any(mcolors.to_hex(c) != '#000000' for c in mean_cols)

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
    else:
        combined = [df[c].dropna().values for c in columns]

    # --- Figure ---------------------------------------------------------------
    if figsize is None:
        auto_height = 5 if n_positions <= 2 else 6
        if aspect_ratio is None:
            figsize = (max(5, 2 + 1.8 * n_positions), auto_height)
        else:
            figsize = (auto_height * aspect_ratio, auto_height)
    fig, ax = plt.subplots(figsize=figsize)

    violin_offset = 0.14 * min_spacing
    scatter_offset = 0.14 * min_spacing
    violin_positions = []
    scatter_positions = []
    for i, f in enumerate(flips):
        p = element_positions[i]
        if f == 'left':
            violin_positions.append(p - violin_offset)
            scatter_positions.append(p + scatter_offset)
        elif f == 'right':
            violin_positions.append(p + violin_offset)
            scatter_positions.append(p - scatter_offset)
        else:
            violin_positions.append(p)
            scatter_positions.append(p)

    # Without the distribution elements the mean sits on the tick itself
    mean_xs = np.array(scatter_positions) if show_distribution else element_positions.copy()

    # --- Boxplots -------------------------------------------------------------
    if box_width is None:
        box_widths = (0.1 if n_positions <= 2 else 0.15) * min_spacing
    elif np.isscalar(box_width):
        box_widths = float(box_width)
    else:
        box_widths = list(box_width)
        if len(box_widths) != n_groups:
            raise ValueError(
                f"`box_width` list length ({len(box_widths)}) must match number of columns ({n_groups})."
            )
    if box_offsets is None:
        box_positions = element_positions
    else:
        box_offsets = np.asarray(box_offsets, dtype=float)
        if len(box_offsets) != n_groups:
            raise ValueError(
                f"`box_offsets` length ({len(box_offsets)}) must match number of columns ({n_groups})."
            )
        box_positions = element_positions + box_offsets
        if not show_box:
            # No boxes to separate the levels, so the means take over their shift
            mean_xs = mean_xs + box_offsets

    if show_box:
        bp = ax.boxplot(
            combined,
            patch_artist=True,
            vert=True,
            widths=box_widths,
            positions=box_positions,
            boxprops=dict(facecolor='white', edgecolor='black'),
            capprops=dict(color='black'),
            whiskerprops=dict(color='black'),
            flierprops=dict(color='black', markeredgecolor='black', markersize=3),
            medianprops=dict(color='black'),
            manage_ticks=False,
        )
        for patch, fc in zip(bp['boxes'], colours):
            patch.set_facecolor(fc)
            patch.set_alpha(0.6)

    # --- Violins --------------------------------------------------------------
    if show_violin:
        vp = ax.violinplot(
            combined,
            points=300,
            positions=violin_positions,
            widths=0.3 * min_spacing,
            showmeans=False,
            showextrema=False,
            showmedians=False,
            vert=True,
        )
        for idx, body in enumerate(vp['bodies']):
            body.set_color(colours[idx])
            body.set_alpha(0.6 if violin_alpha is None else violin_alpha)
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
        jitter = rng.uniform(-jitter_width, jitter_width, size=size)
        xs_all.append(np.full(size, base_x) + jitter)

    # --- Connecting lines (drawn beneath scatter) -----------------------------
    if connection_pairs and show_individual_lines:
        for (i, j) in connection_pairs:
            n_pair = min(len(combined[i]), len(combined[j]))
            for k in range(n_pair):
                ax.plot(
                    [xs_all[i][k], xs_all[j][k]],
                    [combined[i][k], combined[j][k]],
                    color='grey', alpha=0.25, linewidth=0.6, zorder=1,
                )

    # --- Scatter on top -------------------------------------------------------
    if show_points:
        scatter_size = 15 if n_positions <= 2 else 25
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

        # Mean line(s) follow the same edges as the individual connections.
        # A line takes its columns' colour if both share one, else grey.
        for (i, j) in connection_pairs:
            same = mcolors.to_hex(mean_cols[i]) == mcolors.to_hex(mean_cols[j])
            ax.plot(
                [mean_xs[i], mean_xs[j]],
                [means[i], means[j]],
                color=mean_cols[i] if same else 'grey',
                linewidth=2.0, alpha=1.0, zorder=5,
            )

        for i in range(n_groups):
            ax.errorbar(
                mean_xs[i], means[i], yerr=sems[i],
                fmt='none', ecolor=mean_cols[i],
                elinewidth=1.8, capsize=5, capthick=1.8,
                alpha=1.0, zorder=5,
            )

        if mean_in_colour:
            # Filled, coloured markers with an outline
            ax.scatter(
                mean_xs, means,
                s=mean_size, c=mean_cols,
                edgecolors=mean_edgecolour, linewidths=1.2,
                zorder=6,
            )
        else:
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
    ax.set_xticks(unique_positions)
    ax.set_xticklabels(tick_labels)
    tick_fs = base * font_scale  # same size as the y-axis numbers
    ax.tick_params(axis='x', which='major', labelsize=tick_fs)
    ax.tick_params(axis='y', which='major', labelsize=base * font_scale)
    ax.set_ylabel(ylabel_name, fontsize=base * font_scale)
    ax.set_xlim(unique_positions[0] - 0.6 * min_spacing,
                unique_positions[-1] + 0.6 * min_spacing)
    if logarithmic_scale:
        ax.set_yscale('log')
    if plot_title:
        ax.set_title(plot_name, fontsize=base * 1.2 * font_scale)

    # --- Legend ---------------------------------------------------------------
    if legend_labels is not None:
        legend_cols = colours if show_distribution else mean_cols
        entries = {}
        for i in range(n_groups):
            if legend_labels[i] is None:
                continue
            key = (legend_labels[i], mcolors.to_hex(legend_cols[i]))
            entries.setdefault(key, legend_cols[i])
        handles = []

        def _cap(text):
            text = str(text)
            return text[:1].upper() + text[1:] if capitalise_legend else text

        for (lab, _), c in entries.items():
            lab = _cap(lab)
            if show_distribution:
                handles.append(Patch(facecolor=c, edgecolor='none', alpha=0.6, label=lab))
            else:
                handles.append(Line2D([0], [0], color=c, linewidth=2.0, marker='o',
                                      markersize=7, markerfacecolor=c,
                                      markeredgecolor=mean_edgecolour, label=lab))
        kw = dict(fontsize=base * 0.9 * font_scale, frameon=True)
        if legend_title is not None:
            kw['title'] = _cap(legend_title)
        kw.update(legend_kwargs or {})
        ax.legend(handles=handles, **kw)

    # --- Group separators -----------------------------------------------------
    def _level_spans(level):
        spans = []
        for lab, idxs in level:
            idxs = list(idxs)
            if not idxs:
                continue
            for k in idxs:
                if not (0 <= k < n_groups):
                    raise ValueError(f"group_labels index {k} out of range for {n_groups} columns.")
            ps = positions[idxs]
            spans.append((lab, ps.min(), ps.max()))
        return sorted(spans, key=lambda s: s[1])

    if group_separators is not False and group_separators is not None:
        if group_separators is True or isinstance(group_separators, (int, np.integer)):
            level_idx = 0 if group_separators is True else int(group_separators)
            if group_labels is None or level_idx >= len(group_labels):
                raise ValueError("group_separators refers to a level of `group_labels` that does not exist.")
            spans = _level_spans(group_labels[level_idx])
            sep_xs = [(spans[k][2] + spans[k + 1][1]) / 2 for k in range(len(spans) - 1)]
        else:
            sep_xs = list(group_separators)
        for x in sep_xs:
            ax.axvline(x, color='0.5', linestyle=':', linewidth=1.2, zorder=0)

    # --- Multi-level x-axis labels --------------------------------------------
    if group_labels:
        # Measure how far the tick labels reach below the axes (in points)
        fig.canvas.draw()
        renderer = fig.canvas.get_renderer()
        axes_bottom = ax.get_window_extent(renderer).y0
        tick_bottoms = [t.get_window_extent(renderer).y0
                        for t in ax.get_xticklabels() if t.get_text()]
        tick_bottom = min(tick_bottoms) if tick_bottoms else axes_bottom
        start_pts = (axes_bottom - tick_bottom) * 72.0 / fig.dpi + 4

        group_fs = tick_fs if group_label_fontsize is None else group_label_fontsize
        prong = max(0.0, float(group_prong_length))
        pad = float(group_label_pad)
        # line -> pad -> text -> gap -> next level's prongs -> next line
        level_step = pad + group_fs * 1.3 + 4 + prong
        start_pts = start_pts + prong
        xaxis_trans = ax.get_xaxis_transform()
        # x in data units, y in points measured from the bottom of the axes
        # (stays correct when tight_layout moves the axes)
        points_trans = (Affine2D().scale(1, 1 / 72.0) + fig.dpi_scale_trans
                        + ScaledTranslation(0, 0, ax.transAxes))
        bracket_trans = blended_transform_factory(ax.transData, points_trans)
        single_half_width = 0.05 * min_spacing

        previous_spans = []  # (column index set, label centre) of the level above
        for lvl, level in enumerate(group_labels):
            y_line = start_pts + lvl * level_step
            current_spans = []
            for lab, idxs in level:
                idxs = list(idxs)
                if not idxs:
                    continue
                # First level: from the first to the last box covered.
                # Deeper levels: from the first to the last label of the level
                # above that falls inside this group.
                children = [centre for child_idxs, centre in previous_spans
                            if child_idxs <= set(idxs)]
                if children:
                    x0, x1 = min(children), max(children)
                else:
                    xs = element_positions[idxs]
                    x0, x1 = xs.min(), xs.max()
                if x0 == x1:
                    x0, x1 = x0 - single_half_width, x1 + single_half_width
                current_spans.append((set(idxs), (x0 + x1) / 2))
                ax.add_artist(Line2D(
                    [x0, x0, x1, x1],
                    [-y_line + prong, -y_line, -y_line, -y_line + prong],
                    transform=bracket_trans, color='0.3', linewidth=1.0,
                    solid_joinstyle='miter', clip_on=False,
                ))
                if lab is not None:
                    ax.annotate(
                        lab, xy=((x0 + x1) / 2, 0), xycoords=xaxis_trans,
                        xytext=(0, -(y_line + pad)), textcoords='offset points',
                        ha='center', va='top', fontsize=group_fs,
                        annotation_clip=False,
                    )
            previous_spans = current_spans

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
                 bbox=dict(boxstyle='round', facecolor='black', alpha=0.8),
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