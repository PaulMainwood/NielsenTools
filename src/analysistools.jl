
function prepare_data(all_data, customer, product_nickname)
    #Filter out irrelevant data
    most_data = filter(:Customer => x -> x == customer, all_data)
    most_data = filter(:Nickname => x -> !ismissing(x), most_data)
    #most_data = filter(:Lead => x -> x == 1, most_data)
    
    #Groupby the nickname
    gdf = groupby(most_data, [:Week, :Nickname])
    combined = combine(gdf, :Value => sum, :Volume => sum, :Units => sum, :AC_Distribution => maximum, :Num_Distribution => maximum, :Store_Universe => sum, :AC_Feature_Display => maximum, nrow)
    
    lead = filter(:Nickname => x -> x == product_nickname, combined)
    return_sheet = DataFrame(Week = lead.Week, Volume = lead.Volume_sum, Distribution = lead.AC_Distribution_maximum ./ 100, Feature = lead.AC_Feature_Display_maximum ./ 100, ASP = lead.Value_sum ./ lead.Volume_sum, )
    
    #Sort and cope with NaNs and negatives
    sort!(return_sheet, :Week)
    filter!(:Volume => x -> !(ismissing(x) || isnothing(x) || isnan(x)), return_sheet)
    filter!(:ASP => x -> !(ismissing(x) || isnothing(x) || isnan(x)), return_sheet)
    return_sheet.Volume = abs.(return_sheet.Volume)

    return return_sheet
end

#Prepare a full sheet ready for analysis
function prepare_sheet(all_data; customer = "SSL", product_nickname = "innocent TH NFC", competitors = ["innocent Large NFC", "Trop TH NFC", "Copella TH NFC", "PL TH NFC", "innocent TH Smoothie Classic"], drop_missing = true, use_distribution = false)
    original = prepare_data(all_data, customer, product_nickname)
    competitors_data = [prepare_data(all_data, customer, comp) for comp in competitors]
    
    orig_length = length(original.ASP)
    println(size(original))

    function procrustes(original, new)
        #Shorten or lengthen all columns to fit "original" length
        new_length = length(new.ASP)
        if orig_length == new_length
            return new.ASP
        elseif orig_length > new_length
            return vcat(missings(Float64, orig_length - new_length), new.ASP)
        elseif new_length > orig_length
            return new.ASP[new_length - orig_length + 1: end]
        end
    end


    competitor_ASPs = [procrustes(original, comp_data) for comp_data in competitors_data]

    #Add new columns
    for comp in competitor_ASPs
        original = hcat(original, comp, makeunique = true)
    end
    
    #Rename dataframe with column names from input 
    new_names = Dict(names(original) .=> vcat(names(original)[1:5], competitors))
    original = rename(original, new_names)
    sort!(original, :Week)

    if drop_missing
        return dropmissing(original)
    else
        return original
    end

end

function prepare_matrix(all_data, position; products = ["innocent TH NFC", "innocent Large NFC", "Trop TH NFC", "Copella TH NFC", "PL TH NFC", "innocent TH Smoothie Classic"], customer = "SSL")
    
    #Prepare all combinations
    data_matrix = [prepare_data(all_data, customer, product) for product in products]

    ll = local_level_regression_var_coeffs(create_y(data_matrix, position), X = create_X(data_matrix, position), var_coeffs = create_var_coeffs(data_matrix, position))
    ss = statespace(ll)

    return ss
end

#Create the main 
function create_y(data_matrix, position)
    return log.(data_matrix[position].Volume)
end

#Create the X matrix of regressors - here almost all ASPs
function create_X(data_matrix, position)
    num_prods = size(data_matrix)[1]
    length = size(data_matrix[1])[1]
    X = zeros(Float64, length, num_prods + 1)

    #Grab ASP levels from all
    ASPs = [data_sheet.ASP for data_sheet in data_matrix]

    #Fill matrix
    for i in 1:num_prods
        X[:, i] = ASPs[i]
    end

    #Add feature space for the primary one
    X[:, num_prods + 1] = data_matrix[position].Feature
    println(size(X))
    
    return X
end

