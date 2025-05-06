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

This pipeline is designed to run on a High-Performance Computing (HPC) system with SLURM job scheduling. It includes several batch scripts that handle different stages of data processing, such as downloading data from SRA, preprocessing, variant calling, and HRD score calculation.

The pipeline is organized into the following key steps:

### Batch Scripts Overview

- **`batch_download.sh`**: Downloads raw sequencing data from SRA using **SRAtools** (`prefetch`).
- **`batch_paired_preprocessing.sh`**: Preprocesses raw sequencing data, including trimming and alignment.
- **`batch_paired_variant_calling.sh`**: Performs somatic and germline variant calling.
- **`batch_HRD_calculation.sh`**: Calculates HRD scores from processed data.

### Required Arguments

Each of the batch scripts requires four arguments (except `batch_download.sh`, which takes three arguments):

1. **Sample List**: A file containing a list of sample sheet filenames (typically in `.txt` format) for paired Tumor (T) and Normal (N) samples.
2. **Sample Sheet Directory**: The path to the directory containing the sample sheet files.
3. **Input Directory**: The directory where the required data eg.(`sample.T.bam, sample.N.bam`).
4. **Output Directory**: The directory where the final results will be saved.

### Step-by-Step Usage

1. **Prepare the Sample List**:
   - Create a text file (e.g., `sample_list.txt`) with a list of sample sheet names. Each sheet should contain the necessary information, such as SRA accession numbers for paired Tumor (T) and Normal (N) samples.

2. **Running the Scripts**:

   - **Download Data from SRA**:
     The `batch_download.sh` script downloads data from SRA for each sample sheet:
     ```bash
     bash batch_download.sh <sample_list.txt> <samplesheet_dir> <output_dir>
     ```
     - `<sample_list.txt>`: The file containing the list of sample sheet names.
     - `<samplesheet_dir>`: The directory containing the sample sheets.
     - `<output_dir>`: The directory where the downloaded data will be saved.

     The script will process each sample sheet listed in `sample_list.txt` and download the corresponding SRA files.

   - **Preprocess the Data**:
     Once the data is downloaded, run the `batch_paired_preprocessing.sh` script to preprocess the sequencing data (e.g., trimming, alignment):
     ```bash
     bash batch_preprocessing.sh <sample_list.txt> <samplesheet_dir> <input_dir> <output_dir>
     ```

   - **Perform Variant Calling**:
     The `batch_paired_variant_calling.sh` script handles variant calling for somatic and germline variants:
     ```bash
     bash batch_variant_calling.sh <sample_list.txt> <samplesheet_dir> <input_dir> <output_dir>
     ```

   - **Calculate HRD Scores**:
     The `batch_HRD_calculation.sh` script calculates HRD scores from the processed data:
     ```bash
     bash batch_hrd_calculate.sh <sample_list.txt> <samplesheet_dir> <input_dir> <output_dir>
     ```

### Example Command

For each of the batch scripts (other than `batch_download.sh`), provide the four arguments:

```bash
bash batch_paired_preprocessing.sh sample_list.txt /path/to/sample_sheets /path/to/input_directory /path/to/output_directory
```

### SLURM Configuration

The job scheduler used for running the scripts is **SLURM**. The `slurm.info` header template is included and will automatically be added to each job script. Ensure that you have configured the `slurm.info` file as described in the [Configuration](#configuration) section.

### Monitoring Jobs

Once you submit a job using SLURM, you can monitor its status using the following command:

```bash
squeue -u <your-username>
```

This will show all running jobs under your user account.


## Configuration

Configuration file templates are located in the `template/HRD_pipeline.config` directory.

### Steps to Set Up Configuration:

1. Create a `config/` directory at the root of this project.
2. Modify the template configuration files to suit your data paths and experimental design.
3. Set the path to the configuration file as a global variable in your `~/.bash_aliases`:
    ```bash
    export HRD_PIPELINE_CONFIG=<path/to/HRD-pipeline>/config/HRD_pipeline.config
    ```
   > Make sure to replace `<path/to/HRD-pipeline>` with the correct path to your project directory.

## Contributing

We welcome contributions!  
Feel free to open an issue or submit a pull request.

## License

This project is licensed under the terms of the **GNU General Public License v3.0**.  
You may copy, distribute, and modify the software as long as you track changes/dates in source files.  
Any derivative work must also be licensed under GPLv3.  

See the full license text in the [LICENSE](./LICENSE) file or visit [https://www.gnu.org/licenses/gpl-3.0.html](https://www.gnu.org/licenses/gpl-3.0.html).