version 1.0

task make_report {
  meta {
    description: "Generate a PDF and CSV report for specified columns in a Terra Data Table"
  }
  input {
    File terra_table
    String terra_table_name
    String samplename
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

    #### (theiaprok only) organism-specific output dictionary:
    organism_output_dictionary = {
      "Acinetobacter baumannii" : ["kaptive_version", "kaptive_k_match", "kaptive_k_type", "kaptive_k_confidence", "kaptive_oc_match", "kaptive_oc_type", "kaptive_oc_confidence", "abricate_genes", "abricate_database", "abricate_version"], # "abricate_docker"
      "Escherichia" : ["serotypefinder_docker", "serotypefinder_serotype", "ectyper_version", "ectyper_predicted_serotype", "shigatyper_predicted_serotype", "shigatyper_ipaB_presence_absence", "shigatyper_notes", "shigatyper_version", "shigeifinder_version", "shigeifinder_ipaH_presence_absence", "shigeifinder_num_virulence_plasmid_genes", "shigeifinder_cluster", "shigeifinder_serotype", "shigeifinder_O_antigen", "shigeifinder_H_antigen", "shigeifinder_notes", "virulencefinder_docker", "virulencefinder_hits"], # "shigatyper_docker", "shigeifinder_docker", 
      "Haemophilus influenzae" : ["hicap_serotype", "hicap_genes", "hicap_version"], # "hicap_docker" 
      "Klebsiella" : ["kleborate_version", "kleborate_key_resistance_genes", "kleborate_genomic_resistance_mutations", "kleborate_mlst_sequence_type", "kleborate_klocus", "kleborate_ktype", "kleborate_olocus", "kleborate_otype", "kleborate_klocus_confidence", "kleborate_olocus_confidence"], # "kleborate_docker", 
      "Legionella pneumophila" : ["legsta_predicted_sbt", "legsta_version"],
      "Listeria" : ["lissero_version", "lissero_serotype"],
      "Mycobacterium tuberculosis" : ["tbprofiler_version", "tbprofiler_main_lineage", "tbprofiler_sub_lineage", "tbprofiler_dr_type", "tbprofiler_resistance_genes"],
      "Neisseria gonorrhoeae" : ["ngmaster_version", "ngmaster_ngmast_sequence_type", "ngmaster_ngmast_porB_allele", "ngmaster_ngmast_tbpB_allele", "ngmaster_ngstar_sequence_type", "ngmaster_ngstar_penA_allele", "ngmaster_ngstar_mtrR_allele", "ngmaster_ngstar_porB_allele", "ngmaster_ngstar_ponA_allele", "ngmaster_ngstar_gyrA_allele", "ngmaster_ngstar_parC_allele", "ngmaster_ngstar_23S_allele"],
      "Neisseria meningitidis" : ["meningotype_version", "meningotype_serogroup", "meningotype_PorA", "meningotype_FetA", "meningotype_PorB", "meningotype_fHbp", "meningotype_NHBA", "meningotype_NadA", "meningotype_BAST"],
      "Pseudomonas aeruginosa" : ["pasty_serogroup", "pasty_serogroup_coverage", "pasty_serogroup_fragments", "pasty_version", "pasty_comment"], # "pasty_docker" 
      "Salmonella" : ["sistr_version", "sistr_predicted_serotype", "seqsero2_report", "seqsero2_version", "seqsero2_predicted_antigenic_profile", "seqsero2_predicted_serotype", "seqsero2_predicted_contamination", "genotyphi_version", "genotyphi_species", "genotyphi_st_probes_percent_coverage", "genotyphi_final_genotype", "genotyphi_genotype_confidence"],
      "Shigella" : ["serotypefinder_docker", "serotypefinder_serotype", "ectyper_version", "ectyper_predicted_serotype", "shigatyper_predicted_serotype", "shigatyper_ipaB_presence_absence", "shigatyper_notes", "shigatyper_version", "shigeifinder_version", "shigeifinder_ipaH_presence_absence", "shigeifinder_num_virulence_plasmid_genes", "shigeifinder_cluster", "shigeifinder_serotype", "shigeifinder_O_antigen", "shigeifinder_H_antigen", "shigeifinder_notes"], # "shigatyper_docker", "shigeifinder_docker"
      "Shigella_sonnei" : ["serotypefinder_docker", "serotypefinder_serotype", "ectyper_version", "ectyper_predicted_serotype", "shigatyper_predicted_serotype", "shigatyper_ipaB_presence_absence", "shigatyper_notes", "shigatyper_version",  "shigeifinder_version", "shigeifinder_ipaH_presence_absence", "shigeifinder_num_virulence_plasmid_genes", "shigeifinder_cluster", "shigeifinder_serotype", "shigeifinder_O_antigen", "shigeifinder_H_antigen", "shigeifinder_notes", "sonneityping_mykrobe_version", "sonneityping_species", "sonneityping_final_genotype", "sonneityping_genotype_confidence", "sonneityping_genotype_name"], # "shigatyper_docker", "shigeifinder_docker", "sonneityping_mykrobe_docker",
      "Staphylococcus aureus" : ["spatyper_repeats", "spatyper_type", "spatyper_version", "staphopiasccmec_types_and_mecA_presence", "staphopiasccmec_version", "staphopiasccmec_docker", "agrvate_agr_group", "agrvate_agr_match_score", "agrvate_agr_canonical", "agrvate_agr_multiple", "agrvate_agr_num_frameshifts", "agrvate_version"], # "spatyper_docker", "agrvate_docker"
      "Streptococcus pneumoniae" : ["pbptyper_predicted_1A_2B_2X", "pbptyper_version", "poppunk_gps_cluster", "poppunk_GPS_db_version", "poppunk_version", "seroba_version", "seroba_serotype", "seroba_ariba_serotype" "seroba_ariba_identity"], #"poppunk_docker", "pbptyper_docker", "seroba_docker", 
      "Streptococcus pyogenes" : ["emmtypingtool_emm_type", "emmtypingtool_version"], # "emmtypingtool_docker"
      "Vibrio" : ["srst2_vibrio_version", "srst2_vibrio_ctxA", "srst2_vibrio_ompW", "srst2_vibrio_toxR", "srst2_vibrio_serogroup", "srst2_vibrio_biotype"]
    }

    #### standard outputs (not organism-specific)
    standard_outputs = ["gambit_predicted_taxon", "gambit_version", "gambit_db_version", "amrfinderplus_amr_core_genes", "amrfinderplus_amr_plus_genes", "amrfinderplus_stress_genes", "amrfinderplus_virulence_genes", "amrfinderplus_amr_classes", "amrfinderplus_amr_subclasses", "amrfinderplus_version", "amrfinderplus_db_version", "plasmidfinder_plasmids", "plasmidfinder_db_version"]
    
    #### analysis version and date
    workflow_version_outputs = ["theiaprok_illumina_pe_version", "theiaprok_illumina_pe_analysis_date", "theiaprok_fasta_version", "theiaprok_fasta_analysis_date", "theiaprok_illumina_se_version", "theiaprok_illumina_se_analysis_date", "theiaprok_ont_version", "theiaprok_ont_analysis_date"]

    #### default QC metrics to report
    default_qc = ["num_reads_raw1", "num_reads_raw2", "num_reads_clean1", "num_reads_clean2", "r1_mean_q_raw", "r1_mean_q_clean", "r2_mean_q_raw", "r2_mean_q_clean", "combined_mean_q_raw", "combined_mean_q_clean", "r1_mean_readlength_raw", "r1_mean_readlength_clean", "r2_mean_readlength_raw", "r2_mean_readlength_clean", "combined_mean_readlength_raw", "combined_mean_readlength_clean", "midas_docker", "midas_primary_genus", "midas_secondary_genus", "midas_secondary_genus_abundance", "assembly_length", "number_contigs", "quast_gc_percent", "quast_version" "est_coverage_raw", "est_coverage_clean", "busco_version", "busco_results", "ani_mummer_version", "ani_highest_percent", "ani_top_species_match"]

    #### user-supplied columns
    additional_qc = "~{qc_columns}".split(",")
    additional_cols = "~{additional_columns}".split(",")
    ignore_cols = "~{ignore_columns}".split(",")

    # read exported Terra table into pandas
    table = pd.read_csv(~{terra_table}, delimiter='\t', header=0, index_col=False, dtype={"~{terra_table_name}_id": 'str'}) # ensure sample_id is always a string

    # extract the sample to report on
    row = table[table["~{terra_table_name}_id"] == "~{samplename}"]

    # determine which organism-specific columns to use
    if row["gambit_predicted_taxon"][0] not in organism_output_dictionary.keys():
      organism_specific_value = row["gambit_predicted_taxon"].str.extract('(%s)' % '|'.join(organism_output_dictionary.keys()))[0][0]
      if organism_specific_value not in organism_output_dictionary.keys():
        print("Organism indicated (" + str(row["gambit_predicted_taxon"][0]) + ") does not have any organism specific columns.")
        organism_specific = []
      else:
        organism_specific = organism_output_dictionary[organism_specific_value]
    else:  
      organism_specific = organism_output_dictionary[row["gambit_predicted_taxon"][0]]


    all_columns = standard_outputs + workflow_version_outputs + default_qc + additional_qc + additional_cols + ignore_cols + organism_specific
    for column in row:
      if column in 

    CODE
  >>>
  output {

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