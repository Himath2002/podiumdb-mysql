"""Command-line access to the most useful PodiumDB workflows."""

from __future__ import annotations

import argparse
from collections.abc import Sequence
from datetime import date
from typing import Any

from podiumdb.config import ConfigurationError, DatabaseConfig
from podiumdb.connection import open_connection
from podiumdb.repository import PodiumRepository


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="podiumdb",
        description="Query and maintain the local PodiumDB sports dataset.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("medal-table", help="Show country medal totals")

    athletes_parser = subparsers.add_parser("athletes", help="List athletes")
    athletes_parser.add_argument(
        "--country",
        help="Optional three-letter country code",
    )

    subparsers.add_parser("events", help="Show event participation totals")

    register_parser = subparsers.add_parser(
        "register-athlete",
        help="Register an athlete through the validated stored procedure",
    )
    register_parser.add_argument("--given-name", required=True)
    register_parser.add_argument("--family-name", required=True)
    register_parser.add_argument("--date-of-birth", required=True, type=date.fromisoformat)
    register_parser.add_argument(
        "--gender",
        choices=("FEMALE", "MALE", "NON_BINARY", "UNDISCLOSED"),
        default="UNDISCLOSED",
    )
    register_parser.add_argument("--country", required=True)
    register_parser.add_argument("--coach-id", type=int)
    return parser


def render_table(rows: Sequence[dict[str, Any]]) -> str:
    """Render dictionary rows as a dependency-free aligned table."""

    if not rows:
        return "No rows returned."

    headers = list(rows[0].keys())
    rendered_rows = [[_display_value(row.get(header)) for header in headers] for row in rows]
    widths = [
        max(len(header), *(len(row[index]) for row in rendered_rows))
        for index, header in enumerate(headers)
    ]

    header_line = " | ".join(
        header.ljust(widths[index]) for index, header in enumerate(headers)
    )
    separator = "-+-".join("-" * width for width in widths)
    body = [
        " | ".join(value.ljust(widths[index]) for index, value in enumerate(row))
        for row in rendered_rows
    ]
    return "\n".join([header_line, separator, *body])


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    arguments = parser.parse_args(argv)

    try:
        config = DatabaseConfig.from_env()
    except ConfigurationError as error:
        parser.error(str(error))

    with open_connection(config) as connection:
        repository = PodiumRepository(connection)
        if arguments.command == "medal-table":
            print(render_table(repository.country_medal_table()))
        elif arguments.command == "athletes":
            print(render_table(repository.athletes(arguments.country)))
        elif arguments.command == "events":
            print(render_table(repository.event_summary()))
        elif arguments.command == "register-athlete":
            athlete_id = repository.register_athlete(
                given_name=arguments.given_name,
                family_name=arguments.family_name,
                date_of_birth=arguments.date_of_birth,
                gender=arguments.gender,
                country_code=arguments.country,
                coach_id=arguments.coach_id,
            )
            print(f"Registered athlete {athlete_id}.")
    return 0


def _display_value(value: Any) -> str:
    if value is None:
        return "-"
    if hasattr(value, "isoformat"):
        return str(value.isoformat())
    return str(value)


if __name__ == "__main__":
    raise SystemExit(main())

