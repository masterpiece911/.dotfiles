#!/usr/bin/env python3
"""Capture the active workspace before opening Noctalia; move it to a display."""
import argparse
import json
import subprocess
import sys

PANEL = 'noyan/display-mover:picker'


def query(kind):
    return json.loads(subprocess.check_output(['hyprctl', '-j', kind], text=True, timeout=5))


def monitors():
    return sorted((m for m in query('monitors') if not m.get('disabled')
                   and m.get('mirrorOf', 'none') in ('', 'none', None)),
                  key=lambda m: (m['x'], m['y'], m['name']))


def snapshot():
    workspace = query('activeworkspace')
    return {'workspace': workspace, 'outputs': monitors()}


def dispatch(command, argument):
    result = subprocess.run(['hyprctl', 'dispatch', command, argument], text=True,
                            capture_output=True, timeout=5, check=True)
    if result.stdout.strip() != 'ok':
        raise RuntimeError(result.stdout.strip() or result.stderr.strip() or 'Dispatch failed')


def move(workspace_id, name):
    try:
        workspace_id = int(workspace_id)
    except (TypeError, ValueError):
        raise RuntimeError('No valid workspace was captured when Display Mover opened.')
    target = next((m for m in monitors() if m['name'] == name), None)
    if target is None:
        raise RuntimeError('That display has disconnected. Reopen Display Mover.')
    workspace = next((w for w in query('workspaces') if w.get('id') == workspace_id), None)
    if workspace is None:
        raise RuntimeError('The original workspace no longer exists.')
    if workspace_id in (0, -1) or workspace.get('name', '').startswith('special:'):
        raise RuntimeError('Choose a normal workspace before opening Display Mover.')
    if workspace.get('monitor') == target['name']:
        return
    selector = str(workspace_id) if workspace_id > 0 else 'name:' + workspace['name']
    dispatch('moveworkspacetomonitor', f'{selector} {name}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--snapshot', action='store_true')
    parser.add_argument('--move', nargs=2, metavar=('WORKSPACE_ID', 'OUTPUT'))
    args = parser.parse_args()
    try:
        if args.move:
            move(*args.move)
        elif args.snapshot:
            print(json.dumps(snapshot()))
        else:
            # The layer-shell panel can change focus: capture before opening it.
            context = json.dumps(snapshot(), separators=(',', ':'))
            subprocess.run(['noctalia', 'msg', 'panel-toggle', PANEL, context], check=True, timeout=5)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
