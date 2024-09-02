import os
import contextlib
import datetime
import uuid
from typing import ContextManager

from dotenv import load_dotenv

from sqlalchemy import Column
from sqlalchemy import create_engine
from sqlalchemy import DateTime
from sqlalchemy import Engine
from sqlalchemy import String
from sqlalchemy import Text
from sqlalchemy import func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Session
from sqlalchemy.orm import sessionmaker

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")


engine: Engine | None = None


def get_sqlalchemy_engine() -> Engine:
    global engine
    if engine is None:
        engine = create_engine(
            DATABASE_URL,
            pool_size=100,  # Reduced from 500
            max_overflow=100,  # Allow up to 10 connections beyond pool_size
            pool_recycle=3600,
        )
    return engine


SessionLocal = sessionmaker(
    autocommit=False, autoflush=False, bind=get_sqlalchemy_engine()
)

Base = declarative_base()

metadata = Base.metadata


def get_db():
    with Session(get_sqlalchemy_engine(), expire_on_commit=False) as session:
        yield session


def get_session_context_manager() -> ContextManager[Session]:
    return contextlib.contextmanager(get_db)()


BOOKS_TABLE = "books"

class Book(Base):
    __tablename__ = BOOKS_TABLE

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    book_name = Column(String, nullable=False)
    book_description = Column(Text)
    genre = Column(String)
    embedding = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    def __repr__(self):
        return f"<Book(id={self.id}, book_name='{self.book_name}', genre='{self.genre}')>"

