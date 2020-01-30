## ASG with Spot Blocks for an existing EKS Cluster

In this workshop, you will deploy the following:

### Step1 :  Create a New Version (say V2) of Launch Template Default Version (say V1) from the ASG created by EKS Node Group
This New Version V2 adds the following Tags in this new version


KEY                                               VALUE


eksctl.cluster.k8s.io/v1alpha1/cluster-name      eksworkshop-eksctl	

alpha.eksctl.io/cluster-name	                 eksworkshop-eksctl	

k8s.io/cluster-autoscaler/eksworkshop-eksctl     owned	 

k8s.io/cluster-autoscaler/enabled          	     true 

kubernetes.io/cluster/eksworkshop-eksctl 	     owned


### Step2 : Create a New Version (say V3) from Above V2 of Launch Template
This New Version V3 adds the following spot block configuration


{  
    "InstanceMarketOptions": {
    "MarketType": "spot",
    "SpotOptions": {
      "SpotInstanceType": "one-time",
      "BlockDurationMinutes": 60,
      "InstanceInterruptionBehavior": "terminate"
    }
  } 
 }


### Step3 : Create a Spot Fleet using launch Template Version V2
This is used for simulating the Spot Interruption. The Instances from this spot fleet will join the EKS clsuter

aws ec2 request-spot-fleet --spot-fleet-request-config file://$SPOTFLEET_CONFIG_FILE|jq -r '.SpotFleetRequestId'


### Step4 : Create an ASG using launch Template Version V3
The ASG creates the spot block instances which will join the cluster

aws autoscaling create-auto-scaling-group --auto-scaling-group-name $EKS_SPOT_BLOCKS_ASG_NAME \
    --launch-template LaunchTemplateId=$EKS_NODEGROUP_ASG_LT,Version=$ASG_LT_VERSION_3 \
	--availability-zones $EKS_VPC_AZ1 $EKS_VPC_AZ2  \
	--vpc-zone-identifier "$EKS_VPC_PUB_SUBNET_1,$EKS_VPC_PUB_SUBNET_2" \
	--min-size $MIN_SIZE   --max-size $MAX_SIZE --desired-capacity $DESIRED_CAPACITY
	
	
	
### Step5 : Create a label to the new spot block instances created from Step4
kubectl label nodes $EC2_SPOT_BLOCK_PRIVATE_IP_DNS  spotsa=jp

### Step6 : Configure pods to be deplpoyed on to these spot block instances / nodes using NodeSelector

      nodeSelector:
        spotsa: jp
        
### Step7 : Deploy the pods into K8S 

kubectl apply -f ./monte-carlo-pi-service.yml


### Workshop Cleanup
