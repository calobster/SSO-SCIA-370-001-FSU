# SSO Secure System Observer


With the SSO, you can observe system processes, log them, and verify saved process logs. 

To use the SSO, you will need to enter one of two usernames, either admin or auditor, and their corresponding passwords. 
The admin can:
  1. Create a process log save state with no process filter.
  2. Verify process log files by checking the hash that is generated with them on creation.
  3. can delete old log files as needed.
  4. View system processes in real time (with the help of Top).
  5. Exit out of the program.

The auditor can:
  1. Create a process log save state with a filter that removes all root processes.
  2. Verify process log files by checking the hash that is generated with them on creation.
  3. Can NOT delete old log files as needed.
  4. View system processes in real time with root processes filtered out (with the help of Top).
  5. Exit out of the program

The SSO saves and logs:
 1. When the auditor tries to delete log files.
 2. When the auditor creates a process log file.

To log in, you will need to download both PHAdmin.sh and PHAuditor.sh to create hashes for the SSO to verify against the entered passwords. 
You will need to update line 57 in both PHAdmin.sh and PHAuditor.sh to a directory of your choosing, and lines 3 & 4 in the SSO itself to the directory storing the password hashes generated from PHAdmin.sh and PHAuditor.sh. 


# How the SSO and passwords are kept secure.

