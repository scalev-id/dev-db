FROM postgres:16.8

ENV PARTMAN_VERSION=4.7.4

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    postgresql-server-dev-16 \
    libkrb5-dev \
    git \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Add TimescaleDB repository (more reliable method)
RUN sh -c "echo 'deb [signed-by=/usr/share/keyrings/timescale.keyring] https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -cs) main' > /etc/apt/sources.list.d/timescaledb.list"
RUN wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor -o /usr/share/keyrings/timescale.keyring

# Install TimescaleDB
RUN apt-get update && apt-get install -y \
    timescaledb-2-postgresql-16 \
    && rm -rf /var/lib/apt/lists/*

# Configure TimescaleDB
RUN echo "shared_preload_libraries = 'timescaledb'" >> /usr/share/postgresql/postgresql.conf.sample

# Create directory for custom initialization scripts
RUN mkdir -p /docker-entrypoint-initdb.d

# Add a script to enable the extension when the container starts
RUN echo "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" > /docker-entrypoint-initdb.d/timescaledb-setup.sql

# Install pg_partman
RUN git clone --branch v${PARTMAN_VERSION} https://github.com/pgpartman/pg_partman.git /tmp/pg_partman \
    && cd /tmp/pg_partman \
    && make install \
    && rm -rf /tmp/pg_partman

EXPOSE 5432

CMD ["postgres"]
