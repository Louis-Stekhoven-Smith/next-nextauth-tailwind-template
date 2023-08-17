function waitForDeployRequestState {
    local retries=$1
    local db=$2
    local branch=$3
    local number=$4
    local waitForState=$5

    local count=0
    local wait=10

    echo "Checking if deploy request $number is ${waitForState}."
    while true; do
        local raw_output=`pscaleImage deploy-request list "$db" --format json "${PLANETSCALE_AUTH}"`
        if [ $? -ne 0 ]; then
            echo "Error: pscale deploy-request list returned non-zero exit code $?: $raw_output"
            return 1
        fi
        local currentStatus=`echo $raw_output | jq ".[] | select(.number == $number) | .deployment.state"`
        local deployable=`echo $raw_output | jq ".[] | select(.number == $number) | .deployment.deployable"`

        if [ "$currentStatus" == '"error"' ]; then
          local deploymentDetails=`echo $raw_output | jq ".[] | select(.number == $number)"`
          echo "Database migration failed: $deploymentDetails"
          return 2
        fi

        if [ "$currentStatus" != "\"${waitForState}\"" ] || [ "${deployable}" = false ]; then
            count=$((count+1))
            if [ $count -ge $retries ]; then
                echo "Deploy request $number is either not ${waitForState} or deployable after $retries retries. Exiting..."
                echo "Current status: ${currentStatus} deployable: ${deployable}"
                return 2
            fi
            echo "Deploy-request $number is not ${waitForState} yet. Current status: ${currentStatus} deployable: ${deployable}"
            echo "Retrying in $wait seconds..."
            sleep $wait
        else
            echo  "Deploy-request $number is ${waitForState}"
            return 0
        fi
    done
}