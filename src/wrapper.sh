#!/usr/bin/env bash

set -eo pipefail


prep=$( echo $MOUNT_GCS | tr '+' ' ' )

for point in $prep; do
    
    set -- `echo $point | tr '=' ' '`
    path=$2

    set -- `echo $1 | tr ':' ' '`
    bucket=$1; folder=$2

    mkdir -m 755 -p $path && chown skyant:skyant $path
    
    
    if [[ $folder = "/" ]]
        then
        # mount bucket

            if [[ $DEBUG_GCS = true ]]
                then
                    gcsfuse -o allow_other --uid 10001 --gid 10001 \
                        --debug_http --debug_invariants --debug_gcs --debug_fuse \
                        --implicit-dirs $bucket $path
                    echo "The GCS $bucket was mounted in $path with debug flag"
                else
                    gcsfuse -o allow_other --uid 10001 --gid 10001 \
                        --implicit-dirs $bucket $path
                    echo "The GCS $bucket was mounted in $path"
            fi

        else
        # mount folder
    
            if [[ $DEBUG_GCS = true ]]
                then
                    gcsfuse -o allow_other --uid 10001 --gid 10001 \
                        --debug_http --debug_invariants --debug_gcs --debug_fuse \
                        --implicit-dirs --only-dir $folder $bucket $path
                    echo "The $folder from GCS $bucket was mounted in $path with debug flag"
                else
                    gcsfuse -o allow_other --uid 10001 --gid 10001 \
                        --implicit-dirs --only-dir $folder $bucket $path
                    echo "The $folder from GCS $bucket was mounted in $path"
            fi
    fi
    
done


if [ -f /var/client-key/pg.pem ]; then
    cp /var/client-key/pg.pem /home/skyant/.postgresql/postgresql.key
    chown skyant:skyant /home/skyant/.postgresql/postgresql.key
    chmod 600 /home/skyant/.postgresql/postgresql.key
fi

if [ -f /var/client-crt/pg.pem ]; then
    cp /var/client-crt/pg.pem /home/skyant/.postgresql/postgresql.crt
    chown skyant:skyant /home/skyant/.postgresql/postgresql.crt
fi

if [ -f /var/server-ca/pg.pem ]; then
    cp /var/server-ca/pg.pem /home/skyant/.postgresql/root.crt
    chown skyant:skyant /home/skyant/.postgresql/root.crt
fi


su skyant -c $WORKDIR/run.sh &

# Exit immediately when one of the background processes terminate.
wait -n
