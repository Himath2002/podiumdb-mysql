USE podiumdb;

SET NAMES utf8mb4;
SET time_zone = '+00:00';

DROP TABLE IF EXISTS medal_award_audit;
DROP TABLE IF EXISTS medal_awards;
DROP TABLE IF EXISTS event_schedules;
DROP TABLE IF EXISTS event_entries;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS team_memberships;
DROP TABLE IF EXISTS athletes;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS coaches;
DROP TABLE IF EXISTS countries;

CREATE TABLE countries (
    country_code CHAR(3) PRIMARY KEY,
    country_name VARCHAR(80) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_countries_name UNIQUE (country_name),
    CONSTRAINT chk_countries_code_format
        CHECK (country_code REGEXP '^[A-Z]{3}$'),
    CONSTRAINT chk_countries_name_not_blank
        CHECK (CHAR_LENGTH(TRIM(country_name)) > 0)
) ENGINE = InnoDB;

CREATE TABLE coaches (
    coach_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(120) NOT NULL,
    gender ENUM('FEMALE', 'MALE', 'NON_BINARY', 'UNDISCLOSED')
        NOT NULL DEFAULT 'UNDISCLOSED',
    country_code CHAR(3) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_coaches_name_not_blank
        CHECK (CHAR_LENGTH(TRIM(full_name)) > 0),
    CONSTRAINT fk_coaches_country
        FOREIGN KEY (country_code) REFERENCES countries (country_code),
    INDEX idx_coaches_country (country_code)
) ENGINE = InnoDB;

CREATE TABLE teams (
    team_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    team_code VARCHAR(24) NOT NULL,
    team_name VARCHAR(120) NOT NULL,
    discipline VARCHAR(80) NOT NULL,
    country_code CHAR(3) NOT NULL,
    coach_id BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_teams_code UNIQUE (team_code),
    CONSTRAINT chk_teams_code_not_blank
        CHECK (CHAR_LENGTH(TRIM(team_code)) > 0),
    CONSTRAINT chk_teams_name_not_blank
        CHECK (CHAR_LENGTH(TRIM(team_name)) > 0),
    CONSTRAINT chk_teams_discipline_not_blank
        CHECK (CHAR_LENGTH(TRIM(discipline)) > 0),
    CONSTRAINT fk_teams_country
        FOREIGN KEY (country_code) REFERENCES countries (country_code),
    CONSTRAINT fk_teams_coach
        FOREIGN KEY (coach_id) REFERENCES coaches (coach_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_teams_country (country_code),
    INDEX idx_teams_coach (coach_id)
) ENGINE = InnoDB;

CREATE TABLE athletes (
    athlete_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    given_name VARCHAR(80) NOT NULL,
    family_name VARCHAR(80) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('FEMALE', 'MALE', 'NON_BINARY', 'UNDISCLOSED')
        NOT NULL DEFAULT 'UNDISCLOSED',
    country_code CHAR(3) NOT NULL,
    coach_id BIGINT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_athletes_given_name_not_blank
        CHECK (CHAR_LENGTH(TRIM(given_name)) > 0),
    CONSTRAINT chk_athletes_family_name_not_blank
        CHECK (CHAR_LENGTH(TRIM(family_name)) > 0),
    CONSTRAINT fk_athletes_country
        FOREIGN KEY (country_code) REFERENCES countries (country_code),
    CONSTRAINT fk_athletes_coach
        FOREIGN KEY (coach_id) REFERENCES coaches (coach_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_athletes_birth_date
        CHECK (date_of_birth >= '1900-01-01'),
    INDEX idx_athletes_country (country_code),
    INDEX idx_athletes_coach (coach_id),
    INDEX idx_athletes_name (family_name, given_name)
) ENGINE = InnoDB;

CREATE TABLE team_memberships (
    team_id BIGINT UNSIGNED NOT NULL,
    athlete_id BIGINT UNSIGNED NOT NULL,
    member_role VARCHAR(60) NOT NULL DEFAULT 'Athlete',
    joined_on DATE NULL,
    PRIMARY KEY (team_id, athlete_id),
    CONSTRAINT chk_memberships_role_not_blank
        CHECK (CHAR_LENGTH(TRIM(member_role)) > 0),
    CONSTRAINT fk_memberships_team
        FOREIGN KEY (team_id) REFERENCES teams (team_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_memberships_athlete
        FOREIGN KEY (athlete_id) REFERENCES athletes (athlete_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_memberships_athlete (athlete_id)
) ENGINE = InnoDB;

CREATE TABLE events (
    event_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    event_code VARCHAR(24) NOT NULL,
    sport VARCHAR(80) NOT NULL,
    event_name VARCHAR(120) NOT NULL,
    event_format ENUM('INDIVIDUAL', 'TEAM') NOT NULL,
    venue_name VARCHAR(120) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_events_code UNIQUE (event_code),
    CONSTRAINT chk_events_code_not_blank
        CHECK (CHAR_LENGTH(TRIM(event_code)) > 0),
    CONSTRAINT chk_events_sport_not_blank
        CHECK (CHAR_LENGTH(TRIM(sport)) > 0),
    CONSTRAINT chk_events_name_not_blank
        CHECK (CHAR_LENGTH(TRIM(event_name)) > 0),
    CONSTRAINT chk_events_venue_not_blank
        CHECK (CHAR_LENGTH(TRIM(venue_name)) > 0),
    INDEX idx_events_sport (sport),
    INDEX idx_events_format (event_format)
) ENGINE = InnoDB;

CREATE TABLE event_entries (
    entry_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    event_id BIGINT UNSIGNED NOT NULL,
    athlete_id BIGINT UNSIGNED NULL,
    team_id BIGINT UNSIGNED NULL,
    lane_or_seed VARCHAR(20) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_entries_event
        FOREIGN KEY (event_id) REFERENCES events (event_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_entries_athlete
        FOREIGN KEY (athlete_id) REFERENCES athletes (athlete_id),
    CONSTRAINT fk_entries_team
        FOREIGN KEY (team_id) REFERENCES teams (team_id),
    CONSTRAINT chk_entries_single_participant
        CHECK ((athlete_id IS NULL) + (team_id IS NULL) = 1),
    CONSTRAINT uq_entries_event_athlete UNIQUE (event_id, athlete_id),
    CONSTRAINT uq_entries_event_team UNIQUE (event_id, team_id),
    INDEX idx_entries_athlete (athlete_id),
    INDEX idx_entries_team (team_id)
) ENGINE = InnoDB;

CREATE TABLE event_schedules (
    schedule_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    event_id BIGINT UNSIGNED NOT NULL,
    starts_at DATETIME NOT NULL,
    ends_at DATETIME NOT NULL,
    status ENUM('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')
        NOT NULL DEFAULT 'SCHEDULED',
    CONSTRAINT fk_schedules_event
        FOREIGN KEY (event_id) REFERENCES events (event_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_schedules_time_order CHECK (ends_at >= starts_at),
    CONSTRAINT uq_schedules_event_start UNIQUE (event_id, starts_at),
    INDEX idx_schedules_status_start (status, starts_at)
) ENGINE = InnoDB;

CREATE TABLE medal_awards (
    award_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    event_id BIGINT UNSIGNED NOT NULL,
    medal_type ENUM('GOLD', 'SILVER', 'BRONZE') NOT NULL,
    athlete_id BIGINT UNSIGNED NULL,
    team_id BIGINT UNSIGNED NULL,
    country_code CHAR(3) NOT NULL,
    awarded_on DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_awards_event
        FOREIGN KEY (event_id) REFERENCES events (event_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_awards_athlete
        FOREIGN KEY (athlete_id) REFERENCES athletes (athlete_id),
    CONSTRAINT fk_awards_team
        FOREIGN KEY (team_id) REFERENCES teams (team_id),
    CONSTRAINT fk_awards_country
        FOREIGN KEY (country_code) REFERENCES countries (country_code),
    CONSTRAINT chk_awards_single_recipient
        CHECK ((athlete_id IS NULL) + (team_id IS NULL) = 1),
    CONSTRAINT uq_awards_event_athlete UNIQUE (event_id, athlete_id),
    CONSTRAINT uq_awards_event_team UNIQUE (event_id, team_id),
    INDEX idx_awards_event_medal (event_id, medal_type),
    INDEX idx_awards_athlete (athlete_id),
    INDEX idx_awards_team (team_id),
    INDEX idx_awards_country (country_code)
) ENGINE = InnoDB;

CREATE TABLE medal_award_audit (
    audit_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    award_id BIGINT UNSIGNED NULL,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    changed_by VARCHAR(288) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_medal_audit_award (award_id),
    INDEX idx_medal_audit_changed_at (changed_at)
) ENGINE = InnoDB;
