{{ config(materialized="table") }}

{#
Compare fuel types across multiple metrics simultaneously — one row per fuel type showing:

Average selling price
Average fuel efficiency
Average horsepower
Average torque
Listing count
#}
select
    fuel_type,
    round(avg(selling_price), 2) as avg_selling_price,
    round(avg(fuel_efficiency), 0) as avg_fuel_efficiency,
    round(avg(horsepower), 0) as avg_horsepower,
    round(avg(torque), 0) as avg_torque,
    count(*) as listing_count
from {{ ref("automobile_fact_table") }}
group by fuel_type
