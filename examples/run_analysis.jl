"""
run_analysis.jl


実行順序:
1. data_loading.jl でデータを読み込み
2. drought_extract.jl で春季データを抽出し干ばつ年を判定
3. embedding.jl でリカレンスプロットを作成
"""

using Printf

println("=" ^ 70)
println("炭素フラックスデータ解析 ")
println("=" ^ 70)
println()

# ========================================
# データの読み込みと前処理
# ========================================

println("\n" * "=" ^ 70)
println("データの読み込みと前処理")
println("=" ^ 70 * "\n")

# data_loading.jl を実行
# @__DIR__ は絶対パスを返す
include(joinpath(@__DIR__, "..", "src", "data_loading.jl"))
#include("data_loading.jl")

println("\nデータ読み込み完了: flux_data")
println()

# ========================================
# 春季データの抽出と干ばつ年判定
# ========================================

println("\n" * "=" ^ 70)
println("春季データの抽出と干ばつ年判定")
println("=" ^ 70 * "\n")

# drought_extract.jl を実行
include(joinpath(@__DIR__, "..", "src", "drought_extract.jl"))
# include("drought_extract.jl")

println("\n干ばつ年判定完了: drought_classification")
println()

# ========================================
# embedding機能の読み込み
# ========================================

println("\n" * "=" ^ 70)
println("Embedding")
println("=" ^ 70 * "\n")

# embedding.jl を実行
include(joinpath(@__DIR__, "..", "src", "embedding.jl"))
#include("embedding.jl")

# ========================================
# リカレンスプロットの作成
# ========================================

println("\n" * "=" ^ 70)
println("リカレンスプロット")
println("=" ^ 70 * "\n")

# 干ばつ年と通常年のリカレンスプロットを作成
recurrence_results = compare_recurrence_drought_vs_normal(
    flux_data,
    drought_classification;
    start_month=3,
    end_month=5,
    m=3,
    tau=1,
    threshold_quantile=0.10
)

# ========================================
# 最終サマリー
# ========================================

println("\n" * "=" ^ 70)
println("解析完了サマリー")
println("=" ^ 70)
println()
println("データ期間: $(flux_data["start_date"]) から $(flux_data["end_date"])")
println("総レコード数: $(flux_data["n_records"])")
println()
println("解析対象年: $(drought_classification["years"])")
println("干ばつ年 ($(length(drought_classification["drought_years"]))年): $(drought_classification["drought_years"])")
println("通常年 ($(length(drought_classification["normal_years"]))年): $(drought_classification["normal_years"])")
println()
println("リカレンスプロット:")
println("  干ばつ年: $(length(recurrence_results["drought"])) 個作成")
println("  通常年: $(length(recurrence_results["normal"])) 個作成")
println()
println("=" ^ 70)
println()

println("次のステップ:")
println("- RQA指標の計算")
println("- 統計的比較")
println()

println("利用可能なグローバル変数:")
println("  - flux_data: 読み込んだフラックスデータ")
println("  - drought_classification: 干ばつ年判定結果")
println("  - recurrence_results: リカレンス行列とプロット")
println()