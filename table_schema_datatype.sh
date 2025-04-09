#!/bin/bash

# --- Configuration ---
# This is a Bash comment. The shell ignores this line.
# Specify the Hive database name
DB_NAME="your_database_name" # This is also a Bash comment, after the command.

# Specify the table names in the desired order
# Use spaces to separate table names within the parentheses
# These lines starting with # are Bash comments.
TABLE_NAMES=(
  "table1"
  "table2"
  "another_table"
)
# --- End Configuration --- # Bash comment

# --- Script Logic --- # Bash comment

# Check if hive command exists (Bash comment)
if ! command -v hive &> /dev/null; then
    echo "Error: 'hive' command not found. Please ensure Hive client is installed and in your PATH."
    exit 1
fi

# Check if DB_NAME is set (Bash comment)
if [[ -z "$DB_NAME" ]]; then
  echo "Error: DB_NAME is not set in the script. Please edit the script and provide a database name."
  exit 1
fi

# Check if TABLE_NAMES array is empty (Bash comment)
if [[ ${#TABLE_NAMES[@]} -eq 0 ]]; then
  echo "Warning: TABLE_NAMES array is empty in the script. No tables to process."
  exit 0
fi

# Loop through each table name specified in the array (Bash comment)
for table in "${TABLE_NAMES[@]}"; do
  echo "${DB_NAME}.${table}:"

  # Execute hive command to get detailed table description (Bash comment)
  # Use awk to parse the output (Bash comment)
  hive -e "DESCRIBE FORMATTED ${DB_NAME}.${table};" 2>/dev/null | \
  awk '
    # Lines starting with # INSIDE the awk '\''...'\'' block are AWK comments,
    # NOT Bash comments. They explain the awk script logic.
    BEGIN {
      in_cols = 0      # awk comment: Flag for regular columns section
      in_parts = 0     # awk comment: Flag for partition columns section
    }

    # awk comment: Identify the start of the column definitions
    # The pattern /^\# col_name.../ looks for lines *literally starting* with "# col_name".
    # The \# inside the pattern means a literal #, not a comment marker *for the pattern*.
    /^\# col_name\s+data_type\s+comment/ {
      in_cols = 1
      next # awk command: Skip this header line
    }

    # awk comment: Identify the start of the partition column definitions
    # The pattern /^\# Partition Columns/ looks for lines *literally starting* with "# Partition Columns"
    /^\# Partition Columns/ { # This # is part of the pattern text being searched for
      in_cols = 0   # awk command
      in_parts = 1  # awk command
      next # awk command: Skip this header line
    }

    # awk comment: Identify the end of sections
    # The patterns match lines starting with "# Detailed Table Information", etc.
    /^\# Detailed Table Information/ || /^\# Storage Information/ || /^\# Table Parameters/ {
      in_cols = 0
      in_parts = 0
      next # awk command: Skip these sections
    }

    # awk comment: If we are inside the regular columns section...
    in_cols == 1 {
      # awk comment: Skip empty lines and lines starting with # (comments/separators in Hive output)
      # The pattern $0 ~ /^#/ checks if the *input line* from Hive starts with #
      if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^#/) {
        next # awk command
      }
      # awk command: Print the first two fields (column name and data type)
      if (NF >= 2) {
        gsub(/^[ \t]+|[ \t]+$/, "", $1); # awk command
        gsub(/^[ \t]+|[ \t]+$/, "", $2); # awk command
        if ($1 != "") {
             print $1, $2 # awk command
        }
      } else {
         in_cols = 0 # awk command
      }
    }

    # awk comment: If we are inside the partition columns section...
    in_parts == 1 {
      # awk comment: Skip empty lines and lines starting with # in Hive output
      if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^#/) {
        next # awk command
      }
      # awk command: Print the first two fields (partition column name and data type)
       if (NF >= 2) {
        gsub(/^[ \t]+|[ \t]+$/, "", $1); # awk command
        gsub(/^[ \t]+|[ \t]+$/, "", $2); # awk command
        if ($1 != "") {
            print $1, $2 # awk command
        }
      } else {
         in_parts = 0 # awk command
      }
    }
  ' # <-- This single quote ENDS the awk script for Bash.

  # Add a blank line between table outputs for better readability (Bash comment)
  echo "" # This is a Bash command

done # This ends the Bash 'for' loop

echo "Script finished." # This is a Bash command