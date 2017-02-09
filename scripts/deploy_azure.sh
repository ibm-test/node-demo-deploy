#!/bin/bash

# deploy_azure.sh - A script to deploy to Microsoft Azure

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

if [ -z "$AZURE_USER" ]; then
  echo "Please set the \"\$AZURE_USER\" variable"
  exit 1
fi

if [ -z "$AZURE_PASS" ]; then
  echo "Please set the \"\$AZURE_PASS\" variable"
  exit 1
fi

deployAzure

