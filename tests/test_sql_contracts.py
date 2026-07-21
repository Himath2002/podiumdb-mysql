import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class SqlContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.schema = (ROOT / "sql/schema/001_core_schema.sql").read_text()
        cls.routines = (ROOT / "sql/routines/001_routines_and_triggers.sql").read_text()
        cls.views = (ROOT / "sql/analytics/001_views.sql").read_text()
        cls.seed = (ROOT / "sql/seed/001_synthetic_competition.sql").read_text()

    def test_schema_declares_the_normalized_domain_tables(self) -> None:
        declared = set(re.findall(r"CREATE TABLE (\w+)", self.schema))
        expected = {
            "athletes",
            "coaches",
            "countries",
            "event_entries",
            "event_schedules",
            "events",
            "medal_award_audit",
            "medal_awards",
            "team_memberships",
            "teams",
        }

        self.assertEqual(expected, declared)

    def test_routines_and_views_cover_the_public_workflows(self) -> None:
        procedures = set(re.findall(r"CREATE PROCEDURE (\w+)", self.routines))
        views = set(re.findall(r"CREATE OR REPLACE VIEW (\w+)", self.views))

        self.assertTrue(
            {
                "sp_athlete_medal_count",
                "sp_record_medal_award",
                "sp_register_athlete",
                "sp_rename_team",
            }.issubset(procedures)
        )
        self.assertEqual(
            {
                "vw_athlete_medal_summary",
                "vw_country_medal_table",
                "vw_event_participation_summary",
                "vw_schedule_timeline",
                "vw_team_roster",
            },
            views,
        )

    def test_participant_exclusivity_is_enforced_twice(self) -> None:
        self.assertIn("chk_entries_single_participant", self.schema)
        self.assertIn("chk_awards_single_recipient", self.schema)
        self.assertIn("sp_validate_event_entry", self.routines)
        self.assertIn("sp_validate_medal_award", self.routines)

    def test_seed_is_explicitly_synthetic(self) -> None:
        self.assertIn("Synthetic demonstration data", self.seed)
        self.assertIn("fictional 2026 Aurora Invitational", self.seed)

    def test_python_sources_do_not_embed_database_credentials(self) -> None:
        sources = "\n".join(
            path.read_text() for path in sorted((ROOT / "src").rglob("*.py"))
        )

        self.assertNotRegex(sources, r"(?i)password\s*=\s*['\"][^'\"]+['\"]")
        self.assertIn('source.get("PODIUMDB_PASSWORD", "")', sources)


if __name__ == "__main__":
    unittest.main()
