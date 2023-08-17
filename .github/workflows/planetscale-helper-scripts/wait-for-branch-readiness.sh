function waitForBranchReadiness {
    local retries="${1}"
    local db="${2}"
    local branch="${3}"

    local count=0
    local wait=3

    echo "Checking if branch $branch is ready for use..."
    while true; do
        local raw_output=`pscaleImage branch list $db --format json "${PLANETSCALE_AUTH}"`
        if [ $? -ne 0 ]; then
            echo "Error: pscale branch list returned non-zero exit code $?: $raw_output"
            return 1
        fi
        local output=`echo $raw_output | jq ".[] | select(.name == \"$branch\") | .ready"`
        if [ "$output" == "false" ]; then
            count=$((count+1))
            if [ $count -ge $retries ]; then
                echo "Branch $branch is not ready after $retries retries. Exiting..."
                return 2
            fi
            echo "Branch $branch is not ready yet. Retrying in $wait seconds..."
            sleep $wait
        elif [ "$output" == "true" ]; then
            echo "Branch $branch is ready for use."
            return 0
        else
            echo "Branch $branch in unknown status: $raw_output"
            return 3
        fi
    done
}