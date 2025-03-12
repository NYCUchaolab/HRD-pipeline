myfasta="/home/data/data_SsuChi/summertrain/reference_genome/GRCh38.d1.vd1.fa"
mygermline="/home/data/data_SsuChi/summertrain/reference_genome/gatk_ref/af-only-gnomad.hg38.vcf"
mypon="/home/data/data_SsuChi/summertrain/reference_genome/gatk_ref/1000g_pon.hg38.vcf"
mycommon="/home/data/data_SsuChi/summertrain/reference_genome/gatk_ref/small_exac_common_3.hg38.vcf.gz"
bedfile="/home/data/dataset/bed_file/KAPA_HyperExome_hg38_capture_targets.bed"



samples="`cut -d ',' -f 42 SraRunTable.txt | sort | uniq -c | awk '$1 == 2 {print $2}' | head -n 79 | tail -n 27`"
for i in $samples
do
normal="`cut -d ',' -f 1,27,42 SraRunTable.txt | grep $i | grep -w No | cut -d ',' -f 1 `"
tumor="`cut -d ',' -f 1,27,42 SraRunTable.txt | grep $i | grep -w Yes | cut -d ',' -f 1 `"
label=$i

#s="`cut -d ',' -f 1,40 SraRunTable.txt | grep -w Pt"$i"`"
#tumor="`cut -d ',' -f 1 SraRunTable\(1\).txt | awk 'NR == '$((2 * $i + 1))''`"
#normal="`cut -d ',' -f 1 SraRunTable\(1\).txt | awk 'NR == '$((2 * $i))''`"
#label="`cut -d ',' -f 35 SraRunTable\(1\).txt | awk 'NR == '$((2 * $i))'' | cut -d '-' -f 1`"



gatk Mutect2 -R ${myfasta} \
        -L ${bedfile} \
        -I ${tumor}_sorted_du_bqsr.bam \
        -I ${normal}_sorted_du_bqsr.bam \
        -normal ${normal} \
        -tumor ${tumor} \
        --germline-resource \
        ${mygermline} \
        -pon ${mypon} \
        -O ${label}_unfiltered.vcf

gatk GetPileupSummaries -I ${tumor}_sorted_du_bqsr.bam \
        -V ${mycommon} \
        -L ${mycommon} \
        -O ${tumor}-pileups.table

gatk GetPileupSummaries -I ${normal}_sorted_du_bqsr.bam \
        -V ${mycommon} \
        -L ${mycommon} \
        -O ${normal}-pileups.table

gatk CalculateContamination \
        -I ${tumor}-pileups.table \
        -matched ${normal}-pileups.table \
        -O ${label}_contamination.table \
        -tumor-segmentation ${label}_segments.table

gatk FilterMutectCalls -R ${myfasta} \
        -V ${label}_unfiltered.vcf \
        --tumor-segmentation ${label}_segments.table \
        --contamination-table ${label}_contamination.table \
        -O ./gatk_result/${label}_filtered.vcf

done

