{{ config(materialized='view') }}

select * from {{source('dbt_gt_automotive', 'AUTOMOBILE_DATASET')}}
