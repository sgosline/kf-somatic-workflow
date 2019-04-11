cwlVersion: v1.0
class: CommandLineTool
id: gatk4_filtermutect2calls
label: GATK Filter Mutect2
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:4.1.1.0'
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 2
baseCommand: [/gatk, FilterMutectCalls]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      --java-options "-Xmx4000m"
      -V $(inputs.mutect_vcf.path)
      -O $(inputs.output_basename).mutect2_filtered.vcf.gz
      --contamination-table $(inputs.contamination_table.path)
      --tumor-segmentation $(inputs.segmentation_table.path)
      --ob-priors $(inputs.ob_priors.path)
      --filtering-stats $(inputs.output_basename).mutect2_filtered.tsv

inputs:
  mutect_vcf: {type: File, secondaryFiles: [.tbi]}
  output_basename: string
  contamination_table: File
  segmentation_table: File
  ob_priors: File
  
outputs:
  stats_table:
    type: File
    outputBinding:
      glob: '*.mutect2_filtered.tsv'
  
  filtered_vcf:
    type: {type: File, secondaryFiles: ['.tbi']}
    outputBinding:
      glob: '*.mutect2_filtered.vcf.gz'

