#!/usr/bin/env python3
"""Select a connected display and move only the originally focused window there."""
import argparse
import json
import re
import subprocess
import sys


def query(name):
    return json.loads(subprocess.check_output(['hyprctl', name, '-j'], text=True, timeout=5))


def dispatch(name, argument):
    result = subprocess.run(['hyprctl', 'dispatch', name, argument], text=True,
                            capture_output=True, timeout=5, check=True)
    if result.stdout.strip() != 'ok':
        raise RuntimeError(result.stdout.strip() or result.stderr.strip() or 'Dispatch failed')


def clean(value):
    return ' '.join(str(value).split())


def choices(monitors, current_id=None):
    entries = {}
    for monitor in sorted(monitors, key=lambda m: (m.get('x', 0), m.get('y', 0), m['name'])):
        if monitor.get('disabled'):
            continue
        name = monitor['name']
        label = name + ' — ' + clean(monitor.get('description') or name)
        label += ' (' + str(monitor.get('width', '?')) + '×' + str(monitor.get('height', '?')) + ')'
        if monitor.get('id') == current_id:
            label += ' [current]'
        entries[label] = name
    return entries


def pick(entries):
    result = subprocess.run(
        ['wofi', '--conf', '/dev/null', '--dmenu', '--no-custom-entry',
         '--prompt', 'Move window to display', '--width', '680',
         '--lines', str(min(len(entries), 8)), '--insensitive',
         '--cache-file', '/dev/null', '--define', 'allow_markup=false'],
        input='\n'.join(entries) + '\n', text=True, capture_output=True)
    if result.returncode != 0:
        return None  # Escape / cancellation: change nothing.
    return entries.get(result.stdout.strip())


def move_to_display():
    # Capture the window before the menu can change focus.
    window = query('activewindow')
    address = window.get('address', '')
    if not re.fullmatch(r'0x[0-9a-fA-F]+', address) or address == '0x0':
        return
    entries = choices(query('monitors'), window.get('monitor'))
    if not entries:
        return
    target_name = pick(entries)
    if not target_name:
        return
    # Recheck after the picker: a screen may have disconnected or the window closed.
    monitor = next((m for m in query('monitors')
                    if m['name'] == target_name and not m.get('disabled')), None)
    if monitor is None:
        return
    original = next((c for c in query('clients') if c.get('address') == address), None)
    if original is None:
        return
    if monitor.get('id') == original.get('monitor'):
        return
    workspace = monitor.get('activeWorkspace', {}).get('id')
    if not isinstance(workspace, int) or workspace <= 0:
        raise RuntimeError('The selected display has no normal active workspace')
    # Address targets the original window, never the picker or an entire workspace.
    dispatch('movetoworkspace', f'{workspace},address:{address}')
    dispatch('focuswindow', 'address:' + address)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--list', action='store_true', help='List menu entries without opening a picker or moving a window')
    args = parser.parse_args()
    try:
        if args.list:
            print('\n'.join(choices(query('monitors'))))
        else:
            move_to_display()
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print('Display picker: ' + str(error), file=sys.stderr)
        subprocess.run(['notify-send', 'Display picker', str(error)], check=False)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
