FROM python:3.10.5-slim-bullseye


ARG WORKDIR=/opt/skyant

WORKDIR $WORKDIR

COPY src/pod/ $WORKDIR
COPY src/wrapper.sh /opt/wrapper.sh


ENV PYTHONUNBUFFERED=True
ENV TZ=Europe/Kiev
ENV DEBIAN_FRONTEND="noninteractive"
ENV WORKDIR=$WORKDIR


RUN \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone &&\
    chmod +x run.sh /opt/wrapper.sh &&\
    \
    mkdir -p --mode=750 /root/.config/mc &&\
    mkdir -p /var/pip &&\
    useradd -s /bin/bash -m -u 10001 skyant &&\
    mkdir -p --mode=750 /home/skyant/.postgresql && chown skyant:skyant /home/skyant/.postgresql

    
COPY src/mc/root.ini /root/.config/mc/ini
COPY --chown=skyant:skyant src/mc/skyant.ini /home/skyant/.config/mc/ini
COPY cloudrun.req /var/pip/cloudrun.req

RUN \
    apt update && apt upgrade -y &&\
    apt install -y --no-install-recommends \
        apt-utils tini build-essential gnupg2 curl wget mc &&\
    apt install -y \
        unzip nodejs npm &&\
    \
    echo "deb http://packages.cloud.google.com/apt gcsfuse-bullseye main" | \
        tee /etc/apt/sources.list.d/gcsfuse.list &&\
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - &&\
    \
    echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > \
        /etc/apt/sources.list.d/pgdg.list &&\
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - &&\
    \
    apt update && apt install -y gcsfuse postgresql-client-13 postgresql-client-14 &&\
    apt autoremove -y && apt clean --dry-run

RUN \
    pip3 install --no-cache-dir --upgrade pip; \
    pip3 install --no-cache-dir --upgrade -r /var/pip/cloudrun.req


ENTRYPOINT ["/usr/bin/tini", "--"] 
CMD [ "bash", "-c", "/opt/wrapper.sh" ]
