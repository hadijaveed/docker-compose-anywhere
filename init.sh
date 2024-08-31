#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if .env file exists
if [ ! -f .env ]; then
    log_message "Error: .env file is missing. Please create the .env file and try again."
    exit 1
fi

# Read ROOT_DIRECTORY from environment, default to /opt if not set
ROOT_DIRECTORY=${ROOT_DIRECTORY:-/opt}

# Log file
LOG_FILE="$ROOT_DIRECTORY/full_setup.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Install Docker
install_docker() {
    log_message "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh

    log_message "Installing docker-rollout..."
    # Create directory for Docker cli plugins
    mkdir -p ~/.docker/cli-plugins

    # Download docker-rollout script to Docker cli plugins directory
    curl https://raw.githubusercontent.com/wowu/docker-rollout/master/docker-rollout -o ~/.docker/cli-plugins/docker-rollout

    # Make the script executable
    chmod +x ~/.docker/cli-plugins/docker-rollout
}

# Install Docker Compose
install_docker_compose() {
    log_message "Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}

# Create the database backup script
create_db_backup_script() {
    log_message "Creating database backup script..."

    cat <<EOF > $ROOT_DIRECTORY/db_backup.sh
#!/bin/bash

# Source .env file
if [ -f .env ]; then
    source .env
fi

# Define variables
BACKUP_DIR="$ROOT_DIRECTORY/pg_snapshots"
TIMESTAMP=\$(date +"%Y%m%d%H%M")
BACKUP_FILE="\$BACKUP_DIR/postgres_backup_\$TIMESTAMP.sql"

# Set default values if not available or empty
POSTGRES_USER=\${POSTGRES_USER:-postgres}
STORE_NUMBER_OF_DAYS_BACKUP=\${STORE_NUMBER_OF_DAYS_BACKUP:-7}

# Create the backup directory if it doesn't exist
mkdir -p \$BACKUP_DIR

# Take a snapshot of the PostgreSQL database
docker exec -t postgres_db pg_dumpall -U "\$POSTGRES_USER" > "\$BACKUP_FILE"

# Remove backups older than specified number of days
find \$BACKUP_DIR -type f -name "*.sql" -mtime +\$STORE_NUMBER_OF_DAYS_BACKUP -exec rm {} \;

echo "Backup completed at \$TIMESTAMP"
EOF

    chmod +x $ROOT_DIRECTORY/db_backup.sh
}

# Create the deployment script
create_deployment_script() {
    log_message "Creating deployment script..."

    cat <<EOF > $ROOT_DIRECTORY/deploy.sh
#!/bin/bash

# Run Docker cleanup script
$ROOT_DIRECTORY/docker-cleanup.sh

# Define the Docker Compose file
COMPOSE_FILE="$ROOT_DIRECTORY/docker-compose.yml"

# Source .env file
if [ -f .env ]; then
    source .env
fi

# Define the services to update
IFS=',' read -ra SERVICES <<< "\$COMPOSE_SERVICES_TO_DEPLOY"

# Define Slack Webhook URL
SLACK_WEBHOOK_URL="\${SLACK_NOTIFICATION_WEBHOOK:-}"

# Function to send a message to Slack
send_slack_message() {
    if ! curl -s -X POST -H 'Content-type: application/json' --data '{"text":"'\$1'"}' "\$SLACK_WEBHOOK_URL"; then
        echo "Error: Failed to send Slack message. Please check if Slack is configured properly."
    fi
}

# Step 1: Pull latest Docker images for the selected services
echo "Pulling latest Docker images for selected services..."
for service in "\${SERVICES[@]}"; do
    docker-compose -f "\$COMPOSE_FILE" pull "\$service"
    if [ \$? -ne 0 ]; then
        send_slack_message "Deployment failed: Unable to pull latest image for \$service."
        exit 1
    fi
done

# Step 2: Deploy new containers for the selected services
echo "Deploying new containers for selected services..."
for service in "\${SERVICES[@]}"; do
    docker rollout -f "\$COMPOSE_FILE" "\$service"
    if [ \$? -ne 0 ]; then
        send_slack_message "Deployment failed: Unable to rollout \$service."
        exit 1
    fi
done

# Final confirmation
send_slack_message "Deployment successful for all services."
echo "All services have been deployed successfully."
EOF

    chmod +x $ROOT_DIRECTORY/deploy.sh
    log_message "Deployment script created and made executable."
}

# Create the log search script
create_log_search_script() {
    log_message "Creating log search script..."

    cat <<EOF > $ROOT_DIRECTORY/log-search.sh
#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: \$0"
    echo "This script provides an interactive interface to search Docker logs across multiple service instances."
}

# Function to get available service types
get_service_types() {
    docker ps --format '{{.Names}}' | sed -E 's/[-_][0-9]+\$//g' | sort -u
}

# Function to get instances of a specific service type
get_service_instances() {
    local service_type="\$1"
    docker ps --format '{{.Names}}' | grep "^\${service_type}[-_][0-9]\+\$" | sort
}

# Function to search logs across multiple instances
search_logs() {
    local service_type="\$1"
    local since="\$2"
    local until="\$3"
    local search_term="\$4"

    instances=\$(get_service_instances "\$service_type")
    
    for instance in \$instances; do
        echo "Searching logs for \$instance:"
        docker logs --since "\$since" --until "\$until" "\$instance" 2>&1 | grep -i "\$search_term"
        echo "----------------------------------------"
    done
}

# Function to handle service-specific searches
service_search_loop() {
    local service_type="\$1"
    local since="\$2"
    local until="\$3"

    while true; do
        echo "=== Searching \$service_type logs ==="
        echo "Current time range: From \$since to \$until"
        echo "1. Perform a search"
        echo "2. Change time range"
        echo "3. Return to main menu"
        read -p "Enter your choice (1-3): " choice

        case \$choice in
            1)
                read -p "Enter search term: " search_term
                search_logs "\$service_type" "\$since" "\$until" "\$search_term"
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

        case \$choice in
            1)
                # Get service type
                echo "Available service types:"
                get_service_types
                read -p "Enter the service type (e.g., pt-app, opt-app, background): " service_type

                # Display available instances
                echo "Available instances for \$service_type:"
                get_service_instances "\$service_type"

                # Get initial time range
                read -p "Enter start time (e.g., '2023-01-01T00:00:00' or '1h' for relative time): " since
                read -p "Enter end time (e.g., '2023-01-02T00:00:00' or 'now' for current time): " until

                # Enter service-specific search loop
                service_search_loop "\$service_type" "\$since" "\$until"
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
EOF

    chmod +x $ROOT_DIRECTORY/log-search.sh
    log_message "Log search script created and made executable."
}

# Create Docker cleanup script
create_docker_cleanup_script() {
    log_message "Creating Docker cleanup script..."

    cat <<EOF > $ROOT_DIRECTORY/docker-cleanup.sh
#!/bin/bash

# Check if script is run as root
if [ "\$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Print current disk usage
echo "Current disk usage:"
df -h

# Remove unused containers
echo "Removing unused containers..."
docker container prune -f

# Remove unused images
echo "Removing unused images..."
docker image prune -af

# Remove unused volumes
echo "Removing unused volumes..."
docker volume prune -f

# Remove all unused Docker objects (including networks)
echo "Removing all unused Docker objects..."
docker system prune -af

# Clear Docker build cache
echo "Clearing Docker build cache..."
docker builder prune -af

# Print new disk usage
echo "New disk usage:"
df -h

echo "Docker cleanup completed."
EOF

    chmod +x $ROOT_DIRECTORY/docker-cleanup.sh
    log_message "Docker cleanup script created and made executable."
}

# Setup cron job for DB backup
setup_cron_job() {
    log_message "Setting up cron job for database backup..."

    # Check if crontab is available for the user
    if command -v crontab >/dev/null 2>&1 && crontab -l >/dev/null 2>&1; then
        (crontab -l ; echo "0 */4 * * * $ROOT_DIRECTORY/db_backup.sh >> $ROOT_DIRECTORY/db_backup.log 2>&1") | crontab -
        log_message "Cron job added to user's crontab."
    else
        log_message "Crontab not available for the current user. Using system-wide cron."
        setup_system_cron
    fi
}

setup_system_cron() {
    # Ensure system cron is available and running
    if ! systemctl is-active --quiet cron; then
        log_message "System cron is not running. Attempting to start it..."
        sudo systemctl start cron
        if ! systemctl is-active --quiet cron; then
            log_message "Failed to start system cron. Please check your system configuration."
            return 1
        fi
    fi

    local cron_file="/etc/cron.d/db_backup"
    echo "0 */4 * * * root $ROOT_DIRECTORY/db_backup.sh >> $ROOT_DIRECTORY/db_backup.log 2>&1" | sudo tee $cron_file > /dev/null
    sudo chmod 644 $cron_file
    log_message "Cron job added to system-wide cron at $cron_file."

    # Reload cron to ensure changes take effect
    sudo systemctl reload cron
    log_message "Cron service reloaded to apply changes."
}

# Main execution
main() {
    log_message "Starting full server setup..."

    install_docker
    install_docker_compose
    create_db_backup_script
    create_deployment_script
    create_log_search_script
    create_docker_cleanup_script

    # Restart Docker service
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart docker
    elif command -v service >/dev/null 2>&1; then
        service docker restart
    elif [ -f /etc/init.d/docker ]; then
        /etc/init.d/docker restart
    else
        log_message "Unable to restart Docker. Please restart it manually."
    fi
    setup_cron_job

    log_message "Setup complete. You may need to log out and log back in for group changes to take effect."
}

# Run main function
main

echo "Setup complete. You can start deploying your code now"
