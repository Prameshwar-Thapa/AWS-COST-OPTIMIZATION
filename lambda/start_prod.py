import boto3
import os
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    # Get environment variables
    sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
    
    # Initialize clients
    ec2 = boto3.client('ec2')
    sns = boto3.client('sns') if sns_topic_arn else None
    
    try:
        # Find stopped instances with required tags
        filters = [
            {"Name": "instance-state-name", "Values": ["stopped"]},
            {"Name": "tag:Environment", "Values": ["non-prod"]}
        ]
        
        instance_ids = []
        paginator = ec2.get_paginator('describe_instances')
        
        for page in paginator.paginate(Filters=filters):
            for reservation in page.get("Reservations", []):
                for instance in reservation.get("Instances", []):
                    instance_ids.append(instance["InstanceId"])
        
        if not instance_ids:
            message = "No stopped instances found with Environment=non-prod tag"
            print(message)
            send_notification(sns, sns_topic_arn, "EC2 Start - No Instances", message)
            return {"statusCode": 200, "body": message}
        
        # Start instances
        ec2.start_instances(InstanceIds=instance_ids)
        message = f"Started {len(instance_ids)} instances: {instance_ids}"
        print(message)
        send_notification(sns, sns_topic_arn, "EC2 Start - Success", message)
        
        return {"statusCode": 200, "body": message}
        
    except ClientError as e:
        error_msg = f"AWS Error: {e.response['Error']['Code']} - {e.response['Error']['Message']}"
        print(error_msg)
        send_notification(sns, sns_topic_arn, "EC2 Start - Error", error_msg)
        return {"statusCode": 500, "body": error_msg}
    
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        print(error_msg)
        send_notification(sns, sns_topic_arn, "EC2 Start - Error", error_msg)
        return {"statusCode": 500, "body": error_msg}

def send_notification(sns, topic_arn, subject, message):
    if not sns or not topic_arn:
        return
    try:
        sns.publish(TopicArn=topic_arn, Subject=subject, Message=message)
    except Exception as e:
        print(f"SNS notification failed: {str(e)}")
