
varscan="/home/data2/SRA_dataset/Hugo_2016/VarScan.v2.4.0.jar"
myfasta="/home/data/data_SsuChi/summertrain/reference_genome/GRCh38.d1.vd1.fa"

#source /home/SsuChi/miniconda3/etc/profile.d/conda.sh
#conda activate DNA

samples="`cut -d ',' -f 42 ./SraRunTable.txt | sort | uniq -c | awk '$1 == 2 {print $2}' | head -n 79 | tail -n 27`"

echo $samples

for i in $samples
do
normal="`cut -d ',' -f 1,27,42 ./SraRunTable.txt | grep $i | grep -w No | cut -d ',' -f 1 `"
tumor="`cut -d ',' -f 1,27,42 ./SraRunTable.txt | grep $i | grep -w Yes | cut -d ',' -f 1 `"
label=$i


echo $label
echo $tumor
echo $normal

samtools mpileup \
-f ${myfasta} \
-q 1 -B \
${tumor}_sorted_du_bqsr.bam >./varscan_result/${tumor}.pileup

samtools mpileup \
-f ${myfasta} \
-q 1 -B \
${normal}_sorted_du_bqsr.bam >./varscan_result/${normal}.pileup

# step2: callsnp
java -jar $varscan somatic \
./varscan_result/${normal}.pileup ./varscan_result/${tumor}.pileup ${label}_germline --output-vcf --min-var-freq 0.1
# step3
java -jar $varscan processSomatic ${label}_germline.snp.vcf --min-tumor-freq 0.1
java -jar $varscan processSomatic ${label}_germline.indel.vcf --min-tumor-freq 0.1

rm ./varscan_result/${normal}.pileup
rm ./varscan_result/${tumor}.pileup
done

