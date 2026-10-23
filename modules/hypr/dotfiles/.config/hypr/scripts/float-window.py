#!/usr/bin/env python3
"""Toggle floating; size Kitty to 100 columns by 30 rows on entering floating."""
import argparse
import json
import math
import os
import re
import subprocess
import sys
from pathlib import Path

COLUMNS = 100
ROWS = 30


def query(kind):
    return json.loads(subprocess.check_output(
        ['hyprctl', '-j', kind], text=True, timeout=5))


def dispatch(command, argument):
    result = subprocess.run(['hyprctl', 'dispatch', command, argument],
                            text=True, capture_output=True, timeout=5, check=True)
    if result.stdout.strip() != 'ok':
        raise RuntimeError(result.stdout.strip() or result.stderr.strip())


def kitty_size(window):
    # listen_on in the Kitty module appends the Kitty process ID to this path.
    socket = f'unix:/tmp/kitty-{os.environ["USER"]}-{window["pid"]}'
    kitten = Path(__file__).with_name('kitty-cell-size.py')
    result = subprocess.run(
        ['kitty', '@', '--to', socket, 'kitten', str(kitten), str(COLUMNS), str(ROWS)],
        text=True, capture_output=True, timeout=5, check=True)
    pixels = json.loads(result.stdout)
    monitor = next(m for m in query('monitors') if m['id'] == window['monitor'])
    # Kitty reports physical pixels; Hyprland resize dispatchers use logical pixels.
    return tuple(math.ceil(pixels[axis] / monitor['scale']) for axis in ('width', 'height'))


def apply(window, force_float=False):
    address = window.get('address', '')
    if not re.fullmatch(r'0x[0-9a-fA-F]+', address) or address == '0x0':
        return
    selector = 'address:' + address
    if window['floating'] and not force_float:
        dispatch('settiled', selector)
        return

    size = None
    if window.get('class', '').lower() == 'kitty':
        size = kitty_size(window)
    if window.get('fullscreen'):
        # fullscreenstate and centerwindow are active-window-only dispatchers.
        if query('activewindow').get('address') != address:
            return
        dispatch('fullscreenstate', '0 0')
    dispatch('setfloating', selector)
    if size:
        dispatch('resizewindowpixel', f'exact {size[0]} {size[1]},{selector}')
    if query('activewindow').get('address') == address and (size or force_float):
        dispatch('centerwindow', '1')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--float', action='store_true', help='Float and center instead of toggling')
    args = parser.parse_args()
    apply(query('activewindow'), force_float=args.float)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, StopIteration, RuntimeError, subprocess.SubprocessError) as error:
        print('Floating window: ' + str(error), file=sys.stderr)
        sys.exit(1)
