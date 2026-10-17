#!/usr/bin/env python3
"""Adjust display backlights using the active logind session."""
import pathlib
import shlex
import subprocess
import sys

def run(*args):
    return subprocess.check_output(args, text=True).strip()

session = run('loginctl', 'show-session', 'auto', '-p', 'Id', '--value')
reply = run('busctl', '--system', 'call', 'org.freedesktop.login1',
            '/org/freedesktop/login1', 'org.freedesktop.login1.Manager',
            'GetSession', 's', session)
path = shlex.split(reply)[1]
direction = 1 if sys.argv[1] == 'up' else -1
for device in pathlib.Path('/sys/class/backlight').iterdir():
    maximum = int((device / 'max_brightness').read_text())
    current = int((device / 'brightness').read_text())
    value = max(1, min(maximum, current + direction * max(1, round(maximum * .05))))
    subprocess.run(['busctl', '--system', 'call', 'org.freedesktop.login1',
                    path, 'org.freedesktop.login1.Session', 'SetBrightness',
                    'ssu', 'backlight', device.name, str(value)], check=True)
