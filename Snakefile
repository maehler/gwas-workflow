import os
import pandas as pd
from snakemake.utils import validate

configfile: 'config.yaml'
validate(config, 'schemas/config.schema.yaml')

traits = pd.read_table(config['traits']).set_index('name', drop=False)
validate(traits, 'schemas/traits.schema.yaml')

def get_variants():
    if config['symlink_data']:
        return os.path.join(
            config['symlink_dir'],
            os.path.basename(config['variants']))
    return config['variants']

def get_plink_prefix(trait=False):
    if 'plink_prefix' not in config or not config['plink_prefix']:
        # Make a PLINK prefix based on the VCF file
        variant_fname = get_variants()
        if variant_fname.endswith('.gz'):
            variant_fname = os.path.splitext(variant_fname)[0]
        prefix = os.path.splitext(variant_fname)[0]
        if not trait:
            return '{prefix}_plink'.format(prefix=prefix)
        return 'results/{{trait}}/plink/{prefix}_plink'.format(
            prefix=os.path.basename(prefix))
    # A PLINK prefix has been supplied
    if not trait:
        return config['plink_prefix']
    return 'results/{{trait}}/plink/{prefix}'.format(
        prefix=os.path.basename(config['plink_prefix']))

def get_plink_files(trait=False, extensions=['fam', 'bed', 'bim']):
    if not trait:
        return expand('{prefix}.{ext}',
            prefix=get_plink_prefix(trait), ext=extensions)
    return expand('results/{{trait}}/plink/{prefix}.{ext}',
        prefix=os.path.basename(get_plink_prefix(trait)), ext=extensions)

def get_profile_path():
    return '{home}/.config/snakemake/{profile_name}' \
        .format(home=os.path.expanduser('~'),
                profile_name=config['cluster']['profile_name'])

localrules: all, link_variants, link_plink, link_relatedness,
    setup_plink_traits, cluster_config

rule all:
    input:
        expand('results/{trait}/{trait}.assoc.txt', trait=traits.name)

rule cluster_config:
    output: directory(get_profile_path())
    params:
        url=config['cluster']['cookiecutter_url'],
        profile_name=os.path.basename(get_profile_path()),
        outdir=os.path.dirname(get_profile_path()),
        restart_times=config['cluster']['restart-times'],
        jobs=config['cluster']['jobs'],
        use_conda=str(config['cluster']['use-conda']).lower()
    conda: 'envs/cluster_config.yaml'
    shell:
        '''
        mkdir -p $HOME/.cookiecutters
        cutdir=$HOME/.cookiecutters/$(basename {params.url})
        if [ ! -d ${{cutdir}} ]; then
            git clone {params.url} $HOME/.cookiecutters/$(basename {params.url})
        fi

        yq .cluster config.yaml > ${{cutdir}}/cookiecutter.json

        mkdir -p {params.outdir}
        cookiecutter -o {params.outdir} --no-input ${{cutdir}}

        yq '.["restart-times"]={params.restart_times} | .jobs={params.jobs} | .["use-conda"]={params.use_conda}' \
            {output}/config.yaml > {output}/config_mod.yaml
        mv {output}/config_mod.yaml {output}/config.yaml

        echo "To use profile, run snakemake with --profile {params.profile_name} ..."
        '''

rule gemma:
    input:
        plink=get_plink_files(trait=True),
        relatedness_matrix='{prefix}.relmat.cXX.txt'.format(
            prefix=get_plink_prefix(trait=True))
    output:
        'results/{trait}/{trait}.assoc.txt'
    params:
        plink_prefix=os.path.abspath(get_plink_prefix(trait=True)),
        output_prefix='{trait}'
    threads: 1
    conda: 'envs/gemma.yaml'
    shell:
        '''
        cd $(dirname {output})
        gemma \
            -bfile {params.plink_prefix} \
            -k {params.plink_prefix}.relmat.cXX.txt \
            -lmm 2 \
            -o {params.output_prefix}
        mv output/* .
        rmdir output
        '''

rule link_relatedness:
    input:
        '{prefix}.relmat.cXX.txt'.format(
            prefix=get_plink_prefix())
    output:
        '{prefix}.relmat.cXX.txt'.format(
            prefix=get_plink_prefix(trait=True))
    shell: 'ln -sr {input} {output}'

rule gemma_relatedness:
    input:
        plink=get_plink_files(trait=True)
    output:
        relatedness_matrix='{prefix}.relmat.cXX.txt'.format(
            prefix=get_plink_prefix(trait=True))
    params:
        plink_prefix=os.path.abspath(get_plink_prefix(trait=True)),
        output_prefix='{prefix}.relmat'.format(
            prefix=os.path.basename(get_plink_prefix(trait=True)))
    threads: 1
    conda: 'envs/gemma.yaml'
    shell:
        '''
        cd $(dirname {output.relatedness_matrix})
        gemma \
            -bfile {params.plink_prefix} \
            -gk 1 \
            -o {params.output_prefix}
        mv output/* .
        rmdir output
        '''

rule setup_plink_traits:
    input:
        fam=get_plink_files(extensions='fam'),
        trait=lambda wildcards: traits.filename[wildcards.trait]
    output:
        fam=get_plink_files(trait=True, extensions='fam')
    shell:
        '''
        paste -d' ' <(cut -f1-5 -d' ' {input.fam}) <(tail -n+2 {input.trait} | cut -f2) > {output.fam}
        '''

rule link_plink:
    input:
        plink=get_plink_files(extensions=['bim', 'bed'])
    output:
        plink=get_plink_files(trait=True, extensions=['bim', 'bed'])
    params:
        output_directory=os.path.dirname(get_plink_prefix(trait=True))
    shell: 'ln -sr {input.plink} {params.output_directory}'

rule plink:
    input:
        vcf=get_variants()
    output:
        plink=get_plink_files()
    params:
        plink_prefix=get_plink_prefix(),
        hwe_p=config['snp_filtering']['hwe_p'],
        maf=config['snp_filtering']['maf'],
        allow_extra_chr='--allow-extra-chr' if config['plink']['allow_extra_chr'] else '',
        family_id_flags=config['plink']['family_id_flags']
    conda: 'envs/plink.yaml'
    shell: 
        '''
        plink \
            --make-bed \
            {params.allow_extra_chr} \
            {params.family_id_flags} \
            --maf {params.maf} \
            --hwe {params.hwe_p} \
            --out {params.plink_prefix} \
            --vcf {input.vcf}
        '''

rule link_variants:
    input: config['variants']
    output: get_variants()
    shell: 'ln -sr {input} {output}'
