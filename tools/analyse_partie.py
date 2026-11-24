"""Analyse une partie enregistrée (F3 en jeu) : repère les virements et les empannages
et les compare aux références du banc d'essai.

Usage : python3 tools/analyse_partie.py [tools/out/partie-....csv]
Sans argument, analyse le dernier enregistrement de tools/out/.
"""

import csv
import glob
import os
import sys

# Fourchettes de référence (garder synchronisé avec game/tests/bench.gd).
REFERENCES = {
    "Quillard 6 m": {"virement_duree": (4.0, 8.0), "virement_perte": (25.0, 55.0)},
    "Croiseur 9 m": {"virement_duree": (7.0, 15.0), "virement_perte": (25.0, 55.0)},
}
CLOSE_HAULED = 45.0  # angle au vent qui marque le début et la fin d'un virement (°)
STALL_U = 0.3  # sous cette vitesse vers l'avant (m/s), le bateau est arrêté


def load(path):
    with open(path, newline="") as f:
        rows = list(csv.DictReader(f))
    for r in rows:
        for k in ("t", "vitesse_kn", "u", "twa_deg", "gv", "bome_deg"):
            r[k] = float(r[k])
    return rows


def crossings(rows):
    """Indices où le vent change de bord (signe de l'angle au vent)."""
    out = []
    for i in range(1, len(rows)):
        a, b = rows[i - 1]["twa_deg"], rows[i]["twa_deg"]
        if (a < 0) != (b < 0) and abs(abs(a) - 180) > 0.05:
            out.append(i)
    return out


def analyse_tack(rows, i):
    """Virement autour de l'indice i (le vent traverse l'étrave)."""
    start = i
    while start > 0 and abs(rows[start]["twa_deg"]) < CLOSE_HAULED:
        start -= 1
    end = i
    while end < len(rows) - 1 and abs(rows[end]["twa_deg"]) < CLOSE_HAULED:
        end += 1
    window = rows[start:min(len(rows), end + 30)]
    v0 = rows[start]["vitesse_kn"]
    vmin = min(r["vitesse_kn"] for r in window)
    stalled = any(r["u"] < STALL_U for r in rows[start:end + 1]) or end == len(rows) - 1
    return {
        "t": rows[i]["t"],
        "duree": rows[end]["t"] - rows[start]["t"],
        "v0": v0,
        "perte": (1 - vmin / v0) * 100 if v0 > 0.1 else 0.0,
        "bout_au_vent": stalled,
    }


def analyse_gybe(rows, i):
    before = rows[max(0, i - 30):i]
    after = rows[i:i + 30]
    sheet = rows[i]["gv"]
    swing = max(abs(a["bome_deg"] - b["bome_deg"]) for a in before[-5:] for b in after) if before and after else 0
    return {"t": rows[i]["t"], "ecoute_gv": sheet, "course_bome": swing, "controle": sheet < 0.4}


def check(value, bounds):
    return "✓" if bounds[0] <= value <= bounds[1] else "⚠"


def main(path):
    rows = load(path)
    if not rows:
        print("Enregistrement vide.")
        return
    boat = rows[0]["bateau"]
    refs = REFERENCES.get(boat, REFERENCES["Quillard 6 m"])
    print(f"Partie : {os.path.basename(path)} — {boat}, {rows[-1]['t']:.0f} s\n")
    tacks, gybes = 0, 0
    for i in crossings(rows):
        twa = abs(rows[i]["twa_deg"])
        if twa < 90:
            tacks += 1
            r = analyse_tack(rows, i)
            print(f"Virement à {r['t']:.0f} s")
            if r["bout_au_vent"]:
                print("  ⚠ le bateau est resté bout au vent : il manquait de l'élan, ou la barre a été relâchée trop tôt")
            print(f"  {check(r['duree'], refs['virement_duree'])} durée {r['duree']:.1f} s "
                  f"(réf. {refs['virement_duree'][0]:.0f}–{refs['virement_duree'][1]:.0f} s)")
            print(f"  {check(r['perte'], refs['virement_perte'])} perte de vitesse {r['perte']:.0f} % "
                  f"depuis {r['v0']:.1f} nœuds (réf. {refs['virement_perte'][0]:.0f}–{refs['virement_perte'][1]:.0f} %)")
        else:
            gybes += 1
            r = analyse_gybe(rows, i)
            verdict = "✓ contrôlé (GV bordée)" if r["controle"] else "⚠ non contrôlé (GV choquée)"
            print(f"Empannage à {r['t']:.0f} s : {verdict}, course de la bôme {r['course_bome']:.0f}°")
    if tacks == 0 and gybes == 0:
        print("Aucun virement ni empannage détecté.")
    else:
        print(f"\n{tacks} virement(s), {gybes} empannage(s).")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        target = sys.argv[1]
    else:
        here = os.path.dirname(os.path.abspath(__file__))
        files = sorted(glob.glob(os.path.join(here, "out", "partie-*.csv")))
        if not files:
            sys.exit("Aucun enregistrement dans tools/out/ (F3 en jeu pour enregistrer).")
        target = files[-1]
    main(target)
