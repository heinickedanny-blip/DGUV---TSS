"""
ANCHOR: Application Settings
Konfigurationsmodul für die DGUV3 Flask-Anwendung.

Dieses Modul stellt `get_config()` bereit, damit `src.main` die Anwendungskonfiguration
importieren kann. Die Werte werden aus den Container-Umgebungsvariablen gelesen.
"""

import os


class Config:
    """SECTION: Basiskonfiguration für Flask und Datenbank."""

    SECRET_KEY = os.getenv("SECRET_KEY", "dev-change-me")
    FLASK_ENV = os.getenv("FLASK_ENV", "production")
    DEBUG = os.getenv("FLASK_DEBUG", "0").lower() in {"1", "true", "yes", "on"}
    TESTING = False

    DB_HOST = os.getenv("DB_HOST", "mysql")
    DB_PORT = int(os.getenv("DB_PORT", "3306"))
    DB_USER = os.getenv("DB_USER", "dguv3")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "change_me_dguv3")
    DB_NAME = os.getenv("DB_NAME", "dguv3_db")

    DEFAULT_CUSTOMER = os.getenv("DEFAULT_CUSTOMER", "TSS")

    # NOTE: SQLAlchemy wird hier nicht zwingend verwendet, ist aber für Flask-Erweiterungen hilfreich.
    SQLALCHEMY_DATABASE_URI = (
        f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}?charset=utf8mb4"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False


class DevelopmentConfig(Config):
    """SECTION: Entwicklungskonfiguration."""

    DEBUG = True
    FLASK_ENV = "development"


class ProductionConfig(Config):
    """SECTION: Produktionskonfiguration."""

    DEBUG = False
    FLASK_ENV = "production"


class TestingConfig(Config):
    """SECTION: Testkonfiguration."""

    TESTING = True
    DEBUG = True
    FLASK_ENV = "testing"


def get_config():
    """Gibt anhand von FLASK_ENV die passende Konfigurationsklasse zurück."""

    env = os.getenv("FLASK_ENV", "production").lower()
    if env in {"dev", "development"}:
        return DevelopmentConfig
    if env in {"test", "testing"}:
        return TestingConfig
    return ProductionConfig
