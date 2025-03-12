myfasta="/home/data/data_SsuChi/summertrain/reference_genome/GRCh38.d1.vd1.fa"
mygermline="/home/data/data_SsuChi/summertrain/reference_genome/gatk_ref/af-only-gnomad.hg38.vcf"
mypon="/home/data/data_SsuChi/summertrain/reference_genome/gatk_ref/1000g_pon.hg38.vcf"
mycommon="/home/data/data_SsuChi/summertrain/reference_genome/gatk_ref/small_exac_common_3.hg38.vcf.gz"
bedfile="/home/data/dataset/bed_file/KAPA_HyperExome_hg38_capture_targets.bed"
mysnp="/home/data/data_SsuChi/summertrain/reference_genome/Homo_sapiens_assembly38.dbsnp138.vcf"

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


gatk --java-options -Xmx64g HaplotypeCaller \
  -R ${myfasta} \
  -I ${normal}_sorted_du_bqsr.bam \
  -O ./haplotypecaller/${label}_germline.g.vcf.gz \
  -ERC GVCF \
  -L ${bedfile} \
  --dbsnp ${mysnp}

gatk --java-options -Xmx64g GenotypeGVCFs \
	-R ${myfasta} \
	-L ${bedfile} \
	--dbsnp ${mysnp} \
	-V ./haplotypecaller/${label}_germline.g.vcf.gz \
	-O ./haplotypecaller/${label}_germline.vcf.gz


done


#gatk --java-options -Xmx64g GenomicsDBImport \
#	-

#gatk --java-options -Xmx64g GenotypeGVCFs \
#	-R ${myfasta} \
#	-L ${bedfile} \
#	--dbsnp ${mysnp} \
#	-V ./haplotypecaller/${label}_germline.g.vcf.gz \
#	-O ./haplotypecaller/${label}_germline_g.vcf.gz

#gatk ExtractVariantAnnotations \
#	-V ./haplotypecaller/${label}_germline.vcf \
#	-A MQ -A FS -A QD -A MQRankSum  \
#	--resource:1kg,training=true /home/data/data_SsuChi/summertrain/reference_genome/gatk_ref/1000g_pon.hg38.vcf\
#	-mode SNP  \
#	-mode INDEL \
#	-O ${label}.extracted
#gatk TrainVariantAnnotationsModel \
#	--annotations-hdf5 ${label}.extracted.annot.hdf5 \
#	-mode SNP \
#	-mode INDEL \
#	-O ${label}.trained

#gatk ScoreVariantAnnotations \
#	-V input.vcf \
#	-A MQ -A FS -A QD -A MQRankSum \
#	--resource:1kg,training=true truth.vcf \
#	--resource:extracted,extracted=true output.extracted.vcf.gz \
#	-mode SNP \
#	-mode INDEL \
#	-O output.score \
#	--model-prefix output.trained \



#done


