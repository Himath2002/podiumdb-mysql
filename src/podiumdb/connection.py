"""Transaction-aware MySQL connection boundary."""

from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator

import mysql.connector
from mysql.connector.abstracts import MySQLConnectionAbstract

from podiumdb.config import DatabaseConfig


@contextmanager
def open_connection(
    config: DatabaseConfig | None = None,
) -> Iterator[MySQLConnectionAbstract]:
    """Open a connection, commit on success, roll back on failure, and always close."""

    effective_config = config or DatabaseConfig.from_env()
    connection = mysql.connector.connect(**effective_config.connector_arguments())
    try:
        yield connection
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()

