"""
SQL query executor - loads and executes SQL queries from files
"""
from pathlib import Path
from app.services.db_service import DatabaseService


class SQLExecutor:
    """Execute SQL queries from files"""
    
    def __init__(self, db_service: DatabaseService):
        self.db_service = db_service
        self.sql_dir = Path(__file__).parent.parent / "sql"
    
    def load_query(self, file_path: str) -> str:
        """Load SQL query from file"""
        full_path = self.sql_dir / file_path
        if not full_path.exists():
            raise FileNotFoundError(f"SQL file not found: {full_path}")
        
        with open(full_path, 'r') as f:
            return f.read()
    
    def execute_file(self, file_path: str, params: dict = None):
        """Execute SQL query from file"""
        query = self.load_query(file_path)
        return self.db_service.execute_query(query, params)

