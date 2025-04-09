# #!/bin/bash

# # --- Configuration ---
# # !! MODIFY THESE VALUES !!
# DATABASE_NAME="your_database_name" # Replace with your actual database name
# TABLE_LIST=(
#     "your_table_name_1"   # Replace with your first table name
#     "table_alpha"         # Replace with your second table name
#     "another_table_x"     # Add/remove/replace table names as needed
#     # Keep the order you want for the output
# )
# # --- End Configuration ---

# echo "Fetching HDFS paths for tables in database: ${DATABASE_NAME}"
# echo "=================================================="

# # Iterate through the table list IN THE ORDER provided
# for table in "${TABLE_LIST[@]}"; do
#     full_table_name="${DATABASE_NAME}.${table}"

#     # Use hive -e to execute the DESCRIBE query non-interactively
#     # Pipe the output to grep to find the 'Location:' line
#     # Pipe that to awk to extract the second field (the HDFS path)
#     # Redirect stderr (2>/dev/null) to hide Hive connection messages/errors
#     hdfs_path=$(hive -e "DESCRIBE FORMATTED ${full_table_name};" 2>/dev/null | grep 'Location:' | awk '{print $2}')

#     # Check if the hdfs_path variable was successfully populated
#     if [[ -n "$hdfs_path" ]]; then
#         # If path found, print the table name and the path
#         echo "${table}: ${hdfs_path}"
#     else
#         # If path was not found (e.g., table doesn't exist, permissions error)
#         echo "${table}: ERROR - Could not retrieve HDFS path"
#     fi
# done

# echo "=================================================="
# echo "Script finished."

# hdfs_path=$(hive -e "DESCRIBE FORMATTED ${full_table_name};" 2>/dev/null | grep 'Location:' | cut -d '|' -f 3 | sed 's/^[[:space:]]*//')
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

echo "Fetching HDFS paths and latest timestamps for tables in database: ${DATABASE_NAME}"
echo "Output Format: TableName HDFSLocation LatestFileTimestamp(YYYY-MM-DD HH:MM)"
echo "==================================================================================="

# Iterate through the table list IN THE ORDER provided
for table in "${TABLE_LIST[@]}"; do
    full_table_name="${DATABASE_NAME}.${table}"
    latest_timestamp="N/A" # Default timestamp value

    # Step 1: Get HDFS Path (using the previously confirmed working method)
    hdfs_path=$(hive -e "DESCRIBE FORMATTED ${full_table_name};" 2>/dev/null | grep 'Location:' | awk '{print $4}')

    # Check if HDFS path retrieval was successful
    if [[ -n "$hdfs_path" ]]; then
        # Step 2: Check if HDFS path actually exists before trying to list files
        if ! hdfs dfs -test -e "$hdfs_path" 2>/dev/null; then
            latest_timestamp="ERROR (HDFS path not found)"
            # Output the result for this table even if path doesn't exist
            echo "${table} ${hdfs_path} ${latest_timestamp}"
            continue # Skip timestamp fetching and go to the next table
        fi

        # Step 3: Find the latest file's information in the HDFS path
        #   - List recursively (-R)
        #   - Filter out directories (grep -v '^d')
        #   - Sort by date (field 6) and time (field 7) in reverse order (-k6,7r)
        #   - Take the top line (head -n 1)
        #   - Suppress errors from ls (2>/dev/null) e.g. permission denied on subdirs
        latest_file_info=$(hdfs dfs -ls -R "$hdfs_path" 2>/dev/null | grep -v '^d' | sort -k6,7r | head -n 1)

        # Step 4: Extract timestamp if file info was found
        if [[ -n "$latest_file_info" ]]; then
            # Extract date (field 6) and time (field 7)
            latest_timestamp=$(echo "$latest_file_info" | awk '{print $6 " " $7}')
        else
            # Handle case where directory exists but contains no files
            latest_timestamp="N/A (No files found)"
        fi

        # Step 5: Print the final output for this table
        echo "${table} ${hdfs_path} ${latest_timestamp}"

    else
        # Handle case where HDFS path could not be retrieved from Hive
        echo "${table} ERROR (Could not retrieve HDFS path) N/A"
    fi

done

echo "==================================================================================="
echo "Script finished."
# Reminder: Current time is Wednesday, April 9, 2025 at 9:38:21 PM IST