USE podiumdb;

-- Synthetic demonstration data for the fictional 2026 Aurora Invitational.
-- Names and results are invented and do not represent real people or outcomes.

INSERT INTO countries (country_code, country_name) VALUES
    ('AUS', 'Australia'),
    ('BRA', 'Brazil'),
    ('CAN', 'Canada'),
    ('FRA', 'France'),
    ('GBR', 'Great Britain'),
    ('JPN', 'Japan'),
    ('KEN', 'Kenya'),
    ('USA', 'United States');

INSERT INTO coaches (coach_id, full_name, gender, country_code) VALUES
    (101, 'Jordan Ellis', 'UNDISCLOSED', 'USA'),
    (102, 'Hana Fujimoto', 'FEMALE', 'JPN'),
    (103, 'Morgan Hale', 'UNDISCLOSED', 'GBR'),
    (104, 'Lea Moreau', 'FEMALE', 'FRA'),
    (105, 'Casey Nguyen', 'NON_BINARY', 'AUS'),
    (106, 'Sophie Tremblay', 'FEMALE', 'CAN'),
    (107, 'Daniel Kiptoo', 'MALE', 'KEN'),
    (108, 'Marina Alves', 'FEMALE', 'BRA');

INSERT INTO teams (
    team_id,
    team_code,
    team_name,
    discipline,
    country_code,
    coach_id
) VALUES
    (201, 'USA-RELAY-MIXED', 'United States Mixed Relay', 'Athletics', 'USA', 101),
    (202, 'JPN-RELAY-MIXED', 'Japan Mixed Relay', 'Athletics', 'JPN', 102),
    (203, 'GBR-ARCHERY-MIXED', 'Great Britain Mixed Archery', 'Archery', 'GBR', 103),
    (204, 'FRA-ARCHERY-MIXED', 'France Mixed Archery', 'Archery', 'FRA', 104),
    (205, 'AUS-ARTISTIC-TEAM', 'Australia Artistic Team', 'Artistic Swimming', 'AUS', 105),
    (206, 'CAN-ARTISTIC-TEAM', 'Canada Artistic Team', 'Artistic Swimming', 'CAN', 106);

INSERT INTO athletes (
    athlete_id,
    given_name,
    family_name,
    date_of_birth,
    gender,
    country_code,
    coach_id
) VALUES
    (1001, 'Mara', 'Collins', '1998-03-14', 'FEMALE', 'USA', 101),
    (1002, 'Theo', 'Grant', '1996-08-22', 'MALE', 'USA', 101),
    (1003, 'Aiko', 'Mori', '1999-11-05', 'FEMALE', 'JPN', 102),
    (1004, 'Ren', 'Sato', '1997-06-18', 'MALE', 'JPN', 102),
    (1005, 'Isla', 'Reed', '2000-01-27', 'FEMALE', 'GBR', 103),
    (1006, 'Noah', 'Price', '1995-09-09', 'MALE', 'GBR', 103),
    (1007, 'Camille', 'Laurent', '1998-12-12', 'FEMALE', 'FRA', 104),
    (1008, 'Jules', 'Bernard', '1994-04-30', 'MALE', 'FRA', 104),
    (1009, 'Talia', 'Brooks', '2001-07-16', 'FEMALE', 'AUS', 105),
    (1010, 'Finn', 'Carter', '1997-10-03', 'MALE', 'AUS', 105),
    (1011, 'Amelie', 'Roy', '1999-02-21', 'FEMALE', 'CAN', 106),
    (1012, 'Luca', 'Martin', '1996-05-19', 'MALE', 'CAN', 106),
    (1013, 'Nia', 'Kibet', '1995-01-11', 'FEMALE', 'KEN', 107),
    (1014, 'Ana', 'Costa', '1998-09-24', 'FEMALE', 'BRA', 108);

INSERT INTO team_memberships (team_id, athlete_id, member_role, joined_on) VALUES
    (201, 1001, 'Relay runner', '2026-01-12'),
    (201, 1002, 'Relay runner', '2026-01-12'),
    (202, 1003, 'Relay runner', '2026-01-15'),
    (202, 1004, 'Relay runner', '2026-01-15'),
    (203, 1005, 'Archer', '2026-02-01'),
    (203, 1006, 'Archer', '2026-02-01'),
    (204, 1007, 'Archer', '2026-02-04'),
    (204, 1008, 'Archer', '2026-02-04'),
    (205, 1009, 'Swimmer', '2026-03-10'),
    (205, 1010, 'Swimmer', '2026-03-10'),
    (206, 1011, 'Swimmer', '2026-03-14'),
    (206, 1012, 'Swimmer', '2026-03-14');

INSERT INTO events (
    event_id,
    event_code,
    sport,
    event_name,
    event_format,
    venue_name
) VALUES
    (301, 'SWIM-100-F', 'Swimming', 'Women 100 m Freestyle', 'INDIVIDUAL', 'Aurora Aquatics Centre'),
    (302, 'ATH-MARATHON-M', 'Athletics', 'Men Marathon', 'INDIVIDUAL', 'Riverside Course'),
    (303, 'ARCHERY-MIXED-TEAM', 'Archery', 'Mixed Team Recurve', 'TEAM', 'North Green Arena'),
    (304, 'ATH-4X400-MIXED', 'Athletics', 'Mixed 4 x 400 m Relay', 'TEAM', 'Aurora Stadium'),
    (305, 'FENCING-FOIL-M', 'Fencing', 'Men Individual Foil', 'INDIVIDUAL', 'Central Hall'),
    (306, 'ARTISTIC-TEAM-OPEN', 'Artistic Swimming', 'Open Team Routine', 'TEAM', 'Aurora Aquatics Centre');

INSERT INTO event_entries (event_id, athlete_id, team_id, lane_or_seed) VALUES
    (301, 1009, NULL, 'Lane 4'),
    (301, 1011, NULL, 'Lane 5'),
    (301, 1003, NULL, 'Lane 3'),
    (301, 1001, NULL, 'Lane 6'),
    (302, 1013, NULL, 'Seed 1'),
    (302, 1002, NULL, 'Seed 7'),
    (302, 1006, NULL, 'Seed 4'),
    (302, 1008, NULL, 'Seed 3'),
    (303, NULL, 203, 'Seed 1'),
    (303, NULL, 204, 'Seed 2'),
    (304, NULL, 201, 'Lane 4'),
    (304, NULL, 202, 'Lane 5'),
    (305, 1006, NULL, 'Seed 1'),
    (305, 1008, NULL, 'Seed 2'),
    (305, 1002, NULL, 'Seed 3'),
    (305, 1004, NULL, 'Seed 4'),
    (306, NULL, 205, 'Order 1'),
    (306, NULL, 206, 'Order 2');

INSERT INTO event_schedules (
    schedule_id,
    event_id,
    starts_at,
    ends_at,
    status
) VALUES
    (401, 301, '2026-07-18 10:00:00', '2026-07-18 11:15:00', 'COMPLETED'),
    (402, 302, '2026-07-19 06:30:00', '2026-07-19 10:00:00', 'COMPLETED'),
    (403, 303, '2026-07-19 14:00:00', '2026-07-19 16:00:00', 'COMPLETED'),
    (404, 304, '2026-07-20 18:00:00', '2026-07-20 19:30:00', 'COMPLETED'),
    (405, 305, '2026-07-22 12:00:00', '2026-07-22 15:00:00', 'SCHEDULED'),
    (406, 306, '2026-07-23 16:00:00', '2026-07-23 18:00:00', 'SCHEDULED');

INSERT INTO medal_awards (
    award_id,
    event_id,
    medal_type,
    athlete_id,
    team_id,
    country_code,
    awarded_on
) VALUES
    (501, 301, 'GOLD', 1009, NULL, 'AUS', '2026-07-18'),
    (502, 301, 'SILVER', 1011, NULL, 'CAN', '2026-07-18'),
    (503, 301, 'BRONZE', 1003, NULL, 'JPN', '2026-07-18'),
    (504, 302, 'GOLD', 1013, NULL, 'KEN', '2026-07-19'),
    (505, 302, 'SILVER', 1008, NULL, 'FRA', '2026-07-19'),
    (506, 302, 'BRONZE', 1002, NULL, 'USA', '2026-07-19'),
    (507, 303, 'GOLD', NULL, 203, 'GBR', '2026-07-19'),
    (508, 303, 'SILVER', NULL, 204, 'FRA', '2026-07-19'),
    (509, 304, 'GOLD', NULL, 201, 'USA', '2026-07-20'),
    (510, 304, 'SILVER', NULL, 202, 'JPN', '2026-07-20');

