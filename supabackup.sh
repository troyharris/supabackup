#!/bin/bash

# Script to backup Supabase database
# This script requires:
# - Supabase CLI installed
# - Docker installed
# - Valid Supabase connection string

# Configuration
source ./.supabackup.env

# Create timestamp for backup directory
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_PATH="${SUPABACKUP_PATH}/${TIMESTAMP}"

# Create backup directory
mkdir -p "${BACKUP_PATH}"

# Log file
LOG_FILE="${BACKUP_PATH}/backup.log"

# Function to log messages
LOG_FILE="${SUPABACKUP_PATH}/backup_${TIMESTAMP}.log"
log_message() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "${LOG_FILE}"
}

log_message "Starting Supabase database backup"

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    log_message "Error: Supabase CLI is not installed"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    log_message "Error: Docker is not running"
    exit 1
fi

# Run backups
log_message "Backing up roles..."
if ! supabase db dump --db-url "${SUPABACKUP_CONNECTION_STRING}" -f "${BACKUP_PATH}/roles.sql" --role-only >> "${LOG_FILE}" 2>&1; then
    log_message "Error: Failed to backup roles"
    exit 1
fi

log_message "Backing up schema..."
if ! supabase db dump --db-url "${SUPABACKUP_CONNECTION_STRING}" -f "${BACKUP_PATH}/schema.sql" >> "${LOG_FILE}" 2>&1; then
    log_message "Error: Failed to backup schema"
    exit 1
fi

log_message "Backing up data..."
if ! supabase db dump --db-url "${SUPABACKUP_CONNECTION_STRING}" -f "${BACKUP_PATH}/data.sql" --use-copy --data-only >> "${LOG_FILE}" 2>&1; then
    log_message "Error: Failed to backup data"
    exit 1
fi

# Create a compressed archive of the backup
log_message "Compressing backup..."
tar -czf "${SUPABACKUP_PATH}/${TIMESTAMP}_supabase_backup.tar.gz" -C "${SUPABACKUP_PATH}" "${TIMESTAMP}"
if [ $? -eq 0 ]; then
    # Remove the uncompressed files after successful compression
    rm -rf "${BACKUP_PATH}"
    log_message "Backup compressed successfully"
else
    log_message "Warning: Compression failed"
fi

# Remove backups older than RETENTION_DAYS
if [ $SUPABACKUP_RETENTION_DAYS -gt 0 ]; then
    log_message "Cleaning up backups older than ${SUPABACKUP_RETENTION_DAYS} days"
    find "${SUPABACKUP_PATH}" -name "*_supabase_backup.tar.gz" -type f -mtime +${SUPABACKUP_RETENTION_DAYS} -delete
    
    # Also clean up old log files
    find "${SUPABACKUP_PATH}" -name "backup_*.log" -type f -mtime +${SUPABACKUP_RETENTION_DAYS} -delete
fi
log_message "Backup process completed"