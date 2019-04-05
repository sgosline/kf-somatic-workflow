cwlVersion: v1.0
class: CommandLineTool
id: gatk4_Mutect2
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:4.0.12.0'
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 4
  - class: InitialWorkDirRequirement
    listing: |
      ${
        var listing = []
        listing.push(inputs.input_tumor_aligned);
        listing.push(inputs.input_normal_aligned);
        return listing;
      }
baseCommand: [/gatk, Mutect2]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      --java-options "-Xmx4000m"
      -R $(inputs.reference.path)
      -I $(inputs.input_tumor_aligned.path)
      -I $(inputs.input_normal_aligned.path)
      -tumor $(inputs.input_tumor_name)
      -normal $(inputs.input_normal_name)
      --disable-read-filter MateOnSameContigOrNoMappedMateReadFilter
      -L $(inputs.interval_list.path)
      -O $(inputs.input_tumor_aligned.nameroot).$(inputs.interval_list.nameroot).Mutect2.vcf.gz

inputs:
  reference: {type: File, secondaryFiles: [^.dict, .fai]}
  input_tumor_aligned:
    type: File
    secondaryFiles: |
      ${
        var dpath = self.location.replace(self.basename, "")
        if(self.nameext == '.bam'){
          return {"location": dpath+self.nameroot+".bai", "class": "File"}
        }
        else{
          return {"location": dpath+self.basename+".crai", "class": "File"}
        }
      }
    doc: "tumor SAM, BAM, or CRAM"
  input_tumor_name: string
  input_normal_aligned:
    type: File
    secondaryFiles: |
      ${
        var dpath = self.location.replace(self.basename, "")
        if(self.nameext == '.bam'){
          return {"location": dpath+self.nameroot+".bai", "class": "File"}
        }
        else{
          return {"location": dpath+self.basename+".crai", "class": "File"}
        }
      }
    doc: "normal SAM, BAM, or CRAM"
  input_normal_name: string
  interval_list: File

outputs:
  mutect2_vcf:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: [.tbi]
