#!/bin/bash 

echo "Creating the ASG with Spot Blocks for an existing EKS Cluster..."

#yum update -y
#yum -y install jq amazon-efs-utils

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
EKS_VPC_PUB_SUBNET_1=subnet-0d60f770f347d7949
EKS_VPC_PUB_SUBNET_2=subnet-081386c6e3ace3c8e
ASG_LT_VERSION_2=17
ASG_LT_VERSION_3=18
EC2_KEY_PAIR=awsajp_keypair
SPOT_BLOCK_DURATION=60
SPOTFLEET_CONFIG_FILE=spot_fleet_config.json
SPOT_ALLOCATIION_STRATEGY=capacityOptimized
SPOTFLEET_TARGET_CAPACITY=1


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


exit 0


#Global Defaults
WORKSHOP_NAME=ecs-fargate-cluster-autoscale
LAUNCH_TEMPLATE_NAME=ecs-fargate-cluster-autoscale-LT
ASG_NAME_OD=ecs-fargate-cluster-autoscale-asg-od
ASG_NAME_SPOT=ecs-fargate-cluster-autoscale-asg-spot
OD_CAPACITY_PROVIDER_NAME=od-capacity_provider_3
SPOT_CAPACITY_PROVIDER_NAME=spot-capacity_provider_3

ECS_FARGATE_CLLUSTER_NAME=EcsFargateCluster
LAUNCH_TEMPLATE_VERSION=1
IAM_INSTANT_PROFILE_ARN=arn:aws:iam::000474600478:instance-profile/ecsInstanceRole
SECURITY_GROUP=sg-4f3f0d1e



#EBS Settings

EBS_TYPE=gp2
EBS_SIZE=8
EBS_DEV=/dev/xvdb

#SECONDARY_PRIVATE_IP="172.31.81.24"


sudo curl --silent --location -o /usr/local/bin/kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl

sudo chmod +x /usr/local/bin/kubectl

sudo yum -y install jq gettext bash-completion

for command in kubectl jq envsubst
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done
  
kubectl completion bash >>  ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

rm -vf ${HOME}/.aws/credentials

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo AWS_REGION is not set

echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region

aws sts get-caller-identity

cd ~/environment
git clone https://github.com/brentley/ecsdemo-frontend.git
git clone https://github.com/brentley/ecsdemo-nodejs.git
git clone https://github.com/brentley/ecsdemo-crystal.git

curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp


sudo mv -v /tmp/eksctl /usr/local/bin

eksctl version

eksctl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

eksctl create cluster --name=eksworkshop-eksctl-test --nodes=3 --managed --alb-ingress-access --region=${AWS_REGION}

kubectl get nodes

STACK_NAME=$(eksctl get nodegroup --cluster eksworkshop-eksctl-test -o json | jq -r '.[].StackName')
ROLE_NAME=$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME | jq -r '.StackResources[] | select(.ResourceType=="AWS::IAM::Role") | .PhysicalResourceId')
echo "export ROLE_NAME=${ROLE_NAME}" | tee -a ~/.bash_profile


kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

kubectl proxy --port=8080 --address='0.0.0.0' --disable-filter=true &