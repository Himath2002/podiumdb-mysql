import unittest
from datetime import date

from podiumdb.cli import build_parser, render_table


class CliTest(unittest.TestCase):
    def test_render_table_aligns_headers_and_values(self) -> None:
        rendered = render_table(
            [
                {"country": "AUS", "medals": 2},
                {"country": "GBR", "medals": 1},
            ]
        )

        self.assertIn("country | medals", rendered)
        self.assertIn("AUS", rendered)
        self.assertIn("GBR", rendered)

    def test_render_table_handles_empty_and_date_values(self) -> None:
        self.assertEqual("No rows returned.", render_table([]))
        self.assertIn(
            "2026-07-18",
            render_table([{"awarded_on": date(2026, 7, 18)}]),
        )

    def test_register_parser_validates_iso_date(self) -> None:
        arguments = build_parser().parse_args(
            [
                "register-athlete",
                "--given-name",
                "Ada",
                "--family-name",
                "North",
                "--date-of-birth",
                "2000-01-02",
                "--country",
                "BRA",
            ]
        )

        self.assertEqual(date(2000, 1, 2), arguments.date_of_birth)
        self.assertEqual("UNDISCLOSED", arguments.gender)


if __name__ == "__main__":
    unittest.main()
