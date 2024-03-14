# SAMPLE EXAMPLE OF Medusa dev in dev-container

# get the medusa develop branch and create a new backend project
# which uses the medusa-dev cli to link the packages

# either follow the steps below 
# clone this repo
# uncomment the postCreateCommand in .devcontainer/devcontainer.json
# and rebuild the dev container the script will run on rebuild

# Create a new dev container in VS Code. Add Node & Typescript, Docker-in-Docker and npm
of paste this as the image & features into .devcontainer/devcontainer.json

	"image": "mcr.microsoft.com/devcontainers/typescript-node:1-20-bullseye",
	"features": {
		"ghcr.io/devcontainers/features/azure-cli:1": {},
		"ghcr.io/devcontainers/features/docker-in-docker:2": {},
		"ghcr.io/devcontainers/features/github-cli:1": {},
		"ghcr.io/devcontainers-contrib/features/typescript:2": {}
	}

# clone the packages folder from the repo as this is all we should need
git clone https://github.com/medusajs/medusa.git
cd medusa
yarn install
yarn build

# OR this is better only clone the packages and the minimum other folders required
git clone --filter=blob:none --sparse https://github.com/medusajs/medusa.git
cd medusa

git sparse-checkout add packages
git sparse-checkout add .yarn
git sparse-checkout add docs-util
(Note docs-util is required as the OAS package builds files here and will fail if missing, you can checkout only the packages you want and you may not need the docs-util folder)

yarn install
yarn build


# do bits to set up cli's (need to be on classic for yarn global to work)
(Note: ensure yarn install & build done before switching to classic. Some packages fail to build if the build is done after switching to classic!)
yarn set version classic

yarn global add @medusajs/medusa-cli
yarn global add medusa-dev-cli
export PATH="$(yarn global bin):$PATH"

medusa-dev --set-path-to-repo `pwd`

# create new backend project. This will use the devlope packages from the yarn workspace
(Note this needs to be within the "medusa" folder which is the yarn workspace root)

medusa new my-medusa-store --skip-db --skip-migrations --skip-env

(Note initially this will use npm. there is no option on create-react-app create the project without installing dependencies.)

cd my-medusa-store 
(or whatever you called it)
rm -rf package-lock.json
yarn install

medusa-dev -s
(note this leaves a node folder which will cause npm run dev or buidl to fail to fail. It needs to be removed)
rm -rf src/node

# packages on my-medusa-dev should look like
  "dependencies": {
    "@medusajs/admin": "7.1.11-dev-1710442525218",
    "@medusajs/cache-inmemory": "1.8.10-dev-1710442525218",
    "@medusajs/cache-redis": "1.9.0-dev-1710442525218",
    "@medusajs/event-bus-local": "1.9.8-dev-1710442525218",
    "@medusajs/event-bus-redis": "1.8.11-dev-1710442525218",
    "@medusajs/file-local": "^1.0.3",
    ....
  }

# set up postgres and redis in docker
create a docker-compose.yaml in the project root with the following
# paste this
version: '3'
services:

  redis:
    hostname: redis
    container_name: redis
    image: redis/redis-stack:latest
    restart: unless-stopped
    environment:
      REDIS_ARGS: "--requirepass redis"
    expose:
      - 6379
      - 8001
    ports:
      - 6379:6379
      - 8001:8001
    networks:
      myInternal:
        ipv4_address: 172.28.5.2
        aliases:
          - redis

  postgres:
    hostname: postgres
    container_name: postgres
    image: postgres:latest
    restart: unless-stopped
    shm_size: 128mb
    expose:
      - 5432
    ports:
      - 5432:5432
    environment:
      POSTGRES_PASSWORD: postgres
    networks:
      myInternal:
        ipv4_address: 172.28.5.3
        aliases:
          - postgres

networks:
  myInternal:
    ipam:
      driver: default
      config:
        - subnet: 172.28.0.0/16
          ip_range: 172.28.5.0/24
          gateway: 172.28.5.254

# end paste

(start up redis and postgres)
docker-compose up -d

(add a .env for my-medusa-store)
# start paste
DATABASE_TYPE = "postgres"
DATABASE_URL = postgresql://postgres:postgres@172.28.5.3:5432/postgres?sslmode=disable
DATABASE_SCHEMA = medusa
REDIS_URL = redis://:redis@172.28.5.2:6379
ENVIRONMENT = development
# end paste

# run migrations
(from the my-medusa-store)
medusa migrations run

# create a user
medusa user --email admin@medusa-test.com --password supersecret

# enable redis in medusa config
(update medusa-config.js)
(uncomment modules and REDIS_URL)


# customisations on the admin-ui package will now be reflected
(quick test if amdin changes go through)
edit medusa/packages/admin-ui/ui/src/domain/settings/index.tsx
change line 131 to <h2 className="inter-xlarge-semibold">General (Custom)</h2>
(yarn build on the admin-ui project)

(in my-medusa-store )
medusa-dev -s
rm -rf src/node

npm run dev 
(login with username and password above. The Settings page should have a different header)





