"""
Created by Kenneth van der Zee, 2026

Multi-element ultrasound transducer wavefield - water-ripple animation.
=======================================================================
 
Edit the RENDERS list at the top, then run:
 
    python transducer_wavefield.py
 
Each entry produces one GIF (and one MP4 if ffmpeg is on PATH) written
to the current directory.
 
To add a render, copy any existing dict and tweak the fields you want
changed. Fields you omit fall back to DEFAULTS below. To skip a render
without deleting it, comment its line out or set 'enabled': False.
 
Physics
-------
Each element is a directional source (Rayleigh-Sommerfeld cos theta
obliquity factor, so nothing radiates behind the array). Elements with
a non-zero face width are discretised into many Huygens sub-sources
along their arc; the field is the coherent sum over all sub-sources.
A Hann apodisation across the array suppresses side lobes.
 
Display
-------
Pressure is half-wave rectified (troughs map to calm white). Only
positive pressures above pressure_threshold * vlim are rendered; the
visible range is then stretched across a blue->red palette and
hill-shaded for the water-ripple look.
"""
 
import os
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, FFMpegWriter
from matplotlib.colors import LightSource, LinearSegmentedColormap
 
 
# ======================================================================
#  DEFAULTS - any field a render omits falls back to these
# ======================================================================
DEFAULTS = dict(
    # transducer
    n_elements             = 16,    # Number of ANNULAR rings.
                                    #   The geometry is the 2D cross-section
                                    #   of an annular array: each ring shows
                                    #   up as two arc segments mirrored
                                    #   across the central axis. Ring 0 is
                                    #   the innermost (straddles the axis);
                                    #   ring N-1 is the outermost (at the
                                    #   rim of the aperture).
                                    #   N = 1 means one full-aperture element.
    element_width_mm       = 40.0,    # CHORD width of the aperture face
                                     # (straight tip-to-tip x-distance across
                                     # the bowl mouth). For a flat array this
                                     # is also the line length; for a curved
                                     # bowl the rendered ARC is longer than
                                     # the chord because the line follows the
                                     # bowl's curvature. Capped at 2*R (a
                                     # full hemisphere). 0 -> point source(s).
                                     # If transducer_width_mm is also set,
                                     # it takes precedence.
    transducer_width_mm    = None,   # ARC LENGTH along the curved bowl face
                                     # (i.e. how much surface the element
                                     # wraps around). If set, overrides
                                     # element_width_mm and is converted to
                                     # the equivalent chord via
                                     #   chord = 2 R sin(arc / 2R)
                                     # Capped at pi*R (a full hemisphere).
                                     # For a flat array, arc length equals
                                     # chord, so the two parameters coincide.
    radius_mm              = 50.0,
    focus_depth_mm         = None,   # None  -> natural geometric focus at R
                                     #          (flat phase across all rings)
                                     # value -> electronic focus at this on-
                                     #          axis depth, applied as ONE
                                     #          delay per ring (the way real
                                     #          annular arrays work). With
                                     #          N=1 ring the focus stays at
                                     #          R: a single-element bowl
                                     #          can't be electronically
                                     #          refocused.
    phase_delays_deg       = None,   # Manual per-ring phase delays, deg in
                                     # [0, 360). Length must equal n_elements.
                                     # Overrides focus_depth_mm if set. Each
                                     # value is applied to ALL sub-sources in
                                     # its ring (mirrored left/right).
                                     # Example: [0, 30, 60, 120, 200] for 5
                                     # rings -> innermost rings fire first,
                                     # outermost last.
    subsources_per_element = 64,
 
    # acoustics
    wavelength_mm          = 3.0,
    speed_of_sound         = 1500.0,
 
    # display
    pressure_threshold     = 0.40,
    vert_exag              = 40,
    domain_x_mm            = 80.0,
    domain_y_mm            = 120.0,
    output_dpi             = 200,
 
    # transducer schematic (black line tracing the back of the bowl)
    show_transducer        = True,  # off by default; set True per render
                                     # to draw the body
    backing_depth_mm       = 4.0,    # how far behind the element face
    backing_linewidth      = 4.0,    # line thickness in pts
 
    # output
    frames                 = 30,    # frames per acoustic period (the loop)
    fps                    = 60,    # playback rate
    output_dir             = '/home/affneu/kenvdzee/Documents/phd_1_analysis/animations',  # folder to write MP4s into. None ->
                                    # current working directory. Created
                                    # if it doesn't exist.
 
    # animation timeline
    propagation            = False, # True -> show a build-up phase first
                                    # in which the wavefront expands at the
                                    # real speed of sound from the elements
                                    # outward, slowed down for viewing using
                                    # the same time-step as the steady-state
                                    # loop (see playback_slowdown).
                                    # False -> straight into the steady-state
                                    # loop with no build-up.
    playback_slowdown      = 1.0,   # slow-motion factor controlling visual
                                    # wave speed. 1.0 -> one acoustic period
                                    # plays in frames/fps seconds (e.g. 1.33 s
                                    # at 24 frames, 18 fps). Higher values
                                    # stretch each period over more playback
                                    # time -> slower-moving ripples. Applies
                                    # uniformly to BOTH the propagation phase
                                    # and the steady-state loop, so the wave
                                    # speed is identical across the seam.
    loop_seconds           = 10.0,   # seconds of steady-state loop AFTER
                                    # propagation. 0 -> one period; N -> the
                                    # one-period loop is replayed enough
                                    # times to fill N seconds. Replayed
                                    # frames are reused, not recomputed.
    record_max_pressure    = False, # True  -> each frame shows the running
                                    #          maximum of |pressure| at each
                                    #          pixel since the simulation
                                    #          started, rather than the
                                    #          instantaneous oscillating
                                    #          pressure. The image fills in
                                    #          from the elements outward and
                                    #          never decays; the focal spot
                                    #          stays lit once a converging
                                    #          wavefront has passed through.
                                    #          Useful for showing where the
                                    #          beam deposits energy without
                                    #          the visual clutter of carrier
                                    #          oscillation. Best paired with
                                    #          propagation=True.
                                    # False -> instantaneous pressure (the
                                    #          default ripple animation).
 
    enabled                = True,
)


# ======================================================================
#  RENDERS - edit this list. Each entry becomes one output file.
# ======================================================================

RENDERS = [
    dict(name="point_source_background",
         n_elements=1, element_width_mm=0,
         subsources_per_element=1,
         pressure_threshold = 0.2),

    dict(name="point_source",
         n_elements=1, element_width_mm=0,
         subsources_per_element=1, propagation=True),



    dict(name="transducer_from_start",
         n_elements=1, element_width_mm=40, radius_mm=50,
         propagation=True, loop_seconds=30,frames=15),

    dict(name="transducer_with_max",
         n_elements=64, element_width_mm=40, radius_mm=50,
         subsources_per_element=2,
         propagation=True, loop_seconds=0,frames=15,
         record_max_pressure=True),

    dict(name="transducer_defocussed",
         n_elements=10, element_width_mm=40, radius_mm=50,
         subsources_per_element=20,
         pressure_threshold = 0.2,
         phase_delays_deg=[0, 180, 0, 180, 0, 180, 0, 180, 0, 180],
         propagation=True,frames=15),

    dict(name="transducer_flat",
         n_elements=1, element_width_mm=40, radius_mm=0,
         subsources_per_element=128,
         propagation=True,frames=15),



    dict(name="transducer_curvature_40mm_R30",
         n_elements=1, element_width_mm=40, radius_mm=30,
         subsources_per_element=128),

    dict(name="transducer_curvature_40mm_R50",
         n_elements=1, element_width_mm=40, radius_mm=50,
         subsources_per_element=128),

    dict(name="transducer_curvature_40mm_R100",
         n_elements=1, element_width_mm=40, radius_mm=100,
         subsources_per_element=128),



    dict(name="transducer_width_30mm_R50",
         n_elements=1, transducer_width_mm=30, radius_mm=50,
         subsources_per_element=128),

    dict(name="transducer_width_80mm_R50",
         n_elements=1, transducer_width_mm=80, radius_mm=50,
         subsources_per_element=128),

    dict(name="transducer_width_180mm_R50",
         n_elements=1, transducer_width_mm=180, radius_mm=50,
         subsources_per_element=128),



    dict(name="transducer_low_frequency_40mm_R50",
         n_elements=1, element_width_mm=40, radius_mm=50,
         subsources_per_element=128,
         wavelength_mm=6,frames=60),

    dict(name="transducer_medium_frequency_40mm_R50",
         n_elements=1, element_width_mm=40, radius_mm=50,
         subsources_per_element=128,
         wavelength_mm=3),

    dict(name="transducer_high_frequency_40mm_R50",
         n_elements=1, element_width_mm=40, radius_mm=50,
         subsources_per_element=128,
         wavelength_mm=1.5,frames=15),



    dict(name="transducer_steering_close_40mm_R50",
         n_elements=64, element_width_mm=40, radius_mm=50,
         subsources_per_element=2,
         focus_depth_mm=35,loop_seconds=30,
         propagation=True,frames=15),

    dict(name="transducer_steering_medium_40mm_R50",
         n_elements=64, element_width_mm=40, radius_mm=50,
         subsources_per_element=2,
         focus_depth_mm=50,loop_seconds=30,
         propagation=True,frames=15),

    dict(name="transducer_steering_far_40mm_R50",
         n_elements=64, element_width_mm=40, radius_mm=50,
         subsources_per_element=2,
         focus_depth_mm=65,loop_seconds=30,
         propagation=True,frames=15),
]


# ======================================================================
#  END EDITABLE REGION
# ======================================================================
def make_palette():
    return LinearSegmentedColormap.from_list('water', [
        (0.00, (0.97, 0.98, 1.00)),
        (0.32, (0.55, 0.75, 0.90)),
        (0.64, (0.20, 0.50, 0.80)),
        (0.96, (0.55, 0.55, 0.75)),
        (0.98, (0.90, 0.55, 0.40)),
        (1.00, (0.80, 0.10, 0.15)),
    ])

WATER_CMAP = make_palette()
LIGHT      = LightSource(azdeg=315, altdeg=45)
 
 
# ----------------------------------------------------------------------
# Transducer schematic
# ----------------------------------------------------------------------
def transducer_backing_polyline(N, R, elem_width, backing_d):
    """Continuous black line tracing the element face.
 
    Drawn AT the element face (r = R for curved bowls, y = 0 for flat
    arrays) so it visually aligns with the field mask. `backing_d` only
    affects how much breathing room is left around it in the viewport;
    the line itself sits on the elements."""
    half_chord = elem_width / 2 if elem_width > 0 else 0.0
 
    if half_chord <= 0:
        return np.array([]), np.array([])
 
    if R > 5.0:
        # flat array: line along y = 0 (the element line itself)
        xs = np.array([-half_chord, +half_chord])
        ys = np.array([0.0, 0.0])
        return xs, ys
 
    # curved: arc at radius R (on the elements themselves)
    if half_chord >= R:
        half_theta = np.pi / 2
    else:
        half_theta = np.arcsin(half_chord / R)
    n_pts = max(64, int(200 * half_theta + 2))
    thetas = np.linspace(-half_theta, half_theta, n_pts)
    xs = R * np.sin(thetas)
    ys = R - R * np.cos(thetas)
    return xs, ys
 
 
# ----------------------------------------------------------------------
# Source discretisation - phases applied PER SUB-SOURCE
# ----------------------------------------------------------------------
def build_sources(N, R, elem_width, n_sub, k,
                  focus_depth=None, phase_delays_deg=None):
    """Build all Huygens sub-sources and per-ring phase delays.
 
    Each "element" is an annular ring; in this 2D cross-section it shows
    up as two arc segments mirrored across the central axis. ALL sub-
    sources within one ring (and its mirror) get the SAME phase delay -
    matching how a real annular array hardware operates (one driver per
    ring).
 
    Phase law priority:
      phase_delays_deg given : use those literal per-ring delays
                               (degrees, length must equal N).
      focus_depth given      : compute one delay per ring from the ring's
                               representative distance to (0, focus_depth).
                               This is the physical annular-array focusing
                               law. With N = 1 there's only one ring so
                               all relative delays are zero and the focus
                               stays at the natural geometric R.
      both None              : zero phase on all rings -> natural focus.
    """
    # --- element centres on the arc ---
    # ANNULAR ARRAY (2D cross-section). Each of the N "elements" is a
    # ring; in this side-view it shows up as TWO arc segments mirrored
    # across the central (y) axis. Ring i is driven by one phase / one
    # amplitude, applied identically to its left and right segments.
    #
    # Layout convention:
    #   ring 0   -> innermost (straddles the central axis)
    #   ring N-1 -> outermost (at the rim of the bowl/element_width)
    #
    if N == 1:
        # single full-aperture element: nothing to mirror, one segment
        # spanning -elem_width/2 ... +elem_width/2
        xc_unique  = np.array([0.0])
        yc_unique  = np.array([0.0])
        half_widths = np.array([elem_width / 2.0])
    else:
        # split the aperture into N equal-width rings; ring i occupies
        # |chord_offset| in [i * w, (i+1) * w]   where w = (full half-width)/N
        # ring 0 is centred on the axis (single segment, full width 2w);
        # rings 1..N-1 are two-segment, centred at +/- (i+0.5)*w * 2 chord ... 
        # actually simpler: just track each segment's centre position and width.
        ring_half_w = (elem_width / 2.0) / N        # half-width of each ring along the chord
        # we'll build the segment list directly: 2N - 1 segments
        # (the innermost ring is one segment straddling x = 0; the rest are
        # mirrored pairs). But for clarity and so phases mirror exactly, we
        # build N rings each with its own (signed) chord-centre offset for
        # the LEFT segment, and mirror at the very end.
        # Ring i (i = 0..N-1) occupies chord offsets in [i*2w, (i+1)*2w] on
        # each side; its centre is at (i + 0.5) * 2 * ring_half_w from the axis.
        ring_centre_offset = (np.arange(N) + 0.5) * (2 * ring_half_w)
        # project chord offset onto the bowl arc:
        if R > 5.0:
            xc_unique = ring_centre_offset           # right-side centres
            yc_unique = np.zeros(N)
        else:
            # chord offset -> arc angle from the central axis
            # x = R sin(theta), so theta = arcsin(x / R)
            offsets_clamped = np.clip(ring_centre_offset / R, -1.0, 1.0)
            thetas = np.arcsin(offsets_clamped)
            xc_unique = R * np.sin(thetas)
            yc_unique = R - R * np.cos(thetas)
        half_widths = np.full(N, ring_half_w)
 
    # per-ring (unique) apodisation: Hann taper across the rings, so the
    # outermost ring gets the lightest drive and the innermost the strongest.
    # The window is symmetric in ring-index, which is what you want for an
    # annular array (treat ring 0 as the centre of the aperture).
    if N >= 2:
        # Hann window indexed by ring distance from centre
        ring_idx = np.arange(N)
        apod_unique = 0.5 + 0.5 * np.cos(np.pi * (ring_idx + 0.5) / N)
    else:
        apod_unique = np.ones(N)
 
    # --- expand to sub-sources (mirror each ring's left + right segments) ---
    if elem_width <= 0 or n_sub <= 1:
        # No face-width: each ring is just its centre, but still mirrored.
        # ring 0 has its centre at x = 0 anyway, so mirroring it would
        # duplicate a source on the axis. Suppress that duplicate.
        if N == 1:
            xs = xc_unique; ys = yc_unique
            ws = apod_unique
        else:
            # right side
            xs_r = xc_unique; ys_r = yc_unique
            # left side: mirror x, drop ring 0 if its centre is on the axis
            keep = np.abs(xc_unique) > 1e-9
            xs_l = -xc_unique[keep]; ys_l = yc_unique[keep]
            xs = np.concatenate([xs_l[::-1], xs_r])
            ys = np.concatenate([ys_l[::-1], ys_r])
            ws = np.concatenate([apod_unique[keep][::-1], apod_unique])
    else:
        # discretise each ring along its own chord-width segment, then mirror.
        # For each ring i, sub-source j (j = 0..n_sub-1) sits at chord offset
        # ring_centre_offset[i] + (j - (n_sub-1)/2) * (2*half_widths[i]/n_sub)
        # on the right side; the left side is the mirror.
        j = np.arange(n_sub)
        local_offsets = (j - (n_sub - 1) / 2) * (2 * half_widths[:, None] / n_sub)
 
        if N == 1:
            # single big element straddles the axis; one segment, not mirrored
            chord_pos = local_offsets[0]
            if R > 5.0:
                xs = chord_pos.copy(); ys = np.zeros_like(chord_pos)
            else:
                offsets_clamped = np.clip(chord_pos / R, -1.0, 1.0)
                th = np.arcsin(offsets_clamped)
                xs = R * np.sin(th); ys = R - R * np.cos(th)
            ws = np.full(xs.size, apod_unique[0]) / np.sqrt(n_sub)
        else:
            # right-side chord positions for every (ring, sub) pair
            chord_right = (ring_centre_offset[:, None] + local_offsets).ravel()
            # left side: mirror
            chord_left  = -chord_right
 
            if R > 5.0:
                xs_r = chord_right;  ys_r = np.zeros_like(chord_right)
                xs_l = chord_left;   ys_l = np.zeros_like(chord_left)
            else:
                clp_r = np.clip(chord_right / R, -1.0, 1.0)
                th_r  = np.arcsin(clp_r)
                xs_r  = R * np.sin(th_r); ys_r = R - R * np.cos(th_r)
                clp_l = np.clip(chord_left / R, -1.0, 1.0)
                th_l  = np.arcsin(clp_l)
                xs_l  = R * np.sin(th_l); ys_l = R - R * np.cos(th_l)
 
            xs = np.concatenate([xs_l, xs_r])
            ys = np.concatenate([ys_l, ys_r])
 
            # weights: each sub-source carries its ring's apod / sqrt(n_sub)
            w_one_side = np.repeat(apod_unique, n_sub) / np.sqrt(n_sub)
            ws = np.concatenate([w_one_side, w_one_side])
 
    # --- mask defining where the field is allowed to exist ---
    # For a curved bowl, "outside the bowl" means anything farther than R
    # from the centre of curvature (0, R) - that's the physical solid body
    # behind the elements. The CUP of the bowl (interior, where r_center<=R
    # and y < R) stays fully illuminated, so you can see waves emerging
    # from the curved face.
    # For a flat array, we fall back to a half-plane mask along y = 0.
    # 'forward' is a small dict carrying whichever description applies.
    if R is not None and R < 5.0 and xs.size >= 2:
        forward = {'kind': 'bowl', 'R': R, 'cx': 0.0, 'cy': R}
    else:
        # flat or single-point: simple "everything at y >= 0" mask
        forward = {'kind': 'plane', 'cx': 0.0, 'cy': 0.0,
                   'nx': 0.0, 'ny': 1.0}
 
    # --- per-ring phase delays ---
    # Compute one delay per ring (the physical reality of an annular array
    # is one driver per ring), then broadcast across that ring's sub-sources
    # on both mirrored sides. This is the key change from the earlier per-
    # sub-source law: it correctly produces the focusing-quality-vs-N-rings
    # tradeoff that real annular arrays exhibit.
 
    if phase_delays_deg is not None:
        # Manual override. Length must match N.
        phase_delays_deg = np.asarray(phase_delays_deg, dtype=float)
        if phase_delays_deg.size != N:
            raise ValueError(
                f"phase_delays_deg has length {phase_delays_deg.size} "
                f"but n_elements is {N}")
        # treat input as DELAYS (positive = fire later): negate to convert
        # delay -> phase contribution to the cos(k r - omega t + phi) form.
        # Also wrap to (-pi, pi] so the rendering doesn't depend on whether
        # the user wrote 30 or 390.
        deg = ((phase_delays_deg + 180) % 360) - 180
        phase_per_ring = -np.deg2rad(deg)
    elif focus_depth is None:
        phase_per_ring = np.zeros(N)
    else:
        # Distance from each ring's CENTRE position to the focal target.
        # Using the ring centre (xc_unique, yc_unique) - representative of
        # the whole ring - means all sub-sources in a ring share one delay.
        d_ring = np.sqrt(xc_unique**2 + (focus_depth - yc_unique)**2)
        # subtract mean so phases stay centred (only relative delays matter)
        phase_per_ring = -k * (d_ring - d_ring.mean())
 
    # Broadcast ring phases out to every sub-source. The sub-source layout
    # depends on whether elem_width was 0 and whether N was 1 - mirror it
    # here exactly.
    if elem_width <= 0 or n_sub <= 1:
        if N == 1:
            phs = np.full(xs.size, phase_per_ring[0])
        else:
            keep = np.abs(xc_unique) > 1e-9
            # match the source layout: left mirror (rings with keep, reversed)
            # then right (all rings).
            phs_left  = phase_per_ring[keep][::-1]
            phs_right = phase_per_ring
            phs = np.concatenate([phs_left, phs_right])
    else:
        if N == 1:
            phs = np.full(xs.size, phase_per_ring[0])
        else:
            # right side: each ring contributes n_sub sub-sources in order
            phs_right = np.repeat(phase_per_ring, n_sub)
            # left side: same (mirrored geometry, same per-ring phase)
            phs_left  = phs_right.copy()
            phs = np.concatenate([phs_left, phs_right])
 
    return xs, ys, phs, ws, forward
 
 
# ----------------------------------------------------------------------
# Field and shading
# ----------------------------------------------------------------------
def field_at_time(t, sources, X, Y, k, omega, c, chunk=64,
                  causal_t=None):
    """Coherent pressure plus a boolean "outside the transducer body" mask.
 
    Returns (field, outside_mask). The mask is computed once from the
    transducer geometry and is True for any pixel that lies outside the
    physical transducer body (i.e. behind a flat array, or outside the
    bowl shell). shade_frame() paints those pixels pure white AFTER the
    hill-shader runs, so the calm background really is white rather than
    the faint blue tint the shader otherwise produces for a flat field.
 
    causal_t : None or float
        If None (steady-state): every source contributes its full CW field.
        If a float (build-up phase): the field is restricted to the causal
        wavefront -- a sub-source contributes to a pixel only if the wave
        has had time to travel from source to pixel.
    """
    xs, ys, phs, ws, forward = sources
 
    n_src = xs.size
    total = np.zeros_like(X)
    for i in range(0, n_src, chunk):
        sl = slice(i, i + chunk)
        dx = X[None] - xs[sl, None, None]
        dy = Y[None] - ys[sl, None, None]
        r  = np.sqrt(dx*dx + dy*dy) + 1e-6
        wave = np.cos(k*r - omega*t + phs[sl, None, None]) / np.sqrt(r)
        if causal_t is not None:
            arrived = r <= c * causal_t
            wave = wave * arrived
        total += np.sum(ws[sl, None, None] * wave, axis=0)
 
    # Build the outside-transducer boolean mask. Pixels where this is True
    # will be painted white after shading.
    # For a curved bowl the mask kills only the BACK of the transducer
    # body. A pixel is "behind" the bowl if it's farther than R from the
    # centre of curvature AND on the back side of the bowl's equatorial
    # plane (y < cy). Points beyond the centre of curvature on the FOCUS
    # side (y >= cy, including the post-focal region) stay illuminated.
    if forward['kind'] == 'bowl':
        r_center = np.sqrt((X - forward['cx'])**2 + (Y - forward['cy'])**2)
        outside = (r_center > forward['R']) & (Y < forward['cy'])
    else:
        fwd = (X - forward['cx']) * forward['nx'] + (Y - forward['cy']) * forward['ny']
        outside = fwd < 0
 
    # also zero the field in the masked region so it can't leak into the
    # nearby hillshade (which uses gradients across pixel neighbours)
    total = np.where(outside, 0.0, total)
    return total, outside
 
 
def shade_frame(field, outside, vlim, threshold, vert_exag):
    cutoff   = threshold * vlim
    residual = np.maximum(field - cutoff, 0.0)
    scale    = max(1e-9, vlim - cutoff)
    elev     = np.tanh(residual / scale)
    rgb = LIGHT.shade(elev, cmap=WATER_CMAP, vert_exag=vert_exag,
                      blend_mode='overlay')[..., :3]
    # paint pure white anywhere the field is below threshold (calm water)
    # or outside the transducer body. This overrides the faint blue tint
    # the hillshader produces on flat regions even at zero amplitude.
    calm = residual <= 0
    rgb[calm | outside] = 1.0
    return rgb
 
 
# ----------------------------------------------------------------------
# Per-render driver
# ----------------------------------------------------------------------
def ffmpeg_available():
    try:
        return FFMpegWriter.isAvailable()
    except Exception:
        return False
 
 
def render_one(cfg, out_dir):
    name = cfg['name']
    print(f'[{name}]')
 
    c     = cfg['speed_of_sound']
    lam   = cfg['wavelength_mm'] * 1e-3
    f     = c / lam
    omega = 2 * np.pi * f
    k     = omega / c
 
    dom_x = cfg['domain_x_mm'] * 1e-3
    dom_y = cfg['domain_y_mm'] * 1e-3
 
    fig_short = 6.5
    aspect = dom_x / dom_y
    fig_size = (fig_short*aspect, fig_short) if aspect >= 1 else (fig_short, fig_short/aspect)
 
    dpi    = cfg['output_dpi']
    grid_x = max(2, int(round(fig_size[0] * dpi)))
    grid_y = max(2, int(round(fig_size[1] * dpi)))
    print(f'  grid {grid_x} x {grid_y} px at {dpi} dpi')
 
    lam_px = lam / (dom_x / grid_x)
    if lam_px < 4:
        print(f'  WARNING: only {lam_px:.1f} px per wavelength - '
              f'bump output_dpi to avoid aliasing')
 
    x = np.linspace(-dom_x/2, dom_x/2, grid_x)
    y = np.linspace(0.0, dom_y, grid_y)
    X, Y = np.meshgrid(x, y)
 
    # Resolve element width to a chord (what build_sources and the
    # backing polyline both consume). element_width_mm is already a chord;
    # transducer_width_mm is an arc length and gets converted via
    #   chord = 2 R sin(arc / (2R))
    # Capped at 2*R when the arc reaches a full hemisphere (pi*R).
    raw_R_mm   = cfg['radius_mm']
    if raw_R_mm is None or raw_R_mm <= 0:
        R_m = 1e9
    else:
        R_m = raw_R_mm * 1e-3
    tw_mm = cfg['transducer_width_mm']
    ew_mm = cfg['element_width_mm']
    if tw_mm is not None:
        arc_input_m = tw_mm * 1e-3
        if R_m > 5.0 or arc_input_m <= 0:
            chord_m = arc_input_m                           # flat / degenerate
        elif arc_input_m >= np.pi * R_m:
            chord_m = 2 * R_m                               # full hemisphere
            print(f'  NOTE: transducer_width_mm ({tw_mm:.1f} mm) >= pi*R '
                  f'({np.pi*R_m*1000:.1f} mm); capped to full hemisphere '
                  f'(chord = {chord_m*1000:.1f} mm).')
        else:
            chord_m = 2 * R_m * np.sin(arc_input_m / (2 * R_m))
        print(f'  transducer_width_mm = {tw_mm:.2f} mm arc '
              f'-> chord = {chord_m*1000:.2f} mm')
    else:
        chord_m = ew_mm * 1e-3
 
    fd = cfg['focus_depth_mm']
    pd = cfg['phase_delays_deg']
    sources = build_sources(
        N                = cfg['n_elements'],
        R                = R_m,
        elem_width       = chord_m,
        n_sub            = cfg['subsources_per_element'],
        k                = k,
        focus_depth      = None if fd is None else fd * 1e-3,
        phase_delays_deg = pd,
    )
    if pd is not None:
        mode = f'manual delays {list(np.asarray(pd, dtype=float))}'
    elif fd is not None:
        mode = f'focused at {fd} mm'
    else:
        mode = 'natural focus'
    print(f'  {len(sources[0])} sub-sources, {mode}')
 
    probe, outside = field_at_time(0.0, sources, X, Y, k, omega, c)
    if cfg['record_max_pressure']:
        # In max mode we display the running max of |pressure|. Estimate
        # the eventual steady-state envelope by sampling a few phases of
        # one period and taking the per-pixel maximum, so vlim matches the
        # range of values the accumulator will actually reach.
        envelope = np.zeros_like(probe)
        for tp in np.linspace(0.0, 1.0/f, 8, endpoint=False):
            fld, _ = field_at_time(tp, sources, X, Y, k, omega, c)
            np.maximum(envelope, np.abs(fld), out=envelope)
        vlim = max(1e-3, np.percentile(envelope, 98))
    else:
        vlim  = max(1e-3, np.percentile(np.abs(probe), 98))
 
    fig = plt.figure(figsize=fig_size, dpi=dpi)
    ax  = fig.add_axes([0, 0, 1, 1]); ax.set_axis_off()
    im  = ax.imshow(shade_frame(probe, outside, vlim,
                                cfg['pressure_threshold'], cfg['vert_exag']),
                    origin='lower', interpolation='bilinear',
                    extent=[-dom_x/2, dom_x/2, 0.0, dom_y])
 
    backing_d = cfg['backing_depth_mm'] * 1e-3
    if cfg['show_transducer'] and backing_d > 0:
        bx, by = transducer_backing_polyline(
            N          = cfg['n_elements'],
            R          = R_m,
            elem_width = chord_m,
            backing_d  = backing_d,
        )
        ax.plot(bx, by, color='black',
                linewidth=cfg['backing_linewidth'],
                solid_capstyle='round', solid_joinstyle='round',
                zorder=10)
        pad = 2 * backing_d
        x_min = min(-dom_x/2, bx.min() - pad) if bx.size else -dom_x/2
        x_max = max( dom_x/2, bx.max() + pad) if bx.size else  dom_x/2
        y_min = min(0.0,      by.min() - pad) if by.size else 0.0
        y_max = max(dom_y,    by.max() + pad) if by.size else dom_y
        ax.set_xlim(x_min, x_max)
        ax.set_ylim(y_min, y_max)
    else:
        ax.set_xlim(-dom_x/2, dom_x/2)
        ax.set_ylim(0.0, dom_y)
 
    # ------------------------------------------------------------------
    # Build a frame plan. Two phases:
    #   - "propagation" (optional): waves expand from rest at the speed of
    #     sound, with anything beyond the causal radius masked off. Each
    #     frame is unique, so each is computed once.
    #   - "loop": one full acoustic period sampled at n_loop_eff frames,
    #     then replayed enough times to fill loop_seconds. Replayed frames
    #     come from the cache, not recomputed.
    # Both phases share the same physical time-step (dt_real), so the
    # visual speed of the carrier crests is identical in both. There is
    # no acceleration at the transition.
    # ------------------------------------------------------------------
    period   = 1.0 / f
    n_loop   = cfg['frames']
    fps_     = cfg['fps']
 
    # A single time-step governs BOTH the propagation and loop phases.
    # The loop is sampled at n_loop_eff = n_loop * playback_slowdown points
    # per acoustic period, giving dt_real = period / n_loop_eff seconds of
    # physical time per playback frame. Propagation uses the same dt_real,
    # so the carrier crests and the expanding mask move at identical
    # visual speeds across both phases -- no apparent acceleration at the
    # transition.
    play_slow  = max(1.0, float(cfg['playback_slowdown']))
    n_loop_eff = max(n_loop, int(round(n_loop * play_slow)))
    dt_real    = period / n_loop_eff
 
    if cfg['propagation']:
        diag   = np.hypot(dom_x, dom_y) * 1.1                  # +10% margin
        n_prop = max(1, int(np.ceil((diag / c) / dt_real)))    # frames to cross
        prop_secs = n_prop / fps_
        print(f'  propagation: wavefront crosses {diag*1000:.1f} mm in '
              f'{prop_secs:.2f} s ({n_prop} frames)')
    else:
        n_prop = 0
 
    plan = []
    for j in range(n_prop):
        t_j        = j * dt_real                               # carrier
        causal_t_j = (j + 1) * dt_real                         # one frame ahead
        plan.append((('prop', j), t_j, causal_t_j))
 
    # Steady-state loop segment. Sample n_loop_eff points across one
    # period, rotated so the first loop frame's phase matches where
    # propagation ended (no visible jump at the seam).
    base_times = np.linspace(0.0, period, n_loop_eff, endpoint=False)
    if n_prop > 0:
        phase_continuity = (n_prop * dt_real) % period
        shift_frames     = int(round(phase_continuity / period * n_loop_eff)) % n_loop_eff
    else:
        shift_frames = 0
    loop_times = np.roll(base_times, -shift_frames)
 
    loop_seconds = max(0.0, cfg['loop_seconds'])
    if loop_seconds <= 0:
        n_repeats = 1
    else:
        n_repeats = max(1, int(np.ceil(loop_seconds * fps_ / n_loop_eff)))
    for _ in range(n_repeats):
        for j in range(n_loop_eff):
            plan.append((('loop', j), loop_times[j], None))

    if cfg['record_max_pressure'] and loop_seconds > 0:
        # In max-pressure mode the loop section just holds on the final
        # steady-state max (no oscillation, no further accumulation past
        # one period). Worth flagging so the user knows the loop frames
        # aren't doing anything novel.
        print(f'  NOTE: record_max_pressure=True; loop_seconds={loop_seconds}s '
              f'just holds the final max-pressure image.')

    print(f'  {n_prop} prop frames + {n_repeats} x {n_loop_eff} loop frames '
          f'= {len(plan)} total ({len(plan)/fps_:.2f} s)')
 
    # cache of already-rendered RGB frames (matplotlib reuses the canvas
    # via im.set_data, but we still want to skip the field+shade work
    # for replayed loop frames)
    cache = {}

    # Max-pressure mode keeps a running per-pixel maximum of |pressure|
    # across all frames seen so far. Each "frame" shown is just the current
    # state of that accumulator passed through the shading pipeline, so
    # values never decrease over time and the image fills in monotonically.
    # The accumulator is fresh per render and lives in this closure scope.
    record_max = bool(cfg['record_max_pressure'])
    max_field  = np.zeros_like(X) if record_max else None
    # In max mode we DON'T want to reuse cached frames (the accumulator
    # changes every frame), so the cache_key gets the frame index baked in.

    def render_field(t, causal_t):
        fld, outside_now = field_at_time(t, sources, X, Y, k, omega, c,
                                         causal_t=causal_t)
        if record_max:
            np.maximum(max_field, np.abs(fld), out=max_field)
            display_field = max_field
        else:
            display_field = fld
        return shade_frame(display_field, outside_now, vlim,
                           cfg['pressure_threshold'], cfg['vert_exag'])

    def upd(frame_idx):
        key, t, causal_t = plan[frame_idx]
        # In max-pressure mode every frame is unique (accumulator state
        # depends on history), so don't use the cache at all.
        if record_max:
            im.set_data(render_field(t, causal_t))
        else:
            if key not in cache:
                cache[key] = render_field(t, causal_t)
            im.set_data(cache[key])
        return im,
 
    anim = FuncAnimation(fig, upd, frames=len(plan), blit=False)
 
    if not ffmpeg_available():
        raise RuntimeError(
            "ffmpeg not found on PATH. Install ffmpeg to render MP4 output "
            "(on macOS: 'brew install ffmpeg'; "
            "on Ubuntu: 'sudo apt install ffmpeg'; "
            "on Windows: download from https://www.gyan.dev/ffmpeg/builds/)."
        )
 
    out = os.path.join(out_dir, name + '.mp4')
    # Mathematically lossless H.264 (every pixel preserved exactly).
    # yuv444p keeps the full RGB rather than throwing away chroma
    # detail like the standard yuv420p subsampling does; profile high444
    # is required to carry it. +faststart moves the metadata to the
    # front of the file so PowerPoint starts playback immediately.
    # PowerPoint 2016+ on Windows and Mac decodes this fine.
    writer = FFMpegWriter(
        fps=cfg['fps'],
        codec='libx264',
        extra_args=[
            '-pix_fmt', 'yuv444p',
            '-preset', 'veryslow',      # smallest lossless file
            '-crf', '0',                # 0 = mathematically lossless
            '-profile:v', 'high444',
            '-movflags', '+faststart',
        ],
    )
    anim.save(out, writer=writer)
    print(f'  wrote {out}')
 
    plt.close(fig)
 
 
def main():
    # Command-line interface for Slurm job-array use:
    #   no args                  -> render every enabled entry (legacy behaviour)
    #   --list                   -> print the names of all enabled renders,
    #                               one per line, then exit. The Slurm
    #                               dispatcher uses this to know what to submit.
    #   --name NAME              -> render only the entry with that name.
    #                               Used by individual sbatch sub-jobs.
    import argparse
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('--name',  help='render only the entry with this name')
    p.add_argument('--list',  action='store_true',
                   help='print all enabled render names and exit')
    args = p.parse_args()

    enabled = [r for r in RENDERS if {**DEFAULTS, **r}['enabled']]

    if args.list:
        for r in enabled:
            print(r['name'])
        return

    seen = set()
    for r in enabled:
        nm = r.get('name', '?')
        if nm in seen:
            raise ValueError(f"duplicate render name: {nm!r}")
        seen.add(nm)

    if args.name is not None:
        matches = [r for r in enabled if r.get('name') == args.name]
        if not matches:
            available = ', '.join(r['name'] for r in enabled)
            raise SystemExit(
                f"no enabled render named {args.name!r}. "
                f"Available: {available}")
        targets = matches
        print(f'rendering 1 entry: {args.name}')
    else:
        targets = enabled
        print(f'rendering {len(enabled)} / {len(RENDERS)} entries')

    for r in targets:
        cfg = {**DEFAULTS, **r}
        if 'name' not in r:
            raise ValueError(f"render is missing 'name': {r}")
        out_dir = cfg['output_dir'] if cfg['output_dir'] is not None else os.getcwd()
        out_dir = os.path.abspath(os.path.expanduser(out_dir))
        os.makedirs(out_dir, exist_ok=True)
        render_one(cfg, out_dir)

    print('done.')
 
 
if __name__ == '__main__':
    main()
