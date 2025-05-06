if ("scarHRD" %in% installed.packages()) {
    library(scarHRD)
} else {
    print("scarHRD is NOT installed")
    library(devtools)
    install_github('sztup/scarHRD',build_vignettes = TRUE)
    library(scarHRD)
}

library(optparse)

option_list <- list(
  make_option(c("-i", "--input"), type="character", default=NULL, help="Input directory", metavar="DIR"),
  make_option(c("-p", "--patient"), type="character", default=NULL, help="Patient ID", metavar="ID")
)

# Parse arguments
opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# Check if required arguments are provided
if (is.null(opt$input) || is.null(opt$patient)) {
  print("Error: Missing required arguments!")
  print_help(opt_parser)
  quit(status = 1)
}

# Print received arguments
input_dir <- normalizePath(opt$input)
print(paste("Input Directory:", input_dir))

print(paste("Patient ID:", opt$patient))
seqz.file <- normalizePath(paste(input_dir, '/', opt$patient, '.small.seqz.gz', sep=''))
print(paste("Seqz Files:", seqz.file))
scar_score(seqz.file, reference="grch38", seqz = TRUE)

