from __future__ import annotations

import re
import unittest

from server.main import GameSession


class LauncherTests(unittest.TestCase):
    def test_godot_state_lists_the_players_for_the_host_screen(self) -> None:
        session = GameSession("BZKT")
        session.players = {"helmsman": "Ava", "seer": "Dee"}
        session.step(0.02, now=0.02)
        self.assertEqual(session.godot_state()["players"], {"helmsman": "Ava", "seer": "Dee"})

    def test_host_screen_qr_code_decodes_to_the_join_link(self) -> None:
        from run_local import qr_svg

        link = "http://192.168.1.23:8000/?room=BZKT"
        svg = qr_svg(link)
        if svg is None:
            self.skipTest("no QR library installed (qrcode or OpenCV)")
        try:
            import cv2
            import numpy as np
        except ImportError:
            self.skipTest("OpenCV is needed to decode the QR code")
        n = int(re.search(r'viewBox="0 0 (\d+) ', svg).group(1))
        image = np.full((n, n), 255, np.uint8)
        for x, y in re.findall(r"M(\d+) (\d+)h1", svg):
            image[int(y), int(x)] = 0
        image = cv2.resize(image, (n * 8, n * 8), interpolation=cv2.INTER_NEAREST)
        self.assertEqual(cv2.QRCodeDetector().detectAndDecode(image)[0], link)


if __name__ == "__main__":
    unittest.main()
