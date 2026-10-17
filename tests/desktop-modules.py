#!/usr/bin/env python3
"""Exercise desktop module deployment in temporary homes, without downloads."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class DesktopModuleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='desktop-stow-', dir='/tmp/opencode')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.env = dict(os.environ, HOME=str(self.home))

    def install(self, *args):
        return subprocess.run(['bash', 'install.sh', *args], cwd=REPO, env=self.env,
                              text=True, capture_output=True, timeout=15)

    def test_fresh_home_and_repeat_preserve_generated_palettes(self):
        for args in [('noctalia',), ('--config-only', 'hypr', 'kitty')]:
            result = self.install(*args)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for relative in ['.config/hypr/hyprland.conf', '.config/hypr/noctalia-bindings.conf',
                         '.config/hypr/scripts/desktop-utilities.py',
                         '.config/hypr/scripts/float-window.py',
                         '.config/noctalia/desktop.toml', '.config/kitty/kitty.conf',
                         '.local/share/noctalia/plugins/projector/projector.py']:
            self.assertTrue((self.home / relative).resolve().is_relative_to(REPO), relative)
        palette = self.home / '.config/hypr/noctalia.conf'
        self.assertTrue(palette.is_file())
        self.assertFalse(palette.is_symlink())
        palette.write_text('# existing generated palette\n')
        result = self.install('noctalia')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(palette.read_text(), '# existing generated palette\n')
        self.assertFalse((self.home / '.local/state/noctalia/settings.toml').exists())

    def test_reverse_module_order(self):
        result = self.install('--config-only', 'hypr', 'noctalia', 'kitty')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for relative in ['.config/hypr/scripts/desktop-utilities.py',
                         '.config/hypr/scripts/float-window.py']:
            self.assertTrue((self.home / relative).resolve().is_relative_to(REPO), relative)

    def test_dry_run_is_side_effect_free(self):
        result = self.install('--dry-run', 'hypr', 'noctalia', 'kitty')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_stow_conflict_is_reported_as_failure(self):
        scripts = self.home / '.config/hypr/scripts'
        scripts.parent.mkdir(parents=True)
        unmanaged = self.home / 'unmanaged'
        unmanaged.mkdir()
        scripts.symlink_to(unmanaged, target_is_directory=True)
        result = self.install('--config-only', 'hypr')
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Config/stow failed', result.stderr)
        self.assertIn('hypr', result.stderr)
        self.assertEqual(scripts.resolve(), unmanaged)


if __name__ == '__main__':
    unittest.main()
