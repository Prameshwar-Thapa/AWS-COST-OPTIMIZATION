# Architecture Documentation

This document explains the architecture diagrams for the AWS EC2 Cost Optimization project.

## 📊 Architecture Diagrams Overview

The project includes four comprehensive architecture diagrams that illustrate different aspects of the system:

1. **Main Architecture Diagram** - Overall system components and relationships
2. **Technical Flow Diagram** - Detailed boto3 automation process
3. **Cost Savings Diagram** - Before/after cost impact visualization
4. **Deployment Options Diagram** - Different deployment methods

## 🏗️ Main Architecture Diagram

![Architecture Diagram](generated-diagrams/architecture_diagram.png)

### Components Explained:

#### **External Triggers**
- **DevOps Engineer**: Human operator who deploys and manages the system
- **EventBridge Scheduler**: Time-based triggers for automation

#### **Serverless Automation**
- **Start Instances Lambda**: Executes boto3 code to start stopped instances
- **Stop Instances Lambda**: Executes boto3 code to stop running instances

#### **AWS Services**
- **EC2 Instances (Tagged)**: Target instances with `Environment=non-prod` and `AutoStop=true`
- **SNS Topic**: Handles email notifications for all operations
- **CloudWatch Logs**: Captures execution logs and error details

#### **Infrastructure**
- **Terraform IaC**: Infrastructure as Code for automated deployment
- **IAM Roles & Policies**: Secure permissions for Lambda execution

#### **Monitoring**
- **CloudWatch Alarms**: Monitors Lambda function errors and performance
- **Email Notifications**: Sends detailed operation reports to stakeholders

#### **Cost Management**
- **Cost Explorer**: Tracks actual savings and cost trends
- **AWS Budgets**: Sets up alerts for cost thresholds

### Data Flow:
1. DevOps Engineer deploys infrastructure using Terraform
2. EventBridge triggers Lambda functions on schedule
3. Lambda functions manage EC2 instances using boto3
4. All operations are logged and notifications sent
5. Cost data flows to monitoring and budgeting tools

## ⚡ Technical Flow Diagram

![Technical Flow Diagram](generated-diagrams/technical_flow_diagram.png)

### Boto3 Automation Process:

#### **Scheduling Logic**
- **8 AM Weekdays**: Triggers start_instances.py
- **6 PM Weekdays**: Triggers stop_instances.py  
- **Weekends**: Keeps instances stopped (triggers stop function)

#### **Boto3 Implementation**
```python
# Core boto3 logic used in Lambda functions
ec2_client = boto3.client('ec2')

# Filter instances by tags
filters = [
    {'Name': 'tag:Environment', 'Values': ['non-prod']},
    {'Name': 'tag:AutoStop', 'Values': ['true']},
    {'Name': 'instance-state-name', 'Values': ['stopped']}  # or 'running'
]

# Get matching instances
response = ec2_client.describe_instances(Filters=filters)

# Start or stop instances
ec2_client.start_instances(InstanceIds=instance_ids)
# or
ec2_client.stop_instances(InstanceIds=instance_ids)
```

#### **State Management**
- **Stopped Instances**: Target for start operations
- **Running Instances**: Target for stop operations
- **State Transitions**: Instances move between stopped ↔ running states

#### **Monitoring & Notifications**
- **SNS Topic**: Sends detailed success/error notifications
- **Email Alerts**: Include instance details and operation status
- **CloudWatch Logs**: Capture execution details and error tracking

#### **Cost Impact Tracking**
- **Cost Explorer**: Monitors the 40% cost reduction achieved
- **Savings Calculation**: Tracks 168h → 50h weekly runtime reduction

## 💰 Cost Savings Diagram

![Cost Savings Diagram](generated-diagrams/cost_savings_diagram.png)

### Before vs After Comparison:

#### **Before Automation (24/7 Operation)**
- **Monday through Sunday**: Each day runs 24 hours
- **Weekly Total**: 168 hours of runtime
- **Example Cost**: $69.89/week for 10 × t3.medium instances
- **Annual Cost**: $3,634 for continuous operation

#### **After Automation (Smart Schedule)**
- **Monday-Friday**: 10 hours each (8 AM - 6 PM UTC)
- **Saturday-Sunday**: Completely stopped (0 hours)
- **Weekly Total**: 50 hours of runtime
- **Example Cost**: $20.80/week for 10 × t3.medium instances
- **Annual Cost**: $1,082 with automation

#### **Savings Analysis**
- **Runtime Reduction**: 118 hours/week (70% less)
- **Cost Reduction**: $49.09/week (40% savings)
- **Annual Savings**: $2,552/year per 10 instances
- **ROI**: Infrastructure cost ~$26/year, savings $2,552/year = 9,800% ROI

#### **Scalability**
- Savings scale linearly with number of instances
- Larger instance types (e.g., m5.large, c5.xlarge) provide proportionally higher savings
- Multi-account deployments multiply savings across organization

## 🚀 Deployment Options Diagram

![Deployment Options Diagram](generated-diagrams/deployment_options_diagram.png)

### Three Deployment Paths:

#### **Option 1: Local Testing**
- **ec2_automation.py**: Main boto3 script for immediate testing
- **tag_instances_boto3.py**: Tool for tagging instances
- **test_permissions.sh**: AWS CLI permission validation
- **Use Case**: Development, testing, immediate manual operations

#### **Option 2: Manual AWS Console Deployment**
- **AWS Console**: Step-by-step manual setup
- **Manual Components**: IAM roles, Lambda functions, EventBridge rules, SNS topics
- **Process**: Follow detailed guide in `aws_console.md`
- **Use Case**: Learning, small deployments, full control over setup

#### **Option 3: Terraform Infrastructure as Code**
- **Terraform Configuration**: Automated infrastructure deployment
- **terraform/*.tf Files**: Complete infrastructure definition
- **Automated Deployment**: Single command deployment
- **Use Case**: Production deployments, CI/CD integration, repeatable infrastructure

### Target Infrastructure:
All deployment options create the same final infrastructure:
- **Lambda Functions**: start/stop automation
- **EventBridge Rules**: Scheduling automation
- **SNS Notifications**: Alert system
- **IAM Roles**: Security permissions
- **Target EC2 Instances**: Tagged instances for management

## 🎯 Architecture Benefits

### **Serverless Design**
- **No Infrastructure Management**: Lambda handles scaling automatically
- **Cost Effective**: Pay only for execution time
- **High Availability**: AWS manages redundancy and failover

### **Event-Driven Architecture**
- **Decoupled Components**: Each service operates independently
- **Scalable**: Can handle any number of instances
- **Reliable**: Built-in retry and error handling

### **Tag-Based Targeting**
- **Flexible**: Easy to add/remove instances from automation
- **Safe**: Prevents accidental impact on production resources
- **Granular**: Different automation rules for different environments

### **Comprehensive Monitoring**
- **Visibility**: Full logging and notification system
- **Alerting**: Immediate notification of issues
- **Tracking**: Cost savings measurement and reporting

### **Multiple Deployment Options**
- **Flexibility**: Choose deployment method based on needs
- **Learning Path**: Start with local testing, progress to full automation
- **Production Ready**: Terraform provides enterprise-grade deployment

## 📈 Scaling Considerations

### **Multi-Environment Support**
- Deploy separate stacks for dev, test, staging environments
- Different schedules per environment
- Centralized monitoring across all environments

### **Multi-Account Architecture**
- Cross-account IAM roles for organization-wide automation
- Centralized logging and monitoring
- Account-specific cost tracking

### **Advanced Scheduling**
- Holiday calendar integration
- Team-specific schedules
- Workload-based intelligent scheduling

### **Extended Service Support**
- RDS instance automation
- ECS/Fargate service scaling
- Auto Scaling Group management
- EBS snapshot lifecycle management

---

These architecture diagrams provide a comprehensive view of the AWS EC2 Cost Optimization system, from high-level architecture to detailed technical implementation and cost impact analysis.
