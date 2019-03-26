cwlVersion: v1.0
class: CommandLineTool
id: seurat
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: 'migbro/seurat:2.6'
  - class: ResourceRequirement
    ramMin: 3000
baseCommand: [java]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      "-Xms3000m -Xmx3000m"
      -jar
      -R $(inputs.reference.path)
      -I:dna_tumor $(inputs.input_tumor_bam.path)
      -I:dna_normal $(inputs.input_normal_bam.path)
      --indels
      -L $(inputs.interval_list.path)
      -o $(inputs.input_tumor_bam.nameroot).$(inputs.interval_list.nameroot).somatic.seurat.vcf

inputs:
  reference: {type: File, secondaryFiles: [^.dict, .fai]}
  input_tumor_bam: {type: File, secondaryFiles: [^.bai]}
  input_normal_bam: {type: File, secondaryFiles: [^.bai]}
  interval_list: File

outputs:
  seurat_vcf:
    type: File
    outputBinding:
      glob: '*.vcf'
