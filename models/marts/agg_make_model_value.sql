{{ config(materialized="table") }}

with
    agg_make_model_value as (
        select
            make,
            model,
            count(*) as listing_count,
            max(year) as max_year,
            min(year) as min_year,
            round(avg(car_age), 0) as average_car_age,
            round(avg(selling_price), 2) as average_selling_price,
            round(avg(mileage), 2) as average_mileage,
            round(avg(condition_score), 1) as average_condition_score
        from {{ ref("automobile_fact_table") }}
        group by make, model
    )

select *
from
    agg_make_model_value

    {#
1. Make and model value retention
Which makes and models hold value best. 
Aggregate by make and model — average selling price, average car age, average mileage, average condition score. 
#}
    
