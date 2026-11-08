import importlib.util
import unittest
from unittest.mock import patch, MagicMock
import urllib.error
from pathlib import Path

spec = importlib.util.spec_from_file_location('health', Path(__file__).with_name('check-health.py'))
health = importlib.util.module_from_spec(spec)
spec.loader.exec_module(health)


class HealthTest(unittest.TestCase):
    @patch.object(health.time, 'sleep')
    @patch.object(health.opener, 'open')
    def test_waits_for_startup(self, urlopen, sleep):
        response = MagicMock()
        response.__enter__.return_value.status = 200
        urlopen.side_effect = [urllib.error.URLError('starting'), response]
        health.wait_for_health('http://localhost/health')
        self.assertEqual(urlopen.call_count, 2)
        sleep.assert_called_once_with(1)

    def test_redirect_is_not_followed(self):
        handler = health.NoRedirect()
        self.assertIsNone(handler.redirect_request(None, None, 302, 'Found', {}, 'http://localhost/login'))
        self.assertIsNone(handler.http_error_302(
            urllib.request.Request('http://localhost/health'), None, 302, 'Found',
            {'location': 'http://localhost/login'}))

    @patch.object(health.time, 'monotonic', side_effect=[0, 0, 91])
    @patch.object(health.time, 'sleep')
    @patch.object(health.opener, 'open', side_effect=urllib.error.URLError('down'))
    def test_timeout_fails(self, urlopen, sleep, monotonic):
        with self.assertRaisesRegex(RuntimeError, 'not healthy'):
            health.wait_for_health('http://localhost/health')


if __name__ == '__main__':
    unittest.main()
