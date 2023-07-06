version 1.0

import "../../tasks/utilities/task_download_terra_table.wdl" as download_task
import "../../tasks/utilities/task_report.wdl" as report_task
import "../../tasks/task_versioning.wdl" as versioning_task

workflow theiareport {
  input {
    # data location
    String terra_table_name
    #String terra_workspace_name
    #String terra_project_name 
    File terra_table
    Array[String] samplenames
    String analyst_name
    String report_name
    String? qc_columns # comma-separated list of additional QC values to report
    String? additional_columns # comma-separated list of additional values to report
    String? ignore_columns # comma-separated list of columns to not report
  }
  # call download_task.download_terra_table {
  #   input:
  #     terra_table_name = terra_table_name,
  #     terra_workspace_name = terra_workspace_name,
  #     terra_project_name = terra_project_name
  # }
  scatter (sample in samplenames) {
    call report_task.make_individual_report {
      input:
        #terra_table = download_terra_table.terra_table,
        terra_table = terra_table,
        terra_table_name = terra_table_name,
        samplename = sample,
        analyst_name = analyst_name,
        qc_columns = qc_columns,
        additional_columns = additional_columns,
        ignore_columns = ignore_columns
    }
  }
  call report_task.aggregate_reports {
    input:
      report_name = report_name,
      individual_reports = make_individual_report.individual_report
  }
  call report_task.make_pdf {
    input:
      report_name = report_name,
      individual_reports = make_individual_report.individual_report,
      output_types = make_individual_report.output_types,
      samplenames = samplenames
  }
  call versioning_task.version_capture {
  }
  output {
    String theiareport_version = version_capture.phb_version
    String theiareport_date = version_capture.date
    Array[File] individual_reports = make_individual_report.individual_report
    File aggregated_reports = aggregate_reports.aggregated_reports
    File pdf_report = make_pdf.pdf_report
  }
}