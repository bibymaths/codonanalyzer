#!/usr/bin/env python3

import argparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

def read_hplot(fname):
    """
    Read H_PLOT.txt into a dict of {name: [hydropathy values]}.
    """
    records = {}
    with open(fname) as f:
        for line in f:
            parts = line.rstrip().split('\t')
            if len(parts) != 3:
                continue
            name, _, vals = parts
            records[name] = np.fromstring(vals, sep=' ', dtype=float)
    return records

def plot_profile(name, hydro, smooth_window=None, out_prefix=None):
    """
    Line plot of hydropathy vs residue position.
    """
    positions = np.arange(1, hydro.size + 1)
    fig, ax = plt.subplots()
    ax.plot(positions, hydro, alpha=0.3, linewidth=0.5)
    if smooth_window and smooth_window > 1:
        kernel = np.ones(smooth_window) / smooth_window
        smooth = np.convolve(hydro, kernel, mode='same')
        ax.plot(positions, smooth, linewidth=1.5, label=f'Smoothed({smooth_window})')
        ax.legend(loc='upper right', fontsize='small')
    ax.set_title(f"Hydropathy: {name}")
    ax.set_xlabel("Residue Position")
    ax.set_ylabel("Kyte–Dood Value")
    ax.grid(True, linestyle='--', linewidth=0.5)
    fig.tight_layout()
    fname = f"{out_prefix or name}_profile.png"
    fig.savefig(fname, dpi=150)
    plt.close(fig)

def plot_histogram(name, hydro, bins, out_prefix=None):
    """
    Histogram of hydropathy values.
    """
    fig, ax = plt.subplots()
    ax.hist(hydro, bins=bins, edgecolor='black', linewidth=0.5)
    ax.set_title(f"Distribution: {name}")
    ax.set_xlabel("Value")
    ax.set_ylabel("Frequency")
    ax.grid(True, linestyle='--', linewidth=0.5)
    fig.tight_layout()
    fname = f"{out_prefix or name}_hist.png"
    fig.savefig(fname, dpi=150)
    plt.close(fig)

def plot_boxplot(records, out_prefix="all"):
    """
    Boxplot comparing hydropathy distributions.
    """
    names = list(records.keys())
    data = [records[n] for n in names]
    fig, ax = plt.subplots()
    ax.boxplot(data, labels=names, vert=True, patch_artist=True)
    ax.set_title("Boxplot Hydropathy")
    ax.set_ylabel("Value")
    ax.grid(True, linestyle='--', linewidth=0.5)
    fig.tight_layout()
    fname = f"{out_prefix}_boxplot.png"
    fig.savefig(fname, dpi=150)
    plt.close(fig)

def main():
    parser = argparse.ArgumentParser(description="Fast hydropathy plots")
    parser.add_argument("hplot", help="H_PLOT.txt file")
    parser.add_argument("-t", "--target", help="Sequence ID to plot")
    parser.add_argument("-w", "--window", type=int, default=11,
                        help="Smoothing window size")
    parser.add_argument("-b", "--bins", type=int, default=30,
                        help="Histogram bins")
    args = parser.parse_args()

    records = read_hplot(args.hplot)
    if args.target:
        if args.target not in records:
            parser.error(f"Target {args.target} not found")
        records = {args.target: records[args.target]}

    for name, hydro in records.items():
        prefix = f"{name}"
        plot_profile(name, hydro, smooth_window=args.window, out_prefix=prefix)
        plot_histogram(name, hydro, bins=args.bins, out_prefix=prefix)

    if not args.target and len(records) > 1:
        plot_boxplot(records)

    print("Plots saved to current directory (*.png)")

if __name__ == "__main__":
    main()

