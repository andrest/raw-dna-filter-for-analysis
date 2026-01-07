#!/bin/bash

#===============================================================================
# UNIVERSAL DNA VARIANT FILTER
# Extracts neuropsychiatric-relevant genetic variants from raw DNA data files
#===============================================================================
#
# SUPPORTED FORMATS:
#   Consumer DNA Services:
#   - AncestryDNA (.txt)
#   - 23andMe (.txt)
#   - MyHeritage (.csv)
#   - FamilyTreeDNA (.csv)
#   - LivingDNA (.csv/.txt)
#   - Nebula Genomics (.txt)
#   - Dante Labs (.txt)
#   - Genes for Good (.txt)
#
#   Research/Clinical Formats:
#   - VCF (Variant Call Format) (.vcf, .vcf.gz)
#   - PLINK (.ped/.map, .bed/.bim/.fam)
#   - Illumina GenomeStudio FinalReport (.txt, .csv)
#   - Illumina GSA array exports
#   - Generic tab/comma-separated with rsID column
#
# USAGE:
#   ./filter_dna_variants.sh <input_file> [output_file]
#
# EXAMPLES:
#   ./filter_dna_variants.sh AncestryDNA.txt
#   ./filter_dna_variants.sh 23andme_raw.txt my_variants.txt
#   ./filter_dna_variants.sh myheritage_raw.csv filtered.txt
#   ./filter_dna_variants.sh sample.vcf variants.txt
#   ./filter_dna_variants.sh FinalReport.txt filtered.txt
#
# OUTPUT:
#   A filtered text file containing only the variants relevant for
#   neuropsychiatric and pharmacogenomic analysis, organized by gene/pathway.
#
# PRIVACY NOTE:
#   The output file contains only ~200 specific variants (out of 600,000+)
#   related to brain chemistry, stress response, and drug metabolism.
#   This is safe to share for educational analysis while keeping the
#   vast majority of your genetic data private.
#
#===============================================================================

set -euo pipefail

# Colors for terminal output (disabled if not a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

# Default values
INPUT="${1:-}"
OUTPUT="${2:-dna_variants_filtered.txt}"
TEMP_DIR=""

#-------------------------------------------------------------------------------
# CLEANUP
#-------------------------------------------------------------------------------
cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

#-------------------------------------------------------------------------------
# HELP TEXT
#-------------------------------------------------------------------------------
show_help() {
    cat << 'EOF'
UNIVERSAL DNA VARIANT FILTER
============================

Extracts neuropsychiatric-relevant genetic variants from raw DNA data files.

USAGE:
    ./filter_dna_variants.sh <input_file> [output_file]

ARGUMENTS:
    input_file    Your raw DNA data file (required)
    output_file   Output filename (default: dna_variants_filtered.txt)

SUPPORTED SERVICES & FORMATS:

  Consumer DNA Testing:
    • AncestryDNA      (.txt file from DNA settings page)
    • 23andMe          (.txt file from Browse Raw Data)
    • MyHeritage       (.csv file from DNA settings)
    • FamilyTreeDNA    (.csv file from myFTDNA)
    • LivingDNA        (.csv or .txt file)
    • Nebula Genomics  (.txt file)
    • Dante Labs       (.txt file)
    • Genes for Good   (.txt file)

  Research/Clinical Formats:
    • VCF              (Variant Call Format, .vcf or .vcf.gz)
    • PLINK            (.ped or .bim files)
    • Illumina         (GenomeStudio FinalReport, GSA exports)
    • Generic          (Any TSV/CSV with rsID, chr, pos, alleles)

HOW TO GET YOUR RAW DATA:

  AncestryDNA:  Settings > DNA Settings > Download Raw DNA Data
  23andMe:      Settings > 23andMe Data > Download Raw Data
  MyHeritage:   DNA > Manage DNA kits > Export Data
  FTDNA:        myFTDNA > Download Raw Data

WHAT THIS EXTRACTS:

  ~200 variants across these categories:
    • Dopamine system (COMT, DRD2, DRD3, DRD4, DAT1, DBH)
    • Serotonin system (SERT, 5-HT2A, TPH2, MAOA)
    • Stress response (FKBP5, NR3C1, CRHR1, BDNF)
    • GABA receptors (GABRA2, GABBR1/2)
    • Methylation (MTHFR, MTR, MTRR)
    • Drug metabolism (CYP2D6, CYP2C19, CYP1A2)
    • And more...

PRIVACY:
    Your raw DNA file contains 600,000-700,000+ variants.
    This script extracts only ~200 specific variants (~0.03%).
    The filtered output is safe to share for educational analysis.

EOF
    exit 0
}

#-------------------------------------------------------------------------------
# INPUT VALIDATION
#-------------------------------------------------------------------------------
if [[ -z "$INPUT" ]] || [[ "$INPUT" == "-h" ]] || [[ "$INPUT" == "--help" ]]; then
    show_help
fi

if [[ ! -f "$INPUT" ]]; then
    echo -e "${RED}Error: Input file '$INPUT' not found${NC}"
    echo ""
    echo "Usage: ./filter_dna_variants.sh <input_file> [output_file]"
    echo "Run with --help for more information"
    exit 1
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)

#-------------------------------------------------------------------------------
# COMPREHENSIVE RSID LIST - Neuropsychiatric & Pharmacogenomic Variants
#-------------------------------------------------------------------------------

declare -A GENE_CATEGORIES

GENE_CATEGORIES["MTHFR_Methylation"]="rs1801133 rs1801131 rs4846049 rs17367504"
GENE_CATEGORIES["COMT_Dopamine_Clearance"]="rs4680 rs4633 rs6269 rs165599 rs2274976 rs4818 rs5993883 rs933271"
GENE_CATEGORIES["DRD2_Dopamine_D2_Receptor"]="rs1800497 rs6277 rs1079597 rs2283265 rs1076560 rs12364283 rs2075654 rs4245147 rs4274224 rs4648317 rs4648318 rs7131056 rs11214607 rs17115461"
GENE_CATEGORIES["DRD3_Dopamine_D3_Receptor"]="rs6280 rs2134655 rs963468 rs324029"
GENE_CATEGORIES["DRD4_Dopamine_D4_Receptor"]="rs1800955 rs747302 rs936462 rs916455 rs11246226 rs3758653"
GENE_CATEGORIES["DRD1_Dopamine_D1_Receptor"]="rs4532 rs265981 rs686 rs5326"
GENE_CATEGORIES["DAT1_Dopamine_Transporter"]="rs27072 rs40184 rs2652511 rs463379 rs27048 rs6347 rs2550946 rs37020 rs11564750 rs2975226"
GENE_CATEGORIES["DBH_Dopamine_Beta_Hydroxylase"]="rs1611115 rs1108580 rs2519152 rs129882 rs1611122 rs2007153 rs6271"
GENE_CATEGORIES["NET_Norepinephrine_Transporter"]="rs5569 rs36024 rs1805065 rs28386840 rs2242446 rs998424 rs3785143"
GENE_CATEGORIES["SERT_Serotonin_Transporter"]="rs25531 rs6354 rs25532 rs2020933 rs140700 rs1042173"
GENE_CATEGORIES["5HT2A_Serotonin_2A_Receptor"]="rs6313 rs6314 rs7997012 rs2770304 rs1923884 rs6311"
GENE_CATEGORIES["5HT1A_Serotonin_1A_Receptor"]="rs6295 rs1364043 rs749099"
GENE_CATEGORIES["TPH2_Serotonin_Synthesis"]="rs4570625 rs1386494 rs1843809 rs1487275 rs2171363 rs11179000"
GENE_CATEGORIES["MAOA_MAOB_Monoamine_Oxidase"]="rs1137070 rs1799836 rs3027407 rs6323 rs2064070 rs979605 rs979606"
GENE_CATEGORIES["OPRM1_Opioid_Receptor"]="rs1799971 rs563649 rs2075572 rs589046"
GENE_CATEGORIES["FKBP5_Stress_Response"]="rs1360780 rs9296158 rs3800373 rs9470080 rs4713916 rs737054"
GENE_CATEGORIES["NR3C1_Glucocorticoid_Receptor"]="rs41423247 rs6189 rs6190 rs6195 rs33388 rs33389"
GENE_CATEGORIES["CRHR1_CRH_Receptor"]="rs110402 rs242924 rs7209436 rs4792887"
GENE_CATEGORIES["BDNF_Neurotrophic_Factor"]="rs6265 rs7124442 rs2049046 rs11030101 rs10767664 rs988748 rs11030104"
GENE_CATEGORIES["GABAA_Receptors"]="rs211014 rs279858 rs279871 rs567926 rs894269 rs3219151 rs2229940 rs424740 rs1816072 rs1176744"
GENE_CATEGORIES["GABAB_Receptors"]="rs29220 rs2808531 rs944688 rs3780428 rs1999501 rs2514218"
GENE_CATEGORIES["Nicotinic_Receptors"]="rs16969968 rs1051730 rs578776 rs3743078 rs1044396 rs2236196"
GENE_CATEGORIES["CACNA1C_Calcium_Channel"]="rs1006737 rs2007044 rs4765913 rs7297582"
GENE_CATEGORIES["CLOCK_Circadian_Genes"]="rs1801260 rs11932595 rs12504300 rs934945 rs228697"
GENE_CATEGORIES["Glutamate_System"]="rs1954787 rs2229193 rs1805502 rs3764028 rs4755404"
GENE_CATEGORIES["OXTR_Oxytocin_Receptor"]="rs53576 rs2254298 rs1042778 rs7632287"
GENE_CATEGORIES["ADRA2A_Alpha2_Adrenergic"]="rs1800544 rs553668 rs521674"
GENE_CATEGORIES["Endocannabinoid_System"]="rs1049353 rs806380 rs7766029 rs324420"
GENE_CATEGORIES["ANK3_Mood_Regulation"]="rs10994336 rs9804190"
GENE_CATEGORIES["SNAP25_ADHD"]="rs7495132 rs362584 rs3746544"
GENE_CATEGORIES["Folate_B_Vitamin_Metabolism"]="rs1051266 rs234706 rs2236225 rs1805087 rs1801394 rs7946 rs2287780 rs10380"
GENE_CATEGORIES["VDR_Vitamin_D_Receptor"]="rs1544410 rs731236 rs7975232 rs2228570"
GENE_CATEGORIES["ADRB2_Beta2_Adrenergic"]="rs1042713 rs1042714"
GENE_CATEGORIES["CYP450_Drug_Metabolism"]="rs1065852 rs16947 rs3892097 rs1799853 rs1057910 rs4244285 rs12248560 rs4986893 rs762551"
GENE_CATEGORIES["Inflammation_Markers"]="rs1800629 rs1800795"

#-------------------------------------------------------------------------------
# BUILD COMPLETE RSID LIST
#-------------------------------------------------------------------------------
ALL_RSIDS=""
for category in "${!GENE_CATEGORIES[@]}"; do
    ALL_RSIDS="$ALL_RSIDS ${GENE_CATEGORIES[$category]}"
done

# Create sorted unique list
echo $ALL_RSIDS | tr ' ' '\n' | sort -u > "$TEMP_DIR/rsid_list.txt"

#-------------------------------------------------------------------------------
# FILE FORMAT DETECTION
#-------------------------------------------------------------------------------
detect_format() {
    local file="$1"
    local head_content
    local first_data_line
    
    # Handle gzipped files
    if [[ "$file" == *.gz ]]; then
        head_content=$(zcat "$file" 2>/dev/null | head -50)
        first_data_line=$(echo "$head_content" | grep -v '^#' | grep -v '^$' | head -1)
    else
        head_content=$(head -50 "$file")
        first_data_line=$(grep -v '^#' "$file" | grep -v '^$' | head -1)
    fi
    
    # VCF format detection
    if echo "$head_content" | grep -q "^##fileformat=VCF"; then
        echo "vcf"
        return
    fi
    
    # PLINK .bim format (6 columns: chr, rsid, cm, pos, a1, a2)
    if [[ $(echo "$first_data_line" | awk -F'\t' '{print NF}') -eq 6 ]] && \
       echo "$first_data_line" | grep -qE "^[0-9XYM]+[[:space:]]+rs[0-9]+[[:space:]]"; then
        echo "plink_bim"
        return
    fi
    
    # Illumina GenomeStudio FinalReport
    if echo "$head_content" | grep -qiE "^\[Header\]|GSGT Version|GenomeStudio"; then
        echo "illumina_report"
        return
    fi
    
    # Consumer DNA services
    if echo "$head_content" | grep -qi "AncestryDNA"; then
        echo "ancestrydna"
        return
    fi
    
    if echo "$head_content" | grep -qi "23andMe"; then
        echo "23andme"
        return
    fi
    
    if echo "$head_content" | grep -qi "MyHeritage"; then
        echo "myheritage"
        return
    fi
    
    if echo "$head_content" | grep -qi "FTDNA\|FamilyTreeDNA"; then
        echo "ftdna"
        return
    fi
    
    if echo "$head_content" | grep -qi "Living DNA"; then
        echo "livingdna"
        return
    fi
    
    if echo "$head_content" | grep -qi "Nebula"; then
        echo "nebula"
        return
    fi
    
    if echo "$head_content" | grep -qi "Dante"; then
        echo "dante"
        return
    fi
    
    # Generic format detection based on structure
    # Check for rsID in first column with tab separator
    if echo "$first_data_line" | grep -qE "^rs[0-9]+[[:space:]]"; then
        if echo "$first_data_line" | grep -q $'\t'; then
            echo "generic_tsv_rsid_first"
        else
            echo "generic_csv_rsid_first"
        fi
        return
    fi
    
    # Check for rsID anywhere in tab-separated line
    if echo "$first_data_line" | grep -qE "[[:space:]]rs[0-9]+[[:space:]]"; then
        echo "generic_tsv"
        return
    fi
    
    # Check header row for column names
    local header_line=$(echo "$head_content" | grep -iE "rsid|snp.?name|variant|marker" | head -1)
    if [[ -n "$header_line" ]]; then
        if echo "$header_line" | grep -q $'\t'; then
            echo "generic_tsv_with_header"
        else
            echo "generic_csv_with_header"
        fi
        return
    fi
    
    # Default: try to figure it out by delimiter
    if echo "$first_data_line" | grep -q $'\t'; then
        echo "generic_tsv"
    elif echo "$first_data_line" | grep -q ","; then
        echo "generic_csv"
    else
        echo "unknown"
    fi
}

#-------------------------------------------------------------------------------
# FORMAT-SPECIFIC EXTRACTION FUNCTIONS
#-------------------------------------------------------------------------------

extract_vcf() {
    local file="$1"
    local cat_cmd="cat"
    [[ "$file" == *.gz ]] && cat_cmd="zcat"
    
    $cat_cmd "$file" | grep -v "^##" | \
    awk -F'\t' 'BEGIN{OFS="\t"} 
        /^#CHROM/ {next}
        $3 ~ /^rs[0-9]+$/ {
            # Extract genotype from first sample (column 10+)
            if (NF >= 10) {
                split($10, gt, ":")
                gsub(/[|\/]/, " ", gt[1])
                split(gt[1], alleles, " ")
                
                # Map allele indices to actual alleles
                split($5, alts, ",")
                a1 = (alleles[1] == "0") ? $4 : alts[alleles[1]]
                a2 = (length(alleles) > 1 && alleles[2] != "") ? ((alleles[2] == "0") ? $4 : alts[alleles[2]]) : a1
            } else {
                a1 = $4
                a2 = ($5 != ".") ? $5 : $4
            }
            print $3, $1, $2, a1, a2
        }'
}

extract_plink_bim() {
    local file="$1"
    # .bim format: chr, rsid, cm, pos, a1, a2 (space or tab separated)
    awk 'BEGIN{OFS="\t"} 
        $2 ~ /^rs[0-9]+$/ {
            print $2, $1, $4, $5, $6
        }' "$file"
}

extract_illumina_report() {
    local file="$1"
    # Find [Data] section and extract
    awk -F'\t' 'BEGIN{OFS="\t"; in_data=0; rsid_col=0; chr_col=0; pos_col=0; a1_col=0; a2_col=0}
        /^\[Data\]/ {in_data=1; next}
        in_data==1 && NF>3 && rsid_col==0 {
            # Parse header row
            for(i=1; i<=NF; i++) {
                col = tolower($i)
                gsub(/[^a-z0-9]/, "", col)
                if (col ~ /snpname|rsid|marker/) rsid_col = i
                if (col ~ /^chr$|chromosome/) chr_col = i
                if (col ~ /^pos$|position/) pos_col = i
                if (col ~ /allele1/) a1_col = i
                if (col ~ /allele2/) a2_col = i
            }
            next
        }
        in_data==1 && rsid_col>0 && $rsid_col ~ /^rs[0-9]+$/ {
            chr = (chr_col>0) ? $chr_col : "."
            pos = (pos_col>0) ? $pos_col : "."
            a1 = (a1_col>0) ? $a1_col : "."
            a2 = (a2_col>0) ? $a2_col : "."
            print $rsid_col, chr, pos, a1, a2
        }' "$file"
}

extract_consumer_tsv() {
    local file="$1"
    # Standard consumer format: rsid, chr, pos, allele1, allele2 (tab-separated)
    grep -v "^#" "$file" | \
    awk -F'\t' 'BEGIN{OFS="\t"} 
        NF>=4 && $1 ~ /^rs[0-9]+$/ {
            a1 = $4
            a2 = (NF>=5) ? $5 : $4
            # Handle combined genotype format (e.g., "AG" instead of "A" "G")
            if (length(a1) == 2 && (a2 == "" || a2 == a1)) {
                a2 = substr(a1, 2, 1)
                a1 = substr(a1, 1, 1)
            }
            print $1, $2, $3, a1, a2
        }'
}

extract_consumer_csv() {
    local file="$1"
    # CSV version of consumer format
    grep -v "^#" "$file" | grep -v "^\"#" | \
    sed 's/","/\t/g; s/"//g; s/,/\t/g' | \
    awk -F'\t' 'BEGIN{OFS="\t"} 
        NF>=4 && $1 ~ /^rs[0-9]+$/ {
            a1 = $4
            a2 = (NF>=5) ? $5 : $4
            if (length(a1) == 2 && (a2 == "" || a2 == a1)) {
                a2 = substr(a1, 2, 1)
                a1 = substr(a1, 1, 1)
            }
            print $1, $2, $3, a1, a2
        }'
}

extract_generic_with_header() {
    local file="$1"
    local sep="$2"  # "\t" or ","
    
    awk -v sep="$sep" 'BEGIN{
        if (sep == "comma") FS=","
        else FS="\t"
        OFS="\t"
        rsid_col=0; chr_col=0; pos_col=0; a1_col=0; a2_col=0; gt_col=0
    }
    NR<=5 && rsid_col==0 {
        for(i=1; i<=NF; i++) {
            col = tolower($i)
            gsub(/[^a-z0-9]/, "", col)
            if (col ~ /^rsid$|snpname|markerid|variantid/) rsid_col = i
            if (col ~ /^chr$|chromosome|chrom/) chr_col = i
            if (col ~ /^pos$|position|^bp$/) pos_col = i
            if (col ~ /allele1|^a1$|^ref$/) a1_col = i
            if (col ~ /allele2|^a2$|^alt$/) a2_col = i
            if (col ~ /genotype|^gt$|call/) gt_col = i
        }
        if (rsid_col > 0) next
    }
    rsid_col>0 && $rsid_col ~ /^rs[0-9]+$/ {
        chr = (chr_col>0) ? $chr_col : "."
        pos = (pos_col>0) ? $pos_col : "."
        
        if (a1_col>0 && a2_col>0) {
            a1 = $a1_col
            a2 = $a2_col
        } else if (gt_col>0) {
            gt = $gt_col
            gsub(/[^ACGT]/, "", gt)
            a1 = substr(gt, 1, 1)
            a2 = substr(gt, 2, 1)
            if (a2 == "") a2 = a1
        } else {
            a1 = "."
            a2 = "."
        }
        print $rsid_col, chr, pos, a1, a2
    }' "$file"
}

extract_generic_search() {
    local file="$1"
    # Try to find rsID patterns and extract surrounding data
    grep -E "rs[0-9]+" "$file" | \
    sed 's/[,;|]/\t/g' | \
    awk 'BEGIN{OFS="\t"} {
        for(i=1; i<=NF; i++) {
            if ($i ~ /^rs[0-9]+$/) {
                rsid = $i
                chr = "."
                pos = "."
                a1 = "."
                a2 = "."
                # Try to find chr/pos/alleles in nearby fields
                for(j=1; j<=NF; j++) {
                    if (j != i) {
                        if ($j ~ /^[0-9]+$/ && length($j) > 4 && pos == ".") pos = $j
                        if ($j ~ /^[0-9XYM]+$/ && length($j) <= 2 && chr == ".") chr = $j
                        if ($j ~ /^[ACGT]$/) {
                            if (a1 == ".") a1 = $j
                            else if (a2 == ".") a2 = $j
                        }
                    }
                }
                print rsid, chr, pos, a1, a2
                break
            }
        }
    }'
}

#-------------------------------------------------------------------------------
# MAIN EXTRACTION FUNCTION
#-------------------------------------------------------------------------------
extract_all_variants() {
    local file="$1"
    local format="$2"
    
    case "$format" in
        vcf)
            extract_vcf "$file"
            ;;
        plink_bim)
            extract_plink_bim "$file"
            ;;
        illumina_report)
            extract_illumina_report "$file"
            ;;
        ancestrydna|23andme|nebula|dante|generic_tsv_rsid_first|generic_tsv)
            extract_consumer_tsv "$file"
            ;;
        myheritage|ftdna|livingdna|generic_csv_rsid_first|generic_csv)
            extract_consumer_csv "$file"
            ;;
        generic_tsv_with_header)
            extract_generic_with_header "$file" "tab"
            ;;
        generic_csv_with_header)
            extract_generic_with_header "$file" "comma"
            ;;
        *)
            # Try multiple extraction methods
            {
                extract_consumer_tsv "$file" 2>/dev/null
                extract_consumer_csv "$file" 2>/dev/null
                extract_generic_search "$file" 2>/dev/null
            } | sort -u
            ;;
    esac
}

#-------------------------------------------------------------------------------
# MAIN PROCESSING
#-------------------------------------------------------------------------------
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}            ${GREEN}UNIVERSAL DNA VARIANT FILTER v2.0${NC}                      ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect format
echo -e "${YELLOW}Analyzing input file...${NC}"
FORMAT=$(detect_format "$INPUT")

echo -e "  Input file:  ${GREEN}$(basename "$INPUT")${NC}"
echo -e "  Format:      ${GREEN}$FORMAT${NC}"
echo -e "  Output file: ${GREEN}$OUTPUT${NC}"
echo ""

if [[ "$FORMAT" == "unknown" ]]; then
    echo -e "${YELLOW}Warning: Could not auto-detect format. Attempting generic extraction...${NC}"
    echo ""
fi

# Extract all variants to temp file
echo -e "${YELLOW}Extracting variants...${NC}"
extract_all_variants "$INPUT" "$FORMAT" > "$TEMP_DIR/all_variants.txt" 2>/dev/null || true

total_in_file=$(wc -l < "$TEMP_DIR/all_variants.txt" 2>/dev/null | tr -d ' ' || echo "0")
echo -e "  Found ${CYAN}$total_in_file${NC} total variants in file"
echo ""

# Create output file with header
cat > "$OUTPUT" << EOF
#===============================================================================
# FILTERED GENETIC VARIANTS - Neuropsychiatric & Pharmacogenomic Panel
#===============================================================================
# Generated: $(date)
# Source file: $(basename "$INPUT")
# Detected format: $FORMAT
#
# This file contains a curated subset of genetic variants relevant to:
#   • Neurotransmitter systems (dopamine, serotonin, norepinephrine, GABA)
#   • Stress response and HPA axis regulation
#   • Drug metabolism (pharmacogenomics)
#   • Methylation and B-vitamin pathways
#   • Circadian rhythm regulation
#
# COLUMN FORMAT: rsid  chromosome  position  allele1  allele2
#
# NOTE: These variants are extracted for educational/research purposes.
# Consult healthcare professionals for medical interpretation.
#===============================================================================

EOF

# Process each category
echo -e "${YELLOW}Filtering by gene category...${NC}"
echo ""

total_variants=0
declare -A category_counts

for category in $(echo "${!GENE_CATEGORIES[@]}" | tr ' ' '\n' | sort); do
    rsids="${GENE_CATEGORIES[$category]}"
    rsid_pattern=$(echo "$rsids" | tr ' ' '|')
    
    display_name=$(echo "$category" | tr '_' ' ')
    
    echo "" >> "$OUTPUT"
    echo "# === $display_name ===" >> "$OUTPUT"
    
    variants=$(grep -E "^($rsid_pattern)[[:space:]]" "$TEMP_DIR/all_variants.txt" 2>/dev/null || true)
    
    if [[ -n "$variants" ]]; then
        echo "$variants" >> "$OUTPUT"
        count=$(echo "$variants" | wc -l | tr -d ' ')
        total_variants=$((total_variants + count))
        category_counts["$display_name"]=$count
        printf "  %-42s %3d variants\n" "$display_name:" "$count"
    else
        category_counts["$display_name"]=0
        printf "  ${CYAN}%-42s %3d variants${NC}\n" "$display_name:" "0"
    fi
done

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════${NC}"

#-------------------------------------------------------------------------------
# SUMMARY STATISTICS
#-------------------------------------------------------------------------------

# Count total target rsIDs
total_targets=$(wc -l < "$TEMP_DIR/rsid_list.txt" | tr -d ' ')

# Count variants with valid alleles (not "." or empty)
if [[ $total_variants -gt 0 ]]; then
    variants_with_alleles=$(grep "^rs" "$OUTPUT" | awk -F'\t' '$4 != "." && $4 != "" && $5 != "." && $5 != ""' | wc -l | tr -d ' ')
    variants_with_position=$(grep "^rs" "$OUTPUT" | awk -F'\t' '$3 != "." && $3 != "" && $3 ~ /^[0-9]+$/' | wc -l | tr -d ' ')
else
    variants_with_alleles=0
    variants_with_position=0
fi
variants_missing_alleles=$((total_variants - variants_with_alleles))

# Count categories with at least one hit
categories_with_hits=0
for cat in "${!category_counts[@]}"; do
    if [[ ${category_counts[$cat]} -gt 0 ]]; then
        categories_with_hits=$((categories_with_hits + 1))
    fi
done
total_categories=${#category_counts[@]}

# File sizes
input_size=$(ls -lh "$INPUT" | awk '{print $5}')
output_size=$(ls -lh "$OUTPUT" | awk '{print $5}')

# Determine status
if [[ $total_variants -eq 0 ]]; then
    status="FAILED"
    status_color="$RED"
    status_icon="✗"
elif [[ $total_variants -lt 20 ]]; then
    status="PARTIAL"
    status_color="$YELLOW"
    status_icon="⚠"
elif [[ $variants_with_alleles -lt $((total_variants / 2)) ]]; then
    status="PARTIAL"
    status_color="$YELLOW"
    status_icon="⚠"
else
    status="SUCCESS"
    status_color="$GREEN"
    status_icon="✓"
fi

# Calculate match percentage
match_pct=$(awk "BEGIN {printf \"%.1f\", $total_variants / $total_targets * 100}" 2>/dev/null || echo "0")

echo ""
echo -e "${BLUE}                         EXTRACTION SUMMARY${NC}"
echo -e "${BLUE}────────────────────────────────────────────────────────────────────────${NC}"
echo ""

# Status line
echo -e "  Status:              ${status_color}${status_icon} ${status}${NC}"
echo ""

# Core metrics
echo "  Variants matched:    $total_variants / $total_targets targets ($match_pct%)"
echo "  Alleles detected:    $variants_with_alleles / $total_variants variants"
if [[ $variants_missing_alleles -gt 0 ]]; then
    echo -e "  ${YELLOW}Missing alleles:     $variants_missing_alleles variants${NC}"
fi
echo "  Position data:       $variants_with_position / $total_variants variants"
echo "  Categories covered:  $categories_with_hits / $total_categories gene groups"
echo ""

# Top categories found (show top 5 with hits)
echo "  Top categories:"
{
    for cat in "${!category_counts[@]}"; do
        echo "${category_counts[$cat]}|$cat"
    done
} | sort -t'|' -k1 -rn | head -5 | while IFS='|' read -r count name; do
    if [[ $count -gt 0 ]]; then
        printf "    • %-36s %3d\n" "$name" "$count"
    fi
done
echo ""

# File info
echo -e "${BLUE}────────────────────────────────────────────────────────────────────────${NC}"
echo "  Input file:          $(basename "$INPUT") ($input_size)"
echo "  Output file:         $OUTPUT ($output_size)"
echo "  Format detected:     $FORMAT"
echo -e "${BLUE}────────────────────────────────────────────────────────────────────────${NC}"

# Guidance based on status
echo ""
if [[ "$status" == "FAILED" ]]; then
    echo -e "${RED}No variants were extracted. Possible causes:${NC}"
    echo "  • File format not recognized (detected: $FORMAT)"
    echo "  • File uses non-standard rsID naming"
    echo "  • Data may be in a different encoding"
    echo "  • Try: head -20 '$INPUT' to inspect the file structure"
elif [[ "$status" == "PARTIAL" ]]; then
    echo -e "${YELLOW}Extraction completed with warnings:${NC}"
    if [[ $total_variants -lt 20 ]]; then
        echo "  • Low variant count - file may be filtered or use different IDs"
    fi
    if [[ $variants_with_alleles -lt $((total_variants / 2)) ]]; then
        echo "  • Many variants missing allele data - format may need adjustment"
    fi
    echo "  • Output is usable but may be incomplete"
else
    echo -e "${GREEN}Extraction successful!${NC}"
    echo "  • Output file is ready to share for analysis"
fi

echo ""

# Privacy note (condensed)
if [[ $total_in_file -gt 0 && $total_variants -gt 0 ]]; then
    pct=$(awk "BEGIN {printf \"%.3f\", $total_variants / $total_in_file * 100}" 2>/dev/null || echo "0.03")
    echo -e "${CYAN}Privacy: Extracted $total_variants of ~$total_in_file variants (${pct}%) - safe to share${NC}"
fi
echo ""
