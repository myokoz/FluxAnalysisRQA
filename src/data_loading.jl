"""
data_loading.jl

データの読み込み、前処理、各変数の時系列プロット
"""

using XLSX
using DataFrames
using Dates
using Plots
using Statistics

# データファイルのパス
data_file = joinpath(@__DIR__, "..", "data", "data.xlsx")
# data_file = "/Users/myokoz/Library/CloudStorage/Dropbox/dropbox_WS/current/22_SSR/\
#AmeriFlux_analysis/data.xlsx"


# ========================================
# 1. タイムスタンプ変換関数の定義
# ========================================

"""
タイムスタンプを DateTime に変換する
"""
function parse_timestamp_robust(ts)
    # すでに DateTime の場合
    if ts isa DateTime
        return ts
    end
    
    # 数値の場合
    if ts isa Number
        str = lpad(string(round(Int, ts)), 12, '0')
        year = parse(Int, str[1:4])
        month = parse(Int, str[5:6])
        day = parse(Int, str[7:8])
        hour = parse(Int, str[9:10])
        minute = parse(Int, str[11:12])
        return DateTime(year, month, day, hour, minute)
    end
    
    # 文字列の場合
    if ts isa String
        str = replace(ts, r"\s" => "")  # 空白を削除
        
        if length(str) < 12
            str = lpad(str, 12, '0')
        end
        
        year = parse(Int, str[1:4])
        month = parse(Int, str[5:6])
        day = parse(Int, str[7:8])
        hour = parse(Int, str[9:10])
        minute = parse(Int, str[11:12])
        return DateTime(year, month, day, hour, minute)
    end
    
    return missing
end

# ========================================
# 2. エラーハンドリング付き読み込み関数の定義
# ========================================

"""
    load_flux_data_from_excel_with_missing_safe(
        filepath::String,
        column_names::Vector{String};
        sheet_number::Int=1,
        missing_values::Vector=[-9999, -9999.0, "", nothing]
    ) -> Dict

Excelファイルからフラックスデータを読み込む
Wolfram の loadFluxDataFromExcelWithMissingSafe[] に対応
"""
function load_flux_data_from_excel_with_missing_safe(
    filepath::String,
    column_names::Vector{String};
    sheet_number::Int=1,
    missing_values::Vector=[-9999, -9999.0, "", nothing]
)
    # Excelファイルを読み込み
    xf = XLSX.readxlsx(filepath)
    raw_data = xf[XLSX.sheetnames(xf)[sheet_number]][:]
    
    # ヘッダーとデータ行を分離
    headers = String.(raw_data[1, :])
    data_rows = raw_data[2:end, :]
    
    # カラムインデックスの辞書
    col_indices = Dict(h => i for (i, h) in enumerate(headers))
    
    # 利用可能なカラムと欠損カラムを特定
    available_columns = intersect(column_names, headers)
    missing_columns = setdiff(column_names, headers)
    
    if !isempty(missing_columns)
        println("警告: 以下のカラムが見つかりません:")
        println(missing_columns)
    end
    
    # タイムスタンプを取得
    timestamp_col = col_indices["TIMESTAMP_START"]
    timestamps = [parse_timestamp_robust(row[timestamp_col]) for row in eachrow(data_rows)]
    timestamps = filter(!ismissing, timestamps)
    
    # 各カラムのデータを TimeSeries 相当の構造で保存
    data_dict = Dict{String, Any}()
    missing_count = Dict{String, Int}()
    
    for col_name in available_columns
        col_idx = col_indices[col_name]
        values = [row[col_idx] for row in eachrow(data_rows)]
        values = values[1:length(timestamps)]
        
        # 欠測値を missing に変換
        clean_data = map(values) do v
            if v in missing_values
                return missing
            else
                try
                    return Float64(v)
                catch
                    return missing
                end
            end
        end
        
        # TimeSeries 相当: timestamp と value のペア
        data_dict[col_name] = Dict(
            "timestamps" => timestamps,
            "values" => clean_data
        )
        
        missing_count[col_name] = count(ismissing, clean_data)
    end
    
    # 結果を返す
    return Dict(
        "data" => data_dict,
        "headers" => headers,
        "available_columns" => available_columns,
        "missing_columns" => missing_columns,
        "start_date" => first(timestamps),
        "end_date" => last(timestamps),
        "n_records" => length(timestamps),
        "missing_count" => missing_count
    )
end

# ========================================
# 3. ヘッダーの確認
# ========================================

println("\n========================================")
println("ヘッダーの確認")
println("========================================\n")

if isfile(data_file)
    xf = XLSX.readxlsx(data_file)
    raw_data = xf[1][:]
    headers = raw_data[1, :]
    
    println("利用可能なカラム名:")
    for (i, h) in enumerate(headers)
        println("$i: $h")
    end
else
    println("警告: $data_file が見つかりません")
    println("ファイルパスを確認してください")
end

println()

# ========================================
# 4. データの読み込み（全カラムを指定）
# ========================================

println("\n========================================")
println("データの読み込み")
println("========================================\n")

# 読み込むカラム名（実際のデータに合わせて変更してください）
column_names = [
    "NEE_CUT_REF",
    "NEE_VUT_REF",
    "TA_ERA",
    "SW_IN_ERA(30分平均入射短波放射)",
    "LW_IN_ERA(30分平均入射長波放射)",
    "VPD_ERA(30分平均飽差)",
    "PA_ERA(30分平均気圧)",
    "P_ERA(30分降水量)",
    "WS_ERA(30分平均風速)"
]

if isfile(data_file)
    flux_data = load_flux_data_from_excel_with_missing_safe(data_file, column_names)
    
    # ========================================
    # 5. 読み込み結果の確認
    # ========================================
    
    println("\n========================================")
    println("読み込み結果の確認")
    println("========================================\n")
    
    println("データ期間: $(flux_data["start_date"]) から $(flux_data["end_date"])")
    println("総レコード数: $(flux_data["n_records"])")
    println("利用可能なカラム: $(flux_data["available_columns"])")
    println("見つからなかったカラム: $(flux_data["missing_columns"])")
    
    # ========================================
    # 6. 欠損値の確認
    # ========================================
    
    println("\n========================================")
    println("欠損値の数")
    println("========================================\n")
    
    for (col, count) in flux_data["missing_count"]
        println("$col: $count")
    end
    
    # ========================================
    # 7. 各変数のプロット
    # ========================================
    
    println("\n========================================")
    println("各変数の時系列プロット")
    println("========================================\n")
    
    # プロット設定（変数名 => (タイトル, ylabel, 色)）
    plot_config = Dict(
        "NEE_CUT_REF" => ("NEE_CUT_REF Time Series", "NEE_CUT_REF (μmol/m²/s)", :blue),
        "NEE_VUT_REF" => ("NEE_VUT_REF Time Series", "NEE_VUT_REF (μmol/m²/s)", :red),
        "TA_ERA" => ("Air Temperature Time Series", "Temperature (°C)", :orange),
        "SW_IN_ERA(30分平均入射短波放射)" => ("Shortwave Radiation Time Series", "SW_IN (W/m²)", :green),
        "LW_IN_ERA(30分平均入射長波放射)" => ("Longwave Radiation Time Series", "LW_IN (W/m²)", :purple),
        "VPD_ERA(30分平均飽差)" => ("Vapor Pressure Deficit Time Series", "VPD (kPa)", :brown),
        "PA_ERA(30分平均気圧)" => ("Atmospheric Pressure Time Series", "Pressure (kPa)", :pink),
        "P_ERA(30分降水量)" => ("Precipitation Time Series", "Precipitation (mm)", :cyan),
        "WS_ERA(30分平均風速)" => ("Wind Speed Time Series", "Wind Speed (m/s)", :magenta)
    )
    
    # 各変数をプロット
    for col_name in flux_data["available_columns"]
        if haskey(plot_config, col_name)
            println("プロット中: $col_name")
            
            # データを取得
            timestamps = flux_data["data"][col_name]["timestamps"]
            values = flux_data["data"][col_name]["values"]
            
            # 欠測値を除去
            valid_indices = findall(!ismissing, values)
            valid_times = timestamps[valid_indices]
            valid_values = Float64.(values[valid_indices])
            
            if !isempty(valid_values)
                # プロット設定を取得
                title, ylabel, color = plot_config[col_name]
                
                # y軸の範囲を計算
                if minimum(valid_values) >= 0
                    # 非負の値の場合
                    ymin = 0
                    ymax = maximum(valid_values) * 1.05
                else
                    # 負の値を含む場合
                    ymin = minimum(valid_values) * (minimum(valid_values) < 0 ? 1.05 : 0.95)
                    ymax = maximum(valid_values) * (maximum(valid_values) > 0 ? 1.05 : 0.95)
                end
                
                # プロット作成
                p = plot(
                    valid_times,
                    valid_values,
                    title=title,
                    xlabel="Date",
                    ylabel=ylabel,
                    label="",
                    color=color,
                    linewidth=1,
                    ylims=(ymin, ymax),
                    size=(800, 400),
                    framestyle=:box,
                    grid=true,
                    gridalpha=0.3
                )
                
                display(p)
            end
        end
    end
    
    
else
    println("エラー: データファイル '$data_file' が見つかりません")
    println("ファイルパスを確認してください")
end