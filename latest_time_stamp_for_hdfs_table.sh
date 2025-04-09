#!/bin/bash

# --- Configuration ---
# !! MODIFY THESE VALUES !!
DATABASE_NAME="your_database_name" # Replace with your actual database name
TABLE_LIST=(
    "your_table_name_1"   # Replace with your first table name
    "table_alpha"         # Replace with your second table name
    "another_table_x"     # Add/remove/replace table names as needed
    # Keep the order you want for the output
)
# --- End Configuration ---

echo "Fetching HDFS paths for tables in database: ${DATABASE_NAME}"
echo "=================================================="

# Iterate through the table list IN THE ORDER provided
for table in "${TABLE_LIST[@]}"; do
    full_table_name="${DATABASE_NAME}.${table}"

    # Use hive -e to execute the DESCRIBE query non-interactively
    # Pipe the output to grep to find the 'Location:' line
    # Pipe that to awk to extract the second field (the HDFS path)
    # Redirect stderr (2>/dev/null) to hide Hive connection messages/errors
    hdfs_path=$(hive -e "DESCRIBE FORMATTED ${full_table_name};" 2>/dev/null | grep 'Location:' | awk '{print $2}')

    # Check if the hdfs_path variable was successfully populated
    if [[ -n "$hdfs_path" ]]; then
        # If path found, print the table name and the path
        echo "${table}: ${hdfs_path}"
    else
        # If path was not found (e.g., table doesn't exist, permissions error)
        echo "${table}: ERROR - Could not retrieve HDFS path"
    fi
done

echo "=================================================="
echo "Script finished."