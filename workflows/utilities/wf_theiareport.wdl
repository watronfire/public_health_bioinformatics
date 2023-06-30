version 1.0

import "../../tasks/utilities/task_download_terra_table.wdl" as download_task
import "../../tasks/utilities/task_report.wdl" as report_task

workflow theiareport {
  input {
    # data location
    String terra_table_name
    String terra_workspace_name
    String terra_project_name 
    Array[String] samplenames
    String? qc_columns # comma-separated list of additional QC values to report
    String? additional_columns # comma-separated list of additional values to report
    String? ignore_columns # comma-separated list of columns to not report
  }
  call download_task.download_terra_table {
    input:
      terra_table_name = terra_table_name,
      terra_workspace_name = terra_workspace_name,
      terra_project_name = terra_project_name
  }
  scatter (sample in samplenames) {
    call report_task.make_report {
      input:
        terra_table = download_terra_table.terra_table,
        samplename = sample
    }
  }
}