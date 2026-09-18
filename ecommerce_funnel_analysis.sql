-- =====================================================
-- ECOMMERCE FUNNEL ANALYSIS
-- Purpose: Identify where users drop off in the purchase journey
-- =====================================================


-- =====================================================
-- SECTION 1: OVERALL FUNNEL ANALYSIS
-- =====================================================

-- Counts unique users per stage and calculates drop-off rate between each consecutive funnel stage

CREATE VIEW funnel_dropoff AS
SELECT
    Page_Type,
    unique_users,
    previous_stage_users,
    ROUND(
        (previous_stage_users - unique_users) * 1.0 / previous_stage_users * 100,
        2
    ) AS drop_off_rate,
    funnel_order
FROM (
    SELECT
        Page_Type,
        COUNT(DISTINCT User_ID) AS unique_users,
        CASE
            WHEN Page_Type = 'home'         THEN 1
            WHEN Page_Type = 'product_page' THEN 2
            WHEN Page_Type = 'cart'         THEN 3
            WHEN Page_Type = 'checkout'     THEN 4
            WHEN Page_Type = 'confirmation' THEN 5
        END AS funnel_order,
        LAG(COUNT(DISTINCT User_ID)) OVER (
            ORDER BY CASE
                WHEN Page_Type = 'home'         THEN 1
                WHEN Page_Type = 'product_page' THEN 2
                WHEN Page_Type = 'cart'         THEN 3
                WHEN Page_Type = 'checkout'     THEN 4
                WHEN Page_Type = 'confirmation' THEN 5
            END
        ) AS previous_stage_users
    FROM ecommerce_funnel_analysis.customer_journey_data
    GROUP BY Page_Type
) AS funnel_with_lag
ORDER BY funnel_order;


-- =====================================================
-- SECTION 2: FUNNEL ANALYSIS BY DEVICE TYPE
-- =====================================================

-- Counts unique users per stage by device type and calculates drop-off rates

CREATE VIEW device_dropoff AS
SELECT
    Device_Type,
    Page_Type,
    unique_users,
    previous_stage_users,
    ROUND(
        (previous_stage_users - unique_users) * 1.0 / previous_stage_users * 100,
        2
    ) AS drop_off_rate,
    funnel_order
FROM (
    SELECT
        Device_Type,
        Page_Type,
        COUNT(DISTINCT User_ID) AS unique_users,
        CASE
            WHEN Page_Type = 'home'         THEN 1
            WHEN Page_Type = 'product_page' THEN 2
            WHEN Page_Type = 'cart'         THEN 3
            WHEN Page_Type = 'checkout'     THEN 4
            WHEN Page_Type = 'confirmation' THEN 5
        END AS funnel_order,
        LAG(COUNT(DISTINCT User_ID)) OVER (
            PARTITION BY Device_Type
            ORDER BY CASE
                WHEN Page_Type = 'home'         THEN 1
                WHEN Page_Type = 'product_page' THEN 2
                WHEN Page_Type = 'cart'         THEN 3
                WHEN Page_Type = 'checkout'     THEN 4
                WHEN Page_Type = 'confirmation' THEN 5
            END
        ) AS previous_stage_users
    FROM ecommerce_funnel_analysis.customer_journey_data
    GROUP BY Device_Type, Page_Type
) AS device_with_lag
ORDER BY Device_Type, funnel_order;


-- =====================================================
-- SECTION 3: FUNNEL ANALYSIS BY COUNTRY
-- =====================================================

-- Counts unique users per stage by country and calculates drop-off rates

CREATE VIEW country_dropoff AS
SELECT
    Country,
    Page_Type,
    unique_users,
    previous_stage_users,
    ROUND(
        (previous_stage_users - unique_users) * 1.0 / previous_stage_users * 100,
        2
    ) AS drop_off_rate,
    funnel_order
FROM (
    SELECT
        Country,
        Page_Type,
        COUNT(DISTINCT User_ID) AS unique_users,
        CASE
            WHEN Page_Type = 'home'         THEN 1
            WHEN Page_Type = 'product_page' THEN 2
            WHEN Page_Type = 'cart'         THEN 3
            WHEN Page_Type = 'checkout'     THEN 4
            WHEN Page_Type = 'confirmation' THEN 5
        END AS funnel_order,
        LAG(COUNT(DISTINCT User_ID)) OVER (
            PARTITION BY Country
            ORDER BY CASE
                WHEN Page_Type = 'home'         THEN 1
                WHEN Page_Type = 'product_page' THEN 2
                WHEN Page_Type = 'cart'         THEN 3
                WHEN Page_Type = 'checkout'     THEN 4
                WHEN Page_Type = 'confirmation' THEN 5
            END
        ) AS previous_stage_users
    FROM ecommerce_funnel_analysis.customer_journey_data
    GROUP BY Country, Page_Type
) AS country_with_lag
ORDER BY Country, funnel_order;