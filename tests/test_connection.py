import unittest
from unittest.mock import MagicMock, patch

from podiumdb.config import DatabaseConfig
from podiumdb.connection import open_connection


class OpenConnectionTest(unittest.TestCase):
    def setUp(self) -> None:
        self.config = DatabaseConfig("127.0.0.1", 3306, "podium", "secret", "podiumdb")

    @patch("podiumdb.connection.mysql.connector.connect")
    def test_commits_and_closes_after_success(self, connect: MagicMock) -> None:
        connection = connect.return_value

        with open_connection(self.config) as opened:
            self.assertIs(connection, opened)

        connection.commit.assert_called_once_with()
        connection.rollback.assert_not_called()
        connection.close.assert_called_once_with()

    @patch("podiumdb.connection.mysql.connector.connect")
    def test_rolls_back_and_closes_after_failure(self, connect: MagicMock) -> None:
        connection = connect.return_value

        with self.assertRaisesRegex(RuntimeError, "query failed"):
            with open_connection(self.config):
                raise RuntimeError("query failed")

        connection.commit.assert_not_called()
        connection.rollback.assert_called_once_with()
        connection.close.assert_called_once_with()


if __name__ == "__main__":
    unittest.main()
