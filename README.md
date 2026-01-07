# DNA Variant Filter for Neuropsychiatric Analysis

A universal script to extract relevant genetic variants from raw DNA testing data for educational analysis of brain chemistry, stress response, and drug metabolism.

## Quick Start

```bash
# Make executable
chmod +x filter_dna_variants.sh

# Run on your DNA file
./filter_dna_variants.sh your_dna_file.txt

# Output will be saved as: dna_variants_filtered.txt
```

## Summary Output

After processing, the script displays a clear summary showing extraction status:

```
                         EXTRACTION SUMMARY
────────────────────────────────────────────────────────────────────────

  Status:              ✓ SUCCESS

  Variants matched:    142 / 196 targets (72.4%)
  Alleles detected:    142 / 142 variants
  Position data:       142 / 142 variants
  Categories covered:  31 / 35 gene groups

  Top categories:
    • COMT Dopamine Clearance                8
    • DRD2 Dopamine D2 Receptor              7
    • CYP450 Drug Metabolism                 6
    ...

────────────────────────────────────────────────────────────────────────
  Input file:          AncestryDNA.txt (15M)
  Output file:         dna_variants_filtered.txt (4.2K)
  Format detected:     ancestrydna
────────────────────────────────────────────────────────────────────────

Extraction successful!
  • Output file is ready to share for analysis

Privacy: Extracted 142 of ~715382 variants (0.020%) - safe to share
```

### Status Indicators

| Status | Icon | Meaning |
|--------|------|---------|
| **SUCCESS** | ✓ | 20+ variants found with alleles detected |
| **PARTIAL** | ⚠ | Some data extracted but may be incomplete |
| **FAILED** | ✗ | No matching variants found |

### Key Metrics Explained

- **Variants matched**: How many of the 196 target rsIDs were found in your file
- **Alleles detected**: Variants where both allele1 and allele2 were successfully extracted
- **Position data**: Variants with valid chromosome position information
- **Categories covered**: How many gene groups have at least one variant

## Supported Formats

### Consumer DNA Testing Services

| Service | File Type | How to Download |
|---------|-----------|-----------------|
| **AncestryDNA** | .txt | Settings → DNA Settings → Download Raw DNA Data |
| **23andMe** | .txt | Settings → 23andMe Data → Download Raw Data |
| **MyHeritage** | .csv | DNA → Manage DNA kits → Export Data |
| **FamilyTreeDNA** | .csv | myFTDNA → Download Raw Data |
| **LivingDNA** | .csv/.txt | Account → Download Raw Data |
| **Nebula Genomics** | .txt | Account → Download Data |
| **Dante Labs** | .txt | Account → Download Raw Data |
| **Genes for Good** | .txt | From research portal |

### Research & Clinical Formats

| Format | Extensions | Description |
|--------|------------|-------------|
| **VCF** | .vcf, .vcf.gz | Variant Call Format (standard bioinformatics format) |
| **PLINK** | .bim | PLINK binary genotype format |
| **Illumina** | .txt, .csv | GenomeStudio FinalReport, GSA array exports |
| **Generic TSV/CSV** | .txt, .csv | Any tab/comma-separated file with rsID column |

### Auto-Detection

The script automatically detects your file format by examining:
- Header comments (service identifiers like "AncestryDNA", "23andMe")
- VCF format markers (`##fileformat=VCF`)
- Illumina markers (`[Header]`, `GSGT Version`)
- Column structure and delimiters
- rsID patterns in data rows

If auto-detection fails, it falls back to generic parsing that searches for rsID patterns.

## What Gets Extracted

The script filters ~200 variants from ~700,000 total, covering:

### Neurotransmitter Systems
- **COMT** – Dopamine/norepinephrine clearance (includes rs4680 Val158Met)
- **DRD2/DRD3/DRD4** – Dopamine receptor variants
- **DAT1** – Dopamine transporter
- **DBH** – Dopamine beta-hydroxylase (dopamine → norepinephrine conversion)
- **NET** – Norepinephrine transporter
- **SERT** – Serotonin transporter
- **5-HT2A/5-HT1A** – Serotonin receptors
- **TPH2** – Serotonin synthesis
- **MAOA/MAOB** – Monoamine oxidase enzymes

### Stress Response & HPA Axis
- **FKBP5** – Stress hormone receptor sensitivity
- **NR3C1** – Glucocorticoid receptor
- **CRHR1** – CRH receptor (stress signaling)
- **BDNF** – Brain-derived neurotrophic factor

### GABA System
- **GABRA2/GABRA6** – GABA-A receptor subunits
- **GABBR1/GABBR2** – GABA-B receptors

### Methylation & B-Vitamins
- **MTHFR** – Folate metabolism (C677T and A1298C)
- **MTR/MTRR** – B12-dependent methylation
- **CBS** – Homocysteine metabolism

### Drug Metabolism (Pharmacogenomics)
- **CYP2D6** – Metabolizes many psych meds
- **CYP2C19** – Metabolizes SSRIs, PPIs
- **CYP1A2** – Caffeine metabolism

### Other Relevant Systems
- **OPRM1** – Opioid receptor
- **OXTR** – Oxytocin receptor
- **CLOCK/PER** – Circadian genes
- **CACNA1C** – Calcium channel (mood)
- **VDR** – Vitamin D receptor

## Output Format

The filtered file is tab-separated with columns:
```
rsid    chromosome    position    allele1    allele2
```

Variants are grouped by gene/pathway with comment headers:
```
# === COMT Dopamine Clearance ===
rs4680    22    19951271    A    G
rs4633    22    19950235    C    T
...
```

## Privacy & Sharing

### What's Safe to Share
✅ The filtered output file (~200 variants, ~0.03% of your data)

### What NOT to Share
❌ Your original raw DNA file (contains ~700,000 variants)

The filtered file contains only the specific variants needed for neuropsychiatric educational analysis. Traits like ancestry, physical characteristics, disease risks, and identifying information are **not** included.

## Sharing Your Results for Analysis

After running the script, you can share the filtered output file for educational analysis. The file contains only the curated subset of variants relevant to:
- How your brain processes neurotransmitters
- Stress response patterns
- Drug metabolism tendencies
- Methylation status

## Technical Notes

- **Cross-platform**: Works on macOS, Linux, and Windows (via WSL/Git Bash)
- **No dependencies**: Uses only standard bash utilities (grep, awk, sed)
- **Auto-detection**: Automatically detects DNA file format
- **Safe**: Read-only access to your original file
- **Gzip support**: Can read .vcf.gz files directly

## Troubleshooting

**"Permission denied"**
```bash
chmod +x filter_dna_variants.sh
```

**"File not found"**
- Make sure you're in the same directory as the script
- Use the full path to your DNA file:
```bash
./filter_dna_variants.sh ~/Downloads/AncestryDNA.txt
```

**Status: FAILED (✗)**
- File format may not be recognized - check the "Format detected" line
- File might use non-standard rsID naming conventions
- Try: `head -20 yourfile.txt` to inspect the file structure
- If format looks correct, the file may be from a different species or panel

**Status: PARTIAL (⚠)**
- Low variant count is normal for filtered or targeted panels
- Missing alleles may indicate format parsing issues
- Output is still usable but review for completeness

**Windows Users**
- Use Git Bash, WSL, or similar bash environment
- Or upload your file to a Mac/Linux system

## Adding Custom Variants

To add your own variants of interest, edit the `GENE_CATEGORIES` section in the script:

```bash
GENE_CATEGORIES["My_Custom_Category"]="rs12345 rs67890 rs11111"
```

Then add the corresponding grep pattern in the extraction section.

## License

MIT License - Free to use, modify, and share.

---

*This tool is for educational purposes only. For medical decisions, consult healthcare professionals and consider clinical-grade genetic testing services.*
