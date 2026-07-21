"""Parameterized application queries and stored-procedure adapters."""

from __future__ import annotations

from datetime import date
from typing import Any

from mysql.connector.abstracts import MySQLConnectionAbstract


class PodiumRepository:
    """Small repository boundary used by the command-line client."""

    def __init__(self, connection: MySQLConnectionAbstract) -> None:
        self._connection = connection

    def country_medal_table(self) -> list[dict[str, Any]]:
        return self._fetch_all(
            """
            SELECT
                country_code,
                country_name,
                gold_medals,
                silver_medals,
                bronze_medals,
                total_medals
            FROM vw_country_medal_table
            WHERE total_medals > 0
            ORDER BY
                gold_medals DESC,
                silver_medals DESC,
                bronze_medals DESC,
                country_code
            """
        )

    def athletes(self, country_code: str | None = None) -> list[dict[str, Any]]:
        query = """
            SELECT
                athlete_id,
                given_name,
                family_name,
                country_code,
                gender
            FROM athletes
        """
        parameters: tuple[object, ...] = ()
        if country_code:
            query += " WHERE country_code = %s"
            parameters = (country_code.upper(),)
        query += " ORDER BY family_name, given_name"
        return self._fetch_all(query, parameters)

    def event_summary(self) -> list[dict[str, Any]]:
        return self._fetch_all(
            """
            SELECT
                event_code,
                sport,
                event_name,
                event_format,
                total_entries
            FROM vw_event_participation_summary
            ORDER BY event_code
            """
        )

    def register_athlete(
        self,
        given_name: str,
        family_name: str,
        date_of_birth: date,
        gender: str,
        country_code: str,
        coach_id: int | None,
    ) -> int:
        cursor = self._connection.cursor(dictionary=True)
        try:
            cursor.callproc(
                "sp_register_athlete",
                (
                    given_name,
                    family_name,
                    date_of_birth,
                    gender.upper(),
                    country_code.upper(),
                    coach_id,
                ),
            )
            for result in cursor.stored_results():
                row = result.fetchone()
                if row:
                    return int(row["athlete_id"] if isinstance(row, dict) else row[0])
        finally:
            cursor.close()
        raise RuntimeError("sp_register_athlete did not return the new athlete ID")

    def _fetch_all(
        self,
        query: str,
        parameters: tuple[object, ...] = (),
    ) -> list[dict[str, Any]]:
        cursor = self._connection.cursor(dictionary=True)
        try:
            cursor.execute(query, parameters)
            return list(cursor.fetchall())
        finally:
            cursor.close()

