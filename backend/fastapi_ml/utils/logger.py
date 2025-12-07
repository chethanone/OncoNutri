import logging
import sys
import os
from datetime import datetime
from pathlib import Path

def setup_logger(name: str = "onconutri_ml", level: int = logging.INFO) -> logging.Logger:
    """
    Setup and configure logger for the ML service
    """
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # Create console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    
    # Create file handler only if logs directory exists or can be created
    try:
        log_dir = Path("logs")
        log_dir.mkdir(exist_ok=True)
        file_handler = logging.FileHandler(f"logs/ml_service_{datetime.now().strftime('%Y%m%d')}.log")
        file_handler.setLevel(level)
    except (OSError, PermissionError):
        # Skip file logging if we can't create the directory (e.g., on read-only filesystems)
        file_handler = None
    
    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    console_handler.setFormatter(formatter)
    if file_handler:
        file_handler.setFormatter(formatter)
    
    # Add handlers
    if not logger.handlers:
        logger.addHandler(console_handler)
        if file_handler:
            logger.addHandler(file_handler)
    
    return logger
