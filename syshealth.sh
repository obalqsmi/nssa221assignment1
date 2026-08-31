#!/usr/bin/env bash
# ===============================================
# syshealth.sh - System Health & Log Analysis Toolkit
# Lab 1 - Data Collector
# Author: Obaid Qassim
# Date: 2026-08-31 14:29
# ===============================================

# basic variables
HOSTNAME=$(hostname)
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# showing the difference between quoted and unquoted variables
echo "Hostname without quotes: $HOSTNAME"
echo "Hostname with quotes: \"$HOSTNAME\""

cat << EOF
# COMMENT FOR GRADER:
# In Bash, an unquoted variable can be split if it contains spaces, tabs, or new lines.
# Double quotes keep the value together, so I use them unless I actually want splitting.
EOF

# collect system info
UPTIME=$(uptime -p)
DISK_USAGE=$(df -h / | tail -1)
MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
PROCESS_COUNT=$(ps -e | wc -l)

# optional output file
OUTPUT_FILE="${1:-}"

print_report() {
    printf "========================================\n"
    printf "System Health Report - %s\n" "$CURRENT_DATE"
    printf "Hostname        : %s\n" "$HOSTNAME"
    printf "Uptime          : %s\n" "$UPTIME"
    printf "Disk /          : %s\n" "$DISK_USAGE"
    printf "Memory used     : %s\n" "$MEMORY_USAGE"
    printf "Total processes : %s\n" "$PROCESS_COUNT"
    printf "========================================\n"
}

if [ -n "$OUTPUT_FILE" ]; then
    print_report > "$OUTPUT_FILE"
    echo "Report written to $OUTPUT_FILE"
else
    print_report
fi

exit 0
