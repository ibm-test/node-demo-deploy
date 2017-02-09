#!/bin/bash

# deploy.sh - A script to deploy to various clouds

##### Constants

# $APPLICATION_NAME

# $AWS_KEY
# $AWS_SECRET
# $AWS_REGION

# $AZURE_USER
# $AZURE_PASS


##### Main Functions

deployBluemix() {
	echo "Deploying to IBM Bluemix..."

	cf push "$APPLICATION_NAME"

}	# end of deployBluemix

deployAzure() {
    echo "Deploying to Microsoft Azure..."

    installAzureCli
    echo "Installing Azure CLI succeeded"

    # https://docs.microsoft.com/en-us/azure/app-service-web/app-service-web-nodejs-get-started-cli-nodejs
    azure login -u $AZURE_USER -p $AZURE_PASS
    azure site deployment user set -u $AZURE_USER -p $AZURE_PASS
    echo "Successfully configured Azure user and pass"

    azure site create --git --location centralus $APPLICATION_NAME
	echo "Application creation succeded"

	git remote add azure https://$AZURE_USER:$AZURE_PASS@localgitdeployment.scm.azurewebsites.net:443/localgitdeployment.git
	git push azure master
	echo "Application deployed to Azure"

	azure site location list

}   # end of deployAzure

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
    $(aws deploy get-application --application-name $APPLICATION_NAME 2>&1)
    if [ $? -ne 0 ]; then
    	echo "Creating AWS Code Deploy Application"
    	runCommand "aws deploy create-application --application-name $APPLICATION_NAME"
    	echo "Application creation succeded"
    fi

    # Create deployment and deploy app with default config
    # http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment.html
    DEPLOYMENT_ID = "$(aws deploy create-deployment --application-name $APPLICATION_NAME)"
    echo "Success created deployment"
    echo "You can follow your deployment at: https://console.aws.amazon.com/codedeploy/home#/deployments/$DEPLOYMENT_ID"

}   # end of deployAws


##### Helper Functions

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
		echo "Installing Python PIP"
		runCommand "sudo apt-get install -y python-pip"
		echo "Installing PIP succeeded"
	fi
  
	echo "Installing AWS CLI"
	runCommand "sudo pip install awscli"
}

installAzureCli() {
	if ! typeExists "npm"; then
		runCommand "sudo apt-get install curl"
	fi

	if ! typeExists "npm"; then
    	echo "Installing Python PIP"
		curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
		runCommand "sudo apt-get install -y nodejs"
	fi

	echo "Installing AWS CLI"
	runCommand "sudo npm install azure-cli"
}


##### Main

if [ -z "$APPLICATION_NAME" ]; then
  echo "Please set the \"\$AWS_APPLICATION_NAME\" variable"
  exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
    	-bluemix | --microsoft-azure )
			deployBluemix
			exit
            ;;
        -azure | --microsoft-azure )
			deployAzure
			exit
            ;;
        -aws | --amazon-web-services )       
			deployAws
            exit
            ;;
        * )                     
			echo 'Error: Please select a cloud environnmet by running deploy.sh (-azure | -aws)'
            exit 1
    esac
    shift
done
