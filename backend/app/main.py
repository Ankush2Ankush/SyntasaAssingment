"""
FastAPI application entry point for NYC TLC Analytics Dashboard
"""
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

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],  # Vite and CRA default ports
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

