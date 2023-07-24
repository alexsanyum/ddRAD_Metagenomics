# ddRAD_Metagenomics

## 1. Demultiplex

## 2. ustacks, cstacks, sstacks
The *stacks* construnction was developed with a single bash script with the first three steps of de_novo pipeline of Stacks.
The code was taked and adaptep from the guide user of stacks

- Bash code to run ustacks, cstacks, and sstacks

~~~
#!/bin/bash

# Path to demultiplex samples
samples=${1}

# Output path
result=${2}

# Popmap file
popmap=${3}

# ustack 
id=1
for sample in $(ls $samples); do
  name=$(echo $sample | cut -d'.' -f 1) # get file name
	ustacks -f $samples$sample -o $result -i $id --name $name -M 4 -p 8 
	let "id+=1"
	
done

# cstack
stacks cstacks -n 6 -P $result -M $popmap -p 1

# sstacks
sstacks -P $src/stacks/ -M $src/popmaps/popmap -p 8
~~~

- To run this script we use next line:
```
sh run_stacks path_to_samples output_path* popmap
```
* The output path need to exist previously
## 3. Extract reads to fasta
Once we run stacks until the sstacks step, we use python to extract the consensus sequences from the catalog together with the sample information in the matches files. 

In order to write the code, next fact were take in count
- ustacks generate three filer per analysed sample: snps, alleles, tags
- cstacks generata a catalog recopilating all information generated in ustacks (also generate snps, alleles, tags)
- sstacks generate one additional ```.mathces``` file per sample that contain both sample and catalog identifier

Next table is an example of a matches file structure.  (Real file does not contain a header)


| **Catalog ID** | **SampleID** | LocusID | LocusID | Depth | CIGAR  |
|------------|----------|---------|---------|-------|--------|
| **192**        | **56**       | 2       | GG      | 18    | 100M2D |
| **39745**      | **56**       | 3       | AC      | 2     | 96M1D  |

Next table is an example of a catalog tag file

| Sample ID | **Locus ID** | Saquence Type | Stack | SequenceID                    | **Sequence**     | Flags |
|-----------|--------------|---------------|-------|-------------------------------|------------------|-------|
| 0         | **1**        | consensus     | 0     | seq_id1, seq_id2,..., seq_idn | **ATCGATCGATCG** | 0 0 0 |
| 0         | **2**        | consensus     | 0     | seq_id1, seq_id2,..., seq_idn | **ATCGATCGATCT** | 0 0 0 |
| 0         | **3**        | consensus     | 0     | seq_id1, seq_id2,..., seq_idn | **ACGATCGATCG**  | 0 0 0 |

In python, highlighted columns were extracted and used to generate a single table that match with the catalog ID of mathces and Locus ID of catalog tags to generate next dataframe

| Catalog ID | Sample ID | Sequence       |
|------------|-----------|----------------|
| 192        | 1         | ACTACGATCGATCG |
| 39745      | 2         | CGATCGATCGATCG |
| 4561       | 3         | GTCAGCTAGCTAGC |

Header for fasta file was generated as show next
| Sequence name | Sequence       |
|-----------------------|----------------|
| Catalog:192, Sample: 1         | ACTACGATCGATCG |
| Catalog:39745, Sample: 2         | CGATCGATCGATCG |
| Catalog:4561, Sample: 3         | GTCAGCTAGCTAGC |

Finally, fasta file was created using ```.to_csv``` function of pandas using ```\n``` as separator

## 4. Elastic-blast



## 5. Metagenomic analysis
