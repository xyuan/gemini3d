from pathlib import Path
import typing as T

from .raw import get_simsize as get_simsize_raw
try:
    from .hdf import get_simsize as get_simsize_h5
except ModuleNotFoundError:
    get_simsize_h5 = None

Pathlike = T.Union[str, Path]


def get_simsize(path: Pathlike) -> T.Tuple[int, ...]:

    path = Path(path).expanduser().resolve()
    if path.is_dir():
        for suffix in (".h5", ".nc", ".dat"):
            fn = path / ("simsize" + suffix)
            if fn.is_file():
                break
    else:
        fn = path
    if not fn.is_file():
        raise FileNotFoundError(path)

    if fn.suffix == '.h5':
        if get_simsize_h5 is None:
            raise ModuleNotFoundError("pip install h5py")
        return get_simsize_h5(fn)
    elif fn.suffix == '.nc':
        raise ValueError('TODO: implement NetCDF4')
    else:
        return get_simsize_raw(fn)