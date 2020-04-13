#!/bin/bash 

echo "Creating the ASG with Spot Blocks for an existing EKS Cluster..."


MAC=$(curl -s http://169.254.169.254/latest/meta-data/mac)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
AWS_AVAIALABILITY_ZONE=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.availabilityZone')
AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
INTERFACE_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/interface-id)

aws configure set default.region ${AWS_REGION}

cp -Rfp templates/*.json .

EKS_NODEGROUP_ASG=eksctl-eksworkshop-eksctl-nodegroup-dev-4vcpu-16gb-spot-NodeGroup-N8LQLHS2DJJO
EKS_CLUSTER_NAME=eksworkshop-eksctl
 
EKS_VPC_AZ1=us-east-1c
EKS_VPC_AZ2=us-east-1f
EKS_VPC_PUB_SUBNET_1=subnet-0d60f770f347d7949
EKS_VPC_PUB_SUBNET_2=subnet-081386c6e3ace3c8e
ASG_LT_VERSION_2=17
ASG_LT_VERSION_3=18
EC2_KEY_PAIR=awsajp_keypair
SPOT_BLOCK_DURATION=60
SPOTFLEET_CONFIG_FILE=spot_fleet_config.json
SPOT_ALLOCATIION_STRATEGY=capacityOptimized
SPOTFLEET_TARGET_CAPACITY=1
EKS_SPOT_BLOCKS_ASG_NAME=eks_spot_blocks_asg
MIN_SIZE=1
MAX_SIZE=2
DESIRED_CAPACITY=1


EKS_NODEGROUP_ASG_LT=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $EKS_NODEGROUP_ASG | jq -r '.AutoScalingGroups[0].MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.LaunchTemplateId')
echo "EKS_NODEGROUP_ASG_LT=$EKS_NODEGROUP_ASG_LT"

if [ 1 == 1 ]; then
aws ec2 create-launch-template-version --launch-template-id $EKS_NODEGROUP_ASG_LT --version-description $ASG_LT_VERSION_2 --source-version '$Default' --launch-template-data "{ \"KeyName\": \"$EC2_KEY_PAIR\", \"TagSpecifications\": [
    {
     \"ResourceType\": \"instance\",
      \"Tags\": [
        {
          \"Key\": \"eksctl.cluster.k8s.io/v1alpha1/cluster-name\",
          \"Value\": \"$EKS_CLUSTER_NAME\"
        },
          {
          \"Key\": \"alpha.eksctl.io/cluster-name\",
          \"Value\": \"$EKS_CLUSTER_NAME\"
        },
		  {
          \"Key\": \"k8s.io/cluster-autoscaler/eksworkshop-eksctl\",
          \"Value\": \"owned\"
        },
		  {
          \"Key\": \"k8s.io/cluster-autoscaler/enabled\",
          \"Value\": \"true\"
        },
		  {
          \"Key\": \"kubernetes.io/cluster/eksworkshop-eksctl\",
          \"Value\": \"owned\"
        }
      ]
    }
  ] }"

fi


 aws ec2 create-launch-template-version --launch-template-id $EKS_NODEGROUP_ASG_LT --version-description $ASG_LT_VERSION_3 --source-version $ASG_LT_VERSION_2 --launch-template-data "{  \"InstanceMarketOptions\": {
    \"MarketType\": \"spot\",
    \"SpotOptions\": {
      \"SpotInstanceType\": \"one-time\",
      \"BlockDurationMinutes\": $SPOT_BLOCK_DURATION,
      \"InstanceInterruptionBehavior\": \"terminate\"
    }
  } }"


sed -i "s/SPOT_ALLOCATIION_STRATEGY/$SPOT_ALLOCATIION_STRATEGY/g" $SPOTFLEET_CONFIG_FILE
sed -i "s/SPOTFLEET_TARGET_CAPACITY/$SPOTFLEET_TARGET_CAPACITY/g" $SPOTFLEET_CONFIG_FILE
sed -i "s/EKS_NODEGROUP_ASG_LT/$EKS_NODEGROUP_ASG_LT/g" $SPOTFLEET_CONFIG_FILE
sed -i "s/ASG_LT_VERSION_2/$ASG_LT_VERSION_2/g" $SPOTFLEET_CONFIG_FILE
sed -i "s/EKS_VPC_PUB_SUBNET_1/$EKS_VPC_PUB_SUBNET_1/g" $SPOTFLEET_CONFIG_FILE
sed -i "s/EKS_VPC_PUB_SUBNET_2/$EKS_VPC_PUB_SUBNET_2/g" $SPOTFLEET_CONFIG_FILE



SPOT_FLEET_REQUEST_ID=$(aws ec2 request-spot-fleet --spot-fleet-request-config file://$SPOTFLEET_CONFIG_FILE|jq -r '.SpotFleetRequestId')
echo "Created the Spot Fleet (using launch template) request id $SPOT_FLEET_REQUEST_ID"


echo "Creating the ASG $ASG_NAME using $ASG_TEMPLATE_TEMP_FILE..."

aws autoscaling create-auto-scaling-group --auto-scaling-group-name $EKS_SPOT_BLOCKS_ASG_NAME \
    --launch-template LaunchTemplateId=$EKS_NODEGROUP_ASG_LT,Version=$ASG_LT_VERSION_3 \
	--availability-zones $EKS_VPC_AZ1 $EKS_VPC_AZ2  \
	--vpc-zone-identifier "$EKS_VPC_PUB_SUBNET_1,$EKS_VPC_PUB_SUBNET_2" \
	--min-size $MIN_SIZE   --max-size $MAX_SIZE --desired-capacity $DESIRED_CAPACITY
	

EC2_SPOT_BLOCK_PRIVATE_IP_DNS=ip-192-168-40-46.ec2.internal
kubectl label nodes $EC2_SPOT_BLOCK_PRIVATE_IP_DNS  spotsa=jp

kubectl apply -f ./monte-carlo-pi-service.yml

