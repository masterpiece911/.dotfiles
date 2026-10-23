#!/usr/bin/env python3
"""Discover and switch built-in Hyprland layouts without editing configuration."""
import argparse
import json
import subprocess
import sys

PRESETS = {'dwindle': None, **{f'master-{side}': side for side in ('left', 'right', 'top', 'bottom', 'center')}}


def command(*args):
    result = subprocess.run(['hyprctl', *args], text=True, capture_output=True, timeout=5)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or 'Hyprland is unavailable.')
    return result.stdout.strip()


def option(name):
    data = json.loads(command('-j', 'getoption', name))
    if not isinstance(data, dict) or not isinstance(data.get('str'), str):
        raise RuntimeError(f'Could not read the current Hyprland option: {name}.')
    return data['str']


def current():
    return option('general:layout')


def status():
    available = json.loads(command('-j', 'layouts'))
    if not isinstance(available, list) or not all(isinstance(item, str) for item in available):
        raise RuntimeError('Could not read available Hyprland layouts.')
    layout = current()
    orientation = option('master:orientation') if layout == 'master' else None
    return {'current': f'master-{orientation}' if layout == 'master' else layout,
            'available': [name for name in PRESETS if ('dwindle' if name == 'dwindle' else 'master') in available]}


def keyword(name, value):
    response = command('keyword', name, value)
    if response != 'ok':
        raise RuntimeError(response or 'Hyprland rejected the layout change.')


def apply(name):
    # Keep the original helper invocation working; Master now has explicit presets.
    if name == 'master':
        name = 'master-left'
    if name not in PRESETS:
        raise ValueError('Unknown layout.')
    data = status()
    if name not in data['available']:
        raise RuntimeError('This layout is not available in the running Hyprland instance.')
    if name == 'dwindle' and name == data['current']:
        return
    orientation = PRESETS[name]
    layout = 'master' if orientation else 'dwindle'
    if orientation:
        keyword('master:orientation', orientation)
        # 0.53 caches orientation per workspace. An empty workspace selector matches
        # all workspaces; layoutopt overrides that cache without switching focus or
        # rebuilding the tiling tree. Hyprland merges this with other workspace options.
        # Like keyword options, this in-memory rule disappears on config reload.
        keyword('workspace', f',layoutopt:orientation:{orientation}')
    keyword('general:layout', layout)
    if current() != layout or (orientation and option('master:orientation') != orientation):
        raise RuntimeError('Hyprland did not activate the selected layout. Reopen the chooser and try again.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument('--status', action='store_true')
    action.add_argument('--apply', choices=(*PRESETS, 'master'))
    args = parser.parse_args()
    try:
        if args.status:
            print(json.dumps(status()))
        else:
            apply(args.apply)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
