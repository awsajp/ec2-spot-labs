# Turbo boost EC2 Fleet with Spot

1. Create launch template

	`aws ec2 create-launch-template --cli-input-json file://ec2-fleet-launch-template.json`

1. Create EC2 Fleet with baseline On-Demand

	`aws ec2 create-fleet --cli-input-json file://ec2-fleet-ec2-spot-turbo-boost.json`

1. Describe Fleet

	`aws ec2 describe-fleets --fleet-id $FLEETID`

1. Describe Fleet history

	`aws ec2 describe-fleet-history --fleet-id $FLEETID --start-time 2018-07-01`

1. Turbo boost EC2 Fleet with Spot

	`aws ec2 modify-fleet --fleet-id $FLEETID --target-capacity-specification TotalTargetCapacity=20`

1. Clean up

	`aws ec2 delete-fleets --fleet-id $FLEETID --terminate-instances`

# EC2 Fleet with million core scale and On-Demand backup

1. Create EC2 Fleet with million core scale and On-Demand backup

	`aws ec2 create-fleet --cli-input-json file://ec2-fleet-on-demand-backup.json`

1. Describe Fleet

	`aws ec2 describe-fleets --fleet-id $FLEETID`

1. Describe Fleet history

	`aws ec2 describe-fleet-history --fleet-id $FLEETID --start-time 2018-07-01`

1. Clean up

	`aws ec2 delete-fleets --fleet-id $FLEETID --terminate-instances`

# EC2 Fleet with weighted capacity (vCPUs)

1. Create EC2 Fleet with weighted capacity (vCPUs)

	`aws ec2 create-fleet --cli-input-json file://ec2-fleet-ec2-spot-weighted-capacity.json`

1. Describe Fleet

	`aws ec2 describe-fleets --fleet-id $FLEETID`

1. Describe Fleet history

	`aws ec2 describe-fleet-history --fleet-id $FLEETID --start-time 2018-07-01`

1. Clean up

	`aws ec2 delete-fleets --fleet-id $FLEETID --terminate-instances`

# EC2 Fleet of type 'instant'

1. Create EC2 Fleet of type 'instant'

	`aws ec2 create-fleet --cli-input-json file://ec2-fleet-ec2-spot-instant.json`

1. Describe Fleet

	`aws ec2 describe-fleets --fleet-id $FLEETID`

An error occurred (Unsupported) when calling the DeleteFleets operation: Fleet fleet-badc6577-a177-075b-069a-810ae31543ca is instant fleet. This type of fleet cannot be cancelled.

    "TargetCapacitySpecification": {
        "TotalTargetCapacity": 12, 
        "OnDemandTargetCapacity": 0, 
        "SpotTargetCapacity": 0, 
        "DefaultTargetCapacityType": "spot"
        
        all 12 spot m4.large 1c
        
                "SingleInstanceType": false, 
        "SingleAvailabilityZone": true
        
        all 6 spot m4.large 1c