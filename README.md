# ddRAD_Metagenomics

## 1. Demultiplex

## 2. ustacks, cstacks, sstacks
The *stacks* construction was developed with a single bash script with the first three steps of de novo pipeline of Stacks.
The code was taking and adapted from the guide user of stacks

- Bash code to run ustacks, cstacks, and sstacks


~~~
#!/bin/bash

# Path to demultiplexed samples
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

In order to write the code, next facts were taken in count
- ustacks generate three filer per analyzed sample: snps, alleles, tags
- cstacks generate a catalog that take all information generated in ustacks (also generate snps, alleles, tags)
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

In python, highlighted columns were extracted and used to generate a single table that match with the catalog ID of matches  and Locus ID of catalog tags to generate next dataframe.

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

Finally, fasta files were created using ```.to_csv``` function of pandas using ```\n``` as separator

## 4. Elastic-blast

We use BLAST to identify consensus sequences obtained through stacks using cloud computing tools. ElasticBlast is a tool that allow to perform alignments of billions reads using cloud computing services of Google Cloud and Amazon Web Services. We decided to use AWS services for this task. Before start, it is need to create permissions and settings in the aws account and the computer were the task is send.
1. Create IAM roles on the aws account. Elastic-blast requieres permissions to acces to computing instances, storage, read IAM roles, among other requiriments to run. To do this, we create the IAM roles accorging to the tool [website](https://blast.ncbi.nlm.nih.gov/doc/elastic-blast/iam-policy.html)
2. Increase aws account vCPUs limit. Amazon web services set a limit of vCPUs that the account can use according to the regular use. To increase this limit, a request need to be send to aws. This (website)[https://repost.aws/knowledge-center/ec2-on-demand-instance-vcpu-increase] has the instructions to increase the limit. Take in count that elastic-blast use On-Demand All Standard (A, C, D, H, I, M, R, T, Z) instances.
3. Install aws-cli establishing the configuration with the account.
4. A s3 bucket need to be created and contain the fasta file.

Before running the script, we merge all fasta files and remove duplicates to avoid redundant alignments.

We installed ```elastic-blast``` according the guide, and create the next confg file to perform a mega-blast using the nucleotide database (nt):

~~~
[cloud-provider]
aws-region =us-east-1

[cluster]
num-nodes = 5
labels = owner=alextest1

[blast]
program = blastn
db = nt
queries = s3://oreos3/meta_data/cat_nd.fasta
results = s3://oreos3/meta_data/results2
options = -task dc-megablast -evalue 0.01 -outfmt "6 qseqid sseqid staxids sskingdoms pident mismatch" -max_target_seqs 20
~~~
Finally, we run elastic-blast using the next code:
~~~
elastic-blast submit --cfg BDQA.ini
~~~

Result were obtained ofter 48 hours analsing 75 millions bp in 200 vCPUs

## 5. Metagenomic analysis
Once obtained and download the blast results, we create a python script to analyze the aligments. We took and adapt the R code published by [Holmes & Rabosky, 2018](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5907781/) where they perform metagenomics analysis of ddRadSeq using pyRAD instead of stacks. 
