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
