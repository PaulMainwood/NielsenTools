

function size_to_OS_TH(size::String, count::String, os_dict::Dict)
    if count != "X1" && count != "SINGLE"
        return "TH"
    else
        return get(os_dict, size, "TH")
    end
end

function string_to_float(x)
    #Process strings to floating point numbers
    if typeof(x) == Float64
        return x
    elseif ismissing(x)
        return 0.0
    elseif x == ""
        return 0.0
    else return parse(Float64, x)
    end
end

function extract_brand(x, sector, range)
    #Function used to extract the brandname from the longer description
    startindex = findfirst(sector, x[11:end])[end] + 12
    finishindex = findlast(range, x)[1] - 2
    return x[startindex:finishindex]
end

function create_dicts(; sizepath = "lookups/size_lookup.csv", rangepath = "lookups/range_lookup.csv", countpath = "lookups/count_lookup.csv", namepath = "lookups/name_lookup.csv")
    #Create all the dictionaries used for parsing the data

    size_consolidated = CSV.File(sizepath) |> DataFrame
    size_dict = Dict(size_consolidated.Size .=> size_consolidated.SizeLookup);
    os_th_dict = Dict(size_consolidated.Size .=> size_consolidated.OSTH)


    range_brand = CSV.File(rangepath) |> DataFrame
    range_brand_dict = Dict(range_brand.Range .=> range_brand.Brand)
    range_sector_dict = Dict(range_brand.Range .=> range_brand.Sector)

    
    count_consolidated = CSV.File(countpath) |> DataFrame
    count_dict = Dict(count_consolidated.Count_original .=> count_consolidated.Count_lookup)

    name_consolidated = CSV.File(namepath) |> DataFrame
    name_dict = Dict(name_consolidated.SKU .=> name_consolidated.Nickname)
    lead_dict = Dict(name_consolidated.SKU .=> name_consolidated.Lead)

    return size_dict, os_th_dict, range_brand_dict, range_sector_dict, count_dict, name_dict, lead_dict
end
