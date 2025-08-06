#!/bin/bash
# --- USER CONFIGURATION ---
AMI_ID="ami-046538ed74e7890f2"        # <-- Your Genymotion AMI ID
INSTANCE_TYPE="m5.2xlarge"
KEY_NAME="ads-jenkins-key-staging"     # <-- Your EC2 key pair name
SECURITY_GROUP="sg-0b95797a61ad133a4"  # <-- Forced: Genymotion security group
REGION="eu-west-2"                     # <-- Your AWS region
DOCKER_COMPOSE_FILE="/path/to/docker-compose.yml"  # <-- Path to your docker-compose file
NAME_TAG="genymotion-test-runner"      # <-- Name tag for the EC2 instance

# --- LAUNCH EC2 INSTANCE ---
echo "Launching EC2 instance from AMI $AMI_ID..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP \
  --region $REGION \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME_TAG}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

if [ -z "$INSTANCE_ID" ]; then
  echo "Failed to launch EC2 instance."
  exit 1
fi

echo "Launched instance: $INSTANCE_ID"
# Save instance ID for Jenkins cleanup
echo "$INSTANCE_ID" > instance_id.txt

# --- WAIT FOR INSTANCE TO BE RUNNING ---
echo "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
echo "Instance is running."

# --- GET PUBLIC IP ---
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

if [ -z "$PUBLIC_IP" ]; then
  echo "Failed to get public IP."
  exit 1
fi

echo "Instance public IP: $PUBLIC_IP"

# --- WAIT FOR GENYMOTION/ADB TO BE READY ---
echo "Waiting 120 seconds for Genymotion/ADB to be ready..."
sleep 120  # Adjust as needed for your environment

# --- CHECK EC2 INSTANCE STATUS BEFORE CURL ---
echo "Checking EC2 instance status before enabling ADB..."
INSTANCE_STATUS=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text)

echo "Instance status: $INSTANCE_STATUS"

if [ "$INSTANCE_STATUS" != "running" ]; then
  echo "Error: EC2 instance is not running. Current status: $INSTANCE_STATUS"
  echo "Waiting for instance to be running..."
  aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
  echo "Instance is now running."
fi

# --- ENABLE ADB VIA GENYMOTION WEB API ---
echo "Enabling ADB via Genymotion web API..."
# Create base64 encoded credentials: genymotion:INSTANCE_ID
CREDENTIALS=$(echo -n "genymotion:$INSTANCE_ID" | base64)

# Enable ADB via API call
curl -s "https://$PUBLIC_IP/api/v1/configuration/adb" \
  --compressed \
  -X POST \
  -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0" \
  -H "Accept: application/json, text/plain, */*" \
  -H "Accept-Language: en-US,en;q=0.5" \
  -H "Accept-Encoding: gzip, deflate, br, zstd" \
  -H "Content-Type: application/json" \
  -H "Origin: https://$PUBLIC_IP" \
  -H "Authorization: Basic $CREDENTIALS" \
  -H "Connection: keep-alive" \
  -H "Referer: https://$PUBLIC_IP/configuration" \
  -H "Sec-Fetch-Dest: empty" \
  -H "Sec-Fetch-Mode: cors" \
  -H "Sec-Fetch-Site: same-origin" \
  -H "Priority: u=0" \
  --data-raw '{"active":true,"active_on_reboot":true}' \
  --insecure

echo "ADB enabled via web API"

# --- WAIT A BIT MORE FOR ADB TO BE FULLY READY ---
echo "Waiting 10 seconds for ADB to be fully ready..."
sleep 10

# --- CONNECT ADB ---
echo "Connecting ADB to $PUBLIC_IP:5555..."
adb connect $PUBLIC_IP:5555
adb devices

# --- RUN DOCKER-COMPOSE (LOCALLY) ---
# echo "Running docker-compose..."
# docker-compose -f $DOCKER_COMPOSE_FILE up -d

echo "All done!"

# --- OPTIONAL: CLEANUP ---
# Uncomment the following lines if you want to terminate the instance after tests
# echo "Terminating EC2 instance $INSTANCE_ID..."
# aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
# echo "Instance terminated." 