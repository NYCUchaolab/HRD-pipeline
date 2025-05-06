from pathos.multiprocessing import ProcessingPool as Pool
from functools import wraps
import pandas as pd 
import time


def chromosome_wise_multi_proc(func):
    """
    A decorator to apply functions chromosome-wise with optional multiprocessing,
    ensuring compatibility with child classes of ITD_DataFrame.

    Args:
        func (function): The function to apply to each chromosome.

    Returns:
        function: Wrapped function that processes the DataFrame chromosome-wise.
    """
    def process_chromosome(args):
        func, chrom, df1_group, df2_group, args, kwargs, df1_class, df2_class = args
        
        # Retrieve or initialize an empty DataFrame for missing chromosomes
        df1_chrom = df1_group.get(chrom, df1_class(columns=df1_group[next(iter(df1_group))].columns))
        df2_chrom = df2_group.get(chrom, df2_class(columns=df2_group[next(iter(df2_group))].columns)) if df2_group else None
        # Call the function
        if df2_chrom is not None:
            result = func(df1_chrom, df2_chrom, *args, **kwargs)
        else:
            result = func(df1_chrom, *args, **kwargs)
        
        return result

    @wraps(func)
    def wrapper(df1, df2=None, chromosome_wise=False, multi_proc=False, *args, **kwargs):
        # Determine the class of the input DataFrame
        df1_class = type(df1)
        df2_class = type(df2) if df2 is not None else type(df1)

        if chromosome_wise:
            # Group by chromosome and store as the appropriate class
            df1_group = {chrom: group for chrom, group in df1.groupby('Chr')}
            df2_group = {chrom: group for chrom, group in df2.groupby('Chr')} if df2 is not None else None
            chromosomes = set(df1_group.keys()).union(df2_group.keys() if df2_group else [])

            for chrom in chromosomes:
                df1_group[chrom] = df1_group.get(chrom, df1_class.empty_df())
                if df2 is not None:
                    df2_group[chrom] = df2_group.get(chrom, df2_class.empty_df())



            # Prepare arguments for multiprocessing
            pool_args = [
                (func, chrom, df1_group, df2_group, args, kwargs, df1_class, df2_class)
                for chrom in chromosomes
            ]

            if multi_proc:
                # Use ProcessingPool from pathos
                with Pool() as pool:
                    results = pool.map(process_chromosome, pool_args)
            else:
                results = [process_chromosome(arg) for arg in pool_args]

            if not results: # all is None Error Avoid
                return df1_class.empty_df()

            # Combine results based on their return type
            if isinstance(results[0], tuple):
                results1, results2 = zip(*results)
                if isinstance(results1[0], df1_class):
                    res1 = df1_class.concat(results1).reset_index(drop=True)
                elif isinstance(results1[0], list):
                    res1 = [item for sublist in results1 for item in sublist]
                else:
                    raise TypeError(f"Expected a ITD_DataFrame or list, object type: {type(results1[0])}")
                if isinstance(results2[0], df2_class):
                    res2 = df2_class.concat(results2).reset_index(drop=True)
                elif isinstance(results1[0], list):
                    res2 = [item for sublist in results2 for item in sublist]
                else:
                    raise TypeError(f"Expected a ITD_DataFrame or list, object type: {type(results2[0])}")                
                return res1, res2
            else:
                return df1_class.concat(results).reset_index(drop=True)
        else:
            # If not chromosome-wise, call the function directly
            if df2 is not None:
                return func(df1, df2, *args, **kwargs)
            else:
                return func(df1, *args, **kwargs)

    return wrapper

def read_sample_info(sample_sheet: str) -> dict[str, str]:
    """
    Read sample information from a tab-separated sample sheet.

    This function loads the sample sheet into a DataFrame, extracts the tumor and normal
    file IDs based on the 14th character of the "Sample ID" column ('0' for tumor, '1' for normal),
    and retrieves the case ID.

    Args:
        sample_sheet (str): Path to the sample sheet file.

    Returns:
        dict[str, str]: A dictionary containing "Case ID", "Tumor ID", and "Normal ID".

    Raises:
        KeyError: If any required column is missing.
        ValueError: If no tumor or normal sample is found with the expected identifier.
    """
    tmp = pd.read_table(sample_sheet, header=0)
    
    required_cols = ["Sample ID", "File ID", "Case ID"]
    for col in required_cols:
        if col not in tmp.columns:
            raise KeyError(f"Required column '{col}' not found in the sample sheet.")
    
    tumor_df = tmp[tmp["Sample ID"].str[13] == '0']
    if tumor_df.empty:
        raise ValueError("No tumor sample found with the expected '0' identifier in 'Sample ID'.")
    tumor_fileID = tumor_df["File ID"].iloc[0]
    
    normal_df = tmp[tmp["Sample ID"].str[13] == '1']
    if normal_df.empty:
        raise ValueError("No normal sample found with the expected '1' identifier in 'Sample ID'.")
    normal_fileID = normal_df["File ID"].iloc[0]
    
    case_ID = tmp["Case ID"].iloc[0]

    return {
        "Case ID": case_ID, 
        "Tumor ID": tumor_fileID,
        "Normal ID": normal_fileID
    }
  
def measure_runtime(function, **kwargs):
    start_time = time.time()
    _ = function(**kwargs)
    return time.time() - start_time