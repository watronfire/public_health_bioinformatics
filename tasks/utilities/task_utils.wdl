version 1.0

task count_reads {
  input {
    File read1
    File read2
    String samplename
    String docker = "us-docker.pkg.dev/general-theiagen/theiagen/utility:1.2"
    Int disk_size = 100
    Int cpu = 4
    Int mem = 8
  }
  command <<<
    for file in $(ls ~{read1}); do echo $file; zcat $file | echo $((`wc -l`/4)); done > count_reads.txt
    tail -n1 count_reads.txt | awk '{print $1}' | tee READ_COUNT
  >>>
  output {
    Int read_count_pairs = read_int("READ_COUNT")
  }
  runtime {
    docker: docker
    memory: "~{mem} GB"
    cpu: cpu
    disks:  "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB" # TES
    preemptible: 0
    maxRetries: 0
  }
}