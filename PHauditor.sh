#!/bin/bash

# Variables to store password and hash
password=""
hashed_password=""

# Function to hash a given password and extract only the hash value
hash_password() {
  echo -n "$1" | openssl dgst -sha256 | awk '{print $2}'
}

# Function to prompt user for password input and hash it
create_password_and_hash() {
  echo -n "Enter your new password:"
  read -s password
  #echo "Your password: $password"
  hashed_password=$(hash_password "$password")
  # echo "Hashed password: $hashed_password"
  echo ""
}
# Function to display options
display_menu() {
  echo "Select an option:"
  echo "1) Enter new password and hash"
  echo "2) Show current password"
  echo "3) Show current hashed password"
  echo "4) Save hashed password to file"
  echo "5) Exit"
}

# Main loop
while true; do
  display_menu
  read -p "Enter choice [1-5]: " choice
  case "$choice" in
    1)
      create_password_and_hash
      ;;
    2)
      if [ -n "$password" ]; then
        echo "Current password: $password"
      else
        echo "No password entered yet."
      fi
      ;;
    3)
      if [ -n "$hashed_password" ]; then
        echo "Current hashed password: $hashed_password"
      else
        echo "No hash generated yet."
      fi
      ;;
    4)
      if [ -n "$hashed_password" ]; then
        filename="auditor_pass.hash"
        save_dir="/path/to/secure_hashes"
        echo "$hashed_password" > "$save_dir/$filename"
        echo "Hashed password saved to $filename"
      else
        echo "No hash to save. Enter a password first."
      fi
      ;;
    5)
      echo "Exiting."
      break
      ;;
    *)
      echo "Invalid option. Please select 1-5."
      ;;
  esac
done
