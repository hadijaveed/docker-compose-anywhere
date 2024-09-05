#!/bin/bash
echo "WARNING: DO NOT RUN THIS SCRIPT UNLESS YOU KNOW EXACTLY WHAT YOU'RE DOING!"
echo "This script is for local migration only and can potentially overwrite your entire database."
echo "Proceed with extreme caution. only if you need to restore on a new host"
echo ""

# Variables
DB_PORT=5433  # Local port where the database is accessible

# Ask user for database name, username, and dump file path
read -p "Enter the database name: " DB_NAME
read -p "Enter the database username: " DB_USER
read -p "Enter the full path to the SQL dump file: " DUMP_FILE_PATH
read -sp "Enter the database password: " POSTGRES_PASSWORD

# Export the password as an environment variable
export PGPASSWORD=$DB_PASSWORD


# Validate inputs
if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DUMP_FILE_PATH" ]; then
    echo "Error: All inputs are required."
    exit 1
fi

if [ ! -f "$DUMP_FILE_PATH" ]; then
    echo "Error: The specified dump file does not exist."
    exit 1
fi

# Restore the database using psql
# Drop all connections to the database
PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -p $DB_PORT -U "$DB_USER" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME';"

# Drop and recreate the database
PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -p $DB_PORT -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -p $DB_PORT -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"

# Create the vector extension
PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -p $DB_PORT -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Restore the database from the dump file
PGPASSWORD=$POSTGRES_PASSWORD psql -h localhost -p $DB_PORT -U "$DB_USER" -d "$DB_NAME" -f "$DUMP_FILE_PATH"

echo "Database restoration completed successfully."
