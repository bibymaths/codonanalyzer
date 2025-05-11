#!/usr/bin/env python3

import argparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

def read_hplot(fname):
    """
    Read H_PLOT.txt into a dict of {name: hydropathy_array}.
    Expects a header line with three tab-columns.
    """
    records = {}
    with open(fname) as f:
        next(f)
        for line in f:
            line = line.strip()
            parts = line.split('\t')
            if len(parts) != 3:
                continue
            name, _, vals = parts
            vals = vals.strip()
            if not vals:
                continue
            arr = np.fromstring(vals, sep=' ', dtype=float)
            if arr.size:
                records[name] = arr
    return records


def plot_histogram(name, hydro, bins, out_prefix=None):
    """
    Histogram of hydropathy values.
    """
    fig, ax = plt.subplots()
    ax.hist(hydro, bins=bins, edgecolor='black', linewidth=0.5)
    ax.set_title(f"{name}")
    ax.set_xlabel("Value")
    ax.set_ylabel("Frequency")
    ax.grid(True, linestyle='--', linewidth=0.2)
    fig.tight_layout()
    fname = f"hplot.png"
    fig.savefig(fname, dpi=300)
    plt.close(fig)

def main():
    parser = argparse.ArgumentParser(description="Hydropathy Histogram Plotter")
    parser.add_argument("hplot", help="H_PLOT.txt file")
    parser.add_argument("-t", "--target", help="Sequence ID to plot")
    parser.add_argument("-b", "--bins", type=int, default=30,
                        help="Histogram bins")
    args = parser.parse_args()

    records = read_hplot(args.hplot)
    if args.target:
        if args.target not in records:
            parser.error(f"Target {args.target} not found")
        records = {args.target: records[args.target]}

    for name, hydro in records.items():
        plot_histogram(name, hydro, bins=args.bins)

if __name__ == "__main__":
    main()

