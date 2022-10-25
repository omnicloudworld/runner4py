# pylint: disable=missing-module-docstring


from os import (
    environ as env,
    path
)

from shutil import rmtree
from duty import duty
import yaml


@duty
def bsd(ctx):
    '''
    Build & Serv the Documentation.
    '''

    ctx.run(
        'mkdocs build --config-file .mkdocs.yml --site-dir .html',
        title='Building documentation'
    )

    ctx.run(
        'mkdocs serve --config-file .mkdocs.yml --dev-addr 0.0.0.0:8008',
        title='Serving on http://localhost:8008/'
    )


@duty
def gauth(ctx):
    '''
    Login to Google Cloud Platform.
    '''

    ctx.run(
        'gcloud beta auth login --update-adc --enable-gdrive-access --add-quota-project-to-adc --brief',
        title='Login'
    )

    project = env['GPROJECT'] if 'GPROJECT' in env else input('Please enter GCP project id: ')
    ctx.run(
        f'gcloud config set project {project}',
        title='Set project'
    )
