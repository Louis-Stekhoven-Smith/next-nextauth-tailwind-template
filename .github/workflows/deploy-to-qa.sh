#/bin/bash
set -e
. ./.github/workflows/planetscale-helper-scripts/pscale-image.sh
. ./.github/workflows/planetscale-helper-scripts/create-branch-connection-string.sh
. ./.github/workflows/planetscale-helper-scripts/wait-for-branch-readiness.sh

ORG_NAME='<replace with planetscale org name>'
DATABASE_NAME='<replace with planetscale database name>'
DEV_BRANCH='main'
DEV_DB="${DATABASE_NAME} ${DEV_BRANCH}"
export PLANETSCALE_AUTH="--org ${ORG_NAME} --service-token ${PLANETSCALE_SERVICE_TOKEN}  --service-token-id ${PLANETSCALE_SERVICE_TOKEN_ID}"


# This nukes and rebuilds the QA database with every run
# to make sure we can rebuild the database from scratch
# and reduce overhead of testing breaking schema changes
# If you want to persist data between runs you will need to build
# another process to nuke and reset the QA database outside of the normal
# ci workflow
# TODO make idempotent by checking if branch exists first before trying to delete
pscaleImage branch delete "${DEV_DB}" --force "${PLANETSCALE_AUTH}"
pscaleImage branch create "${DEV_DB}" --from production "${PLANETSCALE_AUTH}"

createBranchConnectionString ${DATABASE_NAME} ${DEV_BRANCH} ci-pipeline
waitForBranchReadiness 20 ${DATABASE_NAME} ${DEV_BRANCH}

pscaleImage branch list "${DATABASE_NAME}" --format json "${PLANETSCALE_AUTH}"

echo "Seeding init database data"
npm run db:setup


vercel pull --environment=development --token "${VERCEL_TOKEN}"
cp .vercel/.env.development.local .env # Coping so "vercel build" can test config is valid
vercel build --token "${VERCEL_TOKEN}"
vercel deploy --prebuilt --token "${VERCEL_TOKEN}" #> domain.txt
#vercel alias `cat domain.txt` '<replace with qa domain>' --yes --scope "${ORG_NAME}" --token "${VERCEL_TOKEN}"

echo "\nRemoving previous deployment"
PREVIOUS_DEPLOYMENT=1
vercel list --meta githubCommitRef=${DEV_BRANCH} --token "${VERCEL_TOKEN}" &> deployment-list.txt
rawUrls=$(cat ./deployment-list.txt | grep -Eo 'https://\S+' | sed -e 's/^//' -e 's/$//' | tr '\n' ',' | sed 's/,$//')
IFS=',' read -r -a urls <<< "${rawUrls}"

vercel remove "${urls[PREVIOUS_DEPLOYMENT]}" --yes --scope "${ORG_NAME}" --token "${VERCEL_TOKEN}"
