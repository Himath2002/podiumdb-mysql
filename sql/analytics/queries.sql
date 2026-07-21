USE podiumdb;

-- 1. Athlete directory with country and coach context.
SELECT
    a.athlete_id,
    a.given_name,
    a.family_name,
    c.country_name,
    co.full_name AS coach_name
FROM athletes AS a
JOIN countries AS c
    ON c.country_code = a.country_code
LEFT JOIN coaches AS co
    ON co.coach_id = a.coach_id
ORDER BY c.country_name, a.family_name, a.given_name;

-- 2. Team rosters with explicit many-to-many memberships.
SELECT
    team_code,
    team_name,
    discipline,
    country_code,
    athlete_name,
    member_role
FROM vw_team_roster
ORDER BY team_name, athlete_name;

-- 3. Event participation across individual and team formats.
SELECT
    event_code,
    sport,
    event_name,
    event_format,
    total_entries
FROM vw_event_participation_summary
ORDER BY total_entries DESC, event_code;

-- 4. Medal table using conditional aggregation.
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
    country_code;

-- 5. Individual medal leaders, including athletes without an award.
SELECT
    athlete_id,
    athlete_name,
    country_code,
    gold_medals,
    silver_medals,
    bronze_medals,
    total_medals
FROM vw_athlete_medal_summary
ORDER BY total_medals DESC, athlete_name;

-- 6. Athletes whose medal count exceeds the medalist average.
WITH medal_counts AS (
    SELECT
        athlete_id,
        total_medals
    FROM vw_athlete_medal_summary
    WHERE total_medals > 0
),
average_medals AS (
    SELECT AVG(total_medals) AS average_count
    FROM medal_counts
)
SELECT
    summary.athlete_id,
    summary.athlete_name,
    summary.country_code,
    summary.total_medals
FROM vw_athlete_medal_summary AS summary
CROSS JOIN average_medals
WHERE summary.total_medals > average_medals.average_count
ORDER BY summary.total_medals DESC, summary.athlete_name;

-- 7. Chronological competition schedule.
SELECT
    event_code,
    sport,
    event_name,
    venue_name,
    starts_at,
    ends_at,
    status
FROM vw_schedule_timeline
ORDER BY starts_at, event_code;

-- 8. Coaching workload across teams and individual athletes.
SELECT
    co.coach_id,
    co.full_name,
    co.country_code,
    COUNT(DISTINCT t.team_id) AS teams_coached,
    COUNT(DISTINCT a.athlete_id) AS athletes_coached
FROM coaches AS co
LEFT JOIN teams AS t
    ON t.coach_id = co.coach_id
LEFT JOIN athletes AS a
    ON a.coach_id = co.coach_id
GROUP BY co.coach_id, co.full_name, co.country_code
ORDER BY teams_coached DESC, athletes_coached DESC, co.full_name;

-- 9. Event awards with a normalized recipient display name.
SELECT
    e.event_code,
    e.event_name,
    ma.medal_type,
    COALESCE(
        CONCAT(a.given_name, ' ', a.family_name),
        t.team_name
    ) AS recipient_name,
    ma.country_code
FROM medal_awards AS ma
JOIN events AS e
    ON e.event_id = ma.event_id
LEFT JOIN athletes AS a
    ON a.athlete_id = ma.athlete_id
LEFT JOIN teams AS t
    ON t.team_id = ma.team_id
ORDER BY e.event_code, FIELD(ma.medal_type, 'GOLD', 'SILVER', 'BRONZE');

-- 10. Delegation sizes, including countries with no seeded athletes.
SELECT
    c.country_code,
    c.country_name,
    COUNT(a.athlete_id) AS athlete_count
FROM countries AS c
LEFT JOIN athletes AS a
    ON a.country_code = c.country_code
GROUP BY c.country_code, c.country_name
ORDER BY athlete_count DESC, c.country_code;

