version 1.0

task hostile_pe {
  input {
    File read1
    File read2
    String samplename
    String docker = "us-docker.pkg.dev/general-theiagen/biocontainers/hostile:0.1.0--pyhdfd78af_0"
    Int disk_size = 100
    Int cpu = 4
    Int mem = 8
  }
  command <<<
    # date and version control
    date | tee DATE
    hostile --version | tee VERSION

    # dehost reads
    hostile clean \
      --fastq1 ~{read1} \
      --fastq2 ~{read2} \
      --out-dir hostile \
      --threads ~{cpu}
    
    # rename reads
    mv hostile/*.clean_1.fastq.gz "~{samplename}_R1_dehosted.fastq.gz"
    mv hostile/*.clean_2.fastq.gz "~{samplename}_R2_dehosted.fastq.gz"
  >>>
  output {
    String hostile_version = read_string("VERSION")
    File read1_dehosted = "~{samplename}_R1_dehosted.fastq.gz"
    File read2_dehosted = "~{samplename}_R2_dehosted.fastq.gz"
    String hostile_docker = docker
  }
  runtime {
      docker: docker
      memory: "~{mem} GB"
      cpu: cpu
      disks:  "local-disk " + disk_size + " SSD"
      disk: disk_size + " GB" # TES
      preemptible: 0
      maxRetries: 3
  }
}