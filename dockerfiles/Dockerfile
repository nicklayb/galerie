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
            exiftool \
            dcraw \
            inotify-tools \
            libjpeg-dev \
            libtiff-dev


# Install ImageMagic 7
ENV IMAGEMAGICK_VERSION=7.1.0-31

RUN apt-get update && apt-get install -y wget && \
    apt-get install -y autoconf pkg-config

RUN apt-get update && apt-get install -y wget && \
    apt-get install -y build-essential curl libpng-dev && \
    wget https://github.com/ImageMagick/ImageMagick/archive/refs/tags/$IMAGEMAGICK_VERSION.tar.gz && \
    tar xzf $IMAGEMAGICK_VERSION.tar.gz && \
    rm $IMAGEMAGICK_VERSION.tar.gz && \
    apt-get clean && \
    apt-get autoremove

RUN sh ./ImageMagick-$IMAGEMAGICK_VERSION/configure --prefix=/usr/local --with-bzlib=yes --with-fontconfig=yes --with-freetype=yes --with-gslib=yes --with-gvc=yes --with-jpeg=yes --with-jp2=yes --with-png=yes --with-tiff=yes --with-xml=yes --with-gs-font-dir=yes && \
    make -j && make install && ldconfig /usr/local/lib/


# Copy the OTP binary from the build step
COPY --from=builder /opt/build .
# COPY --from=dcraw /opt/dcraw/bin/dcraw/ /opt/bin/dcraw

ENV PATH="/opt/bin/:${PATH}"

COPY dockerfiles/entrypoint.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/entrypoint.sh
RUN mkdir ${ROOT_FOLDER}/logs

# Create a non-root user
RUN useradd galerie && \
    chown -R galerie: ${ROOT_FOLDER}

USER galerie

ENTRYPOINT ["entrypoint.sh"]
CMD ["start"]
