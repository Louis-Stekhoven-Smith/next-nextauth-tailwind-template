#/bin/bash
set -e
. ./.github/workflows/planetscale-helper-scripts/pscale-image.sh
. ./.github/workflows/planetscale-helper-scripts/create-branch-connection-string.sh
. ./.github/workflows/planetscale-helper-scripts/wait-for-branch-readiness.sh
. ./.github/workflows/planetscale-helper-scripts/wait-for-deploy-request-state.sh

ORG_NAME='seen-culture'
DATABASE_NAME='seen-culture-app'
RELEASE_DB_BRANCH='release'
RELEASE_DB="${DATABASE_NAME} ${RELEASE_DB_BRANCH}"
export PLANETSCALE_AUTH="--org ${ORG_NAME} --service-token ${PLANETSCALE_SERVICE_TOKEN}  --service-token-id ${PLANETSCALE_SERVICE_TOKEN_ID}"

cleanUp() {
  pscaleImage branch delete "${RELEASE_DB}" --force "${PLANETSCALE_AUTH}"
}

pscaleImage branch create "${RELEASE_DB}" --from production "${PLANETSCALE_AUTH}"
trap "cleanUp" EXIT

createBranchConnectionString ${DATABASE_NAME} ${RELEASE_DB_BRANCH} ci-pipeline
waitForBranchReadiness 20 ${DATABASE_NAME} ${RELEASE_DB_BRANCH}

prismaResult=`npx prisma db push --skip-generate`

if [[ "${prismaResult}" == *"The database is already in sync"* ]]; then
  echo "${prismaResult}"
  echo "############ No schema changes detected. Skipping database migration ############"
else
  echo "${prismaResult}"
  echo "############ Deploying schema changes to production database ############"
  request=`pscaleImage deploy-request create "${RELEASE_DB}" --into production --format json "${PLANETSCALE_AUTH}"`
  requestNumber=`echo "${request}" | jq .number`
  pscaleImage deploy-request review "${DATABASE_NAME}" "${requestNumber}" --approve --comment "approved-by-CI" "${PLANETSCALE_AUTH}"

  waitForDeployRequestState 20 ${DATABASE_NAME} ${RELEASE_DB_BRANCH} "${requestNumber}" ready

  deployRequests=`pscaleImage deploy-request list "${DATABASE_NAME}" --format json "${PLANETSCALE_AUTH}"`
  echo "${deployRequests}" | jq ".[] | select(.number == ${requestNumber})"

  pscaleImage deploy-request deploy "${DATABASE_NAME}" "${requestNumber}" --wait "${PLANETSCALE_AUTH}"
  # waiting for deploy to finish before running cleanUp
  waitForDeployRequestState 30 ${DATABASE_NAME} ${RELEASE_DB_BRANCH} "${requestNumber}" complete
fi

vercel pull --environment=production --token "${VERCEL_TOKEN}"
cp .vercel/.env.production.local .env # Coping so "vercel build" can test config is valid
vercel build --prod --token "${VERCEL_TOKEN}"
vercel deploy --prebuilt --prod --token "${VERCEL_TOKEN}"

# TODO figure out how to add meta data to identify production deployments so we can automatically clean up old ones
#echo "Removing previous deployment"
#PREVIOUS_DEPLOYMENT=1
#vercel list --meta githubCommitRef=<SOME_META_VALUE> --token "${VERCEL_TOKEN}" &> deployment-list.txt
#rawUrls=$(cat ./deployment-list.txt | grep -Eo 'https://\S+' | sed -e 's/^//' -e 's/$//' | tr '\n' ',' | sed 's/,$//')
#IFS=',' read -r -a urls <<< "${rawUrls}"
#
#vercel remove "${urls[PREVIOUS_DEPLOYMENT]}" --yes --scope "${ORG_NAME}" --token "${VERCEL_TOKEN}"