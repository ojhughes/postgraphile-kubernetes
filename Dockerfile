
# Global args, set before the first FROM, shared by all stages
ARG NODE_ENV="production"

################################################################################
# Build stage 1 - `yarn build`

FROM node:12-alpine as builder
# Import our shared args
ARG NODE_ENV

# Cache node_modules for as long as possible
COPY package.json yarn.lock /app/
WORKDIR /app/
RUN yarn install --frozen-lockfile --production=false --no-progress

# Copy over the server source code
COPY server/ /app/server/

# Finally run the build script
RUN yarn run build

################################################################################
# Build stage 2 - COPY the relevant things (multiple steps)

FROM node:12-alpine as clean
# Import our shared args
ARG NODE_ENV

# Copy over selectively just the tings we need, try and avoid the rest
COPY --from=builder /app/package.json /app/yarn.lock /app/
COPY --from=builder /app/server/dist/ /app/server/dist/

################################################################################
# Build stage FINAL - COPY everything, once, and then do a clean `yarn install`

FROM node:12-alpine
# Import our shared args
ARG NODE_ENV

EXPOSE 5000
WORKDIR /app/
# Copy everything from stage 2, it's already been filtered
COPY --from=clean /app/ /app/

# Install yarn ASAP because it's the slowest
RUN yarn install --frozen-lockfile --production=true --no-progress

LABEL description="My PostGraphile-powered server"

# You might want to disable GRAPHILE_TURBO if you have issues
ENV GRAPHILE_TURBO=1
ENV NODE_ENV=$NODE_ENV
ENTRYPOINT yarn start
