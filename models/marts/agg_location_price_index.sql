{{ config(materialized="table") }}

with
    overall_pricing_avg as (
        select avg(selling_price) as overall_avg_selling_price
        from {{ ref("automobile_fact_table") }}
    ),

    location_averages as (
        select
            location,
            round(avg(selling_price), 2) as avg_selling_price,
            count(*) as listing_count
        from {{ ref("automobile_fact_table") }}
        group by location
    )

select
    l.location,
    l.avg_selling_price,
    l.listing_count,
    round(l.avg_selling_price / o.overall_avg_selling_price, 2) as price_index
from location_averages l
cross join overall_pricing_avg o
