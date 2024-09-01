FROM python:3.11-slim

WORKDIR /backend

COPY . /backend

RUN pip install -r /backend/requirements.txt

EXPOSE 8000

CMD uvicorn main:app --host 0.0.0.0