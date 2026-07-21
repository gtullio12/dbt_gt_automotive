{{ config(materialized="table") }}

with
    price_thresholds as (
        select
            min(selling_price) as min_price,
            max(selling_price) as max_price,
            min(selling_price)
            + ((max(selling_price) - min(selling_price)) / 4 * 1) as low_threshold,
            min(selling_price)
            + ((max(selling_price) - min(selling_price)) / 4 * 3) as high_threshold
        from {{ ref("stg_automobile_dataset") }}
    ),

    raw_dataset as (select * from {{ ref("stg_automobile_dataset") }}),

    transformed_fact_table as (
        select
            *,
            year(current_date()) - year as car_age,
            case
                when horsepower is null or horsepower = 0
                then null
                else selling_price / horsepower
            end as price_per_horsepower,
            case
                when mileage < 20000
                then 'LOW'
                when mileage >= 20000 and mileage < 100000
                then 'MEDIUM'
                else 'HIGH'
            end as mileage_bucket,
            (
                (
                    case
                        when accident_history = 0
                        then 40
                        when accident_history = 1
                        then 0
                        else 20
                    end
                ) + (
                    case
                        when service_history = 'Partial Service'
                        then 16.5
                        when service_history = 'No Service'
                        then 0
                        when service_history = 'Full Service'
                        then 35
                        else 16.5
                    end
                )
                + (25 - ((owners - 1) * (25 / 4)))
            ) as condition_score,
            case
                when selling_price > t.high_threshold
                then 'HIGH'
                when selling_price > t.low_threshold
                then 'MID'
                else 'LOW'
            end as value_bucket

        from raw_dataset
        cross join price_thresholds t
    )

select *
from
    transformed_fact_table

    {#

Price per model Fact Table shape: 

Car age — current year minus YEAR. Raw manufacturing year isn't useful for analysis. Age is what drives depreciation.

Price per horsepower — SELLING_PRICE divided by HORSEPOWER. Normalizes price across different power levels. Lets you compare value across makes.

Mileage buckets — instead of raw mileage numbers, group into ranges. Under 20K, 20K-50K, 50K-100K, over 100K.

Condition score — a derived field combining ACCIDENT_HISTORY, OWNERS, and SERVICE_HISTORY into a single quality signal. A car with no accidents, one owner, and full service history gets a high score. 
A car with multiple accidents, five owners, and no service history gets a low score.
    Weighted scoring system. Score from 0-100:
        Accident history: 0-40
            No accidents(value of 0) -> 40
            Accident (value of 1) -> 0
            Unknown (null value) -> 20
        Service History: 0-35
            No service -> 0
            Full Service -> 35
            Partial Service -> 16.5
            NULL -> 16.5
        Owners: 0-25
            Linear Normalization formula: 25 - ((owners - 1) * (25 / 4))


Value segment — bucket SELLING_PRICE into Low, Mid, High.
    if selling_price > min + (((max-min) / 4) * 3) then HIGH 
    else if selling_price > min + (((max-min) / 4) * 1) and selling_price < min + (((max-min) / 4) * 3) then Mid
    else low
#}
    
