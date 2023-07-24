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

# sstacks -P $src/stacks/ -M $src/popmaps/popmap -p 8
~~~

- To run this script we use next line:
```
sh run_stacks path_to_samples output_path* popmap
```
* The output path need to exist previously
## 3. Extract reads to fasta

## 4. Elastic-blast

## 5. Metagenomic analysis
