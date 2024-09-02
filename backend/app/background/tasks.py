import asyncio
import os
from datetime import datetime
from sqlalchemy.orm import Session

from saq import CronJob
from saq import Queue
from app.models import Book, get_sqlalchemy_engine
from app.logger import get_logger

logger = get_logger(__name__)

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = os.getenv("REDIS_PORT", 6379)
queue = Queue.from_url(f"redis://{REDIS_HOST}", name="book-queue")

async def embed_book(book_id: str):
    """
    Function to create embeddings for a book
    """
    logger.info(f"Creating embedding for book {book_id}")
    with Session(get_sqlalchemy_engine()) as db:
        try:
            book = db.query(Book).filter(Book.id == book_id).first()
            if not book:
                logger.warning(f"Book with id {book_id} not found")
                return
            
            # Here you would typically use an embedding model
            # For this example, we'll just create a mock embedding
            embedding = f"mock_embedding_for_{book.book_name}"
            
            book.embedding = embedding
            await asyncio.to_thread(db.commit)
            logger.info(f"Embedding created for book {book_id}")
        except Exception as e:
            logger.error(f"Error creating embedding for book {book_id}: {e}")
            raise e

async def log_cron_job(ctx):
    """
    Simple CRON job that just logs
    """
    logger.info(f"CRON job ran at {datetime.now()}")

settings = {
    "queue": queue,
    "functions": [embed_book],
    "concurrency": 10,
    "cron_jobs": [
        CronJob(log_cron_job, cron="*/5 * * * * *"),  # Run every 5 seconds
    ],
}
