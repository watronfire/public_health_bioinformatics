version 1.0

import "../../../tasks/quality_control/task_hostile.wdl" as hostile_task
import "../../../tasks/taxon_id/task_kraken2.wdl" as kraken2_task
import "../../../tasks/quality_control/task_ncbi_scrub.wdl" as hrrt_task
import "../../../tasks/utilities/task_utils.wdl" as utils_task

workflow benchmark_host_removal_pe {
  meta {
    description: "Benchmark dehosting tools"
  }
  input {
    File read1
    File read2
    String samplename
    File kraken2_db = "gs://theiagen-public-files-rp/terra/theiaprok-files/k2_standard_08gb_20230605.tar.gz"
  }
  
  call utils_task.count_reads as count_reads_raw {
    input:
      read1 = read1,
      read2 = read2,
      samplename = samplename
  }

  call kraken2_task.kraken2_standalone as kraken2_raw {
    input:
      samplename = samplename,
      read1 = read1,
      read2 = read2,
      kraken2_db = kraken2_db,
      kraken2_args = "",
      classified_out = "classified#.fastq",
      unclassified_out = "unclassified#.fastq"
  }

  call hostile_task.hostile_pe as hostile {
    input:
      samplename = samplename,
      read1 = read1,
      read2 = read2
  }

  call hrrt_task.ncbi_scrub_pe as hrrt {
    input:
      samplename = samplename,
      read1 = read1,
      read2 = read2
  }

  call utils_task.count_reads as count_reads_hostile {
    input:
      read1 = hostile.read1_dehosted,
      read2 = hostile.read2_dehosted,
      samplename = samplename
  }

  call kraken2_task.kraken2_standalone as kraken2_clean_hostile {
    input:
      samplename = samplename,
      read1 = hostile.read1_dehosted,
      read2 = hostile.read2_dehosted,
      kraken2_db = kraken2_db,
      kraken2_args = "",
      classified_out = "classified#.fastq",
      unclassified_out = "unclassified#.fastq"
  }

  call utils_task.count_reads as count_reads_hrrt {
    input:
      read1 = hrrt.read1_dehosted,
      read2 = hrrt.read2_dehosted,
      samplename = samplename
  }

  call kraken2_task.kraken2_standalone as kraken2_clean_hrrt {
    input:
      samplename = samplename,
      read1 = hrrt.read1_dehosted,
      read2 = hrrt.read2_dehosted,
      kraken2_db = kraken2_db,
      kraken2_args = "",
      classified_out = "classified#.fastq",
      unclassified_out = "unclassified#.fastq"
  }

  output {
    # Kraken2 outputs
    ## Standard
    String kraken2_version = kraken2_raw.kraken2_version
    String kraken2_docker = kraken2_raw.kraken2_docker
    File kraken2_report_raw = kraken2_raw.kraken2_report
    Int read_pairs_raw = count_reads_raw.read_count_pairs
    ## hostile
    Float kraken2_percent_human_hostile = kraken2_clean_hostile.kraken2_percent_human
    File kraken2_report_hostile = kraken2_clean_hostile.kraken2_report
    Int read_pairs_hostile = count_reads_hostile.read_count_pairs
    ## hrrt
    Float kraken2_percent_human_hrrt = kraken2_clean_hrrt.kraken2_percent_human
    File kraken2_report_hrrt = kraken2_clean_hrrt.kraken2_report
    Int read_pairs_hrrt = count_reads_hrrt.read_count_pairs
    }
}