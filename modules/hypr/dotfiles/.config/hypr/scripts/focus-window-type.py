#!/usr/bin/env python3
"""Switch focus between floating and tiled windows on the current workspace."""
import json
import subprocess
import sys


def main():
    window = json.loads(subprocess.check_output(
        ['hyprctl', 'activewindow', '-j'], text=True, timeout=5))
    if not window.get('address') or not isinstance(window.get('floating'), bool):
        return
    target = 'tiled' if window['floating'] else 'floating'
    # Let the compositor handle visible windows and focus history on this workspace.
    result = subprocess.run(['hyprctl', 'dispatch', 'cyclenext', target + ' hist'],
                            text=True, capture_output=True, timeout=5, check=True)
    if result.stdout.strip() != 'ok':
        raise RuntimeError(result.stdout.strip() or result.stderr.strip())


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print('Floating/tiled focus: ' + str(error), file=sys.stderr)
        sys.exit(1)
