-- Basic football schema: teams, players, matches, goals

CREATE TABLE IF NOT EXISTS teams (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL UNIQUE,
  city        TEXT,
  founded_year INT,
  stadium     TEXT
);

CREATE TABLE IF NOT EXISTS players (
  id          SERIAL PRIMARY KEY,
  team_id     INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  first_name  TEXT NOT NULL,
  last_name   TEXT NOT NULL,
  position    TEXT NOT NULL CHECK (position IN ('GK','DF','MF','FW')),
  number      INT,
  nationality TEXT,
  birth_date  DATE
);

CREATE TABLE IF NOT EXISTS matches (
  id            SERIAL PRIMARY KEY,
  match_date    DATE NOT NULL,
  home_team_id  INT NOT NULL REFERENCES teams(id),
  away_team_id  INT NOT NULL REFERENCES teams(id),
  home_score    INT NOT NULL DEFAULT 0,
  away_score    INT NOT NULL DEFAULT 0,
  venue         TEXT
);

CREATE TABLE IF NOT EXISTS goals (
  id          SERIAL PRIMARY KEY,
  match_id    INT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  team_id     INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  player_id   INT REFERENCES players(id) ON DELETE SET NULL,
  minute      INT NOT NULL CHECK (minute BETWEEN 1 AND 130),
  is_own_goal BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_players_team ON players(team_id);
CREATE INDEX IF NOT EXISTS idx_matches_date ON matches(match_date);
CREATE INDEX IF NOT EXISTS idx_goals_match ON goals(match_id);
