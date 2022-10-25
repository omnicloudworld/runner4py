#!/usr/bin/env bash

set -eo pipefail


prep=$( echo $MOUNT_GCS | tr '+' ' ' )

for point in $prep; do
    
    set -- `echo $point | tr '=' ' '`
    path=$2

    set -- `echo $1 | tr ':' ' '`
    echo $2
    bucket=$1; folder=$2

    sudo mkdir -m 755 -p $path
    sudo chown $EUID:$EUID $path
    
    
    if [[ $folder = "/" ]]
        then
        # mount bucket

            if [[ $DEBUG_GCS = true ]]
                then
                    sudo gcsfuse -o allow_other --uid $EUID --gid $EUID \
                        --implicit-dirs --debug_gcs --debug_fuse $bucket $path || exit 1;
                    echo "The GCS $bucket was mounted in $path with debug flag"
                else
                    sudo gcsfuse -o allow_other --uid $EUID --gid $EUID \
                        --implicit-dirs $bucket $path || exit 1;
                    echo "The GCS $bucket was mounted in $path"
            fi

        else
        # mount folder
    
            if [[ $DEBUG_GCS = true ]]
                then
                    sudo gcsfuse -o allow_other --uid $EUID --gid $EUID \
                        --implicit-dirs --debug_gcs --debug_fuse --only-dir $folder $bucket $path || exit 1;
                    echo "The $folder from GCS $bucket was mounted in $path with debug flag"
                else
                    sudo gcsfuse -o allow_other --uid $EUID --gid $EUID \
                        --implicit-dirs --only-dir $folder $bucket $path || exit 1;
                    echo "The $folder from GCS $bucket was mounted in $path"
            fi
    fi
    
done


sudo mkdir -m 755 -p $HOME/.postgresql/.mkdir
sudo chown $EUID:$EUID $HOME/.postgresql

if [ -f /var/client-key/pg.pem ]; then
    cp /var/client-key/pg.pem $HOME/.postgresql/postgresql.key;
    chmod 600 $HOME/.postgresql/postgresql.key;
fi

if [ -f /var/client-crt/pg.pem ]; then
    cp /var/client-crt/pg.pem $HOME/.postgresql/postgresql.crt;
fi

if [ -f /var/server-ca/pg.pem ]; then
    cp /var/server-ca/pg.pem $HOME/.postgresql/root.crt;
fi


$WORKDIR/run.sh &

# Exit immediately when one of the background processes terminate.
wait -n
