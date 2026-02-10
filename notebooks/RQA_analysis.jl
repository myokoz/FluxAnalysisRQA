### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# ╔═╡ c87ec8d7-bce5-4d30-b7a5-10fc0c0b942d
begin
    import Pkg
    Pkg.activate(joinpath(@__DIR__, ".."))
    using Printf, XLSX, DataFrames, Dates, Plots, Statistics, LinearAlgebra
end

# ╔═╡ c5e6297e-e4d2-490c-940b-7589bd67bb32
module DataLoad
    using XLSX, DataFrames, Dates, Plots, Statistics
    include(joinpath(@__DIR__, "..", "src", "data_loading.jl"))
end

# ╔═╡ 5935c0f1-3096-4c82-bcad-874658c8fdea
module DroughtExtract
    using DataFrames, Dates, Statistics, Plots, Printf
    import ..DataLoad # 親のDataLoadを参照
    # data_loading.jlで作られたflux_dataをこのモジュール内でも使えるようにする
    const flux_data = DataLoad.flux_data 
    include(joinpath(@__DIR__, "..", "src", "drought_extract.jl"))
end

# ╔═╡ 21ec580d-3a9d-4f11-a30c-4124a770b8d8
module Embedding
    using LinearAlgebra, Statistics, Plots, Printf
    import ..DroughtExtract
    
    # 【重要】隣のモジュールから関数を持ち込む
    const create_daily_mean_nee = DroughtExtract.create_daily_mean_nee
    
    include(joinpath(@__DIR__, "..", "src", "embedding.jl"))
end

# ╔═╡ 8f0f74bf-eaf5-481a-84bf-71d646135804
begin
    # 判定結果とデータの取得
    class_results = DroughtExtract.drought_classification
    main_data = DataLoad.flux_data
    
    # 分析の実行
    Embedding.compare_recurrence_drought_vs_normal(
        main_data,
        class_results;
        start_month=3,
        end_month=5,
        m=3,
        tau=1,
        threshold_quantile=0.10
    )
end

# ╔═╡ d22e6f37-6fc1-4b36-b217-2d7f9f1b79a6
begin
    # 解析を実行し、結果を results に格納
    results = Embedding.compare_recurrence_drought_vs_normal(
        DataLoad.flux_data,
        DroughtExtract.drought_classification;
        start_month=3,
        end_month=5,
        m=3,
        tau=1,
        threshold_quantile=0.10
    )

    # セルの最後に表示したいプロットを置く
    # 例：干ばつ年の最初の年のリカレンスプロットを表示する場合
    first_drought_year = DroughtExtract.drought_classification["drought_years"][1]
    results["drought"][first_drought_year][4] # 4番目が rec_plot です
end

# ╔═╡ 10121cb8-3838-4aa9-86bc-124bd8846d87
let
    # 干ばつ年と通常年から1年ずつ抽出
    d_year = DroughtExtract.drought_classification["drought_years"][1]
    n_year = DroughtExtract.drought_classification["normal_years"][1]
    
    p1 = results["drought"][d_year][4] # 干ばつ年のRP
    p2 = results["normal"][n_year][4]  # 通常年のRP
    
    # 2つを並べて表示
    plot(p1, p2, layout=(1, 2), size=(800, 400))
end

# ╔═╡ Cell order:
# ╠═c87ec8d7-bce5-4d30-b7a5-10fc0c0b942d
# ╠═c5e6297e-e4d2-490c-940b-7589bd67bb32
# ╠═5935c0f1-3096-4c82-bcad-874658c8fdea
# ╠═21ec580d-3a9d-4f11-a30c-4124a770b8d8
# ╠═8f0f74bf-eaf5-481a-84bf-71d646135804
# ╠═d22e6f37-6fc1-4b36-b217-2d7f9f1b79a6
# ╠═10121cb8-3838-4aa9-86bc-124bd8846d87
