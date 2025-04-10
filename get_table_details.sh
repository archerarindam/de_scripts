#!/bin/bash
# Script: describe_tables.sh
# Purpose: For a given Hive database and a list of tables, output only the column names
#          and data types, and separately list the partition columns (if any).
#
# Usage: ./describe_tables.sh <database> <table1> [table2 ... tableN]

# Check that at least two arguments are provided (one database and one table)
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <database> <table1> [table2 ... tableN]"
    exit 1
fi

# The first argument is the database name; the rest are table names.
DATABASE="$1"
shift

# Process each provided table
for TABLE in "$@"
do
    echo "---------------------------------------------"
    echo "Processing table: ${TABLE}"
    echo "---------------------------------------------"

    # Run Hive to describe the table in formatted mode.
    # It outputs a lot of details, including columns and extra metadata.
    DESC_OUTPUT=$(hive -e "USE ${DATABASE}; DESCRIBE FORMATTED ${TABLE};")
    
    # Check if the hive command was successful.
    if [ $? -ne 0 ]; then
        echo "Error: Could not retrieve metadata for table ${TABLE}"
        continue
    fi

    echo "Columns and Data Types:"
    # Process the output to get only table columns.
    # We assume the output has a header line that begins with "col_name   data_type"
    # After that, valid column rows follow until a line that begins with "#" is encountered.
    echo "$DESC_OUTPUT" | awk '
      BEGIN { header_found = 0 }
      {
        # Look for the header line (typically "col_name   data_type")
        if ($1=="col_name" && $2=="data_type") {
          header_found = 1;
          next;
        }
        # Once the header is found, stop processing if a line starts with "#"
        if (header_found && $1 ~ /^#/) {
          exit;
        }
        # If we are in the column section and the line has at least two fields, print them.
        if (header_found && NF >= 2) {
          print $1 " -> " $2
        }
      }
    '

    echo ""
    echo "Partition Columns:"
    # Process the output to extract partition columns.
    # Look for the section that begins with "# Partition Information"
    PARTITION_COLUMNS=$(echo "$DESC_OUTPUT" | awk '
      BEGIN { partition_found = 0 }
      /^# Partition Information/ { partition_found = 1; next }
      # When in the partition section, print lines until an empty line or metadata is encountered.
      partition_found && NF > 0 {
         if ($1 ~ /^#/ || $1 == "") { exit }
         if (NF >= 2) {
           print $1 " -> " $2
         }
      }
    ')
    
    if [ -z "$PARTITION_COLUMNS" ]; then
        echo "None found (this table is not partitioned)"
    else
        echo "$PARTITION_COLUMNS"
    fi

    echo ""
done

echo "Metadata extraction complete."
