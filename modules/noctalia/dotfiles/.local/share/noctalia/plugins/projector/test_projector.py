"""Projection planning and safety tests; never issue real display commands."""
import copy
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import projector as app


def output(name, **changes):
    value = dict(name=name, width=2880, height=1920, refreshRate=120.0,
                 x=-1440, y=0, scale=2.0, transform=0, disabled=False, mirrorOf='none')
    value.update(changes)
    return value


class PlanningTests(unittest.TestCase):
    def setUp(self):
        self.laptop = output('eDP-1')
        self.external = output('DP-2', width=3840, height=2160, scale=1.0, x=0)

    def test_laptop_is_enabled_before_external_disabled(self):
        rules = app.plan([self.laptop, self.external], 'laptop')
        self.assertTrue(rules[0].startswith('eDP-1,2880x1920@120,'))
        self.assertEqual(rules[-1], 'DP-2,disable')

    def test_duplicate_mirrors_all_externals_to_laptop(self):
        rules = app.plan([self.laptop, self.external, output('HDMI-A-1')], 'duplicate')
        self.assertTrue(all(r.endswith(',mirror,eDP-1') for r in rules[1:]))

    def test_extend_clears_mirroring_and_positions_to_right(self):
        self.external['mirrorOf'] = 'eDP-1'
        rules = app.plan([self.laptop, self.external], 'extend')
        self.assertIn(',auto-right,', rules[1])
        self.assertNotIn(',mirror,', rules[1])

    def test_external_is_enabled_before_laptop_disabled(self):
        rules = app.plan([self.laptop, self.external], 'external')
        self.assertTrue(rules[0].startswith('DP-2,'))
        self.assertEqual(rules[-1], 'eDP-1,disable')

    def test_missing_external_is_rejected_without_changing_displays(self):
        for mode in ('duplicate', 'extend', 'external'):
            with self.subTest(mode=mode), self.assertRaisesRegex(ValueError, 'external display'):
                app.plan([self.laptop], mode)

    def test_disabled_output_uses_preferred_mode(self):
        self.external['disabled'] = True
        self.assertTrue(app.rule(self.external).startswith('DP-2,preferred,'))

    def test_restores_mirror_sources_first_and_disabled_outputs_last(self):
        mirror = output('HDMI-A-1', mirrorOf='eDP-1')
        disabled = output('DP-3', disabled=True)
        saved = [mirror, disabled, self.laptop]
        rules = app.restore_rules(saved, saved)
        self.assertTrue(rules[0].startswith('eDP-1,'))
        self.assertTrue(rules[1].endswith(',mirror,eDP-1'))
        self.assertEqual(rules[2], 'DP-3,disable')

    def test_disconnected_original_external_falls_back_to_laptop(self):
        saved = [output('eDP-1', disabled=True), self.external]
        rules = app.restore_rules(saved, [output('eDP-1', disabled=True)])
        self.assertEqual(len(rules), 1)
        self.assertTrue(rules[0].startswith('eDP-1,preferred,'))
        self.assertNotIn('disable', rules[0])

    def test_restore_preserves_geometry(self):
        saved = output('eDP-1', x=-1440, y=120, scale=2.0, transform=0)
        self.assertEqual(app.restore_rules([saved], [saved]),
                         ['eDP-1,2880x1920@120,-1440x120,2,transform,0'])

    def test_planning_does_not_mutate_snapshot(self):
        outputs = [self.laptop, self.external]
        saved = copy.deepcopy(outputs)
        for mode in app.MODES:
            app.plan(outputs, mode)
        self.assertEqual(outputs, saved)

    @patch.object(app.subprocess, 'run')
    @patch.object(app.time, 'sleep')
    @patch.object(app, 'query')
    def test_never_disables_last_independent_screen(self, query, sleep, run):
        query.return_value = [self.laptop, output('DP-2', mirrorOf='eDP-1')]
        with self.assertRaisesRegex(RuntimeError, 'replacement display'):
            app.monitor('eDP-1,disable')
        run.assert_not_called()

    def test_pending_change_can_be_kept(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(app, 'directory', return_value=Path(tmp)):
            app.write_state(dict(token='test', expires=app.time.monotonic() + 15))
            app.finish('test', True)
            self.assertIsNone(app.read_state())

    def test_expired_change_cannot_be_kept(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(app, 'directory', return_value=Path(tmp)):
            state = dict(token='test', expires=app.time.monotonic() - 1)
            app.write_state(state)
            with patch.object(app, 'rollback') as rollback:
                app.finish('test', True)
                rollback.assert_called_once_with(state)

    def test_stale_confirmation_cannot_keep_a_different_change(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(app, 'directory', return_value=Path(tmp)):
            app.write_state(dict(token='new', expires=app.time.monotonic() + 15))
            with self.assertRaisesRegex(RuntimeError, 'expired'):
                app.finish('old', True)
            self.assertEqual(app.read_state()['token'], 'new')

    def test_watchdog_rolls_back_after_expiry(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(app, 'directory', return_value=Path(tmp)):
            state = dict(token='test', expires=app.time.monotonic() - 1)
            app.write_state(state)
            with patch.object(app, 'rollback') as rollback:
                app.watch('test')
                rollback.assert_called_once_with(state)

    def test_apply_validates_before_spawning_or_changing_displays(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(app, 'directory', return_value=Path(tmp)):
            with patch.object(app, 'query', return_value=[self.laptop]), \
                    patch.object(app.subprocess, 'Popen') as spawn, patch.object(app, 'monitor') as monitor:
                with self.assertRaises(ValueError):
                    app.apply('external')
                spawn.assert_not_called()
                monitor.assert_not_called()
                self.assertIsNone(app.read_state())


if __name__ == '__main__':
    unittest.main()
