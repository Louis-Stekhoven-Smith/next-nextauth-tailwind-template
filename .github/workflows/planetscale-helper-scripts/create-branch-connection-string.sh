function createBranchConnectionString {
    local DB_NAME=$1
    local BRANCH_NAME=$2
    local CRED_NAME=$3

    local raw_output=`pscaleImage password list "$DB_NAME" "$BRANCH_NAME" --format json "${PLANETSCALE_AUTH}"`
    if [ $? -ne 0 ]; then
        echo "Error: pscale password list returned non-zero exit code $?: $raw_output"
        exit 1
    fi

    # At the time of writing the only way to programmatically get the username and password for a database is
    # to create a new one password. After its created you can not get it again, thus we delete and recreate the
    # credential. We could store the connection string in CI and read as an environment variable but this
    # would mean that anytime we create a new branch or delete and recreate a branch someone will manually
    # have to go and update that string.
    CRED_ID=`jq -nr --argjson data "${raw_output}" '$data[] | select(.name == "'"${CRED_NAME}"'") | .id '`
    if [[ -n "${CRED_ID}" ]]; then
        pscaleImage password delete --force "$DB_NAME" "$BRANCH_NAME" "${CRED_ID}" "${PLANETSCALE_AUTH}"
        if [ $? -ne 0 ]; then
            echo "Error: pscale password delete returned non-zero exit code $?"
            exit 1
        fi
    fi


    # get id and token from environment vars
    echo "Creating new connection string"
    local raw_output=`pscaleImage password create "$DB_NAME" "$BRANCH_NAME" "$CRED_NAME" --format json "${PLANETSCALE_AUTH}"`
    if [ $? -ne 0 ]; then
        echo "Failed to create credentials for database $DB_NAME branch $BRANCH_NAME: $raw_output"
        exit 1
    fi

    username=`jq -nr --argjson data "${raw_output}" '$data.username'`
    password=`jq -nr --argjson data "${raw_output}" '$data.plain_text'`
    database=`jq -nr --argjson data "${raw_output}" '$data.database_branch.access_host_url'`
    DATABASE_URL="mysql://${username}:${password}@${database}/${DB_NAME}?sslaccept=strict&connect_timeout=100&connection_limit=200&pool_timeout=100"
    export DATABASE_URL
}