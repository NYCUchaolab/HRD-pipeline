# WES Pipeline for HRD

> A modular whole exome sequencing (WES) pipeline for detecting somatic/germline variants and calculating homologous recombination deficiency (HRD) scores.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

## Overview

This pipeline processes WES data from raw sequencing reads through variant calling and HRD score estimation.  
It supports both somatic and germline variant detection using standard bioinformatics tools, and integrates HRD scoring using `scarHRD`.

## Features

- **WES Preprocessing**
  - Adapter trimming, alignment, and quality control
- **Variant Calling**
  - **Somatic:**
    - GATK Mutect2  
    - VarScan2  
  - **Germline:**
    - GATK HaplotypeCaller  
    - VarScan2  
- **HRD Score Calculation**
  - Sequenza-based copy number analysis
  - `scarHRD` score computation

## Installation

Clone the repository:

```bash
git clone https://github.com/NYCUchaolab/HRD-pipeline.git
cd HRD-pipeline
```

Set up Conda environments:
```bash
# Preprocessing Environments
conda create -n wes_preprocessing --file environment/preprocessing.txt
conda create -n wes_sratools --file environment/wes_sratools.txt
conda create -n wes_gatk --file environment/wes_gatk.txt

# Variant Calling Environments
conda create -n wes_varscan --file environment/wes_varscan.txt
conda create -n wes_vep105 --file environment/wes_vep105.txt

# HRD Score Calculation Environments
conda create -n wes_seqz --file environment/sequenza.txt
conda create -n wes_scarHRD --file environment/scarHRD.txt

# Install scarHRD R package
conda activate wes_scarHRD
Rscript install.scarHRD.R
```

## Usage

*Usage instructions coming soon.*

## Configuration

Configuration files are located in the `config/` directory.  
Please modify them according to your data paths and experimental design.

## Contributing

We welcome contributions!  
Feel free to open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).