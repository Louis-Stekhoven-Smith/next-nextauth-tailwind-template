# <NAME>

high level description
sub domain description

# Check out the latest docs
`<project-root>/decision-register`

## Tech Stack

Refer to the respective docs for more information

- [Next.js](https://nextjs.org) - application framework
- [NextAuth.js](https://next-auth.js.org) - handles cookies and token lifecycle
- [Tailwind CSS](https://tailwindcss.com) - CSS framework
- [tRPC](https://trpc.io) - type safe api endpoints
- [ESLint](https://eslint.org/) - linter
- [Prettier](https://prettier.io/) - An opinionated code formatter
- [Typescript](https://www.typescriptlang.org/) - programming language
- [Jest](https://jestjs.io/) - testing framework
- [Vercel](https://vercel.com/docs) - deployment platform
- [github actions](https://docs.github.com/en/actions) - CI pipeline
- [Mountebank](http://www.mbtest.org/) - used to fake 3rd party services to enable integrations and air gaped local dev
- [husky](https://typicode.github.io/husky/) - git hooks
- [Prisma](https://prisma.io) - ORM


## Getting Started

### Prerequisites

* Install the latest LTS version of node
```bash 
brew install nvm
nvm install --lts
```

### Accounts
You will need to get access to the following accounts
* Github repo - <git repot>
* Vercel - <vercel url>


### Deployments

* QA - <add url>
* DEMO - <add url>
* Prod - <add url>

### Local dev setup

1. Copy environment variables and install dependencies

```bash
cp .env.example .env && npm install
```

2. Start mysql database
   ```docker-compose up --build```

   Note: This will automatically seed QA data from the seed.ts file.
   Make sure to include `--build` if you want to apply changes you have made to the seed files


3. Start the application
```npm run dev```

### Running tests
- unit tests: ```npm run unit:test```
- integration tests: ```npm run integration:test```
    - 3rd party integrations are faked by mountebank

### Manual testing

Accounts used for testing
* <role/auth type> login - username:password

## Git and CI/CD

##### Git Conventions
* Branch names - should be the ticket number e.g <NAME>-<number>
* Commit structure - ticket number, short descriptions and lower case. e.g `<COMPANY/TEAM>-100 add forgot password endpoint`
* Always rebase with main before merging your PR
* Keep commits focused and atomic
* Always rebase with main before merging your PR - keep git history linear

##### Git Workflow
The project follows the trunk with release branches workflow.

This workflow looks like the following
1. Cut story branch from main
2. Make changes, commit and push branch
3. .husky/pre-push will run linting and tests on git push
4. CI runs linting and tests on your branch
5. Raise PR and merge to main
6. CI runs linting and tests on main, then builds and deploys main to QA

For more details on the process of trunk with release branches read this documentation
https://trunkbaseddevelopment.com/

### CI credentials
The following credentials are stored in github actions.
To create/update tokens check out:
* https://vercel.com/guides/how-do-i-use-a-vercel-api-access-token
* https://planetscale.com/docs/concepts/service-tokens

      PLANETSCALE_SERVICE_TOKEN
      PLANETSCALE_SERVICE_TOKEN_ID
      VERCEL_TOKEN
      VERCEL_ORG_ID
      VERCEL_PROJECT_ID

## Releases and hot fixes

### Release
1. Checkout to the main branch and run the ./release script. This will
   create a branch with `release/$(date '+%Y-%m-%d')`
    ```bash
    ./release.sh
    ```
3. Verify deployment has succeeded on github <repo-url>/actions

Deployments will run on any branch that starts with `release/`

Actual release versions should be the git sha.

### Hot fix

Follow the normal development process for your fix and then cherry-pick
the change to release

1. Cut story branch from main
2. Fix bug and verify in your local before pushing your branch
3. Raise PR and merge bug fix to main
4. CI runs linting and tests, then builds and deploys main to QA
5. Verify bug has been fixed in QA
6. Cherry-pick changes to the relevant release branch
    ```bash
   git checkout release/<date> && git cherry-pick <sha>
    ```
7. Push changes to kick of deployment
8. Verify bug has been fixed in demo instance


### Database management
#### Updating database schema in local

If you add new tables or change the schema for the db run

```bash
 prisma generate
```

#### Resetting database data

The data will be cached in a docker volume. If you want to restart the database from scratch run
```bash 
docker rm -f seen-culture-app-dev-database-1 && docker volume prune -f && docker-compose up --build
```

#### Rebuild database from scratch

```bash 
docker rm -f <replace with database container name> && docker volume prune -y && docker-compose up --build 
```

# TODO we really should replace the mysql image with the vitess image  
##### Edge case sql query failures in QA
* In prod the database runs on planetscale which runs on top of mysql, in local we are using just mysql
  there are some edge cases where certain sql commands will work locally but not in QA. To better reflect these
  issues in local you can change the local dev setup to use
  https://vitess.io/docs/16.0/get-started/vttestserver-docker-image/
  Here is an example setup https://github.com/prisma/prisma/blob/main/docker/docker-compose.yml#L33-L53


