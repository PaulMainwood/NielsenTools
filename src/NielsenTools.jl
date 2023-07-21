module NielsenTools

using CSV, DataFrames, Dates # Basic data munging tools

include("consolidationtools.jl")
include("analysistools.jl")

export prepare_sheet, size_to_OS_TH, string_to_float, extract_brand, create_dicts, prepare_matrix

end # module
