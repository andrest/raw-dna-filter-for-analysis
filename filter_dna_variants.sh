#!/bin/bash

#===============================================================================
# UNIVERSAL DNA VARIANT FILTER
# Extracts neuropsychiatric-relevant genetic variants from raw DNA data files
#===============================================================================
#
# SUPPORTED FORMATS:
#   - AncestryDNA (txt)
#   - 23andMe (txt)
#   - MyHeritage (csv)
#   - FamilyTreeDNA (csv)
#   - LivingDNA (csv)
#   - Generic VCF-style formats
#
# USAGE:
#   ./filter_dna_variants.sh <input_file> [output_file]
#
# EXAMPLES:
#   ./filter_dna_variants.sh AncestryDNA.txt
#   ./filter_dna_variants.sh 23andme_raw.txt my_variants.txt
#   ./filter_dna_variants.sh myheritage_raw.csv filtered.txt
#
# OUTPUT:
#   A filtered text file containing only the variants relevant for
#   neuropsychiatric and pharmacogenomic analysis, organized by gene/pathway.
#
# PRIVACY NOTE:
#   The output file contains only ~200 specific variants (out of 700,000+)
#   related to brain chemistry, stress response, and drug metabolism.
#   This is safe to share for educational analysis while keeping the
#   vast majority of your genetic data private.
#
#===============================================================================

set -euo pipefail

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
INPUT="${1:-}"
OUTPUT="${2:-dna_variants_filtered.txt}"

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

SUPPORTED SERVICES:
    • AncestryDNA      (.txt file from DNA settings page)
    • 23andMe          (.txt file from Browse Raw Data)
    • MyHeritage       (.csv file from DNA settings)
    • FamilyTreeDNA    (.csv file from myFTDNA)
    • LivingDNA        (.csv or .txt file)
    • Nebula Genomics  (.txt file)

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
    Your raw DNA file contains 600,000-700,000 variants.
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

#-------------------------------------------------------------------------------
# COMPREHENSIVE RSID LIST - Neuropsychiatric & Pharmacogenomic Variants
#-------------------------------------------------------------------------------
# This list covers variants relevant to:
# - Neurotransmitter synthesis, transport, and metabolism
# - Stress response and HPA axis
# - Drug metabolism (pharmacogenomics)
# - Circadian rhythm
# - Methylation and B-vitamin metabolism
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

# Convert to sorted unique list
RSID_LIST=$(echo $ALL_RSIDS | tr ' ' '\n' | sort -u | tr '\n' '|')
RSID_LIST="${RSID_LIST%|}"  # Remove trailing pipe

#-------------------------------------------------------------------------------
# DETECT FILE FORMAT
#-------------------------------------------------------------------------------
detect_format() {
    local file="$1"
    local first_data_line
    
    # Read first non-comment, non-empty line
    first_data_line=$(grep -v '^#' "$file" | grep -v '^$' | head -1)
    
    # Check for common patterns
    if head -20 "$file" | grep -qi "AncestryDNA"; then
        echo "ancestrydna"
    elif head -20 "$file" | grep -qi "23andMe"; then
        echo "23andme"
    elif head -20 "$file" | grep -qi "MyHeritage"; then
        echo "myheritage"
    elif head -20 "$file" | grep -qi "FTDNA\|FamilyTreeDNA"; then
        echo "ftdna"
    elif head -20 "$file" | grep -qi "Living DNA"; then
        echo "livingdna"
    elif head -20 "$file" | grep -qi "Nebula"; then
        echo "nebula"
    elif [[ "$first_data_line" == *","* ]]; then
        # CSV format - try to determine by column count
        local col_count=$(echo "$first_data_line" | awk -F',' '{print NF}')
        if [[ $col_count -ge 4 ]]; then
            echo "generic_csv"
        else
            echo "unknown"
        fi
    elif [[ "$first_data_line" == *$'\t'* ]]; then
        echo "generic_tsv"
    else
        echo "unknown"
    fi
}

#-------------------------------------------------------------------------------
# EXTRACT VARIANTS BY FORMAT
#-------------------------------------------------------------------------------
extract_variants() {
    local file="$1"
    local format="$2"
    local rsid_pattern="$3"
    
    case "$format" in
        ancestrydna|23andme|nebula|generic_tsv)
            # Tab-separated: rsid, chromosome, position, allele1, allele2
            grep -E "^($rsid_pattern)\t" "$file" 2>/dev/null || true
            ;;
        myheritage|ftdna|livingdna|generic_csv)
            # CSV format - convert to TSV and extract
            # Handle quoted fields and various column orders
            grep -v '^#' "$file" | grep -v '^"#' | \
            sed 's/","/\t/g; s/"//g; s/,/\t/g' | \
            grep -E "^($rsid_pattern)\t" 2>/dev/null || true
            ;;
        *)
            # Try both formats
            grep -E "^($rsid_pattern)\t" "$file" 2>/dev/null || \
            grep -v '^#' "$file" | sed 's/,/\t/g' | grep -E "^($rsid_pattern)\t" 2>/dev/null || true
            ;;
    esac
}

#-------------------------------------------------------------------------------
# MAIN PROCESSING
#-------------------------------------------------------------------------------
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}           ${GREEN}UNIVERSAL DNA VARIANT FILTER${NC}                        ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect format
echo -e "${YELLOW}Analyzing input file...${NC}"
FORMAT=$(detect_format "$INPUT")
echo -e "  Input file:  ${GREEN}$INPUT${NC}"
echo -e "  Format:      ${GREEN}$FORMAT${NC}"
echo -e "  Output file: ${GREEN}$OUTPUT${NC}"
echo ""

if [[ "$FORMAT" == "unknown" ]]; then
    echo -e "${YELLOW}Warning: Could not auto-detect format. Attempting generic extraction...${NC}"
fi

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
echo -e "${YELLOW}Extracting variants by category...${NC}"
echo ""

total_variants=0

for category in $(echo "${!GENE_CATEGORIES[@]}" | tr ' ' '\n' | sort); do
    rsids="${GENE_CATEGORIES[$category]}"
    # Convert spaces to pipes for regex
    rsid_pattern=$(echo "$rsids" | tr ' ' '|')
    
    # Format category name for display
    display_name=$(echo "$category" | tr '_' ' ')
    
    # Add category header to output
    echo "" >> "$OUTPUT"
    echo "# === $display_name ===" >> "$OUTPUT"
    
    # Extract and count variants for this category
    variants=$(extract_variants "$INPUT" "$FORMAT" "$rsid_pattern")
    
    if [[ -n "$variants" ]]; then
        echo "$variants" >> "$OUTPUT"
        count=$(echo "$variants" | wc -l)
        total_variants=$((total_variants + count))
        printf "  %-40s %3d variants\n" "$display_name:" "$count"
    else
        printf "  %-40s %3d variants\n" "$display_name:" "0"
    fi
done

echo ""
echo -e "${BLUE}────────────────────────────────────────────────────────────────────${NC}"

# Final statistics
data_lines=$(grep -c "^rs" "$OUTPUT" 2>/dev/null || echo "0")
input_size=$(ls -lh "$INPUT" | awk '{print $5}')
output_size=$(ls -lh "$OUTPUT" | awk '{print $5}')

echo ""
echo -e "${GREEN}✓ Extraction complete!${NC}"
echo ""
echo "  Total variants extracted: $data_lines"
echo "  Original file size:       $input_size"
echo "  Filtered file size:       $output_size"
echo ""
echo -e "${BLUE}Output saved to: ${GREEN}$OUTPUT${NC}"
echo ""

# Privacy reminder
echo -e "${YELLOW}────────────────────────────────────────────────────────────────────${NC}"
echo -e "${YELLOW}PRIVACY NOTE:${NC}"
echo "  Your original DNA file contains ~700,000 variants."
echo "  This filtered file contains only $data_lines variants (~0.03%)."
echo "  The filtered output is safe to share for educational analysis."
echo -e "${YELLOW}────────────────────────────────────────────────────────────────────${NC}"
