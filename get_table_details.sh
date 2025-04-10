#!/bin/bash
# Script: cutdown_describe_tables.sh
# Purpose: For a given Hive database and a list of tables, query the table metadata
#          using DESCRIBE FORMATTED and output only the column definitions and
#          partition information. It suppresses Hive startup logs and truncates
#          the output before the detailed table information section.
#
# Usage: ./cutdown_describe_tables.sh <database> <table1> [table2 ... tableN]

# --- Configuration ---
# This is the line marker *before which* we want to stop printing.
# The line containing this pattern itself will NOT be printed.
STOP_PATTERN="# Detailed Table Information"

# --- Argument Validation ---
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <database> <table1> [table2 ... tableN]"
    exit 1
fi

DATABASE="$1"
shift # Remove database name, remaining arguments are table names

# --- Main Loop ---
for TABLE in "$@"; do
    echo "--- Metadata for ${DATABASE}.${TABLE} ---"

    # Run Hive:
    # -S: Silent mode (reduces log output on stdout)
    # -e: Execute query string
    # 2>/dev/null: Redirect standard error (where logs like SLF4J usually go) to /dev/null (discard)
    # We capture the standard output into the HIVE_OUTPUT variable.
    HIVE_OUTPUT=$(hive -S -e "USE ${DATABASE}; DESCRIBE FORMATTED ${TABLE};" 2>/dev/null)
    HIVE_EXIT_CODE=$? # Capture exit code immediately after the command

    # Check if the Hive command failed
    if [ ${HIVE_EXIT_CODE} -ne 0 ]; then
        echo "[Error retrieving metadata for table ${DATABASE}.${TABLE}. Hive exit code: ${HIVE_EXIT_CODE}]"
        echo "[Check if the table exists and you have permissions.]"
        # If HIVE_OUTPUT captured any error message from stdout (unlikely but possible), print it:
        if [ -n "$HIVE_OUTPUT" ]; then
             echo "Debug Output: $HIVE_OUTPUT"
        fi
        echo "" # Add separation before next table
        continue # Skip to the next table
    fi

    # Process the Hive output using sed:
    # Search for the STOP_PATTERN. When found, execute the 'q' command (quit).
    # Sed automatically prints lines until it's told to quit or finishes input.
    # This effectively prints all lines *up to* (but not including) the line with the pattern.
    echo "$HIVE_OUTPUT" | sed "/${STOP_PATTERN}/q"

    # Check if any output was produced (handles case where table exists but query returns nothing)
    # And add a blank line for separation between tables
    if [ -n "$HIVE_OUTPUT" ]; then
        # Add a final check: did the output actually get truncated? If so, maybe add a note.
        # This grep checks if the STOP_PATTERN was present anywhere in the original output.
        if echo "$HIVE_OUTPUT" | grep -q "${STOP_PATTERN}"; then
            echo "[...Full output truncated...]" # Optional: Add a truncation marker if you like
        fi
        echo ""
    else
        # If HIVE_OUTPUT was empty even on success, mention it.
        echo "[No metadata output returned for ${DATABASE}.${TABLE}]"
        echo ""
    fi
done

echo "--- Script finished ---"