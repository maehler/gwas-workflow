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

Configure the workflow by editing the file [`config.yaml`](config.yaml).

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
For example, if you want to run this using SLURM, you can set up a profile using cookiecutter

```sh
mkdir -p $HOME/.config/snakemake
cd $HOME/.config/snakemake
cookiecutter https://github.com/Snakemake-Profiles/slurm.git
```

and then run snakemake with the generated profile

```sh
snakemake --use-conda --profile slurm --jobs 100
```

For more information on how to configure the cluster parameters, take a look at the [snakemake documentation](https://snakemake.readthedocs.io/en/stable/executable.html).
