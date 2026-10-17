#!/usr/bin/env python3
"""Apply runtime-only Hyprland projection modes with an independent rollback timer."""
import argparse
from contextlib import contextmanager
import fcntl
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import uuid

PANEL = 'noyan/projector:chooser'
INTERNAL = ('eDP-', 'LVDS-', 'DSI-')
MODES = ('laptop', 'duplicate', 'extend', 'external')
TIMEOUT = 15


def query():
    return json.loads(subprocess.check_output(
        ['hyprctl', 'monitors', 'all', '-j'], text=True, timeout=5))


def internal(output):
    return output['name'].startswith(INTERNAL)


def rule(output, position=None, mirror=None):
    name = output['name']
    if not re.fullmatch(r'[A-Za-z0-9_.:-]+', name):
        raise ValueError('Unsupported output connector name.')
    width, height = output.get('width', 0), output.get('height', 0)
    mode = (f"{width}x{height}@{output.get('refreshRate', 60):g}"
            if width > 0 and height > 0 and not output.get('disabled') else 'preferred')
    position = position or f"{output.get('x', 0)}x{output.get('y', 0)}"
    scale = output.get('scale', 1)
    if not isinstance(scale, (int, float)) or not math.isfinite(scale) or scale <= 0:
        scale = 1
    result = f"{name},{mode},{position},{scale:g},transform,{int(output.get('transform', 0))}"
    if mirror:
        result += f',mirror,{mirror}'
    return result


def plan(outputs, mode):
    if mode not in MODES:
        raise ValueError('Unknown projection mode.')
    laptops = [o for o in outputs if internal(o)]
    external = sorted((o for o in outputs if not internal(o)), key=lambda o: o['name'])
    if not laptops:
        raise ValueError('The laptop display is not available.')
    laptop = laptops[0]
    if mode != 'laptop' and not external:
        raise ValueError('Connect an external display first.')
    if mode == 'laptop':
        return [rule(laptop)] + [f"{o['name']},disable" for o in external]
    if mode == 'duplicate':
        return [rule(laptop)] + [rule(o, 'auto', laptop['name']) for o in external]
    if mode == 'extend':
        return [rule(laptop)] + [rule(o, 'auto-right') for o in external]
    # Enable and unmirror the destination before switching off the laptop panel.
    return [rule(o, 'auto-right') for o in external] + [f"{laptop['name']},disable"]


def monitor(command):
    if command.endswith(',disable'):
        target = command.split(',', 1)[0]
        # Monitor rules apply asynchronously. Never disable a screen until the
        # replacement has actually become an independent, active output.
        for _ in range(20):
            if any(o['name'] != target and not o.get('disabled')
                   and o.get('mirrorOf') in ('none', '', None) for o in query()):
                break
            time.sleep(0.1)
        else:
            raise RuntimeError('The replacement display did not activate; keeping the current screen on.')
    result = subprocess.run(['hyprctl', 'keyword', 'monitor', command],
                            text=True, capture_output=True, timeout=5, check=True)
    if result.stdout.strip() != 'ok':
        raise RuntimeError(result.stdout.strip() or result.stderr.strip() or 'Display change failed.')


def restore_rules(saved, connected):
    available = {o['name'] for o in connected}
    active = [o for o in saved if o['name'] in available and not o.get('disabled')]
    # If the original external display was unplugged, keep the laptop usable.
    if not active:
        fallback = next((o for o in connected if internal(o)), next(iter(connected), None))
        if fallback is None:
            raise RuntimeError('No connected display is available to restore.')
        return [rule(fallback, 'auto')]
    primary = [o for o in active if o.get('mirrorOf') in ('none', '', None)]
    mirrors = [o for o in active if o not in primary]
    commands = [rule(o) for o in primary]
    for output in mirrors:
        source = output.get('mirrorOf')
        commands.append(rule(output, mirror=source if source in available else None))
    commands.extend(f"{o['name']},disable" for o in saved
                    if o['name'] in available and o.get('disabled'))
    return commands


def directory():
    path = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')) / 'noctalia-projector'
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    return path


@contextmanager
def locked():
    with (directory() / 'lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield


def read_state():
    path = directory() / 'pending.json'
    return json.loads(path.read_text()) if path.exists() else None


def write_state(state):
    path = directory() / 'pending.json'
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(state))
    temporary.replace(path)


def rollback(state):
    for command in restore_rules(state['outputs'], query()):
        monitor(command)
    (directory() / 'pending.json').unlink(missing_ok=True)


def status():
    with locked():
        state = read_state()
        return {'outputs': query(), 'pending': None if state is None else {
            'mode': state['mode'], 'token': state['token'],
            'remaining': max(0, math.ceil(state['expires'] - time.monotonic())),
        }}


def apply(mode):
    with locked():
        if read_state():
            raise RuntimeError('Keep or revert the current change first.')
        outputs = query()
        commands = plan(outputs, mode)  # Validate before writing state or changing displays.
        state = {'token': uuid.uuid4().hex, 'mode': mode, 'outputs': outputs,
                 'expires': time.monotonic() + 60}
        write_state(state)
        try:
            # Detached watchdog survives the panel closing or Noctalia exiting.
            subprocess.Popen([sys.executable, str(Path(__file__).resolve()), '--watch', state['token']],
                             stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL, start_new_session=True, close_fds=True)
            subprocess.run(['noctalia', 'msg', 'panel-close', PANEL],
                           capture_output=True, timeout=5, check=True)
            for command in commands:
                monitor(command)
            state['expires'] = time.monotonic() + TIMEOUT
            write_state(state)
        except Exception:
            rollback(state)
            raise
    # The previous panel may have been on a display we just disabled. Reopen on
    # the now-active display rather than leaving the confirmation off-screen.
    time.sleep(0.5)
    subprocess.run(['noctalia', 'msg', 'panel-open', PANEL],
                   capture_output=True, timeout=5, check=True)


def finish(token, keep):
    with locked():
        state = read_state()
        if state is None or state['token'] != token:
            raise RuntimeError('This display change has already expired.')
        if keep and time.monotonic() < state['expires']:
            (directory() / 'pending.json').unlink()
        else:
            rollback(state)


def watch(token):
    while True:
        with locked():
            state = read_state()
            if state is None or state['token'] != token:
                return
            remaining = state['expires'] - time.monotonic()
            if remaining <= 0:
                try:
                    rollback(state)
                    return
                except (OSError, ValueError, RuntimeError, subprocess.SubprocessError):
                    # A hotplug or transient IPC failure must not kill recovery.
                    remaining = 1
        time.sleep(min(1, remaining))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_mutually_exclusive_group(required=True)
    commands.add_argument('--status', action='store_true')
    commands.add_argument('--apply', choices=MODES)
    commands.add_argument('--keep')
    commands.add_argument('--revert')
    commands.add_argument('--watch')
    args = parser.parse_args()
    try:
        if args.status:
            print(json.dumps(status()))
        elif args.apply:
            apply(args.apply)
        elif args.watch:
            watch(args.watch)
        else:
            finish(args.keep or args.revert, bool(args.keep))
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
