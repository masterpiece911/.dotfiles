#!/usr/bin/env python3
"""Docked lid close disables internal outputs; lid open restores them."""
import json
import os
import subprocess
import sys
from pathlib import Path

INTERNAL_PREFIXES = ('eDP-', 'LVDS-', 'DSI-')

def active(output, compositor):
    return output.get('active', False) if compositor == 'sway' else not output.get('disabled', False)

def external_active(outputs, compositor):
    return any(not o['name'].startswith(INTERNAL_PREFIXES) and active(o, compositor) for o in outputs)

def restore_rule(output):
    # Preserve the current resolution, refresh rate, position, scale and rotation.
    return (f"{output['name']},{output['width']}x{output['height']}@{output['refreshRate']},"
            f"{output['x']}x{output['y']},{output['scale']},transform,{output.get('transform', 0)}")

def run(*args):
    return subprocess.check_output(args, text=True)

def main():
    compositor, event = sys.argv[1:3]
    state = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')) / f'{compositor}-lid-outputs.json'
    if event == 'open':
        if not state.exists():
            return
        for output in json.loads(state.read_text()):
            if compositor == 'sway':
                run('swaymsg', 'output', output['name'], 'enable')
            else:
                run('hyprctl', 'keyword', 'monitor', restore_rule(output))
        state.unlink()
        return
    try:
        outputs = json.loads(run('swaymsg', '-t', 'get_outputs', '-r') if compositor == 'sway'
                             else run('hyprctl', '-j', 'monitors'))
    except (OSError, subprocess.CalledProcessError, ValueError):
        outputs = []
    if external_active(outputs, compositor):
        internal = [o for o in outputs if o['name'].startswith(INTERNAL_PREFIXES) and active(o, compositor)]
        if not internal:
            return
        state.write_text(json.dumps(internal))
        for output in internal:
            if compositor == 'sway':
                run('swaymsg', 'output', output['name'], 'disable')
            else:
                run('hyprctl', 'keyword', 'monitor', f"{output['name']},disable")
    else:
        subprocess.run(['noctalia', 'msg', 'session', 'lock'] if compositor == 'hypr' else ['swaylock', '-f', '-C', str(Path.home() / '.config/sway/swaylock.conf')], check=True)

if __name__ == '__main__':
    main()
