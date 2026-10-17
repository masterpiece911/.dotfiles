#!/usr/bin/env python3
"""Small utilities for the migrated Hyprland/Noctalia shortcut set."""
import argparse
import json
import re
import subprocess
import sys
import tempfile


def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def menu(items, prompt):
    result = subprocess.run(['noctalia', 'dmenu', '--prompt', prompt],
                            input='\n'.join(items)+'\n', text=True, capture_output=True)
    choice = result.stdout.strip()
    return choice if result.returncode == 0 and choice in items else None


def browser():
    desktop = subprocess.check_output(['xdg-settings','get','default-web-browser'], text=True, timeout=5).strip()
    if not desktop:
        raise RuntimeError('No default browser is configured')
    run(['gtk-launch', desktop])


def screenshot_copy():
    selection = subprocess.run(['slurp'], text=True, capture_output=True)
    if selection.returncode != 0:
        return
    geometry = selection.stdout.strip()
    if not re.fullmatch(r'-?\d+,-?\d+ \d+x\d+', geometry):
        return
    # Verify capture before replacing the user's clipboard.
    with tempfile.TemporaryFile() as image:
        run(['grim', '-g', geometry, '-'], stdout=image, stderr=subprocess.PIPE)
        image.seek(0)
        if image.read(8) != b'\x89PNG\r\n\x1a\n':
            raise RuntimeError('Screenshot did not produce a PNG')
        image.seek(0)
        run(['wl-copy', '--type', 'image/png'], stdin=image)
    run(['notify-send', 'Screenshot', 'Area copied to clipboard'])


def capture_menu():
    actions = {
        'Area screenshot → clipboard': screenshot_copy,
        'Area screenshot → Noctalia editor': lambda: run(['noctalia','msg','screenshot-region']),
        'Fullscreen screenshot': lambda: run(['noctalia','msg','screenshot-fullscreen','all']),
        'Annotate screenshot': lambda: run(['noctalia','msg','screenshot-annotate']),
    }
    choice = menu(actions, 'Screen capture')
    if choice:
        actions[choice]()


def shortcuts():
    bindings=json.loads(subprocess.check_output(['hyprctl','binds','-j'],text=True,timeout=5))
    lines=[]
    for binding in bindings:
        if binding.get('mouse') or binding.get('key','').startswith('switch:'):
            continue
        mask=binding.get('modmask',0)
        mods=[name for bit,name in [(64,'Super'),(4,'Ctrl'),(8,'Alt'),(1,'Shift')] if mask & bit]
        key=binding.get('key','') or 'code:'+str(binding.get('keycode',''))
        scope='['+binding['submap']+'] ' if binding.get('submap') else ''
        action=binding.get('description') or (binding['dispatcher']+' '+binding.get('arg','')).strip()
        lines.append(scope+'+'.join(mods+[key])+' — '+action)
    menu(sorted(set(lines)), 'Keyboard shortcuts (type to filter)')


def confirm_reboot():
    if menu(['Cancel','Reboot'], 'Reboot this computer?') == 'Reboot':
        run(['noctalia','msg','session','reboot'])


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['browser','screenshot-copy','capture-menu','shortcuts','reboot'])
    action=parser.parse_args().action
    {'browser':browser,'screenshot-copy':screenshot_copy,'capture-menu':capture_menu,'shortcuts':shortcuts,'reboot':confirm_reboot}[action]()


if __name__=='__main__':
    try:
        main()
    except (OSError,ValueError,RuntimeError,subprocess.SubprocessError) as error:
        print('Desktop utility: '+str(error),file=sys.stderr)
        subprocess.run(['notify-send','Desktop utility',str(error)],check=False)
        sys.exit(1)
