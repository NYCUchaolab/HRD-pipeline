import pandas as pd
import warnings, re
import gzip
from natsort import natsort_keygen

class VCF_Series(pd.Series):
    _metadata = ['infos', 'formats']

    def __init__(self, *args, infos=None, formats=None, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        self.infos = infos
        self.formats = formats

    @property
    def _constructor(self) -> "VCF_Series":
        def _c(*args, **kwargs):
            kwargs['infos'] = self.infos
            kwargs['formats'] = self.formats
            return VCF_Series(*args, **kwargs)
        return _c 

    @property
    def is_stacked(self) -> bool:
        return len(self['ALT'].split(',')) > 1

    @property
    def stack_count(self) -> int:
        return len(self["ALT"].split(','))

    def split_variant(self) -> list["VCF_Series"]:
        count = self.stack_count
        splitted_rows = [self.copy() for _ in range(count)]
        alt_alleles = self['ALT'].split(',')
        infos = self.parse_info()
        samples = self.parse_samples()
        
        for i in range(count):
            splitted_rows[i]['ALT'] = alt_alleles[i]
            splitted_rows[i]['INFO'] = infos[i]

            for j, sample_name in enumerate(self.index[9:]):  
                splitted_rows[i][sample_name] = samples[j][i]
        return splitted_rows

    def parse_info(self) -> list[str]:
        info_list = []
        count = self.stack_count

        infos = self['INFO'].split(';')
        for info in infos:
            # kv_pair = re.match(r'(\w+)=([\w\.\-\,\+]+)', info)
            kv_pair = re.match(r'([^=]+)=(.+)', info)

            if kv_pair:
                key, value = kv_pair.groups()
                splitted_v: list = value.split(',')

                if key not in self.infos:
                    raise KeyError(f"Unexpected key {key} in INFO field")

                info_type = self.infos[key]

                if info_type == 'R':  # NUMBER = R
                    if len(splitted_v) != count+1:
                        raise ValueError(f"Error: {key} should have {count+1} values, got {len(splitted_v)}")
                    
                    ref_info = splitted_v.pop(0)
                    info_list.append([f'{key}={ref_info},{v_}' for v_ in splitted_v])

                elif info_type == 'A':  # NUMBER = A
                    if len(splitted_v) != count:
                        raise ValueError(f"Error: {key} should have {count} values, got {len(splitted_v)}")
                    
                    info_list.append([f'{key}={v_}' for v_ in splitted_v])

                elif self.infos[key] == '.':
                    continue

                else:
                    try:
                        expected_count = int(info_type)
                    except ValueError:
                        raise ValueError(f"Invalid format type for {key}: {info_type}")
                    
                    if len(splitted_v) != expected_count:
                        raise ValueError(f"Error: {key} should have {expected_count} values, got {len(splitted_v)}")
                    info_list.append([f"{key}={value}" for _ in range(count)])
            else:
                if info not in self.infos or int(self.infos[info]) != 0:
                    raise ValueError(f"{info} is not a FLAG, it has {self.infos.get(info, 'unknown')} number of values")
                info_list.append([info] * count)              

        transposed_info = list(map(list, zip(*info_list)))
        return [';'.join(info_list) for info_list in transposed_info]

    def parse_samples(self) -> list[list[str]]:
        format_dict = self.formats
        format = self['FORMAT']
        count = self.stack_count

        def parse_sample(sample, format, count, format_dict = self.formats):
            info_list = []
            formats: list[str] = format.split(':')
            sample_infos: list[str] = sample.split(':')

            # check number of formats and sample_infos must match 
            if len(formats) != len(sample_infos):
                raise ValueError(f"Mismatch between format fields ({formats}) and sample values ({sample_infos})")

            for fmt, infos in zip(formats, sample_infos):
                splitted_info = infos.split(',')

                if fmt in {'GT', 'PGT'}:
                    if infos in {'0/0', '0', '0|0'}:
                        info_list.append([infos] * count)
                    else:
                        info_list.append(['0/1'] * count)
                    continue

                format_type = format_dict.get(fmt)

                if format_type is None:
                    raise KeyError(f"Format {fmt} is not defined in format_dict")
                
                if format_type == 'R':
                    if len(splitted_info) != count + 1:
                        raise ValueError(f"Error: {fmt} should have {count+1} values, got {len(splitted_info)}")
                    ref_info = splitted_info.pop(0)
                    info_list.append([f'{ref_info},{v_}' for v_ in splitted_info])

                elif format_type == 'A':
                    if len(splitted_info) != count:
                        raise ValueError(f"Error: {fmt} should have {count} values, got {len(splitted_info)}")
                    info_list.append(splitted_info)

                else:
                    expected_length = int(format_type) if format_type.isdigit() else None
                    if expected_length and len(splitted_info) != expected_length:
                        raise ValueError(f"Error: {fmt} should have {expected_length} values, got {len(splitted_info)}")
                    info_list.append([infos] * count)
                
            transposed_info = list(map(list, zip(*info_list)))
            return [':'.join(inf_list) for inf_list in transposed_info]
            
        samples = self.iloc[9:].tolist()
        if not samples:
            raise ValueError("No sample data available")

        return [parse_sample(sample, format, count, format_dict) for sample in samples]

    def get_info(self, normal: bool = False) -> tuple[int, int, float]:
        keys = self["FORMAT"].split(":")

        values = self.iloc[9 if normal else -1].split(":")
        sample_info = {k:v for k,v in zip(keys,values)}

        DP = int(sample_info["DP"]) if "DP" in sample_info else 0

        if "AD" in sample_info:
            AD_values = list(map(int, sample_info["AD"].split(",")))
            AD = AD_values[1] if len(AD_values) > 1 else AD_values[0]
        elif "AO" in sample_info:
            AD = int(sample_info["AO"])
        else:
            AD = 0

        if "AF" in sample_info:
            try:
                VAF = float(sample_info["AF"])
            except ValueError:
                VAF = AD / DP if DP > 0 else 0.0
        else:
            VAF = AD / DP if DP > 0 else 0.0

        return AD, DP, VAF
    
    def filter_VAF(self, AD_thres:int = 5,DP_thres: int = 30, VAF_thres: float = None, germline = False ) -> bool:
        AD, DP, VAF = self.get_info(normal = germline)
        vaf_thres = VAF_thres if VAF_thres else (0.2 if germline else 0.05)
        if AD < AD_thres:
            return False
        if DP < DP_thres:
            return False
        if VAF < vaf_thres:
            return False
        return True
    
    def get_VAF(self, germline=False) -> float:
        AD, DP, VAF = self.get_info(normal = germline)
        return VAF

COLUMNS = ['#CHROM', 'POS', 'ID', 'REF', 'ALT', 'QUAL', 'FILTER', 'INFO', 'FORMAT'] 

class VCF_DataFrame(pd.DataFrame):
    _metadata = ['header', 'source', 'infos', 'formats']
    
    def __init__(self, *args, header=None, source='pyVCF', infos=None, formats=None, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        self.header = header
        self.source = source
        self.infos = infos
        self.formats = formats

    @property
    def _constructor(self):
        def _c(*args, **kwargs):
            kwargs['header'] = self.header
            kwargs['source'] = self.source
            if self.header is not None:
                if self.infos is None:
                    self.set_info()
                kwargs['infos'] = self.infos

                if self.formats is None:
                    self.set_format()
                kwargs['formats'] = self.formats
            
            return VCF_DataFrame(*args, **kwargs)
        return _c 

    @property
    def _constructor_sliced(self):
        def _c(*args, **kwargs):
            if self.header is not None:
                if self.infos is None:
                    self.set_info()
                kwargs['infos'] = self.infos

                if self.formats is None:
                    self.set_format()
                kwargs['formats'] = self.formats           
            return VCF_Series(*args, **kwargs)
        return _c

    @classmethod
    def concat(cls, objs, *args, **kwargs):
        if not objs:
            warnings.warn("No input DataFrames to concatenate. Returning empty DataFrame.")
            return cls.empty_df()
    
        result = pd.concat(objs, *args, **kwargs)
        
        if isinstance(objs[0], cls):
            result = cls(result)
            result.header = objs[0].header  
            result.source = objs[0].source
        return result.sorting().reset_index(drop=True)

    @classmethod
    def empty_df(cls):
        return cls(columns=COLUMNS)
       
    @classmethod
    def read_vcf(cls, path: str) -> "VCF_DataFrame":
        
        open_func = gzip.open if path.endswith('.gz') else open

        header_dict = {}
        with open_func(path, 'rt') as f:
            while True:
                line = f.readline().rstrip()
                if line.startswith('##'):
                    key = re.match(r"##(\w+)", line)
                    if key:
                        category = key.group(1) 
                        if category not in header_dict:
                            header_dict[category] = [] 
                        header_dict[category].append(line)
                        
                else:
                    columns = line.rstrip().split('\t')
                    break

            try:
                vcf = cls(pd.read_csv(f, sep="\t", header=None, comment="#", names=columns))

            except pd.errors.EmptyDataError:
                vcf = cls.empty_df()
        vcf.header = header_dict
        return vcf

    @staticmethod
    def get_number(header_list: list[str]) -> dict[str:str]:
        tmp_dict = {}
        if not isinstance(header_list, list):
            raise TypeError("header_list should be a list of strings")
        
        for v in header_list:
            if not isinstance(v, str):
                continue
            
            match = re.match(r'^##(INFO|FORMAT|FILTER)=<ID=([^,]+),Number=([^,>]+)', v)
            if match:
                category, id_, number = match.groups()
                tmp_dict[id_] = number
        
        return tmp_dict

    def set_info(self) -> None:
        self.infos = self.get_number(self.header['INFO'])

    def set_format(self) -> None:
        self.formats = self.get_number(self.header['FORMAT'])

    def sorting(self) -> "VCF_DataFrame": 
        return self.iloc[self.apply(natsort_keygen(key=lambda x: (x['#CHROM'], x['POS'])), axis=1).argsort()].reset_index(drop=True)

    def unstack(self) -> "VCF_DataFrame":
        splitted_rows = []
        stacked_indices = []
        for idx, row in self.iterrows():
            if row.is_stacked:
                stacked_indices.append(idx)
                splitted_rows.extend(row.split_variant())
    
        vcf = self.drop(stacked_indices).reset_index(drop=True)

        if splitted_rows:
            new_vcf = VCF_DataFrame(splitted_rows)
            vcf = self.concat([vcf, new_vcf], ignore_index=True)

        return vcf.sorting()

    def filtering(self) -> "VCF_DataFrame":
        return self.filter_PASS().filter_VAF()

    def filter_PASS(self) -> "VCF_DataFrame": 
        if self.empty:
            return self.empty_df()
        vcf = self[self["FILTER"] == 'PASS']
        return vcf.reset_index(drop=True) if not vcf.empty else self.empty_df()

    def filter_VAF(self, germline: bool = False) -> "VCF_DataFrame":
        vcf = self[[row.filter_VAF(germline=germline) for _, row in self.iterrows()]]
        return vcf.reset_index(drop=True) if not vcf.empty else self.empty_df()

    def get_VAF(self, germline: bool = False):
        vaf_list = [row.get_VAF(germline) for _, row in self.iterrows()]
        return pd.Series(vaf_list)
    
    def merge(self, other: "VCF_DataFrame") -> "VCF_DataFrame":
        compare_columns = ['#CHROM', 'POS', 'REF', 'ALT']
        other_l = other[compare_columns]
        merge_vcf = pd.merge(self, other_l, on=compare_columns, how='inner')
        return VCF_DataFrame(merge_vcf, header=self.header, source= self.source)

    def to_vcf(self, file_path:str) -> None:
        with open(file_path, "w+") as f:
            f.write('\n'.join(['\n'.join(lines) for _, lines in self.header.items()])) if self.header is not None else ...
            f.write('\n')
            self.to_csv(f, header=True, sep='\t', index=False)
            f.close()


            
