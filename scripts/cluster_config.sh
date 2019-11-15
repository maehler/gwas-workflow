#!/bin/bash

if [ $# -ne 2 ]; then
    echo "usage: $0 <cookiecutter url> <profile name>" >&2
    exit 1
fi

url=$1
profile_name=$2

mkdir -p ${HOME}/.cookiecutters
cutdir=${HOME}/.cookiecutters/${profile_name}
outdir=${HOME}/.config/snakemake/${profile_name}

if [ ! -d ${cutdir} ]; then
    git clone ${url} $HOME/.cookiecutters/${profile_name}
else
    echo "using existing cookiecutter in ${cutdir}" >&2
fi

yq .cluster config.yaml > ${cutdir}/cookiecutter.json

mkdir -p $(dirname ${outdir})
cookiecutter -o $(dirname ${outdir}) --no-input ${cutdir}

# The following parameters are required in the config
use_conda=$(yq '.cluster | .["use-conda"]' config.yaml)
restart_times=$(yq '.cluster | .["restart-times"]' config.yaml)
max_jobs=$(yq '.cluster | .jobs' config.yaml)
latency_wait=$(yq '.cluster | .["latency-wait"]' config.yaml)

yq '.["restart-times"]='"${restart_times}"' | .jobs='"${max_jobs}"' | .["use-conda"]='"${use_conda}"' | .["latency-wait"]='"${latency_wait}" \
    ${outdir}/config.yaml > ${outdir}/config_mod.yaml
mv ${outdir}/config_mod.yaml ${outdir}/config.yaml

echo "To use profile, run snakemake with --profile ${profile_name} ..."
