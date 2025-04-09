#!/bin/bash

# --- Configuration ---
# !! MODIFY THESE VALUES !!
DATABASE_NAME="your_database_name"
TABLE_LIST=(
    "your_table_name_1"
    "your_table_name_2"
    "another_table"
    # Add more table names here, one per line inside the parentheses
)
# --- End Configuration ---

echo "Starting timestamp check for database: ${DATABASE_NAME}"
echo "=================================================="

# Loop through the tables in the order they are defined in TABLE_LIST
for table in "${TABLE_LIST[@]}"; do
    full_table_name="${DATABASE_NAME}.${table}"
    echo "Processing table: ${full_table_name}"

    # 1. Get the HDFS location for the table using Hive
    #    - We execute a 'DESCRIBE FORMATTED' query.
    #    - 'grep Location:' finds the line with the HDFS path.
    #    - 'awk '{print $2}'' extracts the second field, which is the path.
    #    - '2>/dev/null' suppresses potential Hive connection messages/errors from cluttering output.
    echo "  Fetching HDFS path..."
    hdfs_path=$(hive -e "DESCRIBE FORMATTED ${full_table_name};" 2>/dev/null | grep 'Location:' | awk '{print $2}')

    # Check if we successfully got a path
    if [[ -z "$hdfs_path" ]]; then
        echo "  ERROR: Could not retrieve HDFS path for ${full_table_name}. Skipping."
        echo "--------------------------------------------------"
        continue # Go to the next table in the loop
    fi

    echo "  HDFS Path: ${hdfs_path}"

    # 2. Check if the HDFS path actually exists
    if ! hdfs dfs -test -e "${hdfs_path}" ; then
        echo "  ERROR: HDFS path '${hdfs_path}' does not exist or is not accessible. Skipping."
        echo "--------------------------------------------------"
        continue # Go to the next table in the loop
    fi

    # 3. Find the latest file timestamp in that HDFS path
    #    - 'hdfs dfs -ls -R ${hdfs_path}' lists all files and directories recursively.
    #    - 'grep -v '^d'' filters out directories (lines starting with 'd').
    #    - 'sort -k6,7r' sorts the lines:
    #        - '-k6,6' sorts by the 6th field (date YYYY-MM-DD).
    #        - '-k7,7' sorts by the 7th field (time HH:MM).
    #        - 'r' reverses the sort, putting the newest items first.
    #    - 'head -n 1' takes only the first line (which is the latest file).
    #    - 'awk '{print $6 " " $7}'' extracts the date (field 6) and time (field 7).
    #    - We store the result in latest_timestamp.
    #    - '2>/dev/null' suppresses potential errors like empty directories.
    echo "  Finding latest file timestamp..."
    latest_file_info=$(hdfs dfs -ls -R "${hdfs_path}" 2>/dev/null | grep -v '^d' | sort -k6,7r | head -n 1)

    if [[ -z "$latest_file_info" ]]; then
        latest_timestamp="N/A (No files found or path empty)"
        echo "  INFO: No files found in path '${hdfs_path}'."
    else
        latest_timestamp=$(echo "${latest_file_info}" | awk '{print $6 " " $7}')
         echo "  Latest Timestamp Found: ${latest_timestamp}"
    fi

    # 4. Print the result for the current table
    echo "Result for ${table}: Latest Timestamp = ${latest_timestamp}"
    echo "--------------------------------------------------"

done

echo "=================================================="
echo "Script finished."