"""
FastAPI application entry point for NYC TLC Analytics Dashboard
"""
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database.connection import engine, Base
from app.api import overview, zones, efficiency, surge, wait_time, congestion, incentives, variability, simulation

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="NYC TLC Analytics API",
    description="API for NYC Yellow Taxi Trip Records Analysis (Jan-Apr 2025)",
    version="1.0.0",
    docs_url=None,  # Disable Swagger UI
    redoc_url=None  # Disable ReDoc
)

# CORS configuration - allow frontend URLs from environment or default to localhost
frontend_urls = os.getenv("FRONTEND_URLS", "http://localhost:5173,http://localhost:3000").split(",")
frontend_urls = [url.strip() for url in frontend_urls if url.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=frontend_urls,  # Configure via FRONTEND_URLS environment variable
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(overview.router, prefix="/api/v1", tags=["Overview"])
app.include_router(zones.router, prefix="/api/v1", tags=["Zones"])
app.include_router(efficiency.router, prefix="/api/v1", tags=["Efficiency"])
app.include_router(surge.router, prefix="/api/v1", tags=["Surge"])
app.include_router(wait_time.router, prefix="/api/v1", tags=["Wait Time"])
app.include_router(congestion.router, prefix="/api/v1", tags=["Congestion"])
app.include_router(incentives.router, prefix="/api/v1", tags=["Incentives"])
app.include_router(variability.router, prefix="/api/v1", tags=["Variability"])
app.include_router(simulation.router, prefix="/api/v1", tags=["Simulation"])


@app.get("/")
async def root():
    return {"message": "NYC TLC Analytics API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.get("/api/health")
async def api_health_check():
    """Health check endpoint for API monitoring"""
    return {"status": "healthy", "service": "nyc-taxi-api"}

