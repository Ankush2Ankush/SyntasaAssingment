"""
FastAPI application entry point for NYC TLC Analytics Dashboard
"""
import os
import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from app.database.connection import engine, Base
from app.api import overview, zones, efficiency, surge, wait_time, congestion, incentives, variability, simulation


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Startup and shutdown events for the application.
    Database tables are created asynchronously to not block startup.
    """
    # Create database tables in background to not block startup
    def create_tables():
        try:
            Base.metadata.create_all(bind=engine)
            print("Database tables created/verified successfully")
        except Exception as e:
            print(f"Warning: Error creating database tables: {e}")
            # Don't fail startup if tables already exist
    
    # Run table creation in thread pool to not block startup
    loop = asyncio.get_event_loop()
    loop.run_in_executor(None, create_tables)
    
    yield  # Application is running
    
    # Cleanup on shutdown (if needed)
    pass

app = FastAPI(
    title="NYC TLC Analytics API",
    description="API for NYC Yellow Taxi Trip Records Analysis (Jan-Apr 2025)",
    version="1.0.0",
    docs_url=None,  # Disable Swagger UI
    redoc_url=None,  # Disable ReDoc
    lifespan=lifespan  # Use lifespan context manager for startup/shutdown
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
    """Health check endpoint for load balancer"""
    try:
        # Quick database connectivity check (non-blocking)
        from app.database.connection import engine
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        # Still return healthy even if DB check fails (ETL might be running)
        return {"status": "healthy", "database": "initializing"}


@app.get("/api/health")
async def api_health_check():
    """Health check endpoint for API monitoring"""
    try:
        # Quick database connectivity check
        from app.database.connection import engine
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {
            "status": "healthy",
            "service": "nyc-taxi-api",
            "database": "connected"
        }
    except Exception as e:
        # Return healthy even during ETL/initialization
        return {
            "status": "healthy",
            "service": "nyc-taxi-api",
            "database": "initializing"
        }

