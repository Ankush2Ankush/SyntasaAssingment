"""
Script to run ETL pipeline
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.pipelines.etl import load_taxi_zones, load_parquet_to_sql

if __name__ == "__main__":
    print("Starting ETL Pipeline...")
    print("=" * 50)
    
    # Load taxi zones first
    print("\n1. Loading Taxi Zone Lookup Table...")
    try:
        load_taxi_zones()
        print("[OK] Taxi zones loaded successfully")
    except Exception as e:
        print(f"[ERROR] Error loading taxi zones: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    # Load trip data
    print("\n2. Loading Trip Data...")
    try:
        load_parquet_to_sql()
        print("[OK] Trip data loaded successfully")
    except Exception as e:
        print(f"[ERROR] Error loading trip data: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    print("\n" + "=" * 50)
    print("ETL Pipeline Completed Successfully!")
    print("=" * 50)

