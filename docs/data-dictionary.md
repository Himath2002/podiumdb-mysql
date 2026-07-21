# Data dictionary

PodiumDB separates reference data, people, teams, competition activity, awards, and audit history. All tables use InnoDB; identifiers are stable numeric keys except the ISO-style three-letter country code.

## Reference and people

| Table | Purpose | Notable integrity rules |
| --- | --- | --- |
| `countries` | Canonical delegation lookup | Unique uppercase `country_code` and unique name |
| `coaches` | Coach identity and delegation | Country is required; deletion of a referenced country is restricted |
| `athletes` | Individual competitor identity | Country is required; coach is optional; birth dates before 1900 are rejected |

## Teams and membership

| Table | Purpose | Notable integrity rules |
| --- | --- | --- |
| `teams` | Named team for one discipline and country | Unique `team_code`; coach is optional |
| `team_memberships` | Many-to-many athlete/team bridge | Composite primary key prevents duplicate membership; deleting a team removes its memberships |

Membership is modelled independently from event entry. An athlete can belong to a team without that team being entered in every competition event.

## Competition

| Table | Purpose | Notable integrity rules |
| --- | --- | --- |
| `events` | Sport event definition | Unique `event_code`; format is `INDIVIDUAL` or `TEAM` |
| `event_entries` | Participant registered for an event | Exactly one of `athlete_id` and `team_id`; trigger confirms the participant matches the event format |
| `event_schedules` | Timed event occurrence | End cannot precede start; duplicate event/start combinations are rejected |

`event_entries` is deliberately polymorphic. A check constraint enforces a single participant, while validation triggers enforce the event-format rule before every insert and update.

## Awards and audit

| Table | Purpose | Notable integrity rules |
| --- | --- | --- |
| `medal_awards` | Gold, silver, or bronze result | Exactly one athlete/team recipient; recipient must be entered in the event; country must match the recipient |
| `medal_award_audit` | Immutable description of award changes | Captures insert, update, and delete snapshots as JSON with database user and timestamp |

Award validation is enforced at the database boundary, so it applies equally to the SQL scripts, Python client, and any future application.

## Relationship summary

```text
countries ─┬─< coaches
           ├─< athletes >─< team_memberships >─ teams
           ├─< teams
           └─< medal_awards

events ────┬─< event_entries >─ one athlete or one team
           ├─< event_schedules
           └─< medal_awards  >─ one athlete or one team

medal_awards ──< medal_award_audit
```

For column types, indexes, foreign-key actions, and checks, the executable source of truth is [`sql/schema/001_core_schema.sql`](../sql/schema/001_core_schema.sql).
