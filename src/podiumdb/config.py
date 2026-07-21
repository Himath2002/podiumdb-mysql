"""Environment-backed database configuration without embedded credentials."""

from __future__ import annotations

from dataclasses import dataclass
from os import environ
from typing import Mapping


class ConfigurationError(ValueError):
    """Raised when connection configuration is missing or malformed."""


@dataclass(frozen=True)
class DatabaseConfig:
    """Connection values accepted by MySQL Connector/Python."""

    host: str
    port: int
    user: str
    password: str
    database: str

    @classmethod
    def from_env(cls, values: Mapping[str, str] | None = None) -> "DatabaseConfig":
        source = environ if values is None else values
        password = source.get("PODIUMDB_PASSWORD", "")
        if not password:
            raise ConfigurationError(
                "PODIUMDB_PASSWORD is required; copy .env.example for local values"
            )

        try:
            port = int(source.get("PODIUMDB_PORT", "3306"))
        except ValueError as error:
            raise ConfigurationError("PODIUMDB_PORT must be an integer") from error

        if not 1 <= port <= 65535:
            raise ConfigurationError("PODIUMDB_PORT must be between 1 and 65535")

        return cls(
            host=source.get("PODIUMDB_HOST", "127.0.0.1"),
            port=port,
            user=source.get("PODIUMDB_USER", "podium"),
            password=password,
            database=source.get("PODIUMDB_DATABASE", "podiumdb"),
        )

    def connector_arguments(self) -> dict[str, object]:
        """Return an isolated dictionary suitable for ``mysql.connector.connect``."""

        return {
            "host": self.host,
            "port": self.port,
            "user": self.user,
            "password": self.password,
            "database": self.database,
            "autocommit": False,
        }

