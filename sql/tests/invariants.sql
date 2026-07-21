USE podiumdb;

DROP PROCEDURE IF EXISTS assert_equal;
DROP PROCEDURE IF EXISTS assert_invalid_entry_rejected;
DROP PROCEDURE IF EXISTS assert_invalid_award_rejected;

DELIMITER //

CREATE PROCEDURE assert_equal(
    IN p_label VARCHAR(120),
    IN p_expected BIGINT,
    IN p_actual BIGINT
)
BEGIN
    DECLARE v_message VARCHAR(255);

    IF NOT (p_expected <=> p_actual) THEN
        SET v_message = CONCAT(
            p_label,
            ': expected ',
            p_expected,
            ', received ',
            COALESCE(p_actual, 'NULL')
        );
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_message;
    END IF;
END //

CREATE PROCEDURE assert_invalid_entry_rejected()
BEGIN
    DECLARE v_rejected BOOLEAN DEFAULT FALSE;

    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            SET v_rejected = TRUE;

        INSERT INTO event_entries (event_id, athlete_id, team_id)
        VALUES (301, NULL, 201);
    END;

    IF NOT v_rejected THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Team entry was accepted for an individual event';
    END IF;
END //

CREATE PROCEDURE assert_invalid_award_rejected()
BEGIN
    DECLARE v_rejected BOOLEAN DEFAULT FALSE;

    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            SET v_rejected = TRUE;

        INSERT INTO medal_awards (
            event_id,
            medal_type,
            athlete_id,
            team_id,
            country_code,
            awarded_on
        ) VALUES (305, 'GOLD', 1006, NULL, 'USA', '2026-07-22');
    END;

    IF NOT v_rejected THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Medal award accepted a mismatched country';
    END IF;
END //

DELIMITER ;

SELECT COUNT(*) INTO @actual FROM countries;
CALL assert_equal('country count', 8, @actual);

SELECT COUNT(*) INTO @actual FROM coaches;
CALL assert_equal('coach count', 8, @actual);

SELECT COUNT(*) INTO @actual FROM teams;
CALL assert_equal('team count', 6, @actual);

SELECT COUNT(*) INTO @actual FROM athletes;
CALL assert_equal('athlete count', 14, @actual);

SELECT COUNT(*) INTO @actual FROM team_memberships;
CALL assert_equal('membership count', 12, @actual);

SELECT COUNT(*) INTO @actual FROM events;
CALL assert_equal('event count', 6, @actual);

SELECT COUNT(*) INTO @actual FROM event_entries;
CALL assert_equal('entry count', 18, @actual);

SELECT COUNT(*) INTO @actual FROM event_schedules;
CALL assert_equal('schedule count', 6, @actual);

SELECT COUNT(*) INTO @actual FROM medal_awards;
CALL assert_equal('medal count', 10, @actual);

SELECT COUNT(*) INTO @actual FROM medal_award_audit;
CALL assert_equal('initial audit count', 10, @actual);

SELECT COUNT(*)
INTO @actual
FROM event_entries
WHERE (athlete_id IS NULL) = (team_id IS NULL);
CALL assert_equal('participant exclusivity', 0, @actual);

SELECT COUNT(*)
INTO @actual
FROM medal_awards
WHERE (athlete_id IS NULL) = (team_id IS NULL);
CALL assert_equal('award recipient exclusivity', 0, @actual);

SELECT SUM(total_medals) INTO @actual FROM vw_country_medal_table;
CALL assert_equal('medal-table total', 10, @actual);

SELECT COUNT(*)
INTO @actual
FROM event_schedules
WHERE ends_at < starts_at;
CALL assert_equal('schedule chronology', 0, @actual);

SELECT COUNT(*)
INTO @actual
FROM event_entries AS ee
JOIN events AS e
    ON e.event_id = ee.event_id
WHERE (e.event_format = 'INDIVIDUAL' AND ee.athlete_id IS NULL)
   OR (e.event_format = 'TEAM' AND ee.team_id IS NULL);
CALL assert_equal('entry format alignment', 0, @actual);

SELECT COUNT(*)
INTO @actual
FROM medal_awards AS ma
LEFT JOIN event_entries AS ee
    ON ee.event_id = ma.event_id
   AND ee.athlete_id <=> ma.athlete_id
   AND ee.team_id <=> ma.team_id
WHERE ee.entry_id IS NULL;
CALL assert_equal('award recipient registration', 0, @actual);

SELECT COUNT(*)
INTO @actual
FROM medal_awards AS ma
LEFT JOIN athletes AS a
    ON a.athlete_id = ma.athlete_id
LEFT JOIN teams AS t
    ON t.team_id = ma.team_id
WHERE ma.country_code <> COALESCE(a.country_code, t.country_code);
CALL assert_equal('award country alignment', 0, @actual);

CALL sp_athlete_medal_count(1009, @athlete_medals);
CALL assert_equal('stored medal count', 1, @athlete_medals);

CALL assert_invalid_entry_rejected();
CALL assert_invalid_award_rejected();

START TRANSACTION;

CALL sp_register_athlete(
    'Test',
    'Runner',
    '2000-01-01',
    'UNDISCLOSED',
    'BRA',
    108
);
SELECT COUNT(*) INTO @actual FROM athletes;
CALL assert_equal('transactional athlete insert', 15, @actual);

ROLLBACK;

SELECT COUNT(*) INTO @actual FROM athletes;
CALL assert_equal('athlete rollback', 14, @actual);

START TRANSACTION;

CALL sp_record_medal_award(
    305,
    'GOLD',
    1006,
    NULL,
    'GBR',
    '2026-07-22'
);
SELECT COUNT(*) INTO @actual FROM medal_awards;
CALL assert_equal('transactional medal insert', 11, @actual);

SELECT COUNT(*) INTO @actual FROM medal_award_audit;
CALL assert_equal('transactional audit insert', 11, @actual);

ROLLBACK;

SELECT COUNT(*) INTO @actual FROM medal_awards;
CALL assert_equal('medal rollback', 10, @actual);

SELECT COUNT(*) INTO @actual FROM medal_award_audit;
CALL assert_equal('audit rollback', 10, @actual);

START TRANSACTION;

CALL sp_rename_team('AUS-ARTISTIC-TEAM', 'Aurora Australia Artistic Team');
SELECT COUNT(*)
INTO @actual
FROM teams
WHERE team_code = 'AUS-ARTISTIC-TEAM'
  AND team_name = 'Aurora Australia Artistic Team';
CALL assert_equal('transactional team rename', 1, @actual);

ROLLBACK;

SELECT COUNT(*)
INTO @actual
FROM teams
WHERE team_code = 'AUS-ARTISTIC-TEAM'
  AND team_name = 'Australia Artistic Team';
CALL assert_equal('team rename rollback', 1, @actual);

START TRANSACTION;

UPDATE medal_awards
SET awarded_on = '2026-07-21'
WHERE award_id = 501;

DELETE FROM medal_awards
WHERE award_id = 510;

SELECT COUNT(*)
INTO @actual
FROM medal_award_audit
WHERE action_type = 'UPDATE';
CALL assert_equal('award update audit', 1, @actual);

SELECT COUNT(*)
INTO @actual
FROM medal_award_audit
WHERE action_type = 'DELETE';
CALL assert_equal('award delete audit', 1, @actual);

ROLLBACK;

SELECT COUNT(*) INTO @actual FROM medal_awards;
CALL assert_equal('award mutation rollback', 10, @actual);

SELECT COUNT(*) INTO @actual FROM medal_award_audit;
CALL assert_equal('mutation audit rollback', 10, @actual);

DROP PROCEDURE assert_invalid_award_rejected;
DROP PROCEDURE assert_invalid_entry_rejected;
DROP PROCEDURE assert_equal;

SELECT 'All PodiumDB invariants passed.' AS verification_result;
