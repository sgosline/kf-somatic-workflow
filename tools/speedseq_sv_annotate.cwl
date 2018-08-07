cwlVersion: v1.0
class: CommandLineTool
id: speedseq_sv_annotate
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 24000
  - class: DockerRequirement
    dockerPull: 'speedseq:latest'
baseCommand: [/speedseq/src/samtools-1.3.1/misc/seq_cache_populate.pl ]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      -root ref_cache
      $(inputs.reference.path)
      && export REF_CACHE=$PWD/ref_cache
      && /speedseq/bin/speedseq sv
      -B $(inputs.input_align.path)
      -R $(inputs.reference.path)
      -t 8
      -o $(inputs.output_basename)
      -v

inputs:
  reference: { type: File,  secondaryFiles: [.fai] }
  input_align: { type: File,  secondaryFiles: [^.crai|^.bai] }
  output_basename: string
outputs:
  output:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: [.tbi]