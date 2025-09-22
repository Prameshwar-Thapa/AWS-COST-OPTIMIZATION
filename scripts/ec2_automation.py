#!/usr/bin/env python3
"""
Simple EC2 automation for local testing
"""

import boto3
from datetime import datetime, timezone

def get_tagged_instances(state):
    """Get instances with Environment=non-prod tag in specific state"""
    ec2 = boto3.client('ec2')
    
    filters = [
        {'Name': 'tag:Environment', 'Values': ['non-prod']},
        {'Name': 'instance-state-name', 'Values': [state]}
    ]
    
    response = ec2.describe_instances(Filters=filters)
    instance_ids = []
    
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
    
    return instance_ids

def start_instances():
    """Start stopped instances"""
    ec2 = boto3.client('ec2')
    instance_ids = get_tagged_instances('stopped')
    
    if not instance_ids:
        print("No stopped instances found with Environment=non-prod tag")
        return
    
    print(f"Starting {len(instance_ids)} instances: {instance_ids}")
    ec2.start_instances(InstanceIds=instance_ids)
    print("✅ Start command sent successfully")

def stop_instances():
    """Stop running instances"""
    ec2 = boto3.client('ec2')
    instance_ids = get_tagged_instances('running')
    
    if not instance_ids:
        print("No running instances found with Environment=non-prod tag")
        return
    
    print(f"Stopping {len(instance_ids)} instances: {instance_ids}")
    ec2.stop_instances(InstanceIds=instance_ids)
    print("✅ Stop command sent successfully")

def list_instances():
    """List all instances with their states"""
    ec2 = boto3.client('ec2')
    
    filters = [{'Name': 'tag:Environment', 'Values': ['non-prod']}]
    response = ec2.describe_instances(Filters=filters)
    
    print("=== Tagged Instances ===")
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            state = instance['State']['Name']
            instance_type = instance['InstanceType']
            
            # Get name tag
            name = 'N/A'
            for tag in instance.get('Tags', []):
                if tag['Key'] == 'Name':
                    name = tag['Value']
                    break
            
            print(f"{instance_id:<20} {name:<20} {instance_type:<12} {state}")

def main():
    """Main menu"""
    while True:
        print("\n=== EC2 Cost Optimization - Local Testing ===")
        print("1. Start instances")
        print("2. Stop instances") 
        print("3. List instances")
        print("4. Exit")
        
        choice = input("\nEnter choice (1-4): ").strip()
        
        try:
            if choice == '1':
                start_instances()
            elif choice == '2':
                stop_instances()
            elif choice == '3':
                list_instances()
            elif choice == '4':
                print("Goodbye!")
                break
            else:
                print("Invalid choice. Please enter 1-4.")
        except Exception as e:
            print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()
