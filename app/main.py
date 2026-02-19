from fastapi import FastAPI, Depends, HTTPException # Importiert FastAPI-Grundfunktionen
from fastapi.middleware.cors import CORSMiddleware # Erlaubt dem Browser den Zugriff (CORS)
from sqlalchemy import create_engine, text # Werkzeuge für die Datenbankverbindung und SQL
from sqlalchemy.orm import sessionmaker, Session # Verwaltung von Datenbank-Sitzungen
from pydantic import BaseModel # Datenvalidierung für eingehende JSON-Daten
from typing import Optional # Erlaubt optionale Felder
import os # Zugriff auf Umgebungsvariablen

# --- Datenbank-Konfiguration ---
DB_URL = os.getenv("DATABASE_URL", "postgresql://football_user:football_pass@postgres:5432/baba") # Datenbank-Pfad
engine = create_engine(DB_URL) # Erstellt die Verbindung zur DB
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine) # Erstellt die Sitzungs-Fabrik

app = FastAPI(title="Football Manager API") # Startet die API

# --- CORS Einstellungen (Damit das Frontend zugreifen darf) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Erlaubt Anfragen von allen Quellen
    allow_methods=["*"], # Erlaubt alle HTTP-Methoden (GET, POST, etc.)
    allow_headers=["*"], # Erlaubt alle Header
)

# --- Daten-Modelle ---
class TeamCreate(BaseModel): # Schema für ein neues Team
    name: str
    city: Optional[str] = None
    founded_year: Optional[int] = None

class PlayerCreate(BaseModel): # Schema für einen neuen Spieler
    team_id: int
    first_name: str
    last_name: str
    position: str

# --- Datenbank-Hilfsfunktion ---
def get_db(): # Stellt eine Datenbankverbindung für Anfragen bereit
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close() # Schließt die Verbindung am Ende immer

# --- ENDPUNKTE: TEAMS ---
@app.get("/teams") # Ruft alle Teams ab
def get_teams(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT * FROM teams ORDER BY name")).fetchall()
    return [dict(row._mapping) for row in result]

@app.post("/teams") # Erstellt ein neues Team
def create_team(team: TeamCreate, db: Session = Depends(get_db)):
    query = text("INSERT INTO teams (name, city, founded_year) VALUES (:n, :c, :y) RETURNING id")
    result = db.execute(query, {"n": team.name, "c": team.city, "y": team.founded_year})
    db.commit() # Speichert die Änderung
    return {"id": result.fetchone()[0]}

# --- ENDPUNKTE: SPIELER ---
@app.get("/players") # Ruft alle Spieler inklusive Team-Namen ab (WICHTIG für 'Vereinslos'-Problem)
def get_players(db: Session = Depends(get_db)):
    # Der LEFT JOIN verknüpft Spieler mit Teams, um den Team-Namen zu erhalten
    query = text("""
        SELECT p.*, t.name as team_name 
        FROM players p 
        LEFT JOIN teams t ON p.team_id = t.id 
        ORDER BY p.id DESC
    """)
    result = db.execute(query).fetchall()
    return [dict(row._mapping) for row in result]

@app.post("/players") # Erstellt einen neuen Spieler
def create_player(player: PlayerCreate, db: Session = Depends(get_db)):
    query = text("INSERT INTO players (team_id, first_name, last_name, position) VALUES (:t_id, :fn, :ln, :pos) RETURNING id")
    result = db.execute(query, {"t_id": player.team_id, "fn": player.first_name, "ln": player.last_name, "pos": player.position})
    db.commit()
    return {"id": result.fetchone()[0]}

@app.put("/players/{player_id}") # Bearbeitet einen vorhandenen Spieler
def update_player(player_id: int, player: PlayerCreate, db: Session = Depends(get_db)):
    query = text("UPDATE players SET team_id = :t_id, first_name = :fn, last_name = :ln, position = :pos WHERE id = :id")
    result = db.execute(query, {"id": player_id, "t_id": player.team_id, "fn": player.first_name, "ln": player.last_name, "pos": player.position})
    db.commit()
    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Spieler nicht gefunden")
    return {"status": "updated"}

@app.delete("/players/{player_id}") # Löscht einen Spieler
def delete_player(player_id: int, db: Session = Depends(get_db)):
    db.execute(text("DELETE FROM players WHERE id = :id"), {"id": player_id})
    db.commit()
    return {"status": "deleted"}

# --- ENDPUNKT: STATISTIK ---
@app.get("/stats/goals") # Berechnet Top-Torschützen über JOIN mit der 'goals' Tabelle
def get_goal_stats(db: Session = Depends(get_db)):
    query = text("""
        SELECT p.first_name, p.last_name, COUNT(g.id) as goal_count 
        FROM players p 
        JOIN goals g ON p.id = g.player_id 
        GROUP BY p.id, p.first_name, p.last_name 
        ORDER BY goal_count DESC
    """)
    result = db.execute(query).fetchall()
    return [dict(row._mapping) for row in result]