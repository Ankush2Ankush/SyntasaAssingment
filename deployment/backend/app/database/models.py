"""
SQLAlchemy models for NYC TLC data
"""
from sqlalchemy import Column, Integer, Float, String, DateTime, Index
from sqlalchemy.sql import func
from app.database.connection import Base


class Trip(Base):
    """Trip records table"""
    __tablename__ = "trips"

    id = Column(Integer, primary_key=True, index=True)
    tpep_pickup_datetime = Column(DateTime, nullable=False, index=True)
    tpep_dropoff_datetime = Column(DateTime, nullable=False, index=True)
    pulocationid = Column(Integer, nullable=False, index=True)
    dolocationid = Column(Integer, nullable=False, index=True)
    trip_distance = Column(Float, nullable=True)
    fare_amount = Column(Float, nullable=True)
    tip_amount = Column(Float, nullable=True)
    total_amount = Column(Float, nullable=True)
    extra = Column(Float, nullable=True)
    mta_tax = Column(Float, nullable=True)
    tolls_amount = Column(Float, nullable=True)
    payment_type = Column(Integer, nullable=True)
    ratecodeid = Column(Integer, nullable=True)
    passenger_count = Column(Integer, nullable=True)
    vendorid = Column(Integer, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    # Composite indexes for common queries
    __table_args__ = (
        Index('idx_pickup_location_time', 'pulocationid', 'tpep_pickup_datetime'),
        Index('idx_dropoff_location_time', 'dolocationid', 'tpep_dropoff_datetime'),
    )


class TaxiZone(Base):
    """Taxi zone lookup table"""
    __tablename__ = "taxi_zones"

    locationid = Column(Integer, primary_key=True, index=True)
    borough = Column(String)
    zone = Column(String)
    service_zone = Column(String)

