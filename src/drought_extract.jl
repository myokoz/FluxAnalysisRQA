"""
drought_extract.jl

春季データの抽出と干ばつ年・通常年の分類を行うスクリプト
data_loading.jl で読み込んだデータを引き継ぐ

1. 日平均NEEの計算
2. 各年の春季（3-5月）の降水量・VPD・気温を計算
3. 統計量を計算
4. 干ばつ年と通常年を判定
"""

using DataFrames
using Dates
using Statistics
using Plots

# ========================================
# 日平均NEEを計算する関数
# ========================================

"""
    create_daily_mean_nee(flux_data::Dict, year::Int, start_month::Int, end_month::Int) -> Dict

指定期間の日平均NEEを計算する

# 引数
- flux_data: data_loading.jl で作成したデータ
- year: 年
- start_month: 開始月
- end_month: 終了月

# 戻り値
- timestamps: 日付のベクトル
- values: 日平均NEEのベクトル
"""
function create_daily_mean_nee(flux_data::Dict, year::Int, start_month::Int, end_month::Int)
    # 終了月の最終日を取得
    if end_month == 12
        end_day = 31
    else
        end_day = daysinmonth(Date(year, end_month))
    end
    
    # 期間の開始日と終了日
    start_date = DateTime(year, start_month, 1)
    end_date = DateTime(year, end_month, end_day, 23, 59, 59)
    
    # NEE_CUT_REFのデータを取得
    nee_data = flux_data["data"]["NEE_CUT_REF"]
    timestamps = nee_data["timestamps"]
    values = nee_data["values"]
    
    # 指定期間のデータを抽出
    period_indices = findall(t -> start_date <= t <= end_date, timestamps)
    period_timestamps = timestamps[period_indices]
    period_values = values[period_indices]
    
    # 日付（時刻なし）のリストを作成
    days_only = Date.(period_timestamps)
    
    # ユニークな日付を取得
    unique_days = unique(days_only)
    
    # 各日の平均を計算
    daily_means = Float64[]
    daily_dates = DateTime[]
    
    for day in unique_days
        # その日のデータのインデックスを取得
        day_indices = findall(d -> d == day, days_only)
        day_values = period_values[day_indices]
        
        # 欠測値を除外して平均を計算
        valid_values = filter(!ismissing, day_values)
        if !isempty(valid_values)
            push!(daily_means, mean(valid_values))
            push!(daily_dates, DateTime(day))
        end
    end
    
    return Dict("timestamps" => daily_dates, "values" => daily_means)
end

# ========================================
# 年ごとの春季気象条件を解析
# ========================================

println("\n========================================")
println("春季データの抽出と干ばつ年判定")
println("========================================\n")

# 解析する年の範囲
years = collect(2006:2014)

println("解析対象年: $(years)")
println()

# ========================================
# 3. 各年の春季（3-5月）の降水量とVPDを計算
# ========================================

println("各年の春季（3-5月）の気象条件を計算中...")

# 降水量の計算
annual_precip = Float64[]
for year in years
    # 春季の降水量データを取得
    p_data = flux_data["data"]["P_ERA(30分降水量)"]
    timestamps = p_data["timestamps"]
    values = p_data["values"]
    
    # 期間の範囲
    start_date = DateTime(year, 3, 1)
    end_date = DateTime(year, 5, 31, 23, 59, 59)
    
    # 期間内のデータを抽出
    period_indices = findall(t -> start_date <= t <= end_date, timestamps)
    p_values = values[period_indices]
    
    # 欠測値を除外して合計を計算
    valid_p = filter(!ismissing, p_values)
    total_precip = sum(valid_p)
    
    push!(annual_precip, total_precip)
end

# VPDの計算
annual_vpd = Float64[]
for year in years
    # 春季のVPDデータを取得
    vpd_data = flux_data["data"]["VPD_ERA(30分平均飽差)"]
    timestamps = vpd_data["timestamps"]
    values = vpd_data["values"]
    
    # 期間の範囲
    start_date = DateTime(year, 3, 1)
    end_date = DateTime(year, 5, 31, 23, 59, 59)
    
    # 期間内のデータを抽出
    period_indices = findall(t -> start_date <= t <= end_date, timestamps)
    vpd_values = values[period_indices]
    
    # 欠測値を除外して平均を計算
    valid_vpd = filter(!ismissing, vpd_values)
    year_mean_vpd = mean(valid_vpd)  # 変数名を変更
    
    push!(annual_vpd, year_mean_vpd)
end

# 気温の計算
annual_ta = Float64[]
for year in years
    # 春季の気温データを取得
    ta_data = flux_data["data"]["TA_ERA"]
    timestamps = ta_data["timestamps"]
    values = ta_data["values"]
    
    # 期間の範囲
    start_date = DateTime(year, 3, 1)
    end_date = DateTime(year, 5, 31, 23, 59, 59)
    
    # 期間内のデータを抽出
    period_indices = findall(t -> start_date <= t <= end_date, timestamps)
    ta_values = values[period_indices]
    
    # 欠測値を除外して平均を計算
    valid_ta = filter(!ismissing, ta_values)
    year_mean_ta = mean(valid_ta)  # 変数名を変更
    
    push!(annual_ta, year_mean_ta)
end

# ========================================
# 結果を表示
# ========================================

println("\n春季気象条件サマリー（3-5月）:")
println("=" ^ 70)
println("Year  | Total Precip (mm) | Mean VPD (kPa) | Mean TA (°C)")
println("-" ^ 70)
for i in 1:length(years)
    @printf("%4d  | %17.4f | %14.4f | %12.4f\n", 
            years[i], annual_precip[i], annual_vpd[i], annual_ta[i])
end
println("=" ^ 70)
println()

# ========================================
# 統計量の計算
# ========================================

mean_precip = mean(annual_precip)
std_precip = std(annual_precip)
mean_vpd = mean(annual_vpd)
std_vpd = std(annual_vpd)

println("統計量:")
println("-" ^ 50)
@printf("降水量 - 平均: %.4f mm, 標準偏差: %.4f mm\n", mean_precip, std_precip)
@printf("VPD - 平均: %.4f kPa, 標準偏差: %.4f kPa\n", mean_vpd, std_vpd)
println("-" ^ 50)
println()

# ========================================
# 降水量とVPDのプロット
# ========================================

println("プロット作成中...")

# 降水量のプロット
precip_plot = plot(
    years, annual_precip,
    title="Spring Total Precipitation (Mar-May)",
    xlabel="Year",
    ylabel="Total Precipitation (mm)",
    label="",
    marker=:circle,
    markersize=8,
    color=:blue,
    linewidth=2,
    size=(800, 400),
    framestyle=:box,
    grid=true,
    gridalpha=0.3
)

# 平均線を追加
hline!(precip_plot, [mean_precip], 
       label="Mean", 
       color=:blue, 
       linestyle=:dash, 
       linewidth=2)

# 平均-1SD線を追加
hline!(precip_plot, [mean_precip - std_precip], 
       label="Mean - 1SD", 
       color=:orange, 
       linestyle=:dash, 
       linewidth=2)

display(precip_plot)

# VPDのプロット
vpd_plot = plot(
    years, annual_vpd,
    title="Spring Mean VPD (Mar-May)",
    xlabel="Year",
    ylabel="Mean VPD (kPa)",
    label="",
    marker=:circle,
    markersize=8,
    color=:red,
    linewidth=2,
    size=(800, 400),
    framestyle=:box,
    grid=true,
    gridalpha=0.3
)

# 平均線を追加
hline!(vpd_plot, [mean_vpd], 
       label="Mean", 
       color=:blue, 
       linestyle=:dash, 
       linewidth=2)

# 平均+1SD線を追加
hline!(vpd_plot, [mean_vpd + std_vpd], 
       label="Mean + 1SD", 
       color=:orange, 
       linestyle=:dash, 
       linewidth=2)

display(vpd_plot)

# ========================================
# 干ばつ年の判定
# ========================================

println("\n干ばつ年の判定:")
println("条件: 降水量が平均-1SD以下 または VPDが平均+1SD以上")
println("-" ^ 50)

# 干ばつ年を判定
drought_years = Int[]
for (i, year) in enumerate(years)
    is_drought = (annual_precip[i] < (mean_precip - std_precip)) || 
                 (annual_vpd[i] > (mean_vpd + std_vpd))
    
    if is_drought
        push!(drought_years, year)
    end
end

# 通常年を判定
normal_years = setdiff(years, drought_years)

println("\n=================================")
println("干ばつ年: ", drought_years)
println("通常年: ", normal_years)
println("=================================")
println()

# ========================================
# 判定結果の詳細
# ========================================

println("判定詳細:")
println("=" ^ 70)
println("Year  | Precip | Precip < Mean-1SD | VPD    | VPD > Mean+1SD | Drought?")
println("-" ^ 70)

for (i, year) in enumerate(years)
    precip_drought = annual_precip[i] < (mean_precip - std_precip)
    vpd_drought = annual_vpd[i] > (mean_vpd + std_vpd)
    is_drought = precip_drought || vpd_drought
    
    @printf("%4d  | %6.1f | %-17s | %6.4f | %-14s | %s\n",
            year,
            annual_precip[i],
            precip_drought ? "Yes" : "No",
            annual_vpd[i],
            vpd_drought ? "Yes" : "No",
            is_drought ? "DROUGHT" : "Normal")
end
println("=" ^ 70)
println()

# ========================================
# 結果を変数として保存（次のスクリプトで使用可能）
# ========================================

# グローバル変数として保存
global drought_classification = Dict(
    "years" => years,
    "annual_precip" => annual_precip,
    "annual_vpd" => annual_vpd,
    "annual_ta" => annual_ta,
    "mean_precip" => mean_precip,
    "std_precip" => std_precip,
    "mean_vpd" => mean_vpd,
    "std_vpd" => std_vpd,
    "drought_years" => drought_years,
    "normal_years" => normal_years
)

println("結果が drought_classification 辞書に保存されました")
println()