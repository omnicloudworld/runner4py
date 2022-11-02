FROM python:3.10.5-slim-bullseye


ARG WORKDIR=/opt/skyant

WORKDIR $WORKDIR
COPY src/ $WORKDIR

ENV PYTHONUNBUFFERED=True
ENV TZ=Europe/Kiev
ENV DEBIAN_FRONTEND="noninteractive"
ENV WORKDIR=$WORKDIR


RUN \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone &&\
    chmod +x run.sh wrapper.sh &&\
    \
    mkdir -p --mode=750 /root/.config/mc &&\
    useradd -s /bin/bash -m -u 10001 skyant &&\
    mkdir -p --mode=750 /home/skyant/.postgresql && chown skyant:skyant /home/skyant/.postgresql

    
COPY src/mc/root.ini /root/.config/mc/ini
COPY --chown=skyant:skyant src/mc/skyant.ini /home/skyant/.config/mc/ini
COPY req.pip /tmp/req.pip

RUN \
    apt-get update &&\
    apt-get install \
        apt-utils tini lsb-release build-essential gnupg2 curl mc \
        -y --no-install-recommends &&\
    apt-get install -y unzip nodejs npm &&\
    release=`lsb_release -c -s`; \
    \
    status_code=$(curl --write-out %{http_code} --silent --output /dev/null \
        https://packages.cloud.google.com/apt/dists/gcsfuse-$release/main/binary-amd64/Packages.gz) &&\
    if [[ $status_code -eq 200 ]]; \
        then \
            gcsFuseRepo=gcsfuse-$release; \
        else \
            gcsFuseRepo=gcsfuse-buster; \
    fi &&\
    \
    echo "deb http://packages.cloud.google.com/apt $gcsFuseRepo main" | \
        tee /etc/apt/sources.list.d/gcsfuse.list; \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - &&\
    apt update && apt-get install -y gcsfuse &&\
    apt autoremove -y && apt clean --dry-run

RUN \
    pip3 install --no-cache-dir --upgrade pip; \
    pip3 install --no-cache-dir --upgrade -r /tmp/req.pip


ENTRYPOINT ["/usr/bin/tini", "--"] 
CMD [ "bash", "-c", "${WORKDIR}/wrapper.sh" ]
