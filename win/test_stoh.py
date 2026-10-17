"""Run: uv run --no-project python -m unittest discover -s win -p test_stoh.py"""

import contextlib
import ctypes
import io
import unittest
from unittest.mock import Mock, patch

import stoh


class FontNotificationTests(unittest.TestCase):
    def test_notification_is_queued_not_sent_synchronously(self):
        user32 = Mock()
        user32.PostMessageW.return_value = 1
        with patch.object(ctypes, "windll", Mock(user32=user32), create=True):
            stoh._notify_font_change()
        user32.PostMessageW.assert_called_once_with(0xFFFF, 0x001D, 0, 0)
        user32.SendMessageW.assert_not_called()
        self.assertEqual(len(user32.PostMessageW.argtypes), 4)

    def test_notification_failure_warns_without_raising(self):
        user32 = Mock()
        user32.PostMessageW.return_value = 0
        output = io.StringIO()
        with patch.object(ctypes, "windll", Mock(user32=user32), create=True):
            with contextlib.redirect_stdout(output):
                stoh._notify_font_change()
        self.assertIn("warning:", output.getvalue())


if __name__ == "__main__":
    unittest.main()
