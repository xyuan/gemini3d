#!/usr/bin/env python3
"""
do a simple test of Fang 2008
"""
import numpy as np
import subprocess
from pathlib import Path
import shutil
import sys
import io
import argparse

R = Path(__file__).parent


def checker(exe: str, doplot: bool):
    if not shutil.which(exe):
        print('executable', exe, 'not found', file=sys.stderr)
        raise SystemExit(77)

    ret = subprocess.check_output(exe, universal_newlines=True)

    keV = list(map(float, ret.split('\n')[0].split()[1:]))
    dat = np.loadtxt(io.StringIO(ret), skiprows=1)
    alt_km = dat[:, 0]
    ionization_rates = dat[:, 1:]

    assert np.isclose(ionization_rates[89, 0], 2214.052), "100eV"
    assert np.isclose(ionization_rates[17, 4], 9579.046), "1MeV"

    if not doplot:
        return

    ax = figure().gca()
    for i, e in enumerate(keV):
        ax.semilogx(ionization_rates[:, i], alt_km, label=str(e))
    ax.set_ylabel('altitude [km]')
    ax.set_xlabel('Total ionization rate [cm$^{-3}$ s$^{-1}$]')
    ax.grid(True)
    ax.set_title(r'Figure 3 of Fang 2008 by $E_0$ [keV]\nAp=5 f107=50 Midnight MLT 60$^\circ$ lat.')
    ax.legend(loc='best')
    ax.set_xlim(10, 1e5)


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('exe')
    p.add_argument("-p", "--plot", help="make plots", action="store_true")
    P = p.parse_args()

    if P.plot:
        from matplotlib.pyplot import figure, show

    checker(P.exe, P.plot)

    if P.plot:
        show()