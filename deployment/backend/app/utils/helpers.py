"""
Helper utility functions
"""
from typing import Any, Dict
import json


def format_response(data: Any, assumptions: Dict[str, Any] = None) -> Dict[str, Any]:
    """Format API response with data and assumptions"""
    return {
        "data": data,
        "assumptions": assumptions or {}
    }


def safe_divide(numerator: float, denominator: float, default: float = 0.0) -> float:
    """Safely divide two numbers, returning default if denominator is zero"""
    if denominator == 0 or denominator is None:
        return default
    return numerator / denominator

