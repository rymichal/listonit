from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    app_name: str = "Listonit API"
    debug: bool = True
    sql_echo: bool = False

    # Database
    database_url: str = "postgresql://listonit:listonit_dev@localhost:5433/listonit"

    # CORS
    cors_origins: list[str] = ["http://localhost:3000", "http://localhost:8080"]

    # Mock user ID for development (until auth is implemented)
    mock_user_id: str = "00000000-0000-0000-0000-000000000001"

    # JWT Authentication
    jwt_secret_key: str = "your-secret-key-change-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()
