version 1.0

import "../tasks/task_stylo.wdl" as stylo_task

workflow stylo_wf {
  meta {
    description: "A WDL wrapper around the stylo nf pipeline."
  }
  input {
    File read1
    String barcode
    String wgsid
    String genus
    String species
  }
  call stylo_task.stylo {
    input:
      read1 = read1,
      barcode = barcode,
      wgsid = wgsid,
      genus = genus,
      species = species
  }
  output {
    String stylo_docker = stylo.stylo_docker
    String stylo_analysis_date = stylo.stylo_analysis_date
    File stylo_sampleinfo = stylo.stylo_sampleinfo
    File? stylo_clean_downsampled_read1 = stylo.stylo_clean_downsampled_read1
    File? stylo_final_assembly_fasta = stylo.stylo_final_assembly_fasta
    File? stylo_socru_report_txt = stylo.stylo_socru_report_txt
    File? stylo_busco_report_txt = stylo.stylo_busco_report_txt
  }
}