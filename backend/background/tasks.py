import asyncio
from datetime import datetime
from celery import Celery
from celery.schedules import crontab
from backend.logger import get_logger
from backend.models import get_sqlalchemy_engine, Book
from sqlalchemy.orm import Session

logger = get_logger(__name__)

# Celery configuration
celery_app = Celery('tasks', broker='redis://redis:6379/0')
celery_app.conf.update(
    result_backend='redis://redis:6379/0',
    task_serializer='json',
    result_serializer='json',
    accept_content=['json'],
    timezone='UTC',
    enable_utc=True,
)

@celery_app.on_after_configure.connect
def setup_periodic_tasks(sender, **kwargs):
    sender.add_periodic_task(
        crontab(minute='*'),  # Run every minute
        cron_job.s(),
        name='cron job every minute'
    )

@celery_app.task
def cron_job():
    """
    Basic cron job that runs every minute
    """
    logger.info(f"Cron job running at {datetime.now()}")

@celery_app.task
def process_book(book_id: str):
    """
    Job to process a book
    """
    logger.info(f"Processing book {book_id}")
    db_engine = get_sqlalchemy_engine()
    with Session(db_engine) as db:
        book = db.query(Book).filter(Book.id == book_id).first()
        if not book:
            logger.warning(f"Book not found: {book_id}")
            return
        # Add your book processing logic here
        # For example:
        # book.processed = True
        # db.commit()
    logger.info(f"Finished processing book {book_id}")

@celery_app.task
def enqueue_book(book_id: str):
    """
    Enqueue a book for processing
    """
    logger.info(f"Enqueuing book {book_id} for processing")
    process_book.delay(book_id)

# For testing purposes
if __name__ == "__main__":
    enqueue_book.delay('test_book_id')
    print("Enqueued test job")

"""
How to run Celery and Celery Beat in Docker with additional parameters:

1. Update your Dockerfile.background to include Celery:

FROM python:3.11-slim

WORKDIR /backend

COPY . /backend

RUN pip install -r /backend/requirements.txt

EXPOSE 8080

CMD ["celery", "-A", "backend.background.tasks", "worker", "--beat", "--loglevel=info"]

2. Update your docker-compose.yml file to include the Celery worker and beat with additional parameters:

  celery_worker:
    build:
      context: ./backend
      dockerfile: Dockerfile.background
    depends_on:
      - db
      - redis
    environment:
      - DATABASE_URL=postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    networks:
      - net
    deploy:
      replicas: 2
    restart: always
    command: >
      celery -A backend.background.tasks worker --beat --loglevel=info
      --concurrency=4
      --max-tasks-per-child=100
      --time-limit=3600
      --soft-time-limit=3540

3. Run your Docker containers:
   docker-compose up -d

This setup will run both the Celery worker and Celery Beat in the same container with additional parameters:
- concurrency: Sets the number of worker processes/threads.
- max-tasks-per-child: Maximum number of tasks a worker process can execute before it's replaced with a new one.
- time-limit: Hard time limit in seconds for the execution of a task.
- soft-time-limit: Soft time limit in seconds for the execution of a task.

You can adjust these parameters or add more as needed.

If you need to scale them separately, you can split them into two services in your docker-compose.yml file.

To check the logs:
docker-compose logs celery_worker

To scale the number of workers:
docker-compose up -d --scale celery_worker=3

Remember to add celery to your requirements.txt file if it's not already there.
"""
