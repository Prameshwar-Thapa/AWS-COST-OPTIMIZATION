#!/bin/bash

# Test AWS Permissions for EC2 Cost Optimization
echo "=== AWS Permissions Test ==="

# Check AWS CLI configuration
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not installed"
    exit 1
fi

echo "✅ AWS CLI configured"

# Get account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
REGION=$(aws configure get region 2>/dev/null)
USER_ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)

if [ -z "$ACCOUNT_ID" ]; then
    echo "❌ AWS credentials not configured"
    exit 1
fi

echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"
echo "User: $USER_ARN"
echo ""

echo "Testing permissions..."

# Test EC2 permissions
echo -n "✅ EC2 describe-instances: "
if aws ec2 describe-instances --max-items 1 &>/dev/null; then
    echo "OK"
else
    echo "FAILED"
fi

echo -n "✅ EC2 start-instances: "
if aws iam simulate-principal-policy --policy-source-arn "$USER_ARN" --action-names ec2:StartInstances --resource-arns "*" --query 'EvaluationResults[0].EvalDecision' --output text 2>/dev/null | grep -q "allowed"; then
    echo "OK (permission exists)"
else
    echo "FAILED or cannot verify"
fi

echo -n "✅ EC2 stop-instances: "
if aws iam simulate-principal-policy --policy-source-arn "$USER_ARN" --action-names ec2:StopInstances --resource-arns "*" --query 'EvaluationResults[0].EvalDecision' --output text 2>/dev/null | grep -q "allowed"; then
    echo "OK (permission exists)"
else
    echo "FAILED or cannot verify"
fi

echo -n "✅ SNS list-topics: "
if aws sns list-topics &>/dev/null; then
    echo "OK"
else
    echo "FAILED"
fi

echo ""
echo "✅ Permission test complete"
