#!/bin/bash

# deploy_aws.sh - A script to deploy to Amazon Web Services

# $AWS_DEPLOYMENT_GROUP
# $AWS_DEPLOYMENT_CONFIG_NAME


deployAws() {
    echo "Deploying to Amazon Web Services..."

    installAwsCli
    echo "Installing AWS CLI succeeded"

    # export PATH=~/.local/bin:$PATH

    # Configure and set AWS CLI options, port stderr to stdout 
    # http://docs.aws.amazon.com/cli/latest/reference/configure/set.html
    aws configure set aws_access_key_id $AWS_KEY
    aws configure set aws_secret_access_key $AWS_SECRET
    aws configure set default.region $AWS_REGION
  	echo "Successfully configured AWS deploy key, deploy secret and default region"

    # Create AWS Code Deploy Application if one doesn't exist
    aws deploy get-application --application-name $APPLICATION_NAME
    if [ $? -ne 0 ]; then
    	echo "Creating AWS Code Deploy Application..."
    	runCommand "aws deploy create-application --application-name $APPLICATION_NAME"
    	echo "Application creation succeded"
    fi


    # Create AWS Deploy group if one doesn't exist
    # aws iam get-role --role-name CodeDeployServiceRole --query "Role.Arn" --output text
    aws deploy get-deployment-group --application-name $APPLICATION_NAME --deployment-group-name $AWS_DEPLOYMENT_GROUP
    if [ $? -ne 0 ]; then
    	echo "Creating AWS Code Deploy Group..."

      if [ ! -n "$EC2_TAG_FILTERS" ]; then
        echo "Using existing EC2 instance..."
      else
        echo "Creating new EC2 instance..."

        aws ec2 run-instances \
          --image-id $AWS_EC2_AMI \
          --key-name $APPLICATION_NAME \
          --user-data file://aws/instance-setup.sh \
          --count 1 \
          --instance-type $EC2_INSTANCE_TYPE

        ec2InstanceId="$(aws ec2 describe-instances \
          --filters "Name=key-name,Values=$APPLICATION_NAME" \
          --query "Reservations[*].Instances[*].[InstanceId]" \
          --output text)"

        aws ec2 create-tags --resources $ec2InstanceId --tags Key=Name,Value=$APPLICATION_NAME

        echo "Instance Launched?"
        aws ec2 describe-instance-status --instance-ids $ec2InstanceId --query "InstanceStatuses[*].InstanceStatus.[Status]" --output text
      fi

    	runCommand "aws deploy create-deployment-group \
        --application-name $APPLICATION_NAME \
        --deployment-group-name $AWS_DEPLOYMENT_GROUP \
        --deployment-config-name CodeDeployDefault.AllAtOnce \
        --ec2-tag-filters $EC2_TAG_FILTERS \
        --service-role-arn $AWS_SERVICE_ROLE_ARN"
    	echo "Deploy Group creation succeded"
    fi


    # Create deployment and deploy app with default config
    # http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment.html
    latestCommitId="$(git rev-parse HEAD 2>&1)"

    DEPLOYMENT_ID="$(aws deploy create-deployment \
      --application-name $APPLICATION_NAME  \
      --deployment-group-name $AWS_DEPLOYMENT_GROUP \
      --github-location commitId=$latestCommitId,repository=$GIT_URL 2>&1)"
    if [ $? -ne 0 ]; then
  		echo "Deploy failed..."
    else
    	echo "Successfully created deployment"
    	echo "You can follow your deployment at: https://console.aws.amazon.com/codedeploy/home#/deployments/"
    fi

    DEPLOYMENT_GET="aws deploy get-deployment --deployment-id \"$DEPLOYMENT_ID\""
    echo "Monitoring deployment..."
    echo DEPLOYMENT_GET

}   # end of deployAws

runCommand() {
	command="$1"
	output="$(eval $command 2>&1)"
	ret_code=$?

	if [ $? != 0 ]; then
		echo "$output"
		exit $ret_code
	fi
}

typeExists() {
  if [ $(type -P $1) ]; then
  	return 0
  fi
  	return 1
}

installAwsCli() {
	if ! typeExists "pip"; then
		echo "Installing Python PIP..."
		runCommand "sudo apt-get install -y python-pip"
		echo "Installing PIP succeeded"
	fi
  
	echo "Installing AWS CLI..."
	runCommand "sudo pip install awscli"
}

##### Main

if [ -z "$APPLICATION_NAME" ]; then
  echo "Please set the \"\$APPLICATION_NAME\" variable"
  exit 1
fi

if [ -z "$AWS_KEY" ]; then
  echo "Please set the \"\$AWS_KEY\" variable"
  exit 1
fi

if [ -z "$AWS_SECRET" ]; then
  echo "Please set the \"\$AWS_SECRET\" variable"
  exit 1
fi

if [ -z "$AWS_REGION" ]; then
  echo "Please set the \"\$AWS_REGION\" variable"
  exit 1
fi

deployAws

