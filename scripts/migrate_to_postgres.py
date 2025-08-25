#!/usr/bin/env python3
"""
Migration script to transfer embeddings from JSON file to PostgreSQL database.

Usage:
    python scripts/migrate_to_postgres.py --source server/storage/embeddings.json --db-dsn "postgresql://user:pass@host:port/db"
    
Environment variables:
    DB_DSN: PostgreSQL connection string
    EMBEDDING_DIM: Expected embedding dimension (default: 512)
"""

import argparse
import json
import logging
import os
import sys
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any, Dict

import numpy as np
import psycopg
from psycopg_pool import ConnectionPool

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def validate_embedding(embedding: Any, expected_dim: int) -> np.ndarray:
    """Validate and convert embedding to numpy array."""
    if isinstance(embedding, list):
        emb_array = np.array(embedding, dtype=np.float32)
    elif isinstance(embedding, np.ndarray):
        emb_array = embedding.astype(np.float32)
    else:
        raise ValueError(f"Invalid embedding type: {type(embedding)}")
    
    if emb_array.shape[0] != expected_dim:
        raise ValueError(f"Embedding dimension mismatch: got {emb_array.shape[0]}, expected {expected_dim}")
    
    return emb_array


def load_json_embeddings(json_path: Path) -> Any:
    """Load embeddings from JSON file."""
    if not json_path.exists():
        raise FileNotFoundError(f"JSON file not found: {json_path}")
    
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    logger.info(f"Loaded {len(data)} records from {json_path}")
    return data


def init_postgres_schema(pool: ConnectionPool, embedding_dim: int) -> None:
    """Initialize PostgreSQL schema with pgvector extension."""
    with pool.connection() as conn:
        with conn.cursor() as cur:
            # Enable pgvector extension
            cur.execute("CREATE EXTENSION IF NOT EXISTS vector")
            
            # Create users table
            cur.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id UUID PRIMARY KEY,
                    name TEXT NOT NULL,
                    position TEXT DEFAULT '',
                    model TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                    active BOOLEAN NOT NULL DEFAULT TRUE
                )
            """)
            
            # Create user_embeddings table
            cur.execute(f"""
                CREATE TABLE IF NOT EXISTS user_embeddings (
                    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
                    embedding vector({embedding_dim}) NOT NULL
                )
            """)
            
            # Create index for efficient similarity search
            cur.execute("CREATE INDEX IF NOT EXISTS user_embeddings_idx ON user_embeddings USING ivfflat (embedding vector_cosine_ops)")
        
        conn.commit()
    logger.info("PostgreSQL schema initialized")


def migrate_embeddings(json_data: Any, pool: ConnectionPool, embedding_dim: int, dry_run: bool = False) -> None:
    """Migrate embeddings from JSON to PostgreSQL."""
    migrated_count = 0
    skipped_count = 0
    error_count = 0
    
    # Handle both dict and list formats
    if isinstance(json_data, list):
        # Convert list format to dict format for processing
        data_items = [(item.get('id'), item) for item in json_data if isinstance(item, dict) and 'id' in item]
    elif isinstance(json_data, dict):
        data_items = list(json_data.items())
    else:
        logger.error(f"Unsupported JSON data format: {type(json_data)}")
        return
    
    with pool.connection() as conn:
        with conn.cursor() as cur:
            # Check existing users to avoid duplicates
            cur.execute("SELECT id FROM users")
            existing_ids = {str(row[0]) for row in cur.fetchall()}
            logger.info(f"Found {len(existing_ids)} existing users in database")
            
            for user_id_str, user_data in data_items:
                try:
                    # Validate user_id format
                    try:
                        user_uuid = uuid.UUID(user_id_str)
                    except ValueError:
                        logger.warning(f"Invalid UUID format: {user_id_str}, skipping")
                        skipped_count += 1
                        continue
                    
                    # Skip if already exists
                    if user_id_str in existing_ids:
                        logger.info(f"User {user_id_str} already exists, skipping")
                        skipped_count += 1
                        continue
                    
                    # Extract user information
                    name = user_data.get('name', 'Unknown')
                    position = user_data.get('position', '')
                    model = user_data.get('model', 'unknown')
                    timestamp_str = user_data.get('timestamp', '')
                    
                    # Parse timestamp
                    if timestamp_str:
                        try:
                            created_at = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
                        except ValueError:
                            created_at = datetime.now()
                    else:
                        created_at = datetime.now()
                    
                    # Validate embedding
                    embedding_data = user_data.get('embedding')
                    if embedding_data is None:
                        logger.warning(f"No embedding data for user {user_id_str}, skipping")
                        skipped_count += 1
                        continue
                    
                    try:
                        embedding = validate_embedding(embedding_data, embedding_dim)
                    except ValueError as e:
                        logger.warning(f"Invalid embedding for user {user_id_str}: {e}, skipping")
                        skipped_count += 1
                        continue
                    
                    # Insert into database (if not dry run)
                    if not dry_run:
                        # Insert user
                        cur.execute("""
                            INSERT INTO users (id, name, position, model, created_at, active)
                            VALUES (%s, %s, %s, %s, %s, %s)
                        """, (user_uuid, name, position, model, created_at, True))
                        
                        # Insert embedding
                        cur.execute("""
                            INSERT INTO user_embeddings (user_id, embedding)
                            VALUES (%s, %s)
                        """, (user_uuid, embedding.tolist()))
                    
                    logger.info(f"{'[DRY RUN] ' if dry_run else ''}Migrated user: {name} ({user_id_str})")
                    migrated_count += 1
                    
                except Exception as e:
                    logger.error(f"Error migrating user {user_id_str}: {e}")
                    error_count += 1
                    continue
        
        if not dry_run:
            conn.commit()
    
    logger.info(f"Migration summary: {migrated_count} migrated, {skipped_count} skipped, {error_count} errors")


def main():
    parser = argparse.ArgumentParser(description="Migrate embeddings from JSON to PostgreSQL")
    parser.add_argument("--source", "-s", type=Path, help="Path to JSON embeddings file")
    parser.add_argument("--db-dsn", "-d", type=str, help="PostgreSQL connection DSN")
    parser.add_argument("--embedding-dim", type=int, default=512, help="Expected embedding dimension")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be migrated without actually doing it")
    
    args = parser.parse_args()
    
    # Get source file
    source_file = args.source or Path(os.getenv("JSON_SOURCE", "server/storage/embeddings.json"))
    
    # Get database DSN
    db_dsn = args.db_dsn or os.getenv("DB_DSN")
    if not db_dsn:
        logger.error("Database DSN not provided. Use --db-dsn or set DB_DSN environment variable")
        sys.exit(1)
    
    # Get embedding dimension
    embedding_dim = args.embedding_dim or int(os.getenv("EMBEDDING_DIM", "512"))
    
    logger.info(f"Starting migration from {source_file} to PostgreSQL")
    logger.info(f"Expected embedding dimension: {embedding_dim}")
    
    if args.dry_run:
        logger.info("DRY RUN MODE - No changes will be made to the database")
    
    try:
        # Load JSON data
        json_data = load_json_embeddings(source_file)
        
        # Connect to PostgreSQL
        pool = ConnectionPool(db_dsn, min_size=1, max_size=2)
        logger.info("Connected to PostgreSQL")
        
        # Initialize schema
        init_postgres_schema(pool, embedding_dim)
        
        # Migrate data
        migrate_embeddings(json_data, pool, embedding_dim, dry_run=args.dry_run)
        
        logger.info("Migration completed successfully")
        
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
