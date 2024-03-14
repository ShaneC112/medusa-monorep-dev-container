# Clone the initial medusa repository and install the required dependencies
git clone --filter=blob:none --sparse https://github.com/medusajs/medusa.git
cd medusa

git sparse-checkout add packages
git sparse-checkout add .yarn
git sparse-checkout add docs-util

yarn install
yarn build

# Install the medusa-cli and medusa-dev-cli globally
yarn set version classic

yarn global add @medusajs/medusa-cli
yarn global add medusa-dev-cli
export PATH="$(yarn global bin):$PATH"

medusa-dev --set-path-to-repo `pwd`

# create a backend
medusa new my-medusa-store --skip-db --skip-migrations --skip-env

cd my-medusa-store 
rm -rf package-lock.json
rm -rf node_modules
yarn install

# update the packages using medusa dev cli -s to scan once
medusa-dev -s
rm -rf src/node

# start redis & postgres
docker-compose up -d

# cp
cp ../../.platform/env.template .env
# run migrations
medusa migrations run

# create a user
medusa user --email admin@medusa-test.com --password supersecret

# copy the config
rm -rf medusa-config.js
cp ../../.platform/medusa-config.template medusa-config.js




