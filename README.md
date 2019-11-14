# Snakemake workflow for GWAS in aspen

The goal of this workflow is to provide a flexible interface to performing GWAS in *Populus tremula*.

## Requirements

- snakemake
- conda ([miniconda](https://docs.conda.io/en/latest/miniconda.html))
- [cookiecutter](https://cookiecutter.readthedocs.io/en/latest/) (optional)

The recommended approach would be to create a snakemake conda environment that is used for running the workflow.

```sh
conda create -n snakemake snakemake
conda activate snakemake
```

## Usage

### Configuration

Configure the workflow by editing the file [`config.yaml`](config.yaml) and the `traits.tsv` file.

### Execution

Test the configuration by performing a dry-run

```sh
snakemake --use-conda --dry-run
```

You can execute the workflow locally using `$N` cores with

```sh
snakemake --use-conda --cores $N
```

#### Cluster environments

It is also possible to execute the workflow in a cluster environment, and the easiest approach is probably by using an existing [snakemake profile](https://github.com/Snakemake-Profiles).
Profiles can be generated through snakemake by modifying the cluster entry in [config.yaml](config.yaml) and running

```sh
snakemake --use-conda cluster_config
```

This will generate a profile with the desired name in `$HOME/.config/snakemake`.
The profile can be utilised by running snakemake with the `--profile` flag, specifing the generated profile

```sh
snakemake --profile <profile_name>
```

For more information on how to configure the cluster parameters, take a look at the [snakemake documentation](https://snakemake.readthedocs.io/en/stable/executable.html).

## Test data

There is a small test dataset included under [`test/data`](test/data).
The traits are in this case just random numbers sampled from a standard normal distribution.
Running the workflow without modifying `config.yaml` will use this data.
