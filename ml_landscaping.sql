-- Dimension tables
DROP TABLE IF EXISTS dim_job_type CASCADE;

CREATE TABLE dim_job_type (
  job_type_id   smallint PRIMARY KEY,
  job_type_name text
);

COPY dim_job_type (job_type_id, job_type_name)
FROM '/Personal Projects/Mallow - Liscarroll Landscaping/dim_job_type.csv'
DELIMITER ','
CSV HEADER;

DROP TABLE IF EXISTS dim_customer CASCADE;

CREATE TABLE dim_customer (
  customer_id        text PRIMARY KEY,
  customername       text,
  eircode            text,
  street             text,
  town               text,
  country            text,
  phone              text,
  email              text,
  preffered_contact  text
);

COPY dim_customer (customer_id, customername, eircode, street, town, country, phone, email, preffered_contact)
FROM '/Personal Projects/Mallow - Liscarroll Landscaping/dim_customer.csv'
DELIMITER ','
CSV HEADER;

DROP TABLE IF EXISTS dim_equipment CASCADE;

CREATE TABLE dim_equipment (
  equipment_id   smallint PRIMARY KEY,
  equipment_name text,
  rental_rate    numeric(12,2),
  website        text
);

COPY dim_equipment
FROM '/Personal Projects/Mallow - Liscarroll Landscaping/dim_equipment.csv'
WITH (
  FORMAT  csv,     -- first row has column headers
  HEADER  true,    -- header present
  DELIMITER ',',   -- comma-delimited
  NULL ''          -- empty strings treated as NULL
);

-- Fact table
DROP TABLE IF EXISTS fact_work_order CASCADE;

CREATE TABLE fact_work_order (
  work_order_id       text PRIMARY KEY,
  customer_id         text REFERENCES dim_customer,
  work_date           date,
  two_men             bool,
  service_charge      numeric(12,2),
  rate_charge         numeric(12,2),
  rental_costs        numeric(12,2),
  hours_worked        numeric(5,2),
  hours_traveling     numeric(5,2),
  distance_km         numeric(7,2),
  petrol_litre_cost   numeric(6,3),
  hedge_trim          bool,
  high_hedge_trim     bool,
  grass_strim         bool,
  lawn_mow            bool,
  weed_pulling        bool,
  tree_shrub_removal  bool,
  waste_removal       bool
);

COPY fact_work_order
FROM '/Personal Projects/Mallow - Liscarroll Landscaping/fact_work_order.csv'
WITH (
  FORMAT  csv,     -- first row has column headers
  HEADER  true,    -- header present
  DELIMITER ',',   -- comma-delimited
  NULL ''          -- empty strings treated as NULL
);

-- Bridge table
DROP TABLE IF EXISTS bridge_job_type_equipment CASCADE;

CREATE TABLE bridge_job_type_equipment (
  job_type_id   smallint REFERENCES dim_job_type,
  equipment_id  smallint REFERENCES dim_equipment
);

COPY bridge_job_type_equipment
FROM '/Personal Projects/Mallow - Liscarroll Landscaping/bridge_job_type_equipment.csv'
WITH (
  FORMAT  csv,     -- first row has column headers
  HEADER  true,    -- header present
  DELIMITER ',',   -- comma-delimited
  NULL ''          -- empty strings treated as NULL
);

/* -------------------------------------------------------------
   CTE “base”  
   Pulls every row from fact_work_order and adds two reusable
   row‑level calculations:
      • operating_cost_raw  – rental_costs + fuel (km/L × €/L)
      • total_profit_raw    – revenue – operating cost
   Doing this once keeps the outer SELECT tidy and avoids
   repeating the same math in multiple derived columns.
------------------------------------------------------------- */
WITH base AS (
    SELECT
        -- identifiers & raw fields
        work_order_id,
        customer_id,
        work_date,
        two_men,
        service_charge,
        rate_charge,
        rental_costs,
        hours_worked,
        hours_traveling,
        distance_km,
        petrol_litre_cost,
        hedge_trim,
        high_hedge_trim,
        grass_strim,
        lawn_mow,
        weed_pulling,
        tree_shrub_removal,
        waste_removal,

        /* operating cost (un‑rounded) */
        rental_costs + (distance_km / 20) * petrol_litre_cost            AS operating_cost_raw,

        /* total profit (un‑rounded) */
        (rate_charge * hours_worked + service_charge)
          - (rental_costs + (distance_km / 20) * petrol_litre_cost)      AS total_profit_raw
    FROM fact_work_order
)

SELECT
    work_order_id,
    customer_id,
    work_date,
    two_men,
    service_charge,
    rate_charge,
    rental_costs,
    hours_worked,
    hours_traveling,
    distance_km,
    petrol_litre_cost,
    ROUND(operating_cost_raw, 2)                                                        AS operating_cost,
    ROUND(total_profit_raw, 2)                                                          AS total_profit,
    ROUND(total_profit_raw / CASE WHEN two_men THEN 2 ELSE 1 END, 2)                    AS profit_per_person,
    hours_worked + hours_traveling                                                      AS total_time,
    ROUND(
        total_profit_raw /
        (hours_worked + hours_traveling) /
        CASE WHEN two_men THEN 2 ELSE 1 END,
    2)                                                                                  AS profit_per_hour,
    hedge_trim,
    high_hedge_trim,
    grass_strim,
    lawn_mow,
    weed_pulling,
    tree_shrub_removal,
    waste_removal
FROM base;
