"""
ETL Pipeline to load parquet files into SQL database
"""
import pandas as pd
from pathlib import Path
from sqlalchemy import create_engine
from app.database.connection import DATABASE_URL
import os
from dotenv import load_dotenv

load_dotenv()

# Use SQLite if DATABASE_URL is not set or is SQLite
if not os.getenv("DATABASE_URL") or DATABASE_URL.startswith("sqlite"):
    # SQLite-specific engine for ETL
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    engine = create_engine(DATABASE_URL)


def load_parquet_to_sql(data_dir: str = "../data", batch_size: int = 10000):
    """
    ETL pipeline to load parquet files into SQL database
    
    Args:
        data_dir: Directory containing parquet files
        batch_size: Number of rows to insert per batch
    """
    # Engine is created at module level
    
    # List of parquet files to load
    files = [
        "yellow_tripdata_2025-01.parquet",
        "yellow_tripdata_2025-02.parquet",
        "yellow_tripdata_2025-03.parquet",
        "yellow_tripdata_2025-04.parquet",
    ]
    
    data_path = Path(data_dir)
    
    for file in files:
        file_path = data_path / file
        if not file_path.exists():
            print(f"Warning: {file} not found, skipping...")
            continue
            
        print(f"Loading {file}...")
        
        # Read parquet file
        df = pd.read_parquet(file_path)
        
        # Clean and transform data
        # Remove rows with missing critical fields
        df = df.dropna(subset=[
            'tpep_pickup_datetime', 
            'tpep_dropoff_datetime', 
            'PULocationID', 
            'DOLocationID'
        ])
        
        # Filter to valid dates (2025 only)
        df['tpep_pickup_datetime'] = pd.to_datetime(df['tpep_pickup_datetime'])
        df['tpep_dropoff_datetime'] = pd.to_datetime(df['tpep_dropoff_datetime'])
        df = df[df['tpep_pickup_datetime'].dt.year == 2025]
        
        # Remove invalid durations
        df = df[df['tpep_dropoff_datetime'] > df['tpep_pickup_datetime']]
        
        # Rename columns to match database schema
        column_mapping = {
            'PULocationID': 'pulocationid',
            'DOLocationID': 'dolocationid',
        }
        df = df.rename(columns=column_mapping)
        
        # Select only columns that exist in database
        # Map original column names to database column names
        column_selection = {}
        db_column_mapping = {
            'tpep_pickup_datetime': 'tpep_pickup_datetime',
            'tpep_dropoff_datetime': 'tpep_dropoff_datetime',
            'pulocationid': 'pulocationid',  # Already renamed above
            'dolocationid': 'dolocationid',  # Already renamed above
            'trip_distance': 'trip_distance',
            'fare_amount': 'fare_amount',
            'tip_amount': 'tip_amount',
            'total_amount': 'total_amount',
            'extra': 'extra',
            'mta_tax': 'mta_tax',
            'tolls_amount': 'tolls_amount',
            'payment_type': 'payment_type',
            'RatecodeID': 'ratecodeid',  # Original name
            'passenger_count': 'passenger_count',
            'VendorID': 'vendorid'  # Original name
        }
        
        # Build column selection dict
        for orig_col, db_col in db_column_mapping.items():
            if orig_col in df.columns:
                column_selection[orig_col] = db_col
        
        # Rename columns for database
        df = df.rename(columns={k: v for k, v in column_selection.items() if k != v})
        
        # Select only the columns we need
        df = df[list(column_selection.values())]
        
        # Load to database in batches
        # SQLite doesn't support 'multi' method, use default
        if DATABASE_URL.startswith("sqlite"):
            df.to_sql(
                'trips',
                engine,
                if_exists='append',
                index=False,
                chunksize=batch_size
            )
        else:
            df.to_sql(
                'trips',
                engine,
                if_exists='append',
                index=False,
                method='multi',
                chunksize=batch_size
            )
        
        print(f"Loaded {len(df)} rows from {file}")
    
    print("ETL pipeline completed!")


def load_taxi_zones(data_dir: str = "../data"):
    """Load taxi zone lookup table"""
    # Engine is created at module level
    
    zones_file = Path(data_dir) / "taxi_zone_lookup.csv"
    
    if not zones_file.exists():
        print(f"Warning: {zones_file} not found")
        return
    
    df = pd.read_csv(zones_file)
    
    # Rename columns to match database schema
    # Handle case-insensitive column matching
    column_mapping = {}
    for col in df.columns:
        col_lower = col.lower()
        if col_lower == 'locationid':
            column_mapping[col] = 'locationid'
        elif col_lower == 'borough':
            column_mapping[col] = 'borough'
        elif col_lower == 'zone':
            column_mapping[col] = 'zone'
        elif col_lower == 'service_zone':
            column_mapping[col] = 'service_zone'
    
    df = df.rename(columns=column_mapping)
    
    # Select only the columns we need
    required_cols = ['locationid', 'borough', 'zone', 'service_zone']
    available_cols = [col for col in required_cols if col in df.columns]
    df = df[available_cols]
    
    df.to_sql(
        'taxi_zones',
        engine,
        if_exists='replace',
        index=False
    )
    
    print(f"Loaded {len(df)} taxi zones")


if __name__ == "__main__":
    # Run ETL pipeline
    load_taxi_zones()
    load_parquet_to_sql()

