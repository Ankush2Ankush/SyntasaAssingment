"""
Database service layer for executing SQL queries
"""
from sqlalchemy.orm import Session
from sqlalchemy import text
import pandas as pd


class DatabaseService:
    """Service for database operations"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def execute_query(self, query: str, params: dict = None) -> pd.DataFrame:
        """
        Execute SQL query and return results as pandas DataFrame
        
        Args:
            query: SQL query string
            params: Query parameters
            
        Returns:
            pandas DataFrame with query results
        """
        result = self.db.execute(text(query), params or {})
        columns = result.keys()
        rows = result.fetchall()
        
        return pd.DataFrame(rows, columns=columns)
    
    def execute_scalar(self, query: str, params: dict = None):
        """Execute query and return scalar value"""
        result = self.db.execute(text(query), params or {})
        return result.scalar()
    
    def refresh_materialized_view(self, view_name: str):
        """Refresh a materialized view"""
        self.db.execute(text(f"REFRESH MATERIALIZED VIEW {view_name}"))
        self.db.commit()

