"""
Database connection and session management
"""
import os
from sqlalchemy import create_engine, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

# Database URL from environment variable
# Default to SQLite for easy setup
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./nyc_taxi.db"
)

# Create engine
# SQLite-specific configuration
if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(
        DATABASE_URL,
        connect_args={
            "check_same_thread": False,  # SQLite requirement
            "timeout": 300,  # 5 minute timeout for long queries
        },
        pool_pre_ping=True,  # Verify connections before using
        echo=False
    )
    # Set SQLite optimizations on connection
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_conn, connection_record):
        cursor = dbapi_conn.cursor()
        # Enable WAL mode for better concurrency
        cursor.execute("PRAGMA journal_mode=WAL")
        # Increase cache size to 1GB (256MB * 4)
        cursor.execute("PRAGMA cache_size=-256000")
        # Set synchronous to NORMAL (faster than FULL, still safe with WAL)
        cursor.execute("PRAGMA synchronous=NORMAL")
        # Enable query planner optimizations
        cursor.execute("PRAGMA optimize")
        cursor.close()
else:
    # PostgreSQL configuration
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,
        pool_size=10,
        max_overflow=20
    )

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()


def get_db():
    """Dependency for getting database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

