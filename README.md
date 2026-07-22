# dbt Automotive Analytics

A dbt project built on a used car transaction dataset from Kaggle. The goal was to understand what drives used car pricing — how region, fuel type, vehicle condition, and specs affect resale value.

## Dataset

Used car transaction data sourced from Kaggle containing pricing, vehicle specifications, condition history, and location across the US. Loaded into Snowflake as a raw source table.

[Automobile Market Dataset — Vehicle Specification](https://www.kaggle.com/datasets/ranaghulamnabi/automobile-market-dataset-vehicle-specification)

## Project Structure

```
models/
  staging/
    stg_automobile_dataset.sql       # Source connection, no transformations
  intermediate/
    automobile_fact_table.sql        # Enriched fact table with calculated fields
  marts/
    agg_make_model_value.sql         # Average pricing and condition by make/model
    agg_location_price_index.sql     # Regional pricing relative to overall average
    agg_fuel_type.sql                # Performance and pricing metrics by fuel type
```

Follows the **medallion architecture** — raw source → staging → intermediate → marts.

## Fact Table — Calculated Fields

The fact table enriches each car record with fields not available in the raw data:

| Field | Description |
|---|---|
| `car_age` | Current year minus manufacturing year |
| `price_per_horsepower` | Selling price divided by horsepower. Null when horsepower is unknown |
| `mileage_bucket` | LOW (under 20K), MEDIUM (20K–100K), HIGH (over 100K) |
| `condition_score` | 0–100 quality score combining accident history (0–40), service history (0–35), and number of owners (0–25) |
| `value_bucket` | LOW, MID, or HIGH price segment based on dataset price distribution |

## Aggregate Models

**agg_make_model_value** — one row per make/model combination showing average selling price, car age, mileage, and condition score. Identifies which vehicles hold their value best.

**agg_location_price_index** — one row per location showing average selling price and a price index (location average / overall average). Values above 1.0 indicate a premium market.

**agg_fuel_type** — one row per fuel type comparing average price, fuel efficiency, horsepower, and torque across Electric, Hybrid, Petrol, and Diesel vehicles.

## Testing

Tests are defined in schema.yml files across all three layers:

- `not_null` on critical columns at the staging layer — make, model, year, mileage, selling_price, owners, fuel_type, drivetrain
- `not_null` on all calculated fields in the fact table — car_age, mileage_bucket, value_bucket, condition_score
- `not_null` on key columns in all aggregate models

## Tech Stack

- **dbt Cloud** — Fusion engine (2.0.0-preview)
- **Snowflake** — data warehouse
- **GitHub** — version control

## Condition Score Logic

The condition score combines three signals into a single 0–100 quality metric:

- **Accident history (0–40)** — No accidents: 40, Has accidents: 0, Unknown: 20
- **Service history (0–35)** — Full service: 35, Partial service: 16.5, No service: 0
- **Owners (0–25)** — Linear normalization: `25 - ((owners - 1) * (25 / 4))`. One owner scores 25, five owners score 0.
