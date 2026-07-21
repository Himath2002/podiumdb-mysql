USE podiumdb;

DROP TRIGGER IF EXISTS trg_event_entries_validate_insert;
DROP TRIGGER IF EXISTS trg_event_entries_validate_update;
DROP TRIGGER IF EXISTS trg_medal_awards_validate_insert;
DROP TRIGGER IF EXISTS trg_medal_awards_validate_update;
DROP TRIGGER IF EXISTS trg_medal_awards_audit_insert;
DROP TRIGGER IF EXISTS trg_medal_awards_audit_update;
DROP TRIGGER IF EXISTS trg_medal_awards_audit_delete;

DROP PROCEDURE IF EXISTS sp_validate_event_entry;
DROP PROCEDURE IF EXISTS sp_validate_medal_award;
DROP PROCEDURE IF EXISTS sp_register_athlete;
DROP PROCEDURE IF EXISTS sp_athlete_medal_count;
DROP PROCEDURE IF EXISTS sp_rename_team;
DROP PROCEDURE IF EXISTS sp_record_medal_award;

DELIMITER //

CREATE PROCEDURE sp_validate_event_entry(
    IN p_event_id BIGINT UNSIGNED,
    IN p_athlete_id BIGINT UNSIGNED,
    IN p_team_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_event_format VARCHAR(16);

    SELECT event_format
    INTO v_event_format
    FROM events
    WHERE event_id = p_event_id;

    IF v_event_format IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Event entry references an unknown event';
    END IF;

    IF (p_athlete_id IS NULL) = (p_team_id IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Event entry must identify exactly one participant';
    END IF;

    IF v_event_format = 'INDIVIDUAL' AND p_athlete_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Individual events require an athlete entry';
    END IF;

    IF v_event_format = 'TEAM' AND p_team_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Team events require a team entry';
    END IF;
END //

CREATE PROCEDURE sp_validate_medal_award(
    IN p_event_id BIGINT UNSIGNED,
    IN p_athlete_id BIGINT UNSIGNED,
    IN p_team_id BIGINT UNSIGNED,
    IN p_country_code CHAR(3)
)
BEGIN
    DECLARE v_entry_count INT DEFAULT 0;
    DECLARE v_recipient_country CHAR(3);

    IF (p_athlete_id IS NULL) = (p_team_id IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Medal award must identify exactly one recipient';
    END IF;

    IF p_athlete_id IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_entry_count
        FROM event_entries
        WHERE event_id = p_event_id
          AND athlete_id = p_athlete_id;

        SELECT country_code
        INTO v_recipient_country
        FROM athletes
        WHERE athlete_id = p_athlete_id;
    ELSE
        SELECT COUNT(*)
        INTO v_entry_count
        FROM event_entries
        WHERE event_id = p_event_id
          AND team_id = p_team_id;

        SELECT country_code
        INTO v_recipient_country
        FROM teams
        WHERE team_id = p_team_id;
    END IF;

    IF v_entry_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Medal recipient is not registered for the event';
    END IF;

    IF v_recipient_country IS NULL OR v_recipient_country <> p_country_code THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Medal country must match the recipient country';
    END IF;
END //

CREATE PROCEDURE sp_register_athlete(
    IN p_given_name VARCHAR(80),
    IN p_family_name VARCHAR(80),
    IN p_date_of_birth DATE,
    IN p_gender VARCHAR(16),
    IN p_country_code CHAR(3),
    IN p_coach_id BIGINT UNSIGNED
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM countries WHERE country_code = p_country_code
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot register athlete: unknown country code';
    END IF;

    IF p_coach_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM coaches WHERE coach_id = p_coach_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot register athlete: unknown coach';
    END IF;

    IF p_gender NOT IN ('FEMALE', 'MALE', 'NON_BINARY', 'UNDISCLOSED') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot register athlete: invalid gender value';
    END IF;

    INSERT INTO athletes (
        given_name,
        family_name,
        date_of_birth,
        gender,
        country_code,
        coach_id
    ) VALUES (
        p_given_name,
        p_family_name,
        p_date_of_birth,
        p_gender,
        p_country_code,
        p_coach_id
    );

    SELECT LAST_INSERT_ID() AS athlete_id;
END //

CREATE PROCEDURE sp_athlete_medal_count(
    IN p_athlete_id BIGINT UNSIGNED,
    OUT p_medal_count INT
)
BEGIN
    SELECT COUNT(*)
    INTO p_medal_count
    FROM medal_awards
    WHERE athlete_id = p_athlete_id;
END //

CREATE PROCEDURE sp_rename_team(
    IN p_team_code VARCHAR(24),
    IN p_team_name VARCHAR(120)
)
BEGIN
    UPDATE teams
    SET team_name = p_team_name
    WHERE team_code = p_team_code;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot rename team: unknown team code';
    END IF;
END //

CREATE PROCEDURE sp_record_medal_award(
    IN p_event_id BIGINT UNSIGNED,
    IN p_medal_type VARCHAR(8),
    IN p_athlete_id BIGINT UNSIGNED,
    IN p_team_id BIGINT UNSIGNED,
    IN p_country_code CHAR(3),
    IN p_awarded_on DATE
)
BEGIN
    IF p_medal_type NOT IN ('GOLD', 'SILVER', 'BRONZE') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot record medal: invalid medal type';
    END IF;

    INSERT INTO medal_awards (
        event_id,
        medal_type,
        athlete_id,
        team_id,
        country_code,
        awarded_on
    ) VALUES (
        p_event_id,
        p_medal_type,
        p_athlete_id,
        p_team_id,
        p_country_code,
        p_awarded_on
    );

    SELECT LAST_INSERT_ID() AS award_id;
END //

CREATE TRIGGER trg_event_entries_validate_insert
BEFORE INSERT ON event_entries
FOR EACH ROW
BEGIN
    CALL sp_validate_event_entry(NEW.event_id, NEW.athlete_id, NEW.team_id);
END //

CREATE TRIGGER trg_event_entries_validate_update
BEFORE UPDATE ON event_entries
FOR EACH ROW
BEGIN
    CALL sp_validate_event_entry(NEW.event_id, NEW.athlete_id, NEW.team_id);
END //

CREATE TRIGGER trg_medal_awards_validate_insert
BEFORE INSERT ON medal_awards
FOR EACH ROW
BEGIN
    CALL sp_validate_medal_award(
        NEW.event_id,
        NEW.athlete_id,
        NEW.team_id,
        NEW.country_code
    );
END //

CREATE TRIGGER trg_medal_awards_validate_update
BEFORE UPDATE ON medal_awards
FOR EACH ROW
BEGIN
    CALL sp_validate_medal_award(
        NEW.event_id,
        NEW.athlete_id,
        NEW.team_id,
        NEW.country_code
    );
END //

CREATE TRIGGER trg_medal_awards_audit_insert
AFTER INSERT ON medal_awards
FOR EACH ROW
BEGIN
    INSERT INTO medal_award_audit (
        award_id,
        action_type,
        new_values,
        changed_by
    ) VALUES (
        NEW.award_id,
        'INSERT',
        JSON_OBJECT(
            'event_id', NEW.event_id,
            'medal_type', NEW.medal_type,
            'athlete_id', NEW.athlete_id,
            'team_id', NEW.team_id,
            'country_code', NEW.country_code,
            'awarded_on', NEW.awarded_on
        ),
        CURRENT_USER()
    );
END //

CREATE TRIGGER trg_medal_awards_audit_update
AFTER UPDATE ON medal_awards
FOR EACH ROW
BEGIN
    INSERT INTO medal_award_audit (
        award_id,
        action_type,
        old_values,
        new_values,
        changed_by
    ) VALUES (
        NEW.award_id,
        'UPDATE',
        JSON_OBJECT(
            'event_id', OLD.event_id,
            'medal_type', OLD.medal_type,
            'athlete_id', OLD.athlete_id,
            'team_id', OLD.team_id,
            'country_code', OLD.country_code,
            'awarded_on', OLD.awarded_on
        ),
        JSON_OBJECT(
            'event_id', NEW.event_id,
            'medal_type', NEW.medal_type,
            'athlete_id', NEW.athlete_id,
            'team_id', NEW.team_id,
            'country_code', NEW.country_code,
            'awarded_on', NEW.awarded_on
        ),
        CURRENT_USER()
    );
END //

CREATE TRIGGER trg_medal_awards_audit_delete
AFTER DELETE ON medal_awards
FOR EACH ROW
BEGIN
    INSERT INTO medal_award_audit (
        award_id,
        action_type,
        old_values,
        changed_by
    ) VALUES (
        OLD.award_id,
        'DELETE',
        JSON_OBJECT(
            'event_id', OLD.event_id,
            'medal_type', OLD.medal_type,
            'athlete_id', OLD.athlete_id,
            'team_id', OLD.team_id,
            'country_code', OLD.country_code,
            'awarded_on', OLD.awarded_on
        ),
        CURRENT_USER()
    );
END //

DELIMITER ;

