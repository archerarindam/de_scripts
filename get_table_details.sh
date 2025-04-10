#!/bin/bash
# Script: cutdown_describe_tables.sh
# Purpose: For a given Hive database and a list of tables, query the table metadata using DESCRIBE FORMATTED
#          and output a "cutdown" version. The output stops at a specific pattern (in this example, a line that
#          includes "# Detailed Table Information"), which is replaced by a placeholder.
#
# Usage: ./cutdown_describe_tables.sh <database> <table1> [table2 ... tableN]

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <database> <table1> [table2 ... tableN]"
    exit 1
fi

DATABASE="$1"
shift

for TABLE in "$@"; do
    # Print table name as header
    echo "$TABLE:"

    # Run Hive in silent mode (-S) to avoid debug/log messages.
    RESULT=$(hive -S -e "USE ${DATABASE}; DESCRIBE FORMATTED ${TABLE};")
    if [ $? -ne 0 ]; then
        echo "[Error retrieving table metadata]"
        continue
    fi

    # Process the Hive output:
    # Print each line until a line is encountered that contains "# Detailed Table Information".
    # When the pattern is found, print a placeholder and stop processing further lines.
    echo "$RESULT" | sed '/# Detailed Table Information/ { s/.*/[...Output truncated...]/; q; }'

    # Add a blank line for separation.
    echo ""
done
