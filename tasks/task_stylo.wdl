version 1.0

task stylo {
  input {
    File read1
    String barcode
    String wgsid
    String genus
    String species
    Int nanoq_length = 1000
    String rasusa_genome_size = "5MB"
    Int rasusa_coverage = 80
    # String flye_read_type = "--nano-hq" # hidden due to weird errors with stylo
    String flye_genome_size = "5m"
    # String flye_minoverlap = '' # hidden due to weird errors with stylo
    String circ_prefix = "flye.circ"
    String medaka_outdir = "medaka"
    String medaka_model = 'r1041_e82_400bps_sup_v5.0.0' #//r1041_e82_400bps_sup_v4.2.0 //r1041_e82_260bps_sup_g632 //r941_min_sup_g507
    String busco_output = 'busco'
    String busco_mode = "genome"
    String socru_output = 'socru_output'
	  String socru_blastoutput = 'blast_hits'
    String docker = "us-docker.pkg.dev/general-theiagen/pni-docker-repo/stylo-nf:f7034d8"
    Boolean debug = false
    Int cpu = 4
    Int memory = 34
  }
  command <<<
    date | tee DATE

    samplename=$(basename ~{read1} | cut -d '.' -f1)
    echo "DEBUG: samplename: $samplename"

    # Make sampleinfo.txt file from inputs
    printf 'BARCODE\tWGSID\tGENUS\tSPECIES' > sampleinfo.txt
    printf '\n~{barcode}\t~{wgsid}\t~{genus}\t~{species}' >> sampleinfo.txt

    # Move reads to expected directory
    mkdir -p reads
    cp ~{read1} reads/

    # Debug
    export TMP_DIR=${TMPDIR:-/tmp}
    export TMP=${TMPDIR:-/tmp}
    env

    # Run the pipeline
    mkdir ~{wgsid}
    echo "DEBUG: Running stylo with the following command:"
    echo "DEBUG: nextflow run /stylo/schtappe/stylo.nf -c /stylo/config/stylo.config -profile local --reads reads/*.{fq,fastq}{,.gz} --sampleinfo sampleinfo.txt --nanoq_length ~{nanoq_length} --rasusa_genome_size ~{rasusa_genome_size} --rasusa_coverage ~{rasusa_coverage} \
        --circ_prefix ~{circ_prefix} \
        --medaka_outdir ~{medaka_outdir} \
        --medaka_model ~{medaka_model} \
        --busco_output ~{busco_output} \
        --busco_mode ~{busco_mode} \
        --socru_output ~{socru_output} \
        --socru_blastoutput ~{socru_blastoutput} \
        --flye_threads ~{cpu} \
        --outdir stylo"
    if nextflow run /stylo/schtappe/stylo.nf -c /stylo/config/stylo.config -profile local \
        --reads "reads/*.{fq,fastq}{,.gz}" \
        --sampleinfo sampleinfo.txt \
        --nanoq_length ~{nanoq_length} \
        --rasusa_genome_size ~{rasusa_genome_size} \
        --rasusa_coverage ~{rasusa_coverage} \
        --flye_genome_size ~{flye_genome_size} \
        --circ_prefix ~{circ_prefix} \
        --medaka_outdir ~{medaka_outdir} \
        --medaka_model ~{medaka_model} \
        --busco_output ~{busco_output} \
        --busco_mode ~{busco_mode} \
        --socru_output ~{socru_output} \
        --socru_blastoutput ~{socru_blastoutput} \
        --flye_threads ~{cpu} \
        --outdir stylo; then 

        # Everything finished, pack up the results
        if [[ "~{debug}" == "false" ]]; then
            # not in debug mode, clean up
            rm -rf .nextflow/ work/
        fi

        # output files - move to root directory
        if [[ -f "stylo/${samplename}/reads/${samplename}_nanoq_rasusa.fastq.gz" ]]; then
            mv "stylo/${samplename}/reads/${samplename}_nanoq_rasusa.fastq.gz" ~{wgsid}_nanoq_rasusa.fastq.gz
        fi
        if [[ -f "stylo/${samplename}/medaka/${samplename}.consensus.fasta" ]]; then
            mv "stylo/${samplename}/medaka/${samplename}.consensus.fasta" ~{wgsid}.fasta
        fi
        if [[ -f "stylo/${samplename}/staramr_assembly/plasmidfinder.tsv" ]]; then
            mv "stylo/${samplename}/staramr_assembly/plasmidfinder.tsv" ~{wgsid}_plasmidfinder_assembly.tsv
        fi
        if [[ -f "stylo/${samplename}/staramr_reads/plasmidfinder.tsv" ]]; then
            mv "stylo/${samplename}/staramr_reads/plasmidfinder.tsv" ~{wgsid}_plasmidfinder_reads.tsv
        fi
        if [[ -f "stylo/${samplename}/socru/socru_output.txt" ]]; then
            mv "stylo/${samplename}/socru/socru_output.txt" ~{wgsid}_socru_output.txt
        fi
        if [[ -f "stylo/${samplename}/busco/short_summary.specific.*.busco.txt" ]]; then
            mv "stylo/${samplename}/busco/short_summary.specific.*.busco.txt" ~{wgsid}_busco_output.txt
        fi

    else
        # Run failed - complete with exit code 0 is assembly file is successfully created
        exit 0
    fi
  >>>
  output {
    String stylo_docker = docker
    String stylo_analysis_date = read_string("DATE")
    File stylo_sampleinfo = "sampleinfo.txt"
    File? stylo_clean_downsampled_read1 = "~{wgsid}_nanoq_rasusa.fastq.gz"
    File stylo_final_assembly_fasta = "~{wgsid}.fasta"
    File? stylo_plasmidcheck_assembly_tsv = "~{wgsid}_plasmidfinder_assembly.tsv"
    File? stylo_plasmidcheck_reads_tsv = "~{wgsid}_plasmidfinder_reads.tsv"
    File? stylo_socru_report_txt = "~{wgsid}_socru_output.txt"
    File? stylo_busco_report_txt = "~{wgsid}_busco_output.txt"
  }
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk 100 SSD"
    maxRetries: 0
    preemptible: 0
  }
}