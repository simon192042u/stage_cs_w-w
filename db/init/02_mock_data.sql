-- Teams
INSERT INTO teams (name, city, founded_year, stadium) VALUES
  ('FC Zurich', 'Zurich', 1896, 'Letzigrund'),
  ('FC Basel', 'Basel', 1893, 'St. Jakob-Park'),
  ('BSC Young Boys', 'Bern', 1898, 'Wankdorf'),
  ('Servette FC', 'Geneva', 1890, 'Stade de Genève')
ON CONFLICT (name) DO NOTHING;

-- Players (a few per team)
WITH t AS (SELECT id, name FROM teams)
INSERT INTO players (team_id, first_name, last_name, position, number, nationality, birth_date)
SELECT t.id, p.first_name, p.last_name, p.position, p.number, p.nationality, p.birth_date
FROM t
JOIN (VALUES
  ('FC Zurich',       'Luca',   'Keller',   'GK',  1,  'Switzerland', '1998-02-10'::date),
  ('FC Zurich',       'Noah',   'Meier',    'DF',  4,  'Switzerland', '2000-06-21'::date),
  ('FC Zurich',       'Elias',  'Schmid',   'MF',  8,  'Switzerland', '1999-11-03'::date),
  ('FC Zurich',       'Milan',  'Petrovic', 'FW',  9,  'Serbia',      '1997-04-18'::date),

  ('FC Basel',        'Jonas',  'Huber',    'GK',  1,  'Switzerland', '1996-09-12'::date),
  ('FC Basel',        'Aron',   'Frei',     'DF',  3,  'Switzerland', '2001-01-09'::date),
  ('FC Basel',        'Sven',   'Lang',     'MF',  10, 'Germany',     '1998-07-27'::date),
  ('FC Basel',        'Thiago', 'Santos',   'FW',  11, 'Brazil',      '1999-03-05'::date),

  ('BSC Young Boys',  'Marco',  'Vogel',    'GK',  1,  'Switzerland', '1997-12-01'::date),
  ('BSC Young Boys',  'Yann',   'Rohner',   'DF',  5,  'Switzerland', '2000-08-14'::date),
  ('BSC Young Boys',  'Adem',   'Krasniqi', 'MF',  6,  'Kosovo',      '1999-05-22'::date),
  ('BSC Young Boys',  'Lucas',  'Diallo',   'FW',  7,  'France',      '1998-10-30'::date),

  ('Servette FC',     'David',  'Morel',    'GK',  1,  'Switzerland', '1995-04-02'::date),
  ('Servette FC',     'Kevin',  'Bernard',  'DF',  2,  'France',      '2000-02-19'::date),
  ('Servette FC',     'Nico',   'Rossi',    'MF',  8,  'Italy',       '1999-09-09'::date),
  ('Servette FC',     'Ibrahim','Kone',     'FW',  9,  'Mali',        '1997-01-11'::date)
) AS p(team_name, first_name, last_name, position, number, nationality, birth_date)
ON p.team_name = t.name;

-- Matches
WITH tz AS (SELECT id FROM teams WHERE name='FC Zurich'),
     ba AS (SELECT id FROM teams WHERE name='FC Basel'),
     yb AS (SELECT id FROM teams WHERE name='BSC Young Boys'),
     se AS (SELECT id FROM teams WHERE name='Servette FC')
INSERT INTO matches (match_date, home_team_id, away_team_id, home_score, away_score, venue)
VALUES
  ('2026-02-01', (SELECT id FROM tz), (SELECT id FROM ba), 2, 1, 'Letzigrund'),
  ('2026-02-08', (SELECT id FROM yb), (SELECT id FROM se), 1, 1, 'Wankdorf'),
  ('2026-02-15', (SELECT id FROM ba), (SELECT id FROM yb), 0, 3, 'St. Jakob-Park');

-- Goals
-- Helper: pick some player ids
WITH
m1 AS (SELECT id FROM matches WHERE match_date='2026-02-01'),
m2 AS (SELECT id FROM matches WHERE match_date='2026-02-08'),
m3 AS (SELECT id FROM matches WHERE match_date='2026-02-15'),
tz AS (SELECT id FROM teams WHERE name='FC Zurich'),
ba AS (SELECT id FROM teams WHERE name='FC Basel'),
yb AS (SELECT id FROM teams WHERE name='BSC Young Boys'),
se AS (SELECT id FROM teams WHERE name='Servette FC'),
p AS (
  SELECT id, first_name, last_name, team_id
  FROM players
)
INSERT INTO goals (match_id, team_id, player_id, minute, is_own_goal)
VALUES
  ((SELECT id FROM m1), (SELECT id FROM tz),
    (SELECT id FROM p WHERE first_name='Milan' AND last_name='Petrovic'), 23, FALSE),
  ((SELECT id FROM m1), (SELECT id FROM ba),
    (SELECT id FROM p WHERE first_name='Thiago' AND last_name='Santos'), 41, FALSE),
  ((SELECT id FROM m1), (SELECT id FROM tz),
    (SELECT id FROM p WHERE first_name='Elias' AND last_name='Schmid'), 78, FALSE),

  ((SELECT id FROM m2), (SELECT id FROM yb),
    (SELECT id FROM p WHERE first_name='Lucas' AND last_name='Diallo'), 12, FALSE),
  ((SELECT id FROM m2), (SELECT id FROM se),
    (SELECT id FROM p WHERE first_name='Ibrahim' AND last_name='Kone'), 67, FALSE),

  ((SELECT id FROM m3), (SELECT id FROM yb),
    (SELECT id FROM p WHERE first_name='Adem' AND last_name='Krasniqi'), 9, FALSE),
  ((SELECT id FROM m3), (SELECT id FROM yb),
    (SELECT id FROM p WHERE first_name='Lucas' AND last_name='Diallo'), 55, FALSE),
  ((SELECT id FROM m3), (SELECT id FROM yb),
    (SELECT id FROM p WHERE first_name='Lucas' AND last_name='Diallo'), 88, FALSE);
