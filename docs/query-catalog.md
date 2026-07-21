# Analytics catalog

The project keeps reusable projections in views and reviewer-friendly examples in [`sql/analytics/queries.sql`](../sql/analytics/queries.sql).

## Views

| View | Question answered |
| --- | --- |
| `vw_athlete_medal_summary` | How many medals of each type has every athlete earned? |
| `vw_country_medal_table` | How does each delegation rank by gold, silver, bronze, and total medals? |
| `vw_event_participation_summary` | How many athlete or team entries does each event contain? |
| `vw_team_roster` | Which athletes belong to each team, and in what role? |
| `vw_schedule_timeline` | Where and when does each event run, and what is its status? |

## Query set

| # | Analysis | SQL concepts demonstrated |
| ---: | --- | --- |
| 1 | Athlete directory with country and coach context | Inner and left joins |
| 2 | Team rosters | Many-to-many bridge traversal |
| 3 | Event participation | Reusable view and multi-format counts |
| 4 | Country medal table | Conditional aggregation and ranked ordering |
| 5 | Individual medal leaders | Outer-join-derived zero counts |
| 6 | Above-average medalists | Common table expressions and scalar comparison |
| 7 | Competition schedule | Chronological projection |
| 8 | Coaching workload | Multiple left joins and distinct aggregation |
| 9 | Normalized award recipient names | Polymorphic joins, `COALESCE`, and domain ordering |
| 10 | Delegation sizes | Inclusive aggregation over reference data |

Run the complete catalog against the Docker environment with:

```bash
make analytics
```

The CLI exposes the highest-signal read models as `podiumdb medal-table`, `podiumdb athletes`, and `podiumdb events`.
