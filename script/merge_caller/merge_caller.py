import pandas as pd
import numpy as np
import os

def read_vcf(file_path: str) -> pd.DataFrame:
    '''read  VCF(4.1.0) file
    '''

    
    file = pd.read_table(file_path, skiprows=17)

    # rename NORMAL and TUMOR column name
    file.columns = ["#CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "NORMAL", "TUMOR"]
    return file

def preprocess_mutect2(mutect: pd.DataFrame) -> pd.DataFrame:
    # ALT multiple --> split 
    ...

def filter(vcf: pd.DataFrame) -> pd.DataFrame:
    # FILTER == PASS
    # extract N DP, RD, T, DP, RD
    # read depth (DP) >= 30, allele depth (AD) >= 3, Allele Frequency (AF) >= 0.05 in T
    # for Normal, allele frequency >=0.10
    # sort vcf
    ...

def merge_caller(vcf1: pd.DataFrame, vcf2: pd.DataFrame):
    # split it into chromosome wise, multiprocessing (?)
    # 
    # compare each mutation site ... 
    ... 






