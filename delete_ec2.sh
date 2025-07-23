#!/bin/bash

JENKINS_URL="http://localhost:8080"
USER="admin"
API_TOKEN="aaaa"

# Function to URL-encode strings (bash only)
urlencode() {
    local string="${1}"
    local length=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<length ; pos++ )); do
        c=${string:pos:1}
        case "$c" in
            [a-zA-Z0-9.~_-]) o="$c" ;;
            *) printf -v o '%%%02X' "'$c"
        esac
        encoded+="$o"
    done
    echo "$encoded"
}

# Get Jenkins crumb without jq
CRUMB=$(curl -s -u "$USER:$API_TOKEN" "$JENKINS_URL/crumbIssuer/api/json" | grep -o '"crumb":"[^"]*"' | sed 's/"crumb":"\([^"]*\)"/\1/')

if [ -z "$CRUMB" ]; then
    echo "Failed to get Jenkins crumb"
    exit 1
fi

# Groovy script that prints node info
read -r -d '' GROOVY_SCRIPT <<'EOF'
Jenkins.instance.nodes.findAll { it instanceof hudson.plugins.ec2.EC2OndemandSlave }.each { node ->
    def computer = node.toComputer()
    if (computer != null) {
        println "${node.name}|${computer.isIdle()}|${!computer.isOffline()}|${computer.getIdleStartMilliseconds()}"
    }
}
EOF

# Call Jenkins script console API
response=$(curl -s -u "$USER:$API_TOKEN" -H "Jenkins-Crumb: $CRUMB" --data-urlencode "script=$GROOVY_SCRIPT" "$JENKINS_URL/scriptText")

# Get current time in ms (Linux-specific)
NOW=$(($(date +%s%3N)))

echo "[$(date '+%Y-%m-%d %H:%M:%S')]"
echo "$response" | while IFS='|' read -r name idle connected idle_start; do
    echo "  Agent: $name"
    echo "  Idle: $idle"
    echo "  Connected: $connected"
    echo "  Idle Start Time: $idle_start"

    if [[ "$idle" == "true" && "$connected" == "true" && "$idle_start" != "null" ]]; then
        idle_duration=$((NOW - idle_start))
        echo "  Idle Duration: $((idle_duration / 1000)) seconds"

        if (( idle_duration > 600000 )); then
            echo "  → Deleting idle node: $name"
            url_name=$(urlencode "$name")
            curl -X POST -u "$USER:$API_TOKEN" -H "Jenkins-Crumb: $CRUMB" \
                "$JENKINS_URL/computer/$url_name/doDelete"
        else
            echo "  → Skipped: idle < 5 minutes"
        fi
    else
        echo "  → Skipped: not eligible (not idle, not connected, or no idle start time)"
    fi

    echo "----------------------------------------------------"
done
