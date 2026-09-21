#!/usr/bin/env bash
# ===============================================
# syshealth.sh - System Health & Log Analysis Toolkit
# Lab 1 - Data Collector
# Author: Obaid Qassim
# Date: 2026-08-31 14:29
# ===============================================

# --- Thresholds (change these values to test alert behavior) ---
CPU_THRESHOLD=75
MEM_THRESHOLD=85
DISK_THRESHOLD=85

# --- Color-coded status helper function ---
# local keeps these temporary values inside the function.
print_status() {
    local status="$1"
    local message="$2"

    if [[ "$status" == "OK" ]]; then
        echo -e "\e[32mOK: $message\e[0m"
    elif [[ "$status" == "ALERT" ]]; then
        echo -e "\e[31mALERT: $message\e[0m"
    else
        echo -e "\e[36m$status: $message\e[0m"
    fi
}

# basic variables
HOSTNAME=$(hostname)
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# showing the difference between quoted and unquoted variables
echo "Hostname without quotes: $HOSTNAME"
echo "Hostname with quotes: \"$HOSTNAME\""

cat << EOF
# In Bash, an unquoted variable can be split if it contains spaces, tabs, or new lines.
# Double quotes keep the value together, so I use them unless I actually want splitting.
EOF

# collect system info
UPTIME=$(uptime -p)
DISK_USAGE=$(df -h / | tail -1)
MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
PROCESS_COUNT=$(ps -e | wc -l)

# --- Parse numeric percentages for threshold comparison (Rocky Linux 9 compatible) ---
# Strip the percent sign from root filesystem usage so Bash can compare integers.
DISK_PCT=$(df / | tail -1 | awk '{gsub("%",""); print $5}')

# Calculate used memory as a percentage of total memory, rounded to an integer.
MEM_PCT=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')

# Calculate CPU usage as 100 minus the idle percentage from a short top snapshot.
CPU_PCT=$(top -bn1 | grep '^%Cpu' | awk '{print 100 - $8}' | cut -d. -f1)

# --- Health checks with conditionals and color-coded output ---
print_status "CHECK" "Running system health analysis..."
HEALTH_STATUS=0

# Disk check for the root filesystem.
if (( DISK_PCT > DISK_THRESHOLD )); then
    print_status "ALERT" "Disk usage on / is ${DISK_PCT}% (threshold ${DISK_THRESHOLD}%)"
    HEALTH_STATUS=1
else
    print_status "OK" "Disk usage on / is ${DISK_PCT}%"
fi

# Memory check.
if (( MEM_PCT > MEM_THRESHOLD )); then
    print_status "ALERT" "Memory usage is ${MEM_PCT}% (threshold ${MEM_THRESHOLD}%)"
    HEALTH_STATUS=1
else
    print_status "OK" "Memory usage is ${MEM_PCT}%"
fi

# CPU check.
if (( CPU_PCT > CPU_THRESHOLD )); then
    print_status "ALERT" "CPU usage is ${CPU_PCT}% (threshold ${CPU_THRESHOLD}%)"
    HEALTH_STATUS=1
else
    print_status "OK" "CPU usage is ${CPU_PCT}%"
fi

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
