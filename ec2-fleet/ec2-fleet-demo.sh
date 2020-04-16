#!/bin/bash 

echo "Demostrating the EC2 Feet API Usage..."


#yum update -y
yum -y install jq


MAC=$(curl -s http://169.254.169.254/latest/meta-data/mac)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
AWS_AVAIALABILITY_ZONE=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.availabilityZone')
AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
INTERFACE_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/interface-id)

aws configure set default.region ${AWS_REGION}

cp -Rfp templates/*.json .
cp -Rfp templates/*.txt .

export AMI_ID=$(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region us-east-1  | jq -r 'last(.Parameters[]).Value')
echo "Latest Amazon Linux 2 AMI is $AMI_ID"


sed -i.bak  -e "s#%ami-id%#$AMI_ID#g" -e "s#%UserData%#$(cat user-data.txt | base64 --wrap=0)#g" launch-template-data.json

#LAUCH_TEMPLATE_ID=lt-07fdb20138ddf466c
LAUCH_TEMPLATE_ID=$(aws ec2 create-launch-template  --cli-input-json file://launch-template-data.json | jq -r '.LaunchTemplate.LaunchTemplateId')
echo "Amazon LAUCH_TEMPLATE_ID is $LAUCH_TEMPLATE_ID"

#
#  Example for the Syncronous one-time Request
#

echo "Start time for ec2-fleet=$(date)"
RESPONSE=$(aws ec2 create-fleet --cli-input-json file://ec2-fleet-template-instance.json)
echo "End time for ec2-fleet=$(date)"


FLEET_ID=$(echo $RESPONSE | jq -r '.FleetId')
echo "FLEET_ID = $FLEET_ID"

LIFECYCLE=$(echo $RESPONSE | jq -r '.Instances[0].Lifecycle')
echo "LIFECYCLE = $LIFECYCLE"
INSTANCE_IDs=$(echo $RESPONSE | jq -r '.Instances[0].InstanceIds')
echo "INSTANCE_IDs = $INSTANCE_IDs"


LIFECYCLE=$(echo $RESPONSE | jq -r '.Instances[1].Lifecycle')
echo "LIFECYCLE = $LIFECYCLE"
INSTANCE_IDs=$(echo $RESPONSE | jq -r '.Instances[1].InstanceIds')
echo "INSTANCE_IDs = $INSTANCE_IDs"




ERRORS=$(echo $RESPONSE | jq -r '.Errors')
echo "ERRORS = $ERRORS"

FLEET_DESCRIPTION=$(aws ec2 describe-fleets --fleet-id $FLEET_ID)

echo "EC2 Fleet Description = $FLEET_DESCRIPTION"

Total_FulfilledCapacity=$(echo $FLEET_DESCRIPTION | jq -r '.Fleets[0].FulfilledCapacity')
echo "Total_FulfilledCapacity = $Total_FulfilledCapacity"

FulfilledOnDemandCapacity=$(echo $FLEET_DESCRIPTION | jq -r '.Fleets[0].FulfilledOnDemandCapacity')
echo "FulfilledOnDemandCapacity = $FulfilledOnDemandCapacity"

#
#  Example for the Asyncronous persistance Request
#

echo "Start time for ec2-fleet=$(date)"
RESPONSE=$(aws ec2 create-fleet --cli-input-json file://ec2-fleet-template-maintain.json)
echo "End time for ec2-fleet=$(date)"

FLEET_ID=$(echo $RESPONSE | jq -r '.FleetId')
echo "FLEET_ID = $FLEET_ID"

#aws ec2 delete-fleets --fleet-id $FLEET_ID --terminate-instances
	