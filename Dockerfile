# Stage 1: Build the Application
FROM node:22 AS build

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./
COPY tsconfig*.json ./

# Install all dependencies (including devDependencies for building)
# Using 'npm ci' is faster and more reliable if you have a lockfile,
# otherwise it falls back to install.
RUN npm install

# Copy source code
COPY . .

# Build the TypeScript code
RUN npm run build

# Stage 2: Production Runner
FROM node:22-slim

WORKDIR /usr/src/app

# Copy package.json to install production dependencies
COPY --from=build /usr/src/app/package*.json ./

# Install ONLY production dependencies to keep image small
RUN npm install --only=production

# Copy the built application from the 'build' stage
# NOTE: Ensure your tsconfig outputs to 'dist'.
# If your app crashes saying "cannot find module", check if the path below
# matches your actual build structure (e.g. dist/index.js vs dist/src/index.js)
COPY --from=build /usr/src/app/dist ./dist

# CRITICAL FIX: Matches fly.toml internal_port = 3000
ENV PORT=3000
EXPOSE 3000

# Use non-root user for security
USER node

# Start the application
CMD [ "node", "dist/src/index.js" ]
