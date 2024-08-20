version 1.0

task stylo {
  input {
    File read1
    String barcode
    String wgsid
    String genus
    String species
    Boolean unicycler = false
    Int nanoq_length = 1000
    String rasusa_genome_size = "4.8MB"
    Int rasusa_coverage = 120
    String flye_read_type = "--nano-hq"
    String flye_genome_size = "4.8m"
    Int unicycler_min_fasta_length = 1000
    String unicycler_mode = "conservative"
    Int unicycler_keep = 3
    Int unicycler_verbosity = 3
    String circ_prefix = "flye.circ"
    String medaka_model = "r1041_e82_260bps_sup_g632"
    String staramr_resfinder_commit = "039e2cc6750a8ad377b32d814e723641316b170a"
    String staramr_pointfinder_commit = "229df577d4e9238d54f1dbfd5580e59b6f77939c"
    String staramr_plasmidfinder_commit = "314d85f43e4e018baf35a2b093d9adc1246bc88d"
    String busco_mode = "genome"
    String docker="us-docker.pkg.dev/general-theiagen/docker-private/stylo-nf:acb649c"
    Int memory = 32
    Int cpu = 8
    Int disk_size = 100
    Boolean debug = false
  }
  command <<<
    date | tee DATE

    # Make sampleinfo.txt file from inputs
    printf 'BARCODE\tWGSID\tGENUS\tSPECIES' > sampleinfo.txt
    printf '\n~{barcode}\t~{wgsid}\t~{genus}\t~{species}' >> sampleinfo.txt

    # Move reads to expected directory
    mkdir -p reads
    mv ~{read1} reads/

    # Debug
    export TMP_DIR=${TMPDIR:-/tmp}
    export TMP=${TMPDIR:-/tmp}
    env

    # Run the pipeline
    mkdir ~{wgsid}
    if nextflow run /stylo/schtappe/stylo.nf -c /stylo/config/stylo.config -profile standard \
        --reads "reads/*.{fq,fastq}{,.gz}" \
        --sampleinfo sampleinfo.txt \
        --unicycler ~{unicycler} \
        --nanoq_length ~{nanoq_length} \
        --rasusa_genome_size ~{rasusa_genome_size} \
        --rasusa_coverage ~{rasusa_coverage} \
        --flye_read_type ~{flye_read_type} \
        --flye_genome_size ~{flye_genome_size} \
        --unicycler_min_fasta_length ~{unicycler_min_fasta_length} \
        --unicycler_mode ~{unicycler_mode} \
        --unicycler_keep ~{unicycler_keep} \
        --unicycler_verbosity ~{unicycler_verbosity} \
        --circ_prefix ~{circ_prefix} \
        --medaka_model ~{medaka_model} \
        --staramr_resfinder_commit ~{staramr_resfinder_commit} \
        --staramr_pointfinder_commit ~{staramr_pointfinder_commit} \
        --staramr_plasmidfinder_commit ~{staramr_plasmidfinder_commit} \
        --busco_mode ~{busco_mode} \
        --flye_threads ~{cpu} \
        --unicycler_threads ~{cpu}; then 

        # Everything finished, pack up the results
        if [[ "~{debug}" == "false" ]]; then
            # not in debug mode, clean up
            rm -rf .nextflow/ work/
        fi

    else
        # Run failed
        exit 1
    fi
  >>>
  output {
    String stylo_docker = docker
    String stylo_analysis_date = read_string("DATE")
    File stylo_sampleinfo = "sampleinfo.txt"
  }
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk ~{disk_size} SSD"
    maxRetries: 3
    preemptible: 0
  }
}