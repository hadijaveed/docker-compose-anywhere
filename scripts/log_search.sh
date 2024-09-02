#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0"
    echo "This script provides an interactive interface to search Docker logs across multiple service instances."
}

# Function to get available service types
get_service_types() {
    docker ps --format '{{.Names}}' | sed -E 's/[-_][0-9]+$//g' | sort -u
}

# Function to get instances of a specific service type
get_service_instances() {
    local service_type="$1"
    docker ps --format '{{.Names}}' | grep "^${service_type}[-_][0-9]\+$" | sort
}

# Function to search logs across multiple instances
search_logs() {
    local service_type="$1"
    local since="$2"
    local until="$3"
    local search_term="$4"

    instances=$(get_service_instances "$service_type")
    
    for instance in $instances; do
        echo "Searching logs for $instance:"
        docker logs --since "$since" --until "$until" "$instance" 2>&1 | grep -i "$search_term"
        echo "----------------------------------------"
    done
}

# Function to handle service-specific searches
service_search_loop() {
    local service_type="$1"
    local since="$2"
    local until="$3"

    while true; do
        echo "=== Searching $service_type logs ==="
        echo "Current time range: From $since to $until"
        echo "1. Perform a search"
        echo "2. Change time range"
        echo "3. Return to main menu"
        read -p "Enter your choice (1-3): " choice

        case $choice in
            1)
                read -p "Enter search term: " search_term
                search_logs "$service_type" "$since" "$until" "$search_term"
                ;;
            2)
                read -p "Enter new start time (e.g., '2023-01-01T00:00:00' or '1h' for relative time): " since
                read -p "Enter new end time (e.g., '2023-01-02T00:00:00' or 'now' for current time): " until
                echo "Time range updated."
                ;;
            3)
                return
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac

        echo
    done
}

# Main interactive loop
main() {
    while true; do
        echo "=== Docker Log Search ==="
        echo "1. Select service and search logs"
        echo "2. Exit"
        read -p "Enter your choice (1-2): " choice

        case $choice in
            1)
                # Get service type
                echo "Available service types:"
                get_service_types
                read -p "Enter the service type (e.g., pt-app, opt-app, background): " service_type

                # Display available instances
                echo "Available instances for $service_type:"
                get_service_instances "$service_type"

                # Get initial time range
                read -p "Enter start time (e.g., '2023-01-01T00:00:00' or '1h' for relative time): " since
                read -p "Enter end time (e.g., '2023-01-02T00:00:00' or 'now' for current time): " until

                # Enter service-specific search loop
                service_search_loop "$service_type" "$since" "$until"
                ;;
            2)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac

        echo
    done
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in the PATH."
    exit 1
fi

# Run the main function
main
