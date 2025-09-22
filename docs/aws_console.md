# AWS Console Deployment Guide

Complete step-by-step guide to deploy EC2 Cost Optimization automation using AWS Console.

## Prerequisites

- AWS Account with administrative access
- Python 3.x installed locally
- boto3 library: `pip install boto3`
- AWS credentials configured: `aws configure`

## Step 1: Test Your Permissions

First, verify you have the required AWS permissions:

```bash
cd scripts
./test_permissions.sh
```

**Expected Output:**
```
=== AWS Permissions Test ===
✅ AWS CLI configured
Account ID: 123456789012
Region: us-east-1
User: arn:aws:iam::123456789012:user/your-user

Testing permissions...
✅ EC2 describe-instances: OK
✅ EC2 start-instances: OK (permission exists)
✅ EC2 stop-instances: OK (permission exists)
✅ SNS list-topics: OK
```

If any permissions fail, contact your AWS administrator.

## Step 2: Tag Your EC2 Instances

Use the boto3 tagging script to prepare your instances:

```bash
python tag_instances_boto3.py
```

### 2.1 List Current Instances
Choose option **1** to see all your instances:
```
=== All EC2 Instances ===
Instance ID          Name                     Type           State           Environment
i-1234567890abcdef0  web-server-dev          t3.medium      running         N/A
i-0987654321fedcba0  database-test           t3.small       stopped         N/A
i-abcdef1234567890  api-server-prod         t3.large       running         production
```

### 2.2 Tag Non-Production Instances
Choose option **2** to tag specific instances:
```
Enter instance IDs (space-separated): i-1234567890abcdef0 i-0987654321fedcba0
Environment (default: non-prod): non-prod
```

**Result:**
```
✅ Successfully tagged instances:
  • i-1234567890abcdef0
  • i-0987654321fedcba0
```

### 2.3 Verify Tagging
Choose option **5** to see tagged instances:
```
=== Instances Tagged for Cost Optimization ===
Instance ID          Name                     Type           State
i-1234567890abcdef0  web-server-dev          t3.medium      running
i-0987654321fedcba0  database-test           t3.small       stopped

Total: 2 instances
These instances will be automatically started/stopped based on schedule
```

## Step 3: Test Local Automation

Before deploying to AWS, test the automation logic locally:

```bash
python ec2_automation.py
```

Choose option **4** (Smart automation) to test:
```
=== Smart EC2 Automation ===
Current time: 2025-08-23 10:30:00 UTC
Day of week: Friday
Is weekend: False
Is work hours: True
Instances should be running: True

🌅 Work hours detected - starting instances...
=== Starting EC2 Instances ===
Starting 1 instances...
  • database-test (i-0987654321fedcba0) - t3.small
Start command sent for: ['i-0987654321fedcba0']
Waiting for instances to start...
✅ Successfully started 1 instances
```

## Step 4: Create SNS Topic for Notifications

### 4.1 Navigate to SNS Console
1. Go to **AWS Console** → **SNS** → **Topics**
2. Click **"Create topic"**

### 4.2 Configure Topic
- **Type**: Standard
- **Name**: `ec2-cost-optimization-alerts`
- **Display name**: `EC2 Cost Optimization Alerts`
- Click **"Create topic"**

### 4.3 Create Email Subscription
1. In the topic details, click **"Create subscription"**
2. **Protocol**: Email
3. **Endpoint**: Your email address (e.g., `admin@company.com`)
4. Click **"Create subscription"**
5. **Check your email** and click the confirmation link

### 4.4 Note the Topic ARN
Copy the Topic ARN (looks like: `arn:aws:sns:us-east-1:123456789012:ec2-cost-optimization-alerts`)
You'll need this for Lambda functions.

## Step 5: Create IAM Role for Lambda

### 5.1 Navigate to IAM Console
1. Go to **AWS Console** → **IAM** → **Roles**
2. Click **"Create role"**

### 5.2 Configure Role Trust Policy
1. **Trusted entity type**: AWS service
2. **Service**: Lambda
3. Click **"Next"**

### 5.3 Create Custom Policy
1. Click **"Create policy"**
2. Choose **JSON** tab
3. Paste this policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EC2Operations",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SNSPublish",
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": "arn:aws:sns:*:*:ec2-cost-optimization-alerts"
        },
        {
            "Sid": "CloudWatchLogs",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
```

4. Click **"Next"**
5. **Policy name**: `EC2CostOptimizationPolicy`
6. Click **"Create policy"**

### 5.4 Complete Role Creation
1. Go back to role creation tab
2. Search for and select `EC2CostOptimizationPolicy`
3. Also attach `AWSLambdaBasicExecutionRole`
4. Click **"Next"**
5. **Role name**: `EC2CostOptimizationRole`
6. Click **"Create role"**

## Step 6: Create Lambda Functions

### 6.1 Create Start Instances Function

#### Navigate to Lambda Console
1. Go to **AWS Console** → **Lambda** → **Functions**
2. Click **"Create function"**

#### Configure Function
- **Function name**: `start-ec2-instances`
- **Runtime**: Python 3.9
- **Execution role**: Use existing role → `EC2CostOptimizationRole`
- Click **"Create function"**

#### Add Function Code
1. In the code editor, **delete all existing code**
2. **Copy and paste this production code**:

```python
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
```

3. Click **"Deploy"**

#### Set Environment Variables
1. Go to **Configuration** → **Environment variables**
2. Click **"Edit"**
3. Add variable:
   - `SNS_TOPIC_ARN` = `arn:aws:sns:us-east-1:YOUR-ACCOUNT-ID:ec2-cost-optimization-alerts`
4. Click **"Save"**

#### Configure Timeout
1. Go to **Configuration** → **General configuration**
2. Click **"Edit"**
3. Set **Timeout** to `5 minutes`
4. Click **"Save"**

### 6.2 Create Stop Instances Function

Repeat the same process for the stop function:
- **Function name**: `stop-ec2-instances`
- **Code**: Use this production code:

```python
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
        # Find running instances with required tags
        filters = [
            {"Name": "instance-state-name", "Values": ["running"]},
            {"Name": "tag:Environment", "Values": ["non-prod"]}
        ]
        
        instance_ids = []
        paginator = ec2.get_paginator('describe_instances')
        
        for page in paginator.paginate(Filters=filters):
            for reservation in page.get("Reservations", []):
                for instance in reservation.get("Instances", []):
                    instance_ids.append(instance["InstanceId"])
        
        if not instance_ids:
            message = "No running instances found with Environment=non-prod tag"
            print(message)
            send_notification(sns, sns_topic_arn, "EC2 Stop - No Instances", message)
            return {"statusCode": 200, "body": message}
        
        # Stop instances
        ec2.stop_instances(InstanceIds=instance_ids)
        message = f"Stopped {len(instance_ids)} instances: {instance_ids}"
        print(message)
        send_notification(sns, sns_topic_arn, "EC2 Stop - Success", message)
        
        return {"statusCode": 200, "body": message}
        
    except ClientError as e:
        error_msg = f"AWS Error: {e.response['Error']['Code']} - {e.response['Error']['Message']}"
        print(error_msg)
        send_notification(sns, sns_topic_arn, "EC2 Stop - Error", error_msg)
        return {"statusCode": 500, "body": error_msg}
    
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        print(error_msg)
        send_notification(sns, sns_topic_arn, "EC2 Stop - Error", error_msg)
        return {"statusCode": 500, "body": error_msg}

def send_notification(sns, topic_arn, subject, message):
    if not sns or not topic_arn:
        return
    try:
        sns.publish(TopicArn=topic_arn, Subject=subject, Message=message)
    except Exception as e:
        print(f"SNS notification failed: {str(e)}")
```

- **Same environment variables and timeout**

### 6.3 Test Lambda Functions

#### Test Start Function
1. Go to `start-ec2-instances` function
2. Click **"Test"**
3. **Event name**: `test-event`
4. Use default event template
5. Click **"Test"**

**Expected Result:**
```json
{
  "statusCode": 200,
  "body": "Started 1 instances: ['i-0987654321fedcba0']"
}
```

#### Test Stop Function
Repeat for `stop-ec2-instances` function.

#### Check Email Notifications
You should receive emails like:
```
Subject: EC2 Start - Success

Started 1 instances: ['i-0987654321fedcba0']
```

## Step 7: Create EventBridge Rules for Scheduling

### 7.1 Create Start Schedule Rule

#### Navigate to EventBridge Console
1. Go to **AWS Console** → **EventBridge** → **Rules**
2. Click **"Create rule"**

#### Configure Start Rule
- **Name**: `start-ec2-instances-schedule`
- **Description**: `Start non-prod EC2 instances at 8 AM weekdays`
- **Event bus**: default
- **Rule type**: Schedule
- Click **"Next"**

#### Define Schedule Pattern
- **Schedule pattern**: Cron expression
- **Cron expression**: `0 8 ? * MON-FRI *`
  - This means: At 8:00 AM UTC, Monday through Friday
- Click **"Next"**

#### Select Target
- **Target type**: AWS service
- **Service**: Lambda function
- **Function**: `start-ec2-instances`
- Click **"Next"**
- Click **"Create rule"**

### 7.2 Create Stop Schedule Rule

Repeat the process for the stop rule:
- **Name**: `stop-ec2-instances-schedule`
- **Description**: `Stop non-prod EC2 instances at 6 PM weekdays`
- **Cron expression**: `0 18 ? * MON-FRI *`
  - This means: At 6:00 PM UTC, Monday through Friday
- **Target**: `stop-ec2-instances` function

### 7.3 Verify EventBridge Rules

1. Go to **EventBridge** → **Rules**
2. You should see both rules with **State**: Enabled

#### Understanding Cron Expressions
```
0 8 ? * MON-FRI *
│ │ │ │    │     │
│ │ │ │    │     └── Year (any)
│ │ │ │    └──────── Day of week (Monday-Friday)
│ │ │ └─────────────── Month (any)
│ │ └───────────────── Day of month (any)
│ └─────────────────── Hour (8 AM)
└───────────────────── Minute (0)
```

**Time Zone Considerations:**
- All times are in UTC
- For different time zones, adjust the hour:
  - **EST/EDT**: Add 5/4 hours to UTC
  - **PST/PDT**: Add 8/7 hours to UTC
  - **CST/CDT**: Add 6/5 hours to UTC

**Examples:**
```bash
# 8 AM EST = 1 PM UTC (winter) / 12 PM UTC (summer)
0 13 ? * MON-FRI *  # EST winter schedule

# 8 AM PST = 4 PM UTC (winter) / 3 PM UTC (summer)  
0 16 ? * MON-FRI *  # PST winter schedule
```

## Step 8: Monitor and Verify

### 8.1 Check CloudWatch Logs

1. Go to **CloudWatch** → **Log groups**
2. Find logs for your functions:
   - `/aws/lambda/start-ec2-instances`
   - `/aws/lambda/stop-ec2-instances`
3. Click on a log group to see execution logs

**Sample Log Entry:**
```
2025-08-23T10:30:15.123Z	INFO	Starting EC2 instances for environment: non-prod
2025-08-23T10:30:16.456Z	INFO	Starting 1 instances: ['i-0987654321fedcba0']
2025-08-23T10:30:45.789Z	INFO	✅ Successfully started 1 instances
```

### 8.2 Verify Instance States

Use your local script to check instance states:
```bash
python ec2_automation.py
# Choose option 3 to list all instances
```

### 8.3 Test Manual Execution

You can manually trigger the EventBridge rules:
1. Go to **EventBridge** → **Rules**
2. Select a rule
3. Click **"Actions"** → **"Test rule"**
4. This will immediately trigger the Lambda function

## Step 9: Set Up Monitoring and Alerts

### 9.1 Create CloudWatch Alarms

#### Lambda Error Alarm
1. Go to **CloudWatch** → **Alarms** → **Create alarm**
2. **Metric**: AWS/Lambda → Errors
3. **Dimensions**: FunctionName = `start-ec2-instances`
4. **Statistic**: Sum
5. **Period**: 5 minutes
6. **Threshold**: Greater than 0
7. **Alarm name**: `EC2-CostOpt-Start-Errors`
8. **SNS topic**: `ec2-cost-optimization-alerts`

Repeat for `stop-ec2-instances` function.

#### Lambda Duration Alarm
Create another alarm for function duration:
- **Metric**: AWS/Lambda → Duration
- **Threshold**: Greater than 240000 (4 minutes)
- **Alarm name**: `EC2-CostOpt-Duration`

### 9.2 Create Cost Budget

1. Go to **AWS Billing** → **Budgets** → **Create budget**
2. **Budget type**: Cost budget
3. **Budget name**: `EC2-Cost-Optimization-Tracking`
4. **Period**: Monthly
5. **Budget amount**: Set based on your expected savings
6. **Filters**: Service = Amazon Elastic Compute Cloud - Compute
7. **Alerts**: Email when actual cost exceeds 80% of budget

## Step 10: Validate End-to-End Operation

### 10.1 Full Workflow Test

Run this validation sequence:

```bash
# 1. Check current instance states
python ec2_automation.py
# Choose option 3 (List all instances)

# 2. Manually trigger start operation
python ec2_automation.py  
# Choose option 1 (Start tagged instances)

# 3. Wait 2 minutes, then check states again
python ec2_automation.py
# Choose option 3 (List all instances)

# 4. Manually trigger stop operation
python ec2_automation.py
# Choose option 2 (Stop tagged instances)

# 5. Verify final states
python ec2_automation.py
# Choose option 3 (List all instances)
```

### 10.2 Check Email Notifications

You should receive 2 emails:
1. **Start notification** with instance details
2. **Stop notification** with instance details

### 10.3 Verify Scheduling

Wait for the next scheduled time (8 AM or 6 PM UTC) and verify:
1. Lambda functions execute automatically
2. Instances change state as expected
3. Email notifications are sent
4. CloudWatch logs show successful execution

## Troubleshooting

### Common Issues

#### 1. Permission Denied Errors
**Symptom**: Lambda function fails with access denied
**Solution**: 
- Verify IAM role has correct policies attached
- Check resource ARNs in policy match your account/region

#### 2. No Instances Found
**Symptom**: Lambda reports "No instances found"
**Solution**:
```bash
# Check instance tags
python tag_instances_boto3.py
# Choose option 5 to see tagged instances

# Re-tag if necessary
python tag_instances_boto3.py
# Choose option 2 to tag specific instances
```

#### 3. EventBridge Not Triggering
**Symptom**: Functions don't run on schedule
**Solution**:
- Check EventBridge rule is **Enabled**
- Verify cron expression is correct
- Check Lambda function permissions for EventBridge

#### 4. Email Notifications Not Working
**Symptom**: No emails received
**Solution**:
- Confirm SNS subscription in email
- Check spam folder
- Verify SNS topic ARN in Lambda environment variables

### Validation Commands

```bash
# Check AWS configuration
aws sts get-caller-identity
aws configure list

# List tagged instances
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=non-prod" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Test SNS topic
aws sns publish \
  --topic-arn "arn:aws:sns:us-east-1:YOUR-ACCOUNT-ID:ec2-cost-optimization-alerts" \
  --subject "Test Message" \
  --message "Testing SNS notifications"

# Check EventBridge rules
aws events list-rules --name-prefix "ec2-instances"

# View Lambda function configuration
aws lambda get-function --function-name start-ec2-instances
```

## Cost Optimization Results

After deployment, you should see:

### Weekly Runtime Comparison
- **Before**: 168 hours/week (24/7)
- **After**: 50 hours/week (10h × 5 days)
- **Reduction**: 118 hours/week (70% savings)

### Monthly Cost Impact
For 10 × t3.medium instances ($0.0416/hour):
- **Before**: 10 × $0.0416 × 720h = $299.52/month
- **After**: 10 × $0.0416 × 220h = $91.52/month
- **Savings**: $208/month = $2,496/year

### Monitoring Your Savings
1. Use **AWS Cost Explorer**
2. Filter by **EC2 service**
3. Group by **instance tags**
4. Compare costs month-over-month

---

**🎉 Congratulations!** Your EC2 Cost Optimization automation is now fully deployed and will start saving money immediately.
