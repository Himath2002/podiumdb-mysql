import unittest
from datetime import date
from unittest.mock import MagicMock

from podiumdb.repository import PodiumRepository


class PodiumRepositoryTest(unittest.TestCase):
    def setUp(self) -> None:
        self.connection = MagicMock()
        self.cursor = self.connection.cursor.return_value
        self.repository = PodiumRepository(self.connection)

    def test_athletes_filters_with_parameterized_country_code(self) -> None:
        self.cursor.fetchall.return_value = [
            {
                "athlete_id": 1009,
                "given_name": "Talia",
                "family_name": "Brooks",
                "country_code": "AUS",
                "gender": "FEMALE",
            }
        ]

        rows = self.repository.athletes("aus")

        query, parameters = self.cursor.execute.call_args.args
        self.assertIn("WHERE country_code = %s", query)
        self.assertEqual(("AUS",), parameters)
        self.assertEqual(1009, rows[0]["athlete_id"])
        self.cursor.close.assert_called_once_with()

    def test_country_medal_table_orders_in_sql(self) -> None:
        self.cursor.fetchall.return_value = []

        self.repository.country_medal_table()

        query, parameters = self.cursor.execute.call_args.args
        self.assertIn("FROM vw_country_medal_table", query)
        self.assertIn("gold_medals DESC", query)
        self.assertEqual((), parameters)

    def test_register_athlete_returns_stored_procedure_identifier(self) -> None:
        stored_result = MagicMock()
        stored_result.fetchone.return_value = {"athlete_id": 1015}
        self.cursor.stored_results.return_value = [stored_result]

        athlete_id = self.repository.register_athlete(
            given_name="Ada",
            family_name="North",
            date_of_birth=date(2000, 1, 2),
            gender="undisclosed",
            country_code="bra",
            coach_id=108,
        )

        self.assertEqual(1015, athlete_id)
        procedure_name, parameters = self.cursor.callproc.call_args.args
        self.assertEqual("sp_register_athlete", procedure_name)
        self.assertEqual("UNDISCLOSED", parameters[3])
        self.assertEqual("BRA", parameters[4])
        self.cursor.close.assert_called_once_with()


if __name__ == "__main__":
    unittest.main()
