cwlVersion: v1.0
class: Workflow
id: kfdrc_somatic_wf
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  indexed_reference_fasta: {type: File, secondaryFiles: [.fai, ^.dict]}
  reference_dict: File
  wgs_calling_interval_list: File
  hg38_strelka_bed: File
  input_tumor_aligned: File
  input_tumor_name: string
  input_normal_aligned: File
  input_normal_name: string
  threads: int
  exome_flag: ['null', string]
  vep_cache: {type: File, label: tar gzipped cache from ensembl/local converted cache}
  chr_len: File
  ref_chrs: File
  output_basename: string

outputs:
  strelka2_vep_vcf: {type: File, outputSource: vep_annot_strelka2/output_vcf}
  strelka2_vep_maf: {type: File, outputSource: vep_annot_strelka2/output_maf}
  strekla2_vep_tbi: {type: File, outputSource: vep_annot_strelka2/output_tbi}
  mutect2_vep_vcf: {type: File, outputSource: vep_annot_mutect2/output_vcf}
  mutect2_vep_tbi: {type: File, outputSource: vep_annot_mutect2/output_tbi}
  mutect2_vep_maf: {type: File, outputSource: vep_annot_mutect2/output_maf}
  manta_vep_vcf: {type: File, outputSource: vep_annot_manta/output_vcf}
  manta_vep_tbi: {type: File, outputSource: vep_annot_manta/output_tbi}
  manta_vep_maf: {type: File, outputSource: vep_annot_manta/output_maf}
  cnv_bam_ratio: { type: File, outputSource: control_free_c/output_txt }
  cnv_pval: { type: File, outputSource: control_free_c_r/output_pval }
  cnv_png: { type: File, outputSource: control_free_c_viz/output_png }

steps:
  samtools_tumor_cram2bam:
    run: ../tools/samtools_cram2bam.cwl
    in:
      input_reads: input_tumor_aligned
      threads:
        valueFrom: ${return 36}
      reference: indexed_reference_fasta
    out: [bam_file]

  samtools_normal_cram2bam:
    run: ../tools/samtools_cram2bam.cwl
    in:
      input_reads: input_normal_aligned
      threads:
        valueFrom: ${return 36}
      reference: indexed_reference_fasta
    out: [bam_file]

  control_free_c:
    run: ../tools/control_freec.cwl
    in:
      ref_chrs: ref_chrs
      chr_len: chr_len
      threads: threads
      tumor_bam: samtools_tumor_cram2bam/bam_file
      normal_bam: samtools_normal_cram2bam/bam_file
      output_basename: output_basename
    out: [output]
  
  control_free_c_r:
    run: ../tools/control_freec_R.cwl
    in:
      cnv_bam_ratio: control_free_c/output_txt
      cnv_result: control_free_c/output_cnv
    out: [output]

  control_free_c_viz:
    run: ../tools/control_freec_visualize.cwl
    in:
      output_basename: output_basename
      cnv_bam_ratio: control_free_c/output_txt
    out: [output]
    
  gatk_intervallisttools:
    run: ../tools/gatk_intervallisttool.cwl
    in:
      interval_list: wgs_calling_interval_list
    out: [output]

  strelka2:
    run: ../tools/strelka2.cwl
    in:
      input_tumor_aligned: input_tumor_aligned
      input_normal_aligned: input_normal_aligned
      reference: indexed_reference_fasta
      hg38_strelka_bed: hg38_strelka_bed
      exome_flag: exome_flag
    out: [output]

  manta:
    run: ../tools/manta.cwl
    in:
      input_tumor_cram: input_tumor_aligned
      input_normal_cram: input_normal_aligned
      output_basename: output_basename
      reference: indexed_reference_fasta
      hg38_strelka_bed: hg38_strelka_bed
    out: [output_sv]
  
  mutect2:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.9xlarge;ebs-gp2;1200
    run: ../tools/gatk_Mutect2.cwl
    in:
      input_tumor_aligned: input_tumor_aligned
      input_tumor_name: input_tumor_name
      input_normal_aligned: input_normal_aligned
      input_normal_name: input_normal_name
      reference: indexed_reference_fasta
      interval_list: gatk_intervallisttools/output
      exome_flag: exome_flag
    scatter: [interval_list]
    out: [mutect2_vcf]
  
  merge_strelka2_vcf:
    run: ../tools/gatk_mergevcfs_pass_filter.cwl
    label: Merge & pass filter strekla2
    in:
      input_vcfs: [strelka2/output_snv, strelka2/output_indel]
      output_basename: output_basename
      reference_dict: reference_dict
      tool_name:
        valueFrom: ${ return "strelka2"}
    out: [merged_vcf]

  rename_strelka_samples:
    run: ../tools/bcftools_reheader_vcf.cwl
    in:
      input_vcf: merge_strelka2_vcf/merged_vcf
      input_normal_name: input_normal_name
      input_tumor_name: input_tumor_name
    out: [reheadered_vcf]

  rename_manta_samples:
    run: ../tools/bcftools_reheader_vcf.cwl
    in:
      input_vcf: manta/output_sv
      input_normal_name: input_normal_name
      input_tumor_name: input_tumor_name
    out: [reheadered_vcf]

  merge_mutect2_vcf:
    run: ../tools/gatk_mergevcfs_pass_filter.cwl
    label: Merge & pass filter mutect2
    in:
      input_vcfs: mutect2/mutect2_vcf
      output_basename: output_basename
      reference_dict: reference_dict
      tool_name:
        valueFrom: ${return "mutect2"}
    out: [merged_vcf]
    
  vep_annot_strelka2:
    run: ../tools/vep_vcf2maf.cwl
    in:
      input_vcf: rename_strelka_samples/reheadered_vcf
      output_basename: output_basename
      tumor_id: input_tumor_name
      normal_id: input_normal_name
      tool_name:
        valueFrom: ${return "strelka2_somatic"}
      reference: indexed_reference_fasta
      cache: vep_cache
    out: [output_vcf, output_tbi, output_html, warn_txt]

  vep_annot_mutect2:
    run: ../tools/vep_vcf2maf.cwl
    in:
      input_vcf: merge_mutect2_vcf/merged_vcf
      output_basename: output_basename
      tumor_id: input_tumor_name
      normal_id: input_normal_name
      tool_name:
        valueFrom: ${return "mutect2_somatic"}
      reference: indexed_reference_fasta
      cache: vep_cache
    out: [output_vcf, output_tbi, output_html, warn_txt]

  vep_annot_manta:
    run: ../tools/vep_vcf2maf.cwl
    in:
      input_vcf: rename_manta_samples/reheadered_vcf
      output_basename: output_basename
      tumor_id: input_tumor_name
      normal_id: input_normal_name
      tool_name:
        valueFrom: ${return "manta_somatic"}
      reference: indexed_reference_fasta
      cache: vep_cache
    out: [output_vcf, output_tbi, output_html, warn_txt]
  
$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 4