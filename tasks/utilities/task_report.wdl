version 1.0

task make_individual_report {
  meta {
    description: "Generate CSV report for a single sample"
  }
  input {
    File terra_table
    String terra_table_name
    String samplename
    String analyst_name
    String? qc_columns
    String? additional_columns
    String? ignore_columns

    Int disk_size = 100
  }
  command <<<
    python3 <<CODE
    import pandas as pd
    import numpy as np
    import os

    ### Establishing default columns to report
    # (theiaprok only) organism-specific output dictionary:
    organism_output_dictionary = {
      "Acinetobacter baumannii" : ["kaptive_version", "kaptive_k_locus", "kaptive_k_type", "kaptive_kl_confidence", "kaptive_oc_locus", "kaptive_ocl_confidence", "abricate_abaum_plasmid_type_genes", "abricate_database", "abricate_version"], # "abricate_docker"
      "Escherichia" : ["serotypefinder_docker", "serotypefinder_serotype", "ectyper_version", "ectyper_predicted_serotype", "shigatyper_predicted_serotype", "shigatyper_ipaB_presence_absence", "shigatyper_notes", "shigatyper_version", "shigeifinder_version", "shigeifinder_ipaH_presence_absence", "shigeifinder_num_virulence_plasmid_genes", "shigeifinder_cluster", "shigeifinder_serotype", "shigeifinder_O_antigen", "shigeifinder_H_antigen", "shigeifinder_notes", "shigeifinder_version_reads", "shigeifinder_ipaH_presence_absence_reads", "shigeifinder_num_virulence_plasmid_genes_reads", "shigeifinder_cluster_reads", "shigeifinder_serotype_reads", "shigeifinder_O_antigen_reads", "shigeifinder_H_antigen_reads", "shigeifinder_notes_reads", "virulencefinder_docker", "virulencefinder_hits"], # "shigatyper_docker", "shigeifinder_docker", 
      "Haemophilus influenzae" : ["hicap_serotype", "hicap_genes", "hicap_version"], # "hicap_docker" 
      "Klebsiella" : ["kleborate_version", "kleborate_key_resistance_genes", "kleborate_genomic_resistance_mutations", "kleborate_mlst_sequence_type", "kleborate_klocus", "kleborate_ktype", "kleborate_olocus", "kleborate_otype", "kleborate_klocus_confidence", "kleborate_olocus_confidence"], # "kleborate_docker", 
      "Legionella pneumophila" : ["legsta_predicted_sbt", "legsta_version"],
      "Listeria" : ["lissero_version", "lissero_serotype"],
      "Mycobacterium tuberculosis" : ["tbprofiler_version", "tbprofiler_main_lineage", "tbprofiler_sub_lineage", "tbprofiler_dr_type", "tbprofiler_resistance_genes"],
      "Neisseria gonorrhoeae" : ["ngmaster_version", "ngmaster_ngmast_sequence_type", "ngmaster_ngmast_porB_allele", "ngmaster_ngmast_tbpB_allele", "ngmaster_ngstar_sequence_type", "ngmaster_ngstar_penA_allele", "ngmaster_ngstar_mtrR_allele", "ngmaster_ngstar_porB_allele", "ngmaster_ngstar_ponA_allele", "ngmaster_ngstar_gyrA_allele", "ngmaster_ngstar_parC_allele", "ngmaster_ngstar_23S_allele"],
      "Neisseria meningitidis" : ["meningotype_version", "meningotype_serogroup", "meningotype_PorA", "meningotype_FetA", "meningotype_PorB", "meningotype_fHbp", "meningotype_NHBA", "meningotype_NadA", "meningotype_BAST"],
      "Pseudomonas aeruginosa" : ["pasty_serogroup", "pasty_serogroup_coverage", "pasty_serogroup_fragments", "pasty_version", "pasty_comment"], # "pasty_docker" 
      "Salmonella" : ["sistr_version", "sistr_predicted_serotype", "seqsero2_report", "seqsero2_version", "seqsero2_predicted_antigenic_profile", "seqsero2_predicted_serotype", "seqsero2_predicted_contamination", "genotyphi_version", "genotyphi_species", "genotyphi_st_probes_percent_coverage", "genotyphi_final_genotype", "genotyphi_genotype_confidence"],
      "Shigella" : ["serotypefinder_docker", "serotypefinder_serotype", "ectyper_version", "ectyper_predicted_serotype", "shigatyper_predicted_serotype", "shigatyper_ipaB_presence_absence", "shigatyper_notes", "shigatyper_version", "shigeifinder_version", "shigeifinder_ipaH_presence_absence", "shigeifinder_num_virulence_plasmid_genes", "shigeifinder_cluster", "shigeifinder_serotype", "shigeifinder_O_antigen", "shigeifinder_H_antigen", "shigeifinder_notes", "shigeifinder_version_reads", "shigeifinder_ipaH_presence_absence_reads", "shigeifinder_num_virulence_plasmid_genes_reads", "shigeifinder_cluster_reads", "shigeifinder_serotype_reads", "shigeifinder_O_antigen_reads", "shigeifinder_H_antigen_reads", "shigeifinder_notes_reads"], # "shigatyper_docker", "shigeifinder_docker"
      "Shigella sonnei" : ["serotypefinder_docker", "serotypefinder_serotype", "ectyper_version", "ectyper_predicted_serotype", "shigatyper_predicted_serotype", "shigatyper_ipaB_presence_absence", "shigatyper_notes", "shigatyper_version",  "shigeifinder_version", "shigeifinder_ipaH_presence_absence", "shigeifinder_num_virulence_plasmid_genes", "shigeifinder_cluster", "shigeifinder_serotype", "shigeifinder_O_antigen", "shigeifinder_H_antigen", "shigeifinder_notes", "shigeifinder_version_reads", "shigeifinder_ipaH_presence_absence_reads", "shigeifinder_num_virulence_plasmid_genes_reads", "shigeifinder_cluster_reads", "shigeifinder_serotype_reads", "shigeifinder_O_antigen_reads", "shigeifinder_H_antigen_reads", "shigeifinder_notes_reads", "sonneityping_mykrobe_version", "sonneityping_species", "sonneityping_final_genotype", "sonneityping_genotype_confidence", "sonneityping_genotype_name"], # "shigatyper_docker", "shigeifinder_docker", "sonneityping_mykrobe_docker",
      "Staphylococcus aureus" : ["spatyper_repeats", "spatyper_type", "spatyper_version", "staphopiasccmec_types_and_mecA_presence", "staphopiasccmec_version", "staphopiasccmec_docker", "agrvate_agr_group", "agrvate_agr_match_score", "agrvate_agr_canonical", "agrvate_agr_multiple", "agrvate_agr_num_frameshifts", "agrvate_version"], # "spatyper_docker", "agrvate_docker"
      "Streptococcus pneumoniae" : ["pbptyper_predicted_1A_2B_2X", "pbptyper_version", "poppunk_gps_cluster", "poppunk_GPS_db_version", "poppunk_version", "seroba_version", "seroba_serotype", "seroba_ariba_serotype" "seroba_ariba_identity"], #"poppunk_docker", "pbptyper_docker", "seroba_docker", 
      "Streptococcus pyogenes" : ["emmtypingtool_emm_type", "emmtypingtool_version"], # "emmtypingtool_docker"
      "Vibrio" : ["srst2_vibrio_version", "srst2_vibrio_ctxA", "srst2_vibrio_ompW", "srst2_vibrio_toxR", "srst2_vibrio_serogroup", "srst2_vibrio_biotype"]
    }

    # standard outputs (not organism-specific)
    standard_outputs = ["gambit_predicted_taxon", "gambit_version", "gambit_db_version", "amrfinderplus_amr_core_genes", "amrfinderplus_amr_plus_genes", "amrfinderplus_stress_genes", "amrfinderplus_virulence_genes", "amrfinderplus_amr_classes", "amrfinderplus_amr_subclasses", "amrfinderplus_version", "amrfinderplus_db_version", "plasmidfinder_plasmids", "plasmidfinder_db_version"]
    
    # analysis version and date
    workflow_version_outputs = ["theiaprok_illumina_pe_version", "theiaprok_illumina_pe_analysis_date", "theiaprok_fasta_version", "theiaprok_fasta_analysis_date", "theiaprok_illumina_se_version", "theiaprok_illumina_se_analysis_date", "theiaprok_ont_version", "theiaprok_ont_analysis_date"]

    # default QC metrics to report
    default_qc = ["num_reads_raw1", "num_reads_raw2", "num_reads_clean1", "num_reads_clean2", "r1_mean_q_raw", "r2_mean_q_raw", "combined_mean_q_raw", "combined_mean_q_clean", "r1_mean_readlength_raw", "r2_mean_readlength_raw", "combined_mean_readlength_raw", "combined_mean_readlength_clean", "midas_docker", "midas_primary_genus", "midas_secondary_genus", "midas_secondary_genus_abundance", "assembly_length", "number_contigs", "quast_gc_percent", "quast_version", "est_coverage_raw", "est_coverage_clean", "busco_version", "busco_results", "ani_mummer_version", "ani_highest_percent", "ani_top_species_match"]

    # columns to hide in the output tables but still needed for proper creation
    hidden_outputs =  ["~{terra_table_name}_id", "analyst_name"]

    # user-supplied columns
    additional_qc = "~{qc_columns}".split(",")
    additional_cols = "~{additional_columns}".split(",")
    ignore_cols = "~{ignore_columns}".split(",")

    ### Processing of data
    # read exported Terra table into pandas
    table = pd.read_csv("~{terra_table}", delimiter='\t', header=0, dtype={"~{terra_table_name}_id": 'str'}) # ensure sample_id is always a string

    # insert analyst name into the table
    table["analyst_name"] = "~{analyst_name}"

    # extract the sample to report on and rename ID column
    row = table[table["~{terra_table_name}_id"] == "~{samplename}"]
    row = row.rename(columns={"~{terra_table_name}_id": "sample"})

    # determine which organism-specific columns to use
    if row["gambit_predicted_taxon"].iloc[0] not in organism_output_dictionary.keys():
      # check to see if we should use genus-specific, not species (e.g., "Vibrio" outputs because there aren't any for "Vibrio cholerae")
      # see also stack overflow question: https://stackoverflow.com/questions/71909135/map-dataframe-with-dictionary-with-not-exact-match
      organism_specific_value = row["gambit_predicted_taxon"].str.extract('(%s)' % '|'.join(organism_output_dictionary.keys())).iloc[0][0]
      if organism_specific_value not in organism_output_dictionary.keys(): # if the organism doesn't have any organism-specific outputs,
        print("Organism indicated (" + str(row["gambit_predicted_taxon"].iloc[0]) + ") does not have any organism specific columns.")
        organism_specific = []
      else: # otherwise, use the genus-specific outputs
        organism_specific = organism_output_dictionary[organism_specific_value]
    else:  
      print(row["gambit_predicted_taxon"].iloc[0])
      organism_specific = organism_output_dictionary[row["gambit_predicted_taxon"].iloc[0]]

    # concatenate all of the columns to report
    all_columns = hidden_outputs + standard_outputs + workflow_version_outputs + default_qc + additional_qc + additional_cols + organism_specific
    # remove any "" items in the list (which is the case when no optional value is provided)
    all_columns = list(filter(None, all_columns))

    # remove any columns that were indicated to be ignored
    final_columns = [item for item in all_columns if item not in ignore_cols]
        
    final_row = pd.DataFrame(columns=final_columns)
    
    # this data frame will be written to a file that will not be given to the user but will be used in determining how to split up the outputs in the PDF report
    output_type = pd.DataFrame(columns=final_columns)

    for column in final_columns:
      if column in row.columns:
        # add the column to the final row
        final_row[column] = row[column]

        # specify what kind of output it is
        if (column in standard_outputs) or (column in additional_cols):
          output_type[column] = "standard"
        elif (column in default_qc) or (column in additional_qc):
          output_type[column] = "qc"
        elif column in organism_specific:
          output_type[column] = "organism"
        elif column in workflow_version_outputs:
          output_type[column] = "workflow versioning"
        elif column in hidden_outputs:
          output_type[column] = "hide"
        else:
          output_type[column] = "unclassified"

      elif column not in workflow_version_outputs:
        final_row[column] = ""
        output_type[column] = "unclassified"
      else: # it's a workflow version output for a different workflow and should be dropped
        final_row = final_row.drop(column, axis=1)
        output_type = output_type.drop(column, axis=1)

    # write row to file
    final_row.to_csv("~{samplename}.csv", sep = ',', index=False)

    # write output_type to file
    output_type.to_csv("~{samplename}_output_types.csv", sep=',', index=False)

    CODE
  >>>
  output {
    File individual_report = "~{samplename}.csv"
    File output_types = "~{samplename}_output_types.csv"
  }
  runtime {
    docker: "quay.io/theiagen/terra-tools:2023-06-21"
    memory: "5 GB"
    cpu: 2
    disks: "local-disk " + disk_size + " HDD"
    disk: disk_size + " GB"
    dx_instance_type: "mem1_ssd1_v2_x2"
  }
}

task aggregate_reports {
  meta {
    description: "Combine individual reports into a single, larger report"
  }
  input {
    String report_name
    Array[File] individual_reports

    Int disk_size = 100
  }
  command <<<
    python3 <<CODE
    import pandas as pd
    # create list of filenames
    filepaths = "~{sep='*' individual_reports}".split("*")

    # concatenate the data frames
    combined = pd.concat(map(pd.read_csv, filepaths), ignore_index=True)

    combined.to_csv("~{report_name}.combined.csv", index=False)
    CODE
  >>>
  output {
    File aggregated_reports = "~{report_name}.combined.csv"
  }
  runtime {
    docker: "quay.io/theiagen/terra-tools:2023-06-21"
    memory: "5 GB"
    cpu: 2
    disks: "local-disk " + disk_size + " HDD"
    disk: disk_size + " GB"
    dx_instance_type: "mem1_ssd1_v2_x2"
  }
}

task make_pdf {
  meta {
    description: "Combine individual reports into a single PDF"
  }
  input {
    Array[File] individual_reports
    Array[File] output_types
    Array[String] samplenames
    String report_name

    Int disk_size = 100
  }
  command <<<
    python3 <<CODE
    import pandas as pd
    import os
    from datetime import date
    from pretty_html_table import build_table

    # create lists from the input arrays
    samples = "~{sep="*" samplenames}".split("*")
    reports = "~{sep="*" individual_reports}".split("*")
    output_types = "~{sep="*" output_types}".split("*")

    # create a single html file
    html_output = "<!DOCTYPE html><html>"
    # add a zebra stripe in the tables
    html_output += "table{border-collapse: collapse;width: 100%;} th, td{text-align: left; padding: 8px;} tr:nth-child(even){background-color: #EDEDED;}</style>"

    # loop through each individual sample
    for entity in samples:
      filename = entity + ".csv"
      output_type = entity + "_output_types.csv"

      table = pd.read_csv(filename, delimiter='\t', header=0, dtype={"sample": 'str'}) # ensure sample_id is always a string
      types = pd.read_csv(output_type, delimiter='\t', header=0, dtype={"sample": 'str'})

      # create the html for a single sample
    
      html_output += "<body style=\"page-break-before: always;\"><h1>" + table["sample"] + "</h1>"
      html_output += "<h2>Report generated by " + table["analyst_name"] + " on " + str(date.today().isoformat()) + "</h2>"
      html_output += "<h3>Organism: " + table["gambit_predicted_taxon"] + "</h3>"
 
      # create empty strings in case there is no columns for that category
      qc_html_table = ""
      standard_html_table = ""
      organism_html_table = ""
    
      # iterate through the columns to separate them into their output types and generate a table
      for column in table.columns:
        if types[column] == "qc":
          qc_html_table += "<tr><th>" + column + "</th><td>" + str(table[column]) + "</td></tr>"
        elif types[column] == "standard":
          standard_html_table += "<tr><th>" + column + "</th><td>" + str(table[column]) + "</td></tr>"
        elif types[column] == "organism":
          organism_html_table += "<tr><th>" + column + "</th><td>" + str(table[column]) + "</td></tr>"
        elif types[column] == "unclassified":
          unclassified_html_table += "<tr><th>" + column + "</th><td>" + str(table[column]) + "</td></tr>"
        elif types[column] == "workflow versioning"
          version_information += "<p>Workflow version: " + str(table[column]) + "<p>"
      
      html_output += "<h3>QC metrics:</h3>"
      html_output += "<table style=\"width: auto\">" + qc_html_table + "</table>"

      html_output += "<h3>Standard outputs:</h3>"
      html_output += "<table style=\"width: auto\">" + qc_html_table + "</table>"

      html_output += "<h3>Organism-specific outputs:</h3>"
      html_output += "<table style=\"width: auto\">" + organism_html_table + "</table>"

      html_output += "<h3>Unclassified outputs:</h3>"
      html_output += "<table style=\"width: auto\">" + unclassified_html_table + "</table>"
      
      html_output += "</body>"

    html_output += "</html>"

    out_html_name = "~{report_name}.html"
    out_pdf_name = "~{report_name}.pdf"

    # save to output file
    with open(out_html_name, "w") as outfile:
      outfile.write(html_output)

    # convert to pdf
    options = {
      'page-size': 'Letter',
      'margin-top': '0.25in',
      'margin-right': '0.25in',
      'margin-bottom': '0.25in',
      'margin-left': '0.25in'
    }

    output_pdf = pdf.from_file(out_html_name, out_pdf_name, options=options)

    CODE
  >>>
  output {
    File pdf_report = "~{report_name}.pdf"
    File html_report = "~{report_name}.html"
  }
  runtime {
    docker: "quay.io/theiagen/terra-tools:2023-06-21"
    memory: "5 GB"
    cpu: 2
    disks: "local-disk " + disk_size + " HDD"
    disk: disk_size + " GB"
    dx_instance_type: "mem1_ssd1_v2_x2"
  }
}