# IMPORTANT! Before running this build, do the following:
#   # The dockerignore actually ignores plugin sources and other goodies (why?!)
#   find . -name .dockerignore -type f -delete
#   # Remove all the local node_modules to avoid copying all that stuff.
#   find . -name node_modules -type d -exec rm -rf {} +
#
# Run this from the top-level directory (not from a workspace). There's some top-level files
# that are required.
#
# Current state: This is currently failing in the package-dynamic-plugins command because podman
# is not installed... There must be another way to achieve this with a FROM scratch build...
FROM registry.redhat.io/ubi9/nodejs-20:latest

WORKDIR /plugin-workspace

USER root

# The recommended way of using yarn is via corepack. However, corepack is not included in the UBI
# image. Below we install corepack so we can install yarn.
# https://github.com/nodejs/corepack?tab=readme-ov-file#default-installs

# TODO: It looks like some of the top-level files, maybe package.json and yarn.lock, are required
# for making the build work. Consider making this COPY statement a little more selective.
COPY . .

RUN find -name node_modules -type d -exec rm -rf {} +

RUN \
    cd workspaces/redhat-argocd && \
    node --version && \
    npm install -g corepack && \
    corepack --version && \
    corepack enable yarn && \
    corepack use 'yarn@4' && \
    yarn --version && \
    yarn install --immutable && \
    echo 'YOLO' && \
    yarn tsc

RUN \
    cd workspaces/redhat-argocd/plugins/argocd-backend && \
    npx @janus-idp/cli@latest package export-dynamic-plugin

RUN \
    cd workspaces/redhat-argocd/plugins/argocd && \
    npx @janus-idp/cli@latest package export-dynamic-plugin

RUN \
    cd workspaces/redhat-argocd && \
    npx @janus-idp/cli@latest package package-dynamic-plugins --tag local
# RUN \
#     # cd workspace/redhat-arogcd && \
#     node --version && \
#     npm install -g corepack && \
#     # npm install -g yarn && \
#     corepack --version && \
#     corepack enable yarn && \
#     corepack use 'yarn@4.6.0' && \
#     yarn --version && \
#     yarn install --immutable && \
#     yarn tsc

# RUN \
#     ls -la . && \
#     cd plugins/argocd-backend && \
#     npx @janus-idp/cli@latest package export-dynamic-plugin
