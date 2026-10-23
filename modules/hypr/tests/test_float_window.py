import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'dotfiles/.config/hypr/scripts/float-window.py'
SPEC = importlib.util.spec_from_file_location('float_window', SCRIPT)
floating = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(floating)


class FloatingWindowTests(unittest.TestCase):
    def setUp(self):
        self.window = {'address': '0x123', 'class': 'kitty', 'floating': False,
                       'fullscreen': 0, 'pid': 123, 'monitor': 0}

    def test_kitty_grid_is_scaled_and_centered(self):
        with patch.object(floating, 'kitty_size', return_value=(971, 591)), \
                patch.object(floating, 'query', return_value=self.window), \
                patch.object(floating, 'dispatch') as dispatch:
            floating.apply(self.window)
        self.assertEqual(dispatch.call_args_list, [
            unittest.mock.call('setfloating', 'address:0x123'),
            unittest.mock.call('resizewindowpixel', 'exact 971 591,address:0x123'),
            unittest.mock.call('centerwindow', '1'),
        ])

    def test_toggling_back_never_resizes(self):
        self.window['floating'] = True
        with patch.object(floating, 'kitty_size') as size, \
                patch.object(floating, 'dispatch') as dispatch:
            floating.apply(self.window)
        size.assert_not_called()
        dispatch.assert_called_once_with('settiled', 'address:0x123')

    def test_other_apps_keep_their_size(self):
        self.window['class'] = 'firefox'
        with patch.object(floating, 'kitty_size') as size, \
                patch.object(floating, 'query', return_value=self.window), \
                patch.object(floating, 'dispatch') as dispatch:
            floating.apply(self.window)
        size.assert_not_called()
        dispatch.assert_called_once_with('setfloating', 'address:0x123')

    def test_force_float_also_centers_other_apps(self):
        self.window['class'] = 'firefox'
        with patch.object(floating, 'query', return_value=self.window), \
                patch.object(floating, 'dispatch') as dispatch:
            floating.apply(self.window, force_float=True)
        self.assertEqual(dispatch.call_args_list[-1], unittest.mock.call('centerwindow', '1'))

    def test_changed_focus_does_not_center_an_unrelated_window(self):
        with patch.object(floating, 'kitty_size', return_value=(971, 591)), \
                patch.object(floating, 'query', return_value={'address': '0x456'}), \
                patch.object(floating, 'dispatch') as dispatch:
            floating.apply(self.window)
        self.assertEqual(len(dispatch.call_args_list), 2)
        self.assertTrue(all('address:0x123' in call.args[1] for call in dispatch.call_args_list))

    def test_fullscreen_is_cleared_before_floating(self):
        self.window['fullscreen'] = 1
        with patch.object(floating, 'kitty_size', return_value=(971, 591)), \
                patch.object(floating, 'query', return_value=self.window), \
                patch.object(floating, 'dispatch') as dispatch:
            floating.apply(self.window, force_float=True)
        self.assertEqual(dispatch.call_args_list[0], unittest.mock.call('fullscreenstate', '0 0'))

    def test_no_active_window_is_a_noop(self):
        with patch.object(floating, 'dispatch') as dispatch:
            floating.apply({})
        dispatch.assert_not_called()

    def test_pixel_metrics_convert_to_logical_pixels(self):
        result = SimpleNamespace(stdout=json.dumps({'width': 1942, 'height': 1182}))
        with patch.dict(floating.os.environ, {'USER': 'test'}), \
                patch.object(floating.subprocess, 'run', return_value=result) as run, \
                patch.object(floating, 'query', return_value=[{'id': 0, 'scale': 2}]):
            self.assertEqual(floating.kitty_size(self.window), (971, 591))
        args = run.call_args.args[0]
        self.assertEqual(args[3], 'unix:/tmp/kitty-test-123')
        self.assertEqual(args[-2:], ['100', '30'])


if __name__ == '__main__':
    unittest.main()
