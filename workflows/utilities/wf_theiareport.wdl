version 1.0

workflow theiareport {
  input {
    # data location
    String terra_table
    String terra_workspace_name
    String terra_project_name 

    # samples to extract ? [ set or individual-level ?]
    String samplename


  }

}