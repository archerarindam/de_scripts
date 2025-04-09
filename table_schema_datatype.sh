#!/bin/bash

# --- Configuration ---
# Specify the Hive database name
DB_NAME="your_database_name"

# Specify the table names in the desired order
# Use spaces to separate table names within the parentheses
TABLE_NAMES=(
  "table1"
  "table2"
  "another_table"
)
# --- End Configuration ---

# --- Script Logic ---

# Check if hive command exists
if ! command -v hive &> /dev/null; then
    echo "Error: 'hive' command not found. Please ensure Hive client is installed and in your PATH."
    exit 1
fi

# Check if DB_NAME is set
if [[ -z "$DB_NAME" ]]; then
  echo "Error: DB_NAME is not set in the script. Please edit the script and provide a database name."
  exit 1
fi

# Check if TABLE_NAMES array is empty
if [[ ${#TABLE_NAMES[@]} -eq 0 ]]; then
  echo "Warning: TABLE_NAMES array is empty in the script. No tables to process."
  exit 0
fi

# Loop through each table name specified in the array
for table in "${TABLE_NAMES[@]}"; do
  echo "${DB_NAME}.${table}:"

  # Execute hive command to get detailed table description
  # Use awk to parse the output
  hive -e "DESCRIBE FORMATTED ${DB_NAME}.${table};" 2>/dev/null | \
  awk '
    BEGIN {
      in_cols = 0      # Flag: are we inside the regular columns section?
      in_parts = 0     # Flag: are we inside the partition columns section?
    }

    # Identify the start of the column definitions (usually after # col_name ...)
    /^\# col_name\s+data_type\s+comment/ {
      in_cols = 1
      next # Skip this header line
    }

    # Identify the start of the partition column definitions
    /^\# Partition Columns/ {
      in_cols = 0   # We are definitely out of regular columns now
      in_parts = 1
      next # Skip this header line
    }

    # Identify the end of sections (e.g., start of detailed info or properties)
    /^\# Detailed Table Information/ || /^\# Storage Information/ || /^\# Table Parameters/ {
      in_cols = 0
      in_parts = 0
      next # Skip these sections entirely if needed, or just stop processing cols/partitions
    }

    # If we are inside the regular columns section...
    in_cols == 1 {
      # Skip empty lines and lines starting with # (comments/separators)
      if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^#/) {
        next
      }
      # Print the first two fields (column name and data type)
      # Handle potential empty lines between column definition blocks
      if (NF >= 2) {
        # Clean up potential leading/trailing whitespace just in case
        gsub(/^[ \t]+|[ \t]+$/, "", $1);
        gsub(/^[ \t]+|[ \t]+$/, "", $2);
        if ($1 != "") {
             print $1, $2
        }
      } else {
         # If a line doesn't have enough fields, might signal end of block
         in_cols = 0
      }
    }

    # If we are inside the partition columns section...
    in_parts == 1 {
      # Skip empty lines and lines starting with #
      if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^#/) {
        next
      }
      # Print the first two fields (partition column name and data type)
       if (NF >= 2) {
        gsub(/^[ \t]+|[ \t]+$/, "", $1);
        gsub(/^[ \t]+|[ \t]+$/, "", $2);
        if ($1 != "") {
            print $1, $2
        }
      } else {
         # If a line doesnt have enough fields, might signal end of block
         in_parts = 0
      }
    }
  '

  # Add a blank line between table outputs for better readability
  echo ""

done

echo "Script finished."