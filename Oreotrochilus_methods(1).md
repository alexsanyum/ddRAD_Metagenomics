# *Oreotrochilus* project

We follow stacks v0.64 referenced pipeline in a *Oreotrochilus* reads. Dataset is a pair of files that correspond to a ddRad Seq that was sequences using a Pair-end protocol. Original data set have a weight of 60 GB and correspond to 96 samples. Some steps were first run into a small subsample with 40 million reads. We analyze this dataset using Stacks referenced pipeline using *Calypte anna* as a reference genome ([GCF_003957555.1](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_003957555.1)). Due to weight and number of samples, we run all analysis using cloud computing services.

We divide this guide into four sections

0. Cloud computing features
1. Demultiplex
2. SNP calling (gstacks)
3. Genotyping 


## 0. Cloud computing features

Computing analysis of this project was executed using amazon web services (aws). We use two services:

1. EC2 instance (computing service):
We generated a c5.9xlarge instace that have 36 vCPUs, and 72 GIB of memory (RAM). This were created with a Ubuntu Server 22.04 as AMI (operating system), and a gp2 storage volume of 24 gb.
2. S3 bucket (storage service):
A bucket were created to storage all data of the project.

Once the instance and bucket were created, we generated the needed permissions (API roles) to connect and use them at the same time. Finally, we set a local computer that connect to the instance and run all the analyses.


## 1. Demultiplexing
We use two software to demultiplex reads into samples in order to determinate potential errors in any software. We run this proof step into the subsample dataset. Next are shown all lines code to run each program

1.1 ```process_radtags``` stacks

~~~
process_radtags -i gzfastq -1 Oreo_40M_R1_001.fastq.gz -2 Oreo_40M_R2_001.fastq.gz -o ./test_process_40m_all_br/ -b barcodes.txt --inline-null --renz-1 pstI --renz-2 bfaI -r -c -q
~~~


1.2 pyrad, steps 1-2
Pyrad requires a parameters text file to run

~~~
------- ipyrad params file (v.0.9.87)-------------------------------------------
oreo_pyrad_40M_all_barcode                     ## [0] [assembly_name]: Assembly name. Used to name output directories for assembly steps
/home/alexsanyum/oreo_raw/pyradtest ## [1] [project_dir]: Project dir (made in curdir if not present)
../*.fastq.gz  ## [2] [raw_fastq_path]: Location of raw non-demultiplexed fastq files
../barcodes2.txt   ## [3] [barcodes_path]: Location of barcodes file
                               ## [4] [sorted_fastq_path]: Location of demultiplexed/sorted fastq files
denovo                         ## [5] [assembly_method]: Assembly method (denovo, reference)
                               ## [6] [reference_sequence]: Location of reference sequence file
rad                            ## [7] [datatype]: Datatype (see docs): rad, gbs, ddrad, etc.
TGCAG,                         ## [8] [restriction_overhang]: Restriction overhang (cut1,) or (cut1, cut2)
5                              ## [9] [max_low_qual_bases]: Max low quality base calls (Q<20) in a read
33                             ## [10] [phred_Qscore_offset]: phred Q score offset (33 is default and very standard)
6                              ## [11] [mindepth_statistical]: Min depth for statistical base calling
6                              ## [12] [mindepth_majrule]: Min depth for majority-rule base calling
10000                          ## [13] [maxdepth]: Max cluster depth within samples
0.85                           ## [14] [clust_threshold]: Clustering threshold for de novo assembly
0                              ## [15] [max_barcode_mismatch]: Max number of allowable mismatches in barcodes
2                              ## [16] [filter_adapters]: Filter for adapters/primers (1 or 2=stricter)
35                             ## [17] [filter_min_trim_len]: Min length of reads after adapter trim
2                              ## [18] [max_alleles_consens]: Max alleles per site in consensus sequences
0.05                           ## [19] [max_Ns_consens]: Max N's (uncalled bases) in consensus
0.05                           ## [20] [max_Hs_consens]: Max Hs (heterozygotes) in consensus
4                              ## [21] [min_samples_locus]: Min # samples per locus for output
0.2                            ## [22] [max_SNPs_locus]: Max # SNPs per locus
8                              ## [23] [max_Indels_locus]: Max # of indels per locus
0.5                            ## [24] [max_shared_Hs_locus]: Max # heterozygous sites per locus
0, 0, 0, 0                     ## [25] [trim_reads]: Trim raw read edges (R1>, <R1, R2>, <R2) (see docs)
0, 0, 0, 0                     ## [26] [trim_loci]: Trim locus edges (see docs) (R1>, <R1, R2>, <R2)
p, s, l                        ## [27] [output_formats]: Output formats (see docs)
                               ## [28] [pop_assign_file]: Path to population assignment file
                               ## [29] [reference_as_filter]: Reads mapped to this reference are removed in step 3
~~~
In order to run just demultiplex step we use next line:
~~~
ipyrad -p params-oreo_pyrad.txt -s12
~~~

We run these programs modifying the number of barcodes (samples) to determinate any possible bug on each one. Both software process_radtags and ipyrad return similar number of reads for each sample.

We decided to keep ```process_radtag``` results.

NOTE: We decide to do this validation because demultiplex log file were inconsistency with the read count in resulted samples. For example, log file reported that AVES-0361 sample keeps 9029032 reads, while a read count returned 167620 reads. Also, we have inconsistency between stacks versions. Firstly, we run this step with a stacks version that was installed from ubuntu apt library. This version returned a very low count of reads on each sample. We decided to move on download version of stacks from its official [website](https://catchenlab.life.illinois.edu/stacks/)

We submit a question regarding this issue on the official forum of stacks. You can find it here: https://groups.google.com/g/stacks-users/c/g1QaZVVbdig/m/LnbMHF5sBwAJ?utm_medium=email&utm_source=footer

Recommendations:
We recommend to run a proof of demultiplex with at least two software to determinate any possible error, then check up reads count in the log file and it the resulted files. Also, we recommend to use the software version of the website.




## 2. Mapping
After demultiplex step was concluded, we mapped each sample against *C. anna* reference genome using bwa software. To do this, we follow next steps

2.1 Download next FASTA genome: GCF_003957555.1 (Annotation file is not required)
2.2 Genome indexing using next line:
~~~
bwa index -p calype_ganome/calypte calype_ganome/GCF_003957555.1_bCalAnn1_v1.p_genomic.fna.gz
~~~
2.3 Map all samples
Once index were generated, we run bwa over all demultiplex samples. To do this we generated next sh script based on the stacks manual:
~~~
#!/bin/bash

path_to_samples='radtags_oreo'
bwa_index='/home/ubuntu/bucket/calypte_genome/calypte'

for read1 in "$path_to_samples"/*.1.fq.gz; do

read2="${read1/.1.fq.gz/.2.fq.gz}"

name=$(echo $read1 | cut -d'.' -f1 | cut -d'/' -f2)

echo "Analyzing $read1 and $read2 ..."
bwa mem -t 8 $bwa_index $read1 $read2 |
samtools view -b |
samtools sort --threads 4 > aligned/${name}.bam

echo "$read1 $read2" >> log_map.txt

done

~~~

# 3. SNP calling
After all reads were mapped, we continue the pipeline with ```gstacks``` program. To do this we use next line:
~~~
 stacks-2.64/gstacks -I aligned/ -M popmap_oreo.txt --rm-pcr-duplicates -O gstacks_oreo/ -t 5 
~~~

NOTE: This step was not run in the EC2 instance due to storage limitations. We notice that ```gstacks``` is not able to run properly using ec2 and s3 services. Even if the S3 bucket is connected to the instance, it was using instance storage (24 GB) instead of both S3 sotage or RAM memory. We could not determinate why or how to solve this issue so we decide to connect the S3 bucket to a local computer with enough storage for this step.


## 4. Genotyping
Last step correspond to a serie of different parametes combinations to run ```populations```. Next code were use as a templete to run all analyses
~~~
/root/stacks-2.64/populations -P gstacks_oreo/ -M popmap_oreo.txt -r 0.65 --genepop --fstats --smooth --hwe -t 32
~~~

Next table represent all combinations done

| Number of populations | whitelist    | fstats | random snp | Name                 |
|-----------------------|--------------|--------|------------|----------------------|
| 4                     | Oreo-jam-chi | Yes    | No         | 4pops_whitelist      |
| 14                    | Oreo 14pops  | No     | No         | 14pops_whitelist     |
| 2sppCZ                | Oreo 14 pops | No     | No         | 2sppCZ               |
| 4                     | No           | No     | Yes        | pop_oreo_random_snp  |
| 4                     | No           | No     | No         | populations_same_map |
| 10                    | No           | No     | No         | populations_diff_map |

Next code was developed to generate a whitelist that correspond to a subsample of n loci


```python
import pandas as pd
import random

def rand_whitelist(num_snp, num_loci):
    
    whitelist = random.sample(range(1,num_loci+1),num_snp)
    whitelist = pd.Series(whitelist)
    return whitelist
    
    
    
```


```python
rand_whitelist(8000,1141530,'14pops_8k_whitelist')
```




    0        28436
    1       572859
    2       833055
    3       256118
    4       970424
             ...  
    7995     22160
    7996    472390
    7997     97906
    7998    200341
    7999     24986
    Length: 8000, dtype: int64


