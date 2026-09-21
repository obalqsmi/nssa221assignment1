#!/usr/bin/env bash
# ===============================================
# syshealth.sh - System Health & Log Analysis Toolkit
# Lab 2 - Health Checks with Conditionals
# Author: Obaid Qassim
# Date: 2026-09-21
# Target: Rocky Linux 9
# ===============================================

# --- Thresholds (change these values to test alert behavior) ---
# CPU usage above 75 percent triggers an alert.
CPU_THRESHOLD=75

# Memory usage above 85 percent triggers an alert.
MEM_THRESHOLD=85

# Disk usage above 85 percent triggers an alert.
DISK_THRESHOLD=85

# --- Color-coded status helper function ---
# This helper keeps all status messages consistent throughout the script.
# local prevents the function arguments from overwriting global variables.
print_status() {
    local status="$1"
    local message="$2"

    # Healthy checks are printed in green.
    if [[ "$status" == "OK" ]]; then
        echo -e "\e[32mOK: $message\e[0m"

    # Failed threshold checks are printed in red.
    elif [[ "$status" == "ALERT" ]]; then
        echo -e "\e[31mALERT: $message\e[0m"

    # Informational messages such as CHECK are printed in cyan.
    else
        echo -e "\e[36m$status: $message\e[0m"
    fi
}

# --- Basic system variables ---
# hostname identifies the system that generated the health report.
HOSTNAME=$(hostname)

# date records when the health information was collected.
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# --- Quoting demonstration retained from Assignment 1 ---
# The same hostname is printed normally and inside visible quote characters.
echo "Hostname without quotes: $HOSTNAME"
echo "Hostname with quotes: \"$HOSTNAME\""

# Explain why variable expansions are normally double-quoted in Bash.
cat << EOF
# In Bash, an unquoted variable can be split if it contains spaces, tabs, or new lines.
# Double quotes keep the value together, so I use them unless I actually want splitting.
EOF

# --- Collect human-readable system information ---
# uptime -p returns a readable system uptime such as "up 2 hours".
UPTIME=$(uptime -p)

# Keep the full human-readable root filesystem line for the final report.
DISK_USAGE=$(df -h / | tail -1)

# Extract used and total memory from free -h for the summary report.
MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}')

# Count the currently listed processes.
PROCESS_COUNT=$(ps -e | wc -l)

# --- Parse numeric percentages for threshold comparison ---
# Remove the percent sign from the root disk usage field so it can be compared numerically.
DISK_PCT=$(df / | tail -1 | awk '{gsub("%",""); print $5}')

# Calculate used memory as a percentage of total memory and round to an integer.
MEM_PCT=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')

# top reports the CPU idle percentage; subtracting it from 100 gives CPU usage.
CPU_PCT=$(top -bn1 | grep '^%Cpu' | awk '{print 100 - $8}' | cut -d. -f1)

# --- Health checks with conditionals and color-coded output ---
# Tell the user that threshold analysis is starting.
print_status "CHECK" "Running system health analysis..."

# Start in a healthy state. Any failed check changes this value to 1.
HEALTH_STATUS=0

# --- Root disk check ---
# Compare the numeric root disk percentage with the configured disk threshold.
if (( DISK_PCT > DISK_THRESHOLD )); then
    print_status "ALERT" "Disk usage on / is ${DISK_PCT}% (threshold ${DISK_THRESHOLD}%)"
    HEALTH_STATUS=1
else
    print_status "OK" "Disk usage on / is ${DISK_PCT}%"
fi

# --- Loop over multiple mount points ---
# Check the root filesystem plus /home and /var when they are separate mount points.
for mount in / /home /var; do

    # mountpoint -q quietly verifies whether the path is an actual mount point.
    # Root is always allowed because it is required by the assignment.
    if mountpoint -q "$mount" 2>/dev/null || [[ "$mount" == "/" ]]; then

        # Parse the usage percentage for the current mount and remove the percent sign.
        PCT=$(df "$mount" | tail -1 | awk '{gsub("%",""); print $5}')

        # Mark the entire system unhealthy if any monitored mount exceeds the threshold.
        if (( PCT > DISK_THRESHOLD )); then
            print_status "ALERT" "Disk usage on $mount is ${PCT}% (threshold ${DISK_THRESHOLD}%)"
            HEALTH_STATUS=1
        else
            print_status "OK" "Disk usage on $mount is ${PCT}%"
        fi
    else
        # Missing optional mount points are handled gracefully instead of causing an error.
        print_status "OK" "Mount point $mount does not exist or is not a mount point on this system"
    fi
done

# --- Memory check ---
# Compare the calculated integer memory percentage with the configured threshold.
if (( MEM_PCT > MEM_THRESHOLD )); then
    print_status "ALERT" "Memory usage is ${MEM_PCT}% (threshold ${MEM_THRESHOLD}%)"
    HEALTH_STATUS=1
else
    print_status "OK" "Memory usage is ${MEM_PCT}%"
fi

# --- CPU check ---
# Compare the CPU snapshot with the configured CPU threshold.
if (( CPU_PCT > CPU_THRESHOLD )); then
    print_status "ALERT" "CPU usage is ${CPU_PCT}% (threshold ${CPU_THRESHOLD}%)"
    HEALTH_STATUS=1
else
    print_status "OK" "CPU usage is ${CPU_PCT}%"
fi

# --- Optional output file ---
# The first positional argument becomes the report filename; no argument means terminal output.
OUTPUT_FILE="${1:-}"

# --- Final report function ---
# printf creates a predictable structured summary suitable for terminal or file output.
print_report() {
    printf "========================================\n"
    printf "System Health Report - %s\n" "$CURRENT_DATE"
    printf "Hostname        : %s\n" "$HOSTNAME"
    printf "Uptime          : %s\n" "$UPTIME"
    printf "Disk /          : %s\n" "$DISK_USAGE"
    printf "Memory used     : %s\n" "$MEMORY_USAGE"
    printf "Total processes : %s\n" "$PROCESS_COUNT"

    # Convert the numeric health flag into a readable final status line.
    printf "Health status   : %s\n" "$([[ "$HEALTH_STATUS" -eq 0 ]] && echo "HEALTHY" || echo "UNHEALTHY - see alerts above")"
    printf "========================================\n"
}

# --- Output handling ---
# When a filename is supplied, write only the structured report to that file.
# The earlier color-coded checks remain visible in the interactive terminal.
if [[ -n "$OUTPUT_FILE" ]]; then
    print_report > "$OUTPUT_FILE"
    echo "Report written to $OUTPUT_FILE (alerts were printed to terminal)"
else
    # Without a filename, print the final report directly to the terminal.
    print_report
fi

# --- Exit code handling ---
# Exit 0 when every check is healthy or 1 when one or more alerts were triggered.
# This makes the script useful in cron jobs and other automated monitoring tools.
exit "${HEALTH_STATUS:-0}"
