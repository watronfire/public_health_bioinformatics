version 1.0

task ska {
  input {
    Array[File] assembly_fasta
    Array[String] samplename
    String cluster_name
    Int kmer_size = 15
    Float min_kmer_prop = 0.9
    Int snp_cutoff = 20
    Float identity_cutoff = 0.9
    String docker_image = "staphb/ska:1.0"
    Int memory = 8
    Int cpu = 4
    Int disk_size = 100
  }
  command <<<
  # using assembly fasta
  assembly_array=(~{sep=' ' assembly_fasta})
  assembly_array_len=$(echo "${#assembly_array[@]}")
  samplename_array=(~{sep=' ' samplename})
  samplename_array_len=$(echo "${#samplename_array[@]}")

  # Ensure assembly, and samplename arrays are of equal length
  if [ "$assembly_array_len" -ne "$samplename_array_len" ]; then
    echo "Assembly array (length: $assembly_array_len) and samplename array (length: $samplename_array_len) are of unequal length." >&2
    exit 1
  fi

  # renaming fasta headers as ska will have a problem if there are similarly named contigs in different assembly files during merge
  assembly_array_modified=()
  for fasta_file in "${assembly_array[@]}"; do
    file_prefix="$(basename "$fasta_file" | sed 's/\.[^.]*$//')"
    new_file="${file_prefix}_modified.fa"
    assembly_array_modified+=("$new_file")
    while IFS= read -r line; do
        if [[ $line == ">"* ]]; then
            modified_header=">${file_prefix}_${line:1}"
        else
            modified_header="$line"
        fi
        echo "$modified_header" >> "$new_file"
    done < "$fasta_file"
  done

  # create a tab-separated list consisting of the sequence name and assembly file path as input
  touch ska_input_alleles.tsv
  # Loop through arrays and write to the file
  for (( i=0; i<${#assembly_array_modified[@]}; i++ )); do
    echo -e "${assembly_array_modified[$i]}" >> ska_input_alleles.tsv
  done

  # build an index of the split k-mers from the assemblies
  ska alleles \
    -f ska_input_alleles.tsv \
    -k ~{kmer_size}

  # input file for merge
  sed "s/\$/.skf/" ska_input_alleles.tsv  > ska_input_merge.tsv

  #merge the split k-mer files
  ska merge \
    -f ska_input_merge.tsv \
    -o ~{cluster_name}_ska_merged
  
  # calculate pairwise distances between and single-linkage clustering of samples in split kmer files based on user-defined SNP and identity cutoffs.
  ska distance \
    -s ~{snp_cutoff} \
    -i ~{identity_cutoff} \
    -o ~{cluster_name}_ska_distances \
    ~{cluster_name}_ska_merged.skf

  # reference-free alignment of split kmer files.
  split_kmers=$(( $(wc -l < ~{cluster_name}_ska_distances.clusters.tsv) - 1 ))
  min_prop=$(awk "BEGIN { printf \"%.2f\", ($assembly_array_len * ~{min_kmer_prop}) / $split_kmers }")
  #min_prop=$(( ($assembly_array_len * ~{min_kmer_prop}) / $split_kmers ))

  ska align \
    -k \
    -o ~{cluster_name}_ska_ref_free_aln \
    -p ${min_prop} \
    -v \
    ~{cluster_name}_ska_merged.skf

  >>>
  output {
    File ska_input = "ska_input_alleles.tsv"
    File ska_merged_kmer_files = "~{cluster_name}_ska_merged.skf"
    File ska_clusters = "~{cluster_name}_ska_distances.clusters.tsv"
    File ska_distances_tsv = "~{cluster_name}_ska_distances.distances.tsv"
    File ska_distances_dot = "~{cluster_name}_ska_distances.dot"
    File ska_alignment = "~{cluster_name}_ska_ref_free_aln_variants.aln"
    String ska_docker_image = docker_image
  }
  runtime {
    docker: docker_image
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk ~{disk_size} SSD"
    preemptible: 0
    maxRetries: 0
  }
}
