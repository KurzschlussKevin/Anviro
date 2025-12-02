from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    # HIER jetzt erstmal hardcoded:
    DATABASE_URL: str = "postgresql+psycopg2://postgres:KevSebKB020012@localhost:5432/anviro"

    BACKEND_CORS_ORIGINS: List[str] = ["http://127.0.0.1:8080", "http://localhost:8080", "*"]

    class Config:
        # .env erstmal deaktivieren zum Test
        env_file = None
        env_file_encoding = "utf-8"


settings = Settings()
