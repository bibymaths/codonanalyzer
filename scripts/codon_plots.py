#!/usr/bin/env python3
"""
codon_plots.py - Visualise codon usage metrics from codon.pl output.

Author : Abhinav Mishra <mishraabhinav36@gmail.com>
Date   : 2025
License: MIT
Usage  : python codon_plots.py <codon_out.txt> <output_prefix>
         Writes <output_prefix>.png  (and .pdf).
"""

import sys
import re
import math
from pathlib import Path
from collections import defaultdict

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.colors import Normalize
from matplotlib.cm import ScalarMappable
import numpy as np

# ── CLI ───────────────────────────────────────────────────────────────────────
if len(sys.argv) < 3:
    sys.exit("Usage: codon_plots.py <codon_out.txt> <output_prefix>")

in_txt   = Path(sys.argv[1])
out_pfx  = Path(sys.argv[2])


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1 – Parser
# ══════════════════════════════════════════════════════════════════════════════

def parse_report(path: Path) -> dict:
    """Parse the plain-text report produced by codon.pl into a dict."""
    txt   = path.read_text(encoding="utf-8")
    data  = {}

    # ── scalar values ────────────────────────────────────────────────────────
    def _find(pattern, cast=str):
        m = re.search(pattern, txt)
        return cast(m.group(1).strip()) if m else None

    data["length"]  = _find(r"length:\s+(\d+)",  int)
    data["n_codon"] = _find(r"codons:\s+(\d+)",  int)
    data["GCpct"]   = _find(r"GC%=\s*([\d.]+)",  float)
    data["ATpct"]   = _find(r"AT%=\s*([\d.]+)",  float)
    data["GCskew"]  = _find(r"GC skew=\s*([-\d.]+|NA)", float) if _find(r"GC skew=\s*([-\d.NA]+)") != "NA" else None
    data["ATskew"]  = _find(r"AT skew=\s*([-\d.]+|NA)", float) if _find(r"AT skew=\s*([-\d.NA]+)") != "NA" else None
    data["Enc"]     = _find(r"Effective Number of Codons \(ENc\):\s*([\d.]+)", float)
    data["H"]       = _find(r"3-MER SHANNON ENTROPY:\s*([\d.]+)", float)

    # nucleotide counts
    m = re.search(r"A=(\d+)\s+T=(\d+)\s+G=(\d+)\s+C=(\d+)", txt)
    if m:
        data["nt"] = {k: int(v) for k, v in zip("ATGC", m.groups())}

    # ── ORF stats ─────────────────────────────────────────────────────────────
    data["start_ct"] = _find(r"start codons \(ATG\):\s*(\d+)", int)
    data["stop_ct"]  = _find(r"stop\s+codons.*?:\s*(\d+)", int)
    data["n_orfs"]   = _find(r"ORFs found:\s*(\d+)", int)
    data["max_orf"]  = _find(r"longest ORF:\s*(\d+)", int)
    data["avg_orf"]  = _find(r"average ORF:\s*([\d.]+)", float)

    # ── block parser helper ───────────────────────────────────────────────────
    def _parse_kv_block(header_re, line_re):
        """Extract key→value pairs from a labelled block."""
        result = {}
        m = re.search(header_re + r"(.*?)(?=\n[A-Z3\-])", txt, re.S)
        if not m:
            return result
        for row in m.group(1).splitlines():
            lm = re.match(line_re, row.strip())
            if lm:
                result[lm.group(1)] = float(lm.group(2))
        return result

    # codon counts
    data["codon"] = _parse_kv_block(
        r"CODON COUNTS:\n",
        r"([A-Z]{3}):\s+([\d]+)"
    )

    # RSCU
    data["RSCU"] = _parse_kv_block(
        r"RSCU:\n",
        r"([A-Z]{3}):\s+([\d.]+)"
    )

    # amino-acid composition
    data["aa"] = {}
    aa_block = re.search(r"AMINO-ACID COMPOSITION:\n(.*?)(?=\nORF)", txt, re.S)
    if aa_block:
        for row in aa_block.group(1).splitlines():
            am = re.match(r"([A-Z\*]):\s+(\d+)\s+\(([\d.]+)%\)", row.strip())
            if am:
                data["aa"][am.group(1)] = {
                    "count": int(am.group(2)),
                    "pct":   float(am.group(3))
                }

    # dinucleotide counts
    data["di"] = _parse_kv_block(
        r"DINUCLT COUNT:\n",
        r"([A-Z]{2}):\s+(\d+)"
    )

    # sliding GC%
    gc_wins = []
    for row in re.findall(r"(\d+)–(\d+):\s*([\d.]+)%", txt):
        mid = (int(row[0]) + int(row[1])) / 2
        gc_wins.append((mid, float(row[2])))
    data["win_gc"] = gc_wins

    return data


report = parse_report(in_txt)


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2 – Codon-table helpers
# ══════════════════════════════════════════════════════════════════════════════

# Standard genetic code groupings  codon → amino-acid (single-letter)
_C2AA = {
    "TTT":"F","TTC":"F","TTA":"L","TTG":"L",
    "CTT":"L","CTC":"L","CTA":"L","CTG":"L",
    "ATT":"I","ATC":"I","ATA":"I","ATG":"M",
    "GTT":"V","GTC":"V","GTA":"V","GTG":"V",
    "TCT":"S","TCC":"S","TCA":"S","TCG":"S",
    "AGT":"S","AGC":"S","CCT":"P","CCC":"P",
    "CCA":"P","CCG":"P","ACT":"T","ACC":"T",
    "ACA":"T","ACG":"T","GCT":"A","GCC":"A",
    "GCA":"A","GCG":"A","TAT":"Y","TAC":"Y",
    "TAA":"*","TAG":"*","TGT":"C","TGC":"C",
    "TGA":"*","TGG":"W","CAT":"H","CAC":"H",
    "CAA":"Q","CAG":"Q","AAT":"N","AAC":"N",
    "AAA":"K","AAG":"K","GAT":"D","GAC":"D",
    "GAA":"E","GAG":"E","CGT":"R","CGC":"R",
    "CGA":"R","CGG":"R","AGA":"R","AGG":"R",
    "GGT":"G","GGC":"G","GGA":"G","GGG":"G",
}

# group codons by amino-acid (excluding stops for most plots)
_AA2C = defaultdict(list)
for _c, _a in _C2AA.items():
    _AA2C[_a].append(_c)

# canonical amino-acid order (hydrophobic → polar → charged)
AA_ORDER = list("ACDEFGHIKLMNPQRSTVWY")


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3 – Figure layout
# ══════════════════════════════════════════════════════════════════════════════

fig = plt.figure(figsize=(22, 28))
fig.patch.set_facecolor("#fafafa")

gs = gridspec.GridSpec(
    4, 3,
    figure=fig,
    hspace=0.52,
    wspace=0.38,
    left=0.06, right=0.97,
    top=0.95,  bottom=0.04,
)

title_kw  = dict(fontsize=11, fontweight="bold", pad=8)
label_kw  = dict(fontsize=9)
tick_kw   = dict(labelsize=8)
ACCENT    = "#2E86AB"
ACCENT2   = "#E84855"
NEUTRAL   = "#A9A9A9"


# ══════════════════════════════════════════════════════════════════════════════
# Plot 1 – Nucleotide composition  (pie)
# ══════════════════════════════════════════════════════════════════════════════
ax1 = fig.add_subplot(gs[0, 0])
nt  = report.get("nt", {})
if nt:
    colors_nt = ["#4C9BE8", "#E87040", "#50C878", "#E8D040"]
    wedge_kw  = dict(startangle=90, colors=colors_nt,
                     wedgeprops=dict(edgecolor="white", linewidth=1.5))
    ax1.pie(
        [nt.get(k, 0) for k in "ATGC"],
        labels=[f"{k}\n{nt.get(k,0):,}" for k in "ATGC"],
        autopct="%1.1f%%",
        pctdistance=0.75,
        textprops={"fontsize": 9},
        **wedge_kw,
    )
ax1.set_title("Nucleotide Composition", **title_kw)


# ══════════════════════════════════════════════════════════════════════════════
# Plot 2 – Scalar metrics  (horizontal bar)
# ══════════════════════════════════════════════════════════════════════════════
ax2   = fig.add_subplot(gs[0, 1])
m_lbl = ["GC %", "AT %", "GC skew", "AT skew", "ENc", "Entropy (bits)"]
m_val = [
    report.get("GCpct", 0),
    report.get("ATpct", 0),
    report.get("GCskew") or 0,
    report.get("ATskew") or 0,
    report.get("Enc", 0),
    report.get("H", 0),
]
m_colors = [ACCENT if v >= 0 else ACCENT2 for v in m_val]
bars = ax2.barh(m_lbl, m_val, color=m_colors, edgecolor="white")
ax2.axvline(0, color="#888", linewidth=0.8, linestyle="--")
for bar, val in zip(bars, m_val):
    ax2.text(
        bar.get_width() + (0.3 if val >= 0 else -0.3),
        bar.get_y() + bar.get_height() / 2,
        f"{val:.2f}",
        va="center", ha="left" if val >= 0 else "right",
        fontsize=8,
    )
ax2.set_title("Sequence Metrics", **title_kw)
ax2.tick_params(**tick_kw)
ax2.set_xlabel("Value", **label_kw)


# ══════════════════════════════════════════════════════════════════════════════
# Plot 3 – ORF statistics  (bar)
# ══════════════════════════════════════════════════════════════════════════════
ax3 = fig.add_subplot(gs[0, 2])
orf_labels = ["Start\n(ATG)", "Stop\n(TAA/TAG/TGA)", "ORFs\nfound",
              "Longest ORF\n(nt)", "Avg ORF\n(nt)"]
orf_vals   = [
    report.get("start_ct", 0),
    report.get("stop_ct",  0),
    report.get("n_orfs",   0),
    report.get("max_orf",  0),
    report.get("avg_orf",  0),
]
bar_colors = ["#50C878", ACCENT2, ACCENT, "#F4A261", "#8338EC"]
ax3.bar(orf_labels, orf_vals, color=bar_colors, edgecolor="white", width=0.6)
for xi, v in enumerate(orf_vals):
    ax3.text(xi, v + max(orf_vals) * 0.01, f"{v:.0f}",
             ha="center", va="bottom", fontsize=8)
ax3.set_title("ORF Statistics", **title_kw)
ax3.tick_params(**tick_kw)
ax3.set_ylabel("Count / Length (nt)", **label_kw)


# ══════════════════════════════════════════════════════════════════════════════
# Plot 4 – Codon counts heatmap (64 codons × 1, grouped by AA)
# ══════════════════════════════════════════════════════════════════════════════
ax4 = fig.add_subplot(gs[1, :])

codon_data = report.get("codon", {})
# build ordered list: group codons by AA in AA_ORDER, then stops
order_codons = []
for aa in AA_ORDER + ["*"]:
    for cd in sorted(_AA2C.get(aa, [])):
        order_codons.append((cd, aa))

x_labels = [f"{cd}\n({aa})" for cd, aa in order_codons]
counts    = np.array([codon_data.get(cd, 0) for cd, _ in order_codons],
                     dtype=float).reshape(1, -1)

cmap4 = plt.cm.YlOrRd
im4   = ax4.imshow(counts, aspect="auto", cmap=cmap4,
                   norm=Normalize(vmin=0, vmax=counts.max() or 1))
ax4.set_xticks(range(len(x_labels)))
ax4.set_xticklabels(x_labels, fontsize=6.5, rotation=90)
ax4.set_yticks([])
ax4.set_title("Codon Count Heatmap (grouped by amino acid)", **title_kw)
plt.colorbar(im4, ax=ax4, orientation="horizontal", pad=0.22,
             fraction=0.025, label="Count")

# draw AA-group separators
aa_boundaries = []
cur_aa = order_codons[0][1]
for i, (_, aa) in enumerate(order_codons):
    if aa != cur_aa:
        aa_boundaries.append(i - 0.5)
        cur_aa = aa
for xb in aa_boundaries:
    ax4.axvline(xb, color="white", linewidth=1.2)


# ══════════════════════════════════════════════════════════════════════════════
# Plot 5 – RSCU heatmap
# ══════════════════════════════════════════════════════════════════════════════
ax5 = fig.add_subplot(gs[2, :])

rscu_data = report.get("RSCU", {})
rscu_vals = np.array([rscu_data.get(cd, 0.0) for cd, _ in order_codons],
                     dtype=float).reshape(1, -1)

cmap5 = plt.cm.RdYlGn
im5   = ax5.imshow(rscu_vals, aspect="auto", cmap=cmap5,
                   norm=Normalize(vmin=0, vmax=max(rscu_vals.max(), 2.0)))
ax5.set_xticks(range(len(x_labels)))
ax5.set_xticklabels(x_labels, fontsize=6.5, rotation=90)
ax5.set_yticks([])
ax5.set_title("RSCU Heatmap  (green = over-represented, red = under-represented)", **title_kw)
plt.colorbar(im5, ax=ax5, orientation="horizontal", pad=0.22,
             fraction=0.025, label="RSCU")
for xb in aa_boundaries:
    ax5.axvline(xb, color="white", linewidth=1.2)


# ══════════════════════════════════════════════════════════════════════════════
# Plot 6 – Amino-acid composition  (horizontal bar)
# ══════════════════════════════════════════════════════════════════════════════
ax6 = fig.add_subplot(gs[3, 0:2])
aa_data = report.get("aa", {})
aa_pcts = [aa_data.get(a, {}).get("pct", 0.0) for a in AA_ORDER]
bar6    = ax6.barh(AA_ORDER, aa_pcts,
                   color=[plt.cm.tab20(i / len(AA_ORDER)) for i in range(len(AA_ORDER))],
                   edgecolor="white")
for b, v in zip(bar6, aa_pcts):
    if v > 0:
        ax6.text(v + 0.05, b.get_y() + b.get_height() / 2,
                 f"{v:.1f}%", va="center", fontsize=7.5)
ax6.set_title("Amino-acid Composition (%)", **title_kw)
ax6.set_xlabel("% of total codons", **label_kw)
ax6.tick_params(**tick_kw)
ax6.invert_yaxis()


# ══════════════════════════════════════════════════════════════════════════════
# Plot 7 – Sliding-window GC%
# ══════════════════════════════════════════════════════════════════════════════
ax7     = fig.add_subplot(gs[3, 2])
win_gc  = report.get("win_gc", [])
if win_gc:
    pos, gc = zip(*win_gc)
    ax7.plot(pos, gc, color=ACCENT, linewidth=0.9, alpha=0.85)
    ax7.axhline(report.get("GCpct", 50), color=ACCENT2,
                linestyle="--", linewidth=1, label=f"Mean GC {report.get('GCpct',0):.1f}%")
    ax7.fill_between(pos, gc, alpha=0.15, color=ACCENT)
    ax7.legend(fontsize=8)
ax7.set_title("Sliding-Window GC%  (w=100 nt)", **title_kw)
ax7.set_xlabel("Position (nt)", **label_kw)
ax7.set_ylabel("GC %", **label_kw)
ax7.tick_params(**tick_kw)


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4 – Save
# ══════════════════════════════════════════════════════════════════════════════
fig.suptitle(
    f"Codon Usage & Sequence Metrics  ·  {in_txt.name}",
    fontsize=14, fontweight="bold", y=0.975,
)

for ext in ("png", "pdf"):
    out_path = out_pfx.with_suffix(f".{ext}")
    fig.savefig(out_path, dpi=180, bbox_inches="tight",
                facecolor=fig.get_facecolor())
    print(f"Saved: {out_path}")

plt.close(fig)