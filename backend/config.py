from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    app_name: str = "Listonit API"
    debug: bool = False
    sql_echo: bool = False
    environment: str = "development"

    # Database configuration
    # For Cloud Run: Set individual components for Unix socket connection
    # For docker-compose: Use full DATABASE_URL
    database_url: str = ""

    # Cloud SQL connection components (for Cloud Run)
    db_user: str = ""
    db_password: str = ""
    db_name: str = "listonit"
    cloud_sql_connection_name: str = ""  # Format: project:region:instance
    db_socket_dir: str = "/cloudsql"     # Cloud SQL Unix socket directory

    @property
    def get_database_url(self) -> str:
        """
        Returns appropriate database URL for environment:
        - Cloud Run: Unix socket via Cloud SQL Proxy
        - Local/Docker: Standard TCP connection
        """
        if self.cloud_sql_connection_name:
            # Cloud Run: Use Unix socket
            return f"postgresql://{self.db_user}:{self.db_password}@/{self.db_name}?host={self.db_socket_dir}/{self.cloud_sql_connection_name}"
        elif self.database_url:
            # Docker-compose or local with full URL
            return self.database_url
        else:
            # Fallback: construct from components
            return f"postgresql://{self.db_user}:{self.db_password}@localhost:5433/{self.db_name}"

    # CORS - will need to add production domain
    cors_origins: list[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:8000"
    ]

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
