#!/usr/bin/env python
"""
runs a job
"""

import subprocess
import gemini
import shutil
from pathlib import Path
import argparse
import typing as T
import os

Pathlike = T.Union[str, Path]
cwd = os.getcwd()


def main(mpiexec: Pathlike, gemexe: Pathlike, config_file: Pathlike, out_dir: Path):

    if not mpiexec:
        mpiexec = "mpiexec"
    mpi_root = os.getenv("MPI_ROOT")
    mpiexec = shutil.which(mpiexec, path=mpi_root + "/bin")
    if not mpiexec:
        raise FileNotFoundError("Need mpiexec to run simulations")
    print("mpiexec:", mpiexec)

    if gemexe:
        gemexe = Path(gemexe).expanduser()
        if not gemexe.is_file():
            raise FileNotFoundError(gemexe)
    else:
        build_dir = Path(__file__).resolve().parents[2] / 'build'
        if not build_dir.is_dir():
            raise NotADirectoryError(build_dir)
        gemexe = shutil.which("gemini.bin", path=str(build_dir))
        if not gemexe:
            raise FileNotFoundError("Cannot find gemini.bin")
    print("gemini executable:", gemexe)

    out_dir = Path(out_dir).expanduser()
    if out_dir.is_file():
        raise NotADirectoryError(out_dir)
    if not out_dir.is_dir():
        out_dir.mkdir(parents=True, exist_ok=True)

    Nmpi = gemini.get_mpi_count(config_file, cwd=cwd)

    ret = subprocess.run([str(mpiexec), "-n", str(Nmpi), str(gemexe), str(config_file), str(out_dir)])

    raise SystemExit(ret.returncode)


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('outdir', help='simulation output directory')
    p.add_argument('-mpiexec', help='path to desired mpiexec executable')
    p.add_argument('-gemexe', help='path to desired gemini.bin')
    P = p.parse_args()

    config_file = Path(__file__).parent / 'config.nml'

    main(P.mpiexec, P.gemexe, config_file, P.outdir)
