#!/bin/bash
# Paths to hash files
ADMIN_HASH_FILE="/home/vboxuser/secure_hashes/admin"
AUDITOR_HASH_FILE="/home/vboxuser/secure_hashes/auditor"

# Function to prompt login
login() {
    echo -n "Username: "
    read username
    echo -n "Password: "
    read -s password
    echo ""

    if [[ "$username" == "admin" ]]; then
        stored_hash=$(cat "$ADMIN_HASH_FILE")
        role="Administrator"
        user_name="admin"
    elif [[ "$username" == "auditor" ]]; then
        stored_hash=$(cat "$AUDITOR_HASH_FILE")
        role="Auditor"
        user_name="auditor"
    fi

    input_hash=$(echo -n "$password" | sha256sum | awk '{print $1}')

    if [[ "$input_hash" == "$stored_hash" ]]; then
        echo "Login successful. Role: $role"
        user_role="$role"
    else
        echo "Invalid credentials."
        exit 1
    fi
}

# Directory where logs and checksum files will be stored
LOG_DIR="/home/vboxuser/log_files"
LOG_DIR_ADMIN="/home/vboxuser/log_files/admin"
# Function to record audit logs
record_audit() {
    local log_dir_admin="/home/vboxuser/log_files/admin"
    local log_file="$log_dir_admin/audit.log"
    echo "$(date): $1" >> "$log_file"
}

log_processes() {
    local role="$1"  # Pass role as argument: "Admin" or "Auditor"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local log_file="${LOG_DIR}/process_log_${timestamp}.log"
    local checksum_file="${log_file}.sha256"
    local log_file_admin="${LOG_DIR_ADMIN}/process_log_${timestamp}.log"
    local checksum_file_admin="${log_file_admin}.sha256"
    local user_id=$(id -u)
    local creator_user=$(whoami)

    # Start new log with metadata
    if [[ "$user_name" == "auditor" ]]; then
    {
        echo "Process Enumeration Log - ${timestamp}"
        echo "Role: $user_name"
        echo "Created by User: $creator_user (UID: $user_id)"
        echo "Creation Timestamp: ${timestamp}"
        echo "-------------------------------------"
    } > "$log_file"
    else
    {
        echo "Process Enumeration Log - ${timestamp}"
        echo "Role: $user_name"
        echo "Created by User: $creator_user (UID: $user_id)"
        echo "Creation Timestamp: ${timestamp}"
        echo "-------------------------------------"
    } > "$log_file_admin"
    fi

    # Append process info
    for pid in /proc/[0-9]*; do
        pid_num=$(basename "$pid")
        if [[ -f "$pid/stat" ]]; then
            owner=$(stat -c '%U' "$pid")
        process_name=$(cat "$pid/comm" 2>/dev/null)
        # Handle potential errors reading process info
        if [[ -z "$process_name" ]]; then
            process_name="N/A"
        fi

	if [[ "$user_name" == "auditor" && "$owner" == "root" ]]; then
		: #do nothing
		elif [[ "$user_name" == "admin" ]]; then
    		# Log admin processes separately
    		echo "PID: $pid_num, Process: $process_name, State: $state, Owner: $owner" >> "$log_file_admin"
	else
    		# Log other processes
    	echo "PID: $pid_num, Process: $process_name, State: $state, Owner: $owner" >> "$log_file"
      fi
    fi
    
done
    if [[ "$user_name" == "admin" ]]; then
       # Generate checksum and store it
       sha256sum "$log_file_admin" | awk '{print $1}' > "$checksum_file_admin"
       echo "Process log saved to $log_file_admin"
       echo "Checksum stored in $checksum_file_admin"
    else 
       sha256sum "$log_file" | awk '{print $1}' > "$checksum_file"
       # Audit alert for logging processes
       record_audit "Security Alert: $user_name logged processes"
       echo "Process log saved to $log_file"
       echo "Checksum stored in $checksum_file"
    fi
    
}

ram_swap() {
	vmstat -s
}

# Function to verify integrity of the log file
verify_log_integrity() {
    local log_dir="$LOG_DIR"
    # Find the latest log and checksum file based on timestamp
    local log_file=$(ls -t "$log_dir"/process_log_*.log | head -n 1)
    local checksum_file="${log_file}.sha256"

    if [[ ! -f "$log_file" || ! -f "$checksum_file" ]]; then
        echo "Log file or checksum file missing!"
        return 1
    fi

    local current_checksum=$(sha256sum "$log_file" | awk '{print $1}')
    local stored_checksum=$(cat "$checksum_file")

    if [[ "$current_checksum" == "$stored_checksum" ]]; then
        echo "Integrity check passed. Log file is unaltered."
        return 0
    else
        echo "WARNING: Log file has been tampered with!"
        return 1
    fi
}

verify_admin_log_integrity() {
    local log_dir="$LOG_DIR_ADMIN"
    # Find the latest log and checksum file based on timestamp
    local log_file=$(ls -t "$log_dir"/process_log_*.log | head -n 1)
    local checksum_file="${log_file}.sha256"

    if [[ ! -f "$log_file" || ! -f "$checksum_file" ]]; then
        echo "Log file or checksum file missing!"
        return 1
    fi

    local current_checksum=$(sha256sum "$log_file" | awk '{print $1}')
    local stored_checksum=$(cat "$checksum_file")

    if [[ "$current_checksum" == "$stored_checksum" ]]; then
        echo "Integrity check passed. Log file is unaltered."
        return 0
    else
        echo "WARNING: Log file has been tampered with!"
        return 1
    fi
}

# Function to delete logs (only admin)
delete_logs() {
    if [[ "$user_name" != "admin" ]]; then
        record_audit "Security Alert: $user_name attempted to delete logs"
        echo "Access denied. $user_name are not authorized to delete logs."
        return
    fi

    local log_dir="/home/vboxuser/log_files"
    local log_dir_admin="/home/vboxuser/log_files/admin"
    
    # Delete all log files except audit.log
    find "$log_dir" -type f ! -name "audit.log" -exec rm -v {} +
    find "$log_dir_admin" -type f ! -name "audit.log" -exec rm -v {} +
    record_audit "Security Alert: $user_name deleted logs"
    echo "Logs deleted."
}

# Function to run system monitoring with watch
system_monitor() {
    if [[ "$user_name" != "admin" ]]; then
        top -U '!root'
        return
    fi
    echo "Starting system monitor. Press Ctrl+C to exit."
    # Example: monitor CPU and memory usage
    # watch -n 1 'ps aux --sort=-%cpu'
    top
}

# Main program
login

# Example menu
while true; do
    echo ""
    echo "Select an option:"
    echo "1. Log_processes"
    echo "2. swap ram"
    echo "3. Verify log integrity"
    echo "4. Verify admin log integrity"
    echo "5. Delete logs"
    echo "6. System monitoring"
    echo "7. Exit"
    read -p "Choice: " choice
    case "$choice" in
        1) log_processes ;;
        2) ram_swap;;
        3) verify_log_integrity;;
        4) verify_admin_log_integrity;;
        5) delete_logs ;;
        6) system_monitor ;;
        7) echo "Goodbye."; exit 0 ;;
        *) echo "Invalid option." ;;
    esac
done
