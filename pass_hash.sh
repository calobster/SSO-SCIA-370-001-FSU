#!/bin/bash

# Directory to store user credentials
CREDENTIALS_DIR="/home/kali/secure_hashes"

# Hardcoded usernames
AUDITOR_USERNAME="auditor"
ADMIN_USERNAME="admin"

# Function to hash a given password
hash_password() {
  echo -n "$1" | openssl dgst -sha256 | awk '{print $2}'
}

# Function to get stored hash for a user
get_stored_hash() {
  local user="$1"
  cat "$CREDENTIALS_DIR/$user" 2>/dev/null
}

# Function to create or update user password
create_or_update_password() {
  local user="$1"
  echo -n "Enter new password for '$user': "
  read -s new_password
  echo
  local new_hash
  new_hash=$(hash_password "$new_password")
  echo "$new_hash" > "$CREDENTIALS_DIR/$user"
  echo "Password set successfully for '$user'."
}

# Function to verify user password
verify_password() {
  local user="$1"
  local password="$2"
  local stored_hash
  stored_hash=$(get_stored_hash "$user")
  if [ -z "$stored_hash" ]; then
    # No password exists
    return 2
  fi
  local input_hash
  input_hash=$(hash_password "$password")
  if [ "$stored_hash" = "$input_hash" ]; then
    return 0
  else
    return 1
  fi
}

# Function to display menu options
display_menu() {
  echo "Select an option:"
  echo "1) Enter new password and hash"
  echo "2) Show current password"
  echo "3) Show current hashed password"
  echo "4) Save hashed password to file"
  echo "5) Exit"
}

# Main login process
while true; do
  echo -n "Enter 'login' to authenticate or 'exit' to quit: "
  read command
  if [ "$command" = "exit" ]; then
    echo "Exiting."
    break
  elif [ "$command" = "login" ]; then
    echo -n "Enter username: "
    read username
    if [ "$username" != "$AUDITOR_USERNAME" ] && [ "$username" != "$ADMIN_USERNAME" ]; then
      continue
    fi

    # Check if password exists
    if [ ! -f "$CREDENTIALS_DIR/$username" ]; then
      echo "No password found for '$username'. Please create a new password."
      create_or_update_password "$username"
    else
      # Prompt for current password
      echo -n "Enter current password for '$username': "
      read -s current_password
      echo
      verify_password "$username" "$current_password"
      result=$?
      if [ $result -eq 0 ]; then
        echo "Authentication successful."
      elif [ $result -eq 2 ]; then
        echo "No password found. Please set a new password."
        create_or_update_password "$username"
      else
        echo "Incorrect password. Access denied."
        continue
      fi
    fi

    # After login/authentication, present options
    while true; do
      display_menu
      echo -n "Enter choice [1-5]: "
      read choice
      case "$choice" in
        1)
          # Enter new password and hash
          create_or_update_password "$username"
          ;;
        2)
          # Show current password (in plain text)
          if [ -f "$CREDENTIALS_DIR/$username" ]; then
            current_hash=$(get_stored_hash "$username")
            echo "Current hashed password: $current_password|"
            echo "Note: You can verify this by hashing your password."
          else
            echo "No password set for '$username'."
          fi
          ;;
        3)
          # Show current hashed password
          if [ -f "$CREDENTIALS_DIR/$username" ]; then
            cat "$CREDENTIALS_DIR/$username"
          else
            echo "No password set for '$username'."
          fi
          ;;
        4)
          # Save hashed password to a file
          if [ -f "$CREDENTIALS_DIR/$username" ]; then
            filename="${username}_password_backup.txt"
            cp "$CREDENTIALS_DIR/$username" "$filename"
            echo "Hashed password saved to $filename."
          else
            echo "No password to save."
          fi
          ;;
        5)
          echo "Logging out."
          break
          ;;
        *)
          echo "Invalid option. Please select 1-5."
          ;;
      esac
    done
  else
    echo "Invalid command. Please enter 'login' or 'exit'."
  fi
  echo
done
