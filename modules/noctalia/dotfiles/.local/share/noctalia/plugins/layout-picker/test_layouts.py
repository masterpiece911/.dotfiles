"""Layout discovery and switching tests; never change the live desktop."""
import subprocess
import unittest
from unittest.mock import call, patch

import layouts as app


class LayoutTests(unittest.TestCase):
    @patch.object(app, 'command', side_effect=['["master", "dwindle", "plugin-layout"]', '{"str":"master"}', '{"str":"right"}'])
    def test_status_filters_supported_layouts_in_display_order(self, command):
        self.assertEqual(app.status(), {'current': 'master-right', 'available': list(app.PRESETS)})
        self.assertEqual(command.call_args_list, [call('-j', 'layouts'), call('-j', 'getoption', 'general:layout'),
                                                call('-j', 'getoption', 'master:orientation')])

    @patch.object(app, 'command', side_effect=['["dwindle"]', '{"str":"dwindle"}'])
    def test_missing_master_hides_all_master_presets(self, command):
        self.assertEqual(app.status(), {'current': 'dwindle', 'available': ['dwindle']})

    @patch.object(app, 'command', return_value='["dwindle"]')
    def test_malformed_current_layout_is_rejected(self, command):
        with self.assertRaisesRegex(RuntimeError, 'current'):
            app.current()

    @patch.object(app, 'command', return_value='{"error":"unavailable"}')
    def test_malformed_available_layouts_are_rejected(self, command):
        with self.assertRaisesRegex(RuntimeError, 'available'):
            app.status()

    @patch.object(app, 'command')
    def test_unknown_layout_is_rejected_before_any_command(self, command):
        with self.assertRaises(ValueError):
            app.apply('other; exec anything')
        command.assert_not_called()

    @patch.object(app, 'status', return_value={'current': 'dwindle', 'available': ['dwindle']})
    @patch.object(app, 'command')
    def test_unavailable_layout_does_not_mutate(self, command, status):
        with self.assertRaisesRegex(RuntimeError, 'not available'):
            app.apply('master')
        command.assert_not_called()

    @patch.object(app, 'status', return_value={'current': 'dwindle', 'available': list(app.PRESETS)})
    @patch.object(app, 'command')
    def test_selecting_current_layout_is_a_noop(self, command, status):
        app.apply('dwindle')
        command.assert_not_called()

    @patch.object(app, 'status', return_value={'current': 'dwindle', 'available': list(app.PRESETS)})
    @patch.object(app, 'command', side_effect=['ok', 'ok', 'ok', '{"str":"master"}', '{"str":"left"}'])
    def test_switch_uses_runtime_keyword_and_verifies_result(self, command, status):
        app.apply('master')
        self.assertEqual(command.call_args_list, [
            call('keyword', 'master:orientation', 'left'),
            call('keyword', 'workspace', ',layoutopt:orientation:left'),
            call('keyword', 'general:layout', 'master'), call('-j', 'getoption', 'general:layout'),
            call('-j', 'getoption', 'master:orientation')])

    def test_each_preset_updates_existing_and_future_workspaces(self):
        for side in ('left', 'right', 'top', 'bottom', 'center'):
            with self.subTest(side=side), \
                    patch.object(app, 'status', return_value={'current': 'master-left', 'available': list(app.PRESETS)}), \
                    patch.object(app, 'command', side_effect=['ok', 'ok', 'ok', '{"str":"master"}',
                                                           '{"str":"' + side + '"}']) as command:
                app.apply('master-' + side)
                self.assertEqual(command.call_args_list[:3], [
                    call('keyword', 'master:orientation', side),
                    call('keyword', 'workspace', ',layoutopt:orientation:' + side),
                    call('keyword', 'general:layout', 'master')])

    @patch.object(app, 'status', return_value={'current': 'master-right', 'available': list(app.PRESETS)})
    @patch.object(app, 'command', side_effect=['ok', '{"str":"dwindle"}'])
    def test_dwindle_preserves_master_settings(self, command, status):
        app.apply('dwindle')
        self.assertEqual(command.call_args_list, [call('keyword', 'general:layout', 'dwindle'),
                                                call('-j', 'getoption', 'general:layout')])

    @patch.object(app, 'status', return_value={'current': 'dwindle', 'available': list(app.PRESETS)})
    @patch.object(app, 'command', return_value='invalid layout')
    def test_hyprland_rejection_is_not_reported_as_success(self, command, status):
        with self.assertRaisesRegex(RuntimeError, 'invalid layout'):
            app.apply('master')

    @patch.object(app, 'status', return_value={'current': 'dwindle', 'available': list(app.PRESETS)})
    @patch.object(app, 'command', side_effect=['ok', 'ok', 'ok', '{"str":"dwindle"}'])
    def test_unchanged_layout_is_not_reported_as_success(self, command, status):
        with self.assertRaisesRegex(RuntimeError, 'did not activate'):
            app.apply('master')

    @patch.object(app, 'status', return_value={'current': 'dwindle', 'available': list(app.PRESETS)})
    @patch.object(app, 'command', side_effect=['ok', 'rule rejected'])
    def test_rule_failure_stops_before_switching_layout(self, command, status):
        with self.assertRaisesRegex(RuntimeError, 'rule rejected'):
            app.apply('master-center')
        self.assertEqual(command.call_count, 2)

    @patch.object(app, 'status', return_value={'current': 'master-left', 'available': list(app.PRESETS)})
    @patch.object(app, 'command', side_effect=['ok', 'ok', 'ok', '{"str":"master"}', '{"str":"left"}'])
    def test_unchanged_orientation_is_not_reported_as_success(self, command, status):
        with self.assertRaisesRegex(RuntimeError, 'did not activate'):
            app.apply('master-right')

    @patch.object(app.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '', 'IPC unavailable'))
    def test_command_failure_preserves_diagnostic(self, run):
        with self.assertRaisesRegex(RuntimeError, 'IPC unavailable'):
            app.command('-j', 'layouts')
        run.assert_called_once_with(['hyprctl', '-j', 'layouts'], text=True, capture_output=True, timeout=5)

    @patch.object(app.subprocess, 'run', side_effect=subprocess.TimeoutExpired('hyprctl', 5))
    def test_command_timeout_propagates(self, run):
        with self.assertRaises(subprocess.TimeoutExpired):
            app.command('-j', 'layouts')


if __name__ == '__main__':
    unittest.main()
