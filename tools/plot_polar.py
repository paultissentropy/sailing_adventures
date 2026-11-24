"""Trace la polaire de vitesse calculée par game/tests/polar.gd (une figure par bateau).

Usage : python3 tools/plot_polar.py tools/out/polar.csv docs/img/polaire.png
"""

import csv
import math
import sys
from collections import defaultdict

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402


def main(csv_path: str, png_path: str) -> None:
    boats = defaultdict(lambda: defaultdict(list))
    with open(csv_path, newline="") as f:
        for row in csv.DictReader(f):
            boats[row["boat"]][float(row["wind_kn"])].append((float(row["twa_deg"]), float(row["speed_kn"])))

    top = max(s for series in boats.values() for pts in series.values() for _, s in pts) * 1.1
    fig = plt.figure(figsize=(6 * len(boats), 6))
    for index, (boat, series) in enumerate(boats.items()):
        ax = fig.add_subplot(1, len(boats), index + 1, projection="polar")
        ax.set_theta_zero_location("N")
        ax.set_theta_direction(-1)
        ax.set_thetamin(0)
        ax.set_thetamax(180)
        for wind, points in sorted(series.items()):
            points.sort()
            ax.plot([math.radians(t) for t, _ in points], [s for _, s in points], marker="o", ms=3,
                    label=f"{wind:.0f} nœuds")
        ax.set_ylim(0, top)
        ax.set_title(f"{boat} : vitesse (nœuds) selon l'angle au vent réel", pad=20)
        ax.legend(loc="lower left", bbox_to_anchor=(0.0, -0.05))
    fig.tight_layout()
    fig.savefig(png_path, dpi=100)
    print(f"Polaire tracée dans {png_path}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
