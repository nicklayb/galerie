# STEP 1 - Build release compiler container
FROM elixir:1.16-slim AS builder

ENV APP_NAME=galerie \
    APP_VERSION=0.1.0 \
    MIX_ENV=prod

# Install build requirements
RUN apt update && \
    apt upgrade && \
    apt install -y \
            libssl-dev \
            make \
            build-essential \
            gcc \
            git \
            nodejs \
            npm 


WORKDIR /galerie

RUN mix local.rebar --force && \
    mix local.hex --force

# Compile dependencies and application
COPY . .
RUN mix deps.get --only ${MIX_ENV}
RUN mix compile

RUN cd assets && npm ci
RUN mix assets.deploy

# Create a release
RUN mkdir -p /opt/build && \
    mix release && \
    cp -r _build/${MIX_ENV}/rel /opt/build

# FROM nboisvert/dcraw:latest as dcraw

# STEP 2 - Build application container
FROM ubuntu:24.10

ARG APP_NAME
ENV APP_NAME=${APP_NAME}

ENV ROOT_FOLDER=/opt

WORKDIR ${ROOT_FOLDER}

# Update kernel and install runtime dependencies
RUN apt update && \
    apt upgrade && \
    apt install -y bash openssl wget \
            build-essential \
            gcc \
            imagemagick \
            exiftool \
            dcraw

# Copy the OTP binary from the build step
COPY --from=builder /opt/build .
# COPY --from=dcraw /opt/dcraw/bin/dcraw/ /opt/bin/dcraw

ENV PATH="/opt/bin/:${PATH}"

RUN ls .

COPY dockerfiles/entrypoint.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/entrypoint.sh
RUN mkdir ${ROOT_FOLDER}/logs

# Create a non-root user
RUN useradd galerie && \
    chown -R galerie: ${ROOT_FOLDER}

USER galerie

ENTRYPOINT ["entrypoint.sh"]
CMD ["start"]
