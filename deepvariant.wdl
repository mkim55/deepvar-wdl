task make_examples {
  File REF_GENOME_FASTA
  File REF_GENOME_FAI
  File READS_BAM
  File READS_BAI
  Int DISK_SPACE_GB
  Int NUM_THREADS

  command <<<
    /opt/deepvariant/bin/make_examples \
      --mode calling \
      --ref ${REF_GENOME_FASTA} \
      --reads ${READS_BAM} \
      --examples output.examples.tfrecord
  >>>
  runtime {
    docker: "mkim55/deep-variant:latest"
    disks: "local-disk " + DISK_SPACE_GB + " HDD"
    cpu: NUM_THREADS
  }
  output {
    File me_outfile = "output.examples.tfrecord"
  }
}

task call_variants {
  File EXAMPLES
  String CHECKPOINT
  Int DISK_SPACE_GB
  Int NUM_THREADS

  command <<<
    /opt/deepvariant/bin/call_variants \
      --outfile output.callvariants.tfrecord \
      --examples ${EXAMPLES} \
      --checkpoint ${CHECKPOINT} 
  >>>
  runtime {
    docker: "mkim55/deep-variant:latest"
    disks: "local-disk " + DISK_SPACE_GB + " HDD"
    cpu: NUM_THREADS
  }
  output {
    File cv_outfile = "output.callvariants.tfrecord"
  }
}

task postprocess_variants {
  File REF_GENOME_FASTA
  File REF_GENOME_FAI
  File VARIANTS
  Int NUM_THREADS

  command <<<
    /opt/deepvariant/bin/postprocess_variants \
      --ref ${REF_GENOME_FASTA} \
      --infile ${VARIANTS} \
      --outfile output.postprocess.vcf
  >>>
  runtime {
    docker : "mkim55/deep-variant:latest"
    cpu: NUM_THREADS
  }
  output {
    File ppv_outfile = "output.postprocess.vcf"
  }
}

workflow deep_variant {
  File REF_GENOME_FASTA
  File REF_GENOME_FAI
  File READS_BAM
  File READS_BAI
  String CHECKPOINT
  Int DISK_SPACE_GB
  Int NUM_THREADS

  call make_examples {
    input:
      REF_GENOME_FASTA = REF_GENOME_FASTA,
      REF_GENOME_FAI = REF_GENOME_FAI,
      READS_BAM = READS_BAM,
      READS_BAI = READS_BAI,
      DISK_SPACE_GB = DISK_SPACE_GB,
      NUM_THREADS = NUM_THREADS
  }

  call call_variants {
    input:
      EXAMPLES = make_examples.me_outfile,
      CHECKPOINT = CHECKPOINT,
      DISK_SPACE_GB = DISK_SPACE_GB,
      NUM_THREADS = NUM_THREADS
  }

  call postprocess_variants {
    input:
      REF_GENOME_FASTA = REF_GENOME_FASTA,
      REF_GENOME_FAI = REF_GENOME_FAI,
      VARIANTS = call_variants.cv_outfile,
      NUM_THREADS = NUM_THREADS
  }
}
