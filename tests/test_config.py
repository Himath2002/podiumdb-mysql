import unittest

from podiumdb.config import ConfigurationError, DatabaseConfig


class DatabaseConfigTest(unittest.TestCase):
    def test_from_env_uses_safe_non_secret_defaults(self) -> None:
        config = DatabaseConfig.from_env({"PODIUMDB_PASSWORD": "local-secret"})

        self.assertEqual("127.0.0.1", config.host)
        self.assertEqual(3306, config.port)
        self.assertEqual("podium", config.user)
        self.assertEqual("podiumdb", config.database)
        self.assertEqual("local-secret", config.password)

    def test_from_env_requires_password(self) -> None:
        with self.assertRaisesRegex(ConfigurationError, "PODIUMDB_PASSWORD"):
            DatabaseConfig.from_env({})

    def test_from_env_rejects_invalid_port(self) -> None:
        with self.assertRaisesRegex(ConfigurationError, "must be an integer"):
            DatabaseConfig.from_env(
                {
                    "PODIUMDB_PASSWORD": "local-secret",
                    "PODIUMDB_PORT": "not-a-port",
                }
            )

        with self.assertRaisesRegex(ConfigurationError, "between 1 and 65535"):
            DatabaseConfig.from_env(
                {
                    "PODIUMDB_PASSWORD": "local-secret",
                    "PODIUMDB_PORT": "70000",
                }
            )

    def test_connector_arguments_do_not_mutate_config(self) -> None:
        config = DatabaseConfig("db.local", 3307, "reader", "secret", "podiumdb")

        arguments = config.connector_arguments()
        arguments["host"] = "changed"

        self.assertEqual("db.local", config.host)
        self.assertFalse(arguments["autocommit"])


if __name__ == "__main__":
    unittest.main()

