"""
Script to check database connection and verify setup
"""
import sys
import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./nyc_taxi.db"
)

def check_database():
    """Check if database is accessible and tables exist"""
    try:
        # SQLite-specific configuration
        if DATABASE_URL.startswith("sqlite"):
            engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
        else:
            engine = create_engine(DATABASE_URL)
        
        print("Checking database connection...")
        with engine.connect() as conn:
            # Test connection
            if DATABASE_URL.startswith("sqlite"):
                result = conn.execute(text("SELECT sqlite_version()"))
                version = result.fetchone()[0]
                print(f"[OK] Connected to SQLite: {version}")
            else:
                result = conn.execute(text("SELECT version()"))
                version = result.fetchone()[0]
                print(f"[OK] Connected to PostgreSQL: {version.split(',')[0]}")
            
            # Check if tables exist (SQLite vs PostgreSQL)
            if DATABASE_URL.startswith("sqlite"):
                result = conn.execute(text("""
                    SELECT name 
                    FROM sqlite_master 
                    WHERE type='table'
                """))
                tables = [row[0] for row in result]
            else:
                result = conn.execute(text("""
                    SELECT table_name 
                    FROM information_schema.tables 
                    WHERE table_schema = 'public'
                """))
                tables = [row[0] for row in result]
            
            print(f"\nTables found: {tables}")
            
            if 'trips' in tables:
                result = conn.execute(text("SELECT COUNT(*) FROM trips"))
                trip_count = result.fetchone()[0]
                print(f"[OK] Trips table exists with {trip_count:,} records")
            else:
                print("[X] Trips table does not exist")
            
            if 'taxi_zones' in tables:
                result = conn.execute(text("SELECT COUNT(*) FROM taxi_zones"))
                zone_count = result.fetchone()[0]
                print(f"[OK] Taxi_zones table exists with {zone_count:,} records")
            else:
                print("[X] Taxi_zones table does not exist")
        
        return True
        
    except Exception as e:
        print(f"[ERROR] Database connection failed: {e}")
        print("\nPlease ensure:")
        print("1. PostgreSQL is running")
        print("2. Database 'nyc_taxi_db' exists")
        print("3. DATABASE_URL in .env is correct")
        return False

if __name__ == "__main__":
    success = check_database()
    sys.exit(0 if success else 1)

