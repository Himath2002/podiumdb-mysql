USE podiumdb;

CREATE OR REPLACE VIEW vw_athlete_medal_summary AS
SELECT
    a.athlete_id,
    CONCAT(a.given_name, ' ', a.family_name) AS athlete_name,
    a.country_code,
    c.country_name,
    COUNT(ma.award_id) AS total_medals,
    COALESCE(SUM(ma.medal_type = 'GOLD'), 0) AS gold_medals,
    COALESCE(SUM(ma.medal_type = 'SILVER'), 0) AS silver_medals,
    COALESCE(SUM(ma.medal_type = 'BRONZE'), 0) AS bronze_medals
FROM athletes AS a
JOIN countries AS c
    ON c.country_code = a.country_code
LEFT JOIN medal_awards AS ma
    ON ma.athlete_id = a.athlete_id
GROUP BY
    a.athlete_id,
    a.given_name,
    a.family_name,
    a.country_code,
    c.country_name;

CREATE OR REPLACE VIEW vw_country_medal_table AS
SELECT
    c.country_code,
    c.country_name,
    COALESCE(SUM(ma.medal_type = 'GOLD'), 0) AS gold_medals,
    COALESCE(SUM(ma.medal_type = 'SILVER'), 0) AS silver_medals,
    COALESCE(SUM(ma.medal_type = 'BRONZE'), 0) AS bronze_medals,
    COUNT(ma.award_id) AS total_medals
FROM countries AS c
LEFT JOIN medal_awards AS ma
    ON ma.country_code = c.country_code
GROUP BY c.country_code, c.country_name;

CREATE OR REPLACE VIEW vw_event_participation_summary AS
SELECT
    e.event_id,
    e.event_code,
    e.sport,
    e.event_name,
    e.event_format,
    COUNT(ee.entry_id) AS total_entries,
    COUNT(ee.athlete_id) AS athlete_entries,
    COUNT(ee.team_id) AS team_entries
FROM events AS e
LEFT JOIN event_entries AS ee
    ON ee.event_id = e.event_id
GROUP BY
    e.event_id,
    e.event_code,
    e.sport,
    e.event_name,
    e.event_format;

CREATE OR REPLACE VIEW vw_team_roster AS
SELECT
    t.team_code,
    t.team_name,
    t.discipline,
    t.country_code,
    a.athlete_id,
    CONCAT(a.given_name, ' ', a.family_name) AS athlete_name,
    tm.member_role
FROM teams AS t
JOIN team_memberships AS tm
    ON tm.team_id = t.team_id
JOIN athletes AS a
    ON a.athlete_id = tm.athlete_id;

CREATE OR REPLACE VIEW vw_schedule_timeline AS
SELECT
    es.schedule_id,
    e.event_code,
    e.sport,
    e.event_name,
    e.venue_name,
    es.starts_at,
    es.ends_at,
    es.status
FROM event_schedules AS es
JOIN events AS e
    ON e.event_id = es.event_id;
