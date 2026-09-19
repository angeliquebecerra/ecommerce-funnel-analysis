# E-Commerce Funnel Analysis: Identifying Conversion Drop-Off Points
E-commerce funnel analysis conducted on a synthetic dataset of 4,129 events from 1,872 unique users, using Excel, SQL and Power BI to identify key drop-off points and actionable optimisation opportunities.
## Table of Contents

- [Executive Summary](#executive-summary)
- [Dataset](#dataset)
- [Methodology](#methodology)
- [Results](#results)
- [Recommendations](#recommendations)
- [Skills](#skills)
- [Files](#files)
## Executive Summary
### Business Problem 
Which stage of the funnel represents the largest drop-off point, and how can we optimise for a better conversion rate to improve revenue?
### Key Findings
- 75.95% of users who reached the product page did not add a product to cart. **This is the largest drop-off in the funnel.** It's the single biggest opportunity in the funnel to test and optimize.

- 58.06% of users who added an item to cart did not proceed to checkout. **Since these users already showed purchase intent, there could be a procedural barrier**.

- 41.88% of users who reached checkout did not complete their purchase. This is arguably the **costliest drop-off point**, as these users had already committed to buying.

- Mobile underperforms desktop and tablet at 3 of 4 funnel stages, pointing to a systemic **mobile UX issue**. The gap is widest at the final stage (57.14% vs ~37%), though that number rests on a small sample (28 users) and should be read as directional.

- Germany’s checkout-to-confirmation drop-off (81.25%) is the highest across all markets. Based on 16 sessions only at that stage, this is a lead worth keeping an eye on, but not a confirmed pattern.
### Recommended Actions (in priority order)
1. **Optimise product pages** with clearer CTAs, transparent pricing, better information delivery, and stronger social proof.

2. **Simplify the path from cart to checkout.** Eliminate forced account creation, surface shipping costs upfront, and add progress indicators to make advancement to payment feel effortless.

3. **Reduce friction at the final purchase step.** Reduce required form fields, verify all payment methods complete without errors, and add trust signals: security badges and a clearly visible return policy.

4. **Conduct an end-to-end mobile UX audit** covering: page load speed, touch target sizing, form usability, and payment flow on smaller screens. Mobile underperforms at 3 of 4 funnel stages.

5. **Validate Germany's checkout-to-confirmation pattern**. Its 81.25% drop-off is the highest in the dataset, but it is based on 16 sessions only. A new analysis needs to be conducted once more data has been collected.

## Dataset
### Overview
**Source:** Synthetic dataset  
**Rows:** 4,129  
**Unique users:** 1,872  
**Funnel stages:** Home → Product Page → Cart → Checkout → Confirmation  
**Key columns:** Session ID, User ID, Timestamp, Page Type, Device Type, Country, Referral Source, Time on Page, Items in Cart, Purchased  

*Note: This is an event-level dataset. Each row represents a single page visit, not a unique user.*
### Limitations
This project uses a synthetic dataset. Compared to real e-commerce averages (see [Benchmark Comparison](#benchmark-comparison)), the conversion funnel isn't underperforming. That doesn't make the business problem invalid. It means the recommendations here are framed around optimising further, not fixing underperformance against an external standard.

The dataset is also small enough that sample sizes shrink sharply at later funnel stages, especially once segmented by country or device. As a result, the country and device level breakdowns at checkout-to-confirmation are thin and should be read as directional, not conclusive. See user counts in [By Device Type](#by-device-type) and [By Country](#by-country). The overall funnel numbers behind the main findings don't have that issue. 

## Methodology
### Data Cleaning — Excel
Prior to any analysis, the dataset was audited for quality and consistency:
- Checked for missing values using `COUNTBLANK()` — none found.
  
- Verified duplicate Session IDs and User IDs were structural (event-level data) — found 14 fully duplicated erroneous rows and removed them, keeping only the first occurrence of each.
  
- Validated data types across all columns.
  
- Screened for invalid values — found 9 rows with negative `Time_On_Page_seconds` values (data entry errors) and corrected them using absolute value.
  
- Reviewed all categorical columns (Page Type, Device Type, Country) for labelling inconsistencies — found 25 rows with inconsistent capitalization in `Device_Type` (e.g. "mobile", "DESKTOP", "Tablet") and standardised to title case.
  
- Standardised column names for SQL compatibility.
### Exploratory Analysis — Excel
A pivot table was built to profile the distribution of page visits across funnel stages, establishing the funnel shape before moving to user-level analysis.

<p align="center"><img width="216" height="125" alt="funnel_stages_page_visits" src="https://github.com/user-attachments/assets/4a9c008e-bcee-4835-aa14-272b060a7afa" />
  <br>
<em>Excel — Pivot table</em></p>  


**Limitation:** Visit counts inflate stages where users browse repeatedly and do not reflect true user progression. These figures provided directional signal only and were superseded by the SQL analysis.

### User-Level Funnel Analysis — SQL
All funnel metrics were recalculated in SQL using `COUNT(DISTINCT User_ID)`, so that each user is counted once per stage regardless of visit frequency.

`CREATE VIEW` was used to store each analysis as a named, queryable object that Power BI could pull from directly. Each view encapsulates user counting, funnel ordering, and drop-off rate calculation in a single self-contained query.

**3 views were created:**

1. `funnel_dropoff` — Calculates the drop-off rate between each consecutive funnel stage, returning unique user counts and percentage of users lost moving from one stage to the next.

```sql
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

```
2. `device_dropoff` — Replicates the overall funnel analysis, segmented by device type, to see whether drop-off patterns differ across Desktop, Mobile, and Tablet.

```sql
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

```
3. `country_dropoff` — Replicates the overall funnel analysis, segmented by country, to surface potential market-specific drop-off patterns and outliers.

```sql
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

```
**Key SQL techniques applied:**

• `COUNT(DISTINCT)` for user-level accuracy

• `CASE` statements to assign logical funnel order to page types

• `LAG()` window function to retrieve the previous stage's user count

• `ROUND()` to format drop-off rates to 2 decimal places for readability

• `PARTITION BY` to reset stage comparisons independently within each segment

• Subqueries (`funnel_with_lag`, `device_with_lag`, `country_with_lag`) to compute user counts and previous stage values before drop-off rates are calculated in the outer query

### Dashboard — Power BI
**5 visuals were created on a single-page dashboard:**

1. The conversion funnel (unique users reaching each stage)
2. Drop-off rate between funnel stages (% of users lost moving from one stage to the next)
3. Drop-off rate by device type (% of users lost at each stage transition, by device)
4. Drop-off rate by country (% of users lost at each stage transition, by country)
5. KPI card showing overall conversion rate

**Key Power BI techniques applied:**

• Power Query to standardise page type labels (replace values) and enforce funnel sort order (sort column by `funnel_order`)

• Custom column `Stage_Transition` created in Power Query to replace `page_type` labels with transition-based naming (e.g. `Home → Product Page` instead of `Product Page`), making drop-off directionality immediately readable on the visuals

• Funnel chart to visualise unique user counts across the five stages

• Clustered bar charts with small multiples to compare drop-off rates across device types and countries

• Conditional colour encoding across bar charts to communicate drop-off severity (darker colours indicate higher loss)

• KPI card to surface overall conversion rate (3.63%) as a headline metric

<p align="center"><img width="2510" height="1422" alt="ecommerce_funnel_analysis_dashboard" src="https://github.com/user-attachments/assets/5584e7a8-9072-4781-a8d3-00de746e67a2" />
<br>
<em>Power BI — E-Commerce Funnel Analysis dashboard, full view</em></p>

## Results
Overall conversion across the funnel is 3.63% (68 of 1,872 users). The most significant drop-offs are concentrated in the middle and bottom of the funnel.
### Overall Funnel
<br>
<p align="center"><img width="568" height="122" alt="overall_funnel_analysis" src="https://github.com/user-attachments/assets/2311639a-74fa-4791-90d1-13cf48c36775" />
<br>
<em>MySQL — funnel_dropoff view output</em></p>
<br>
<p align="center"><img width="2264" height="838" alt="conversion_funnel" src="https://github.com/user-attachments/assets/da771c71-98e1-4a9e-a240-578679cb0b58" />
  <br>
  <em>Power BI — Conversion Funnel view (unique users reaching each stage)</em></p>
  <br>
  <p align="center"><img width="400" height="300" alt="dropoff_rate_by_funnel_stage" src="https://github.com/user-attachments/assets/e4b304fb-fd78-4762-ae00-dec8e52be50b" />
    <br>
    <em>Power BI — Drop-Off Rate by Funnel Stage view (% of users lost between consecutive funnel stages)
</em>
  </p>
<br>

38.03% of users left before reaching a product page.<br>
The biggest drop-off happens between the product page and cart (75.95%).<br>
Cart → Checkout follows at 58.06%, and checkout-to-confirmation at 41.88%.<br>

Not all losses carry equal weight. A user lost at checkout has already selected a product and initiated payment — their intent to purchase was at its highest. A user who leaves the home page may never have intended to buy at all.

### By Device Type
<br>
<p align="center"><img width="600" height="300" alt="funnel_analysis_by_device_type" src="https://github.com/user-attachments/assets/9dcbf224-0d64-4cf0-9a47-db3a5dc10645" />
<br>
<em>MySQL — device_dropoff view output</em></p>
<br>
<p align="center"><img width="450" height="350" alt="dropoff_rate_by_device_type" src="https://github.com/user-attachments/assets/35f722a5-839f-46da-9e21-b73c42241ad4" />
  <br>
<em>Power BI — Drop-Off Rate by Device Type view (% of users lost between consecutive funnel stages)</em></p>
<br>
<div align="center">
  
| Stage | Desktop | Mobile | Tablet |
|---|---|---|---|
| Home | 604 | 646 | 622 |
| Product Page | 415 | 368 | 377 |
| Cart | 111 | 68 | 100 |
| Checkout | 44 | 28 | 45 |
| Confirmation | 27 | 12 | 29 |

<em>Unique users reaching each stage, by device type</em>
</div>

Mobile records the highest drop-off rates at 3 of 4 funnel stage transitions: Home → Product Page (43.03%), Product Page → Cart (81.52%), and Checkout → Confirmation (57.14%). The exception is Cart → Checkout, where Desktop records the highest drop-off (60.36% vs Mobile: 58.82%, Tablet: 55.00%).

The gap between Mobile and the other devices is most pronounced at Checkout → Confirmation: 57.14% against Desktop's 38.64% and Tablet's 35.56%, a difference of roughly 20 points. Like every segmented breakdown at this stage, the sample size is small, so this particular gap should be read as directional, not confirmed.

Desktop and Tablet perform comparably across all stages. The consistency of Mobile's underperformance across three stages points to a potential systemic UX issue.

### By Country
<br>
<p align="center"><img width="600" height="600" alt="funnel_analysis_by_country" src="https://github.com/user-attachments/assets/d96a2cf7-020a-4c30-90dc-26789c1e7cbd" />
  <br>
<em>MySQL — country_dropoff view output</em></p>
<br>
<p align="center"><img width="800" height="300" alt="dropoff_rate_by_country" src="https://github.com/user-attachments/assets/e500db8b-4a04-402e-bf69-73fc05fa1cc4" />
<br>
<em>Power BI — Drop-Off Rate by Country visual (% of users lost between consecutive funnel stages)
</em></p>
<br>
<div align="center">

| Stage | Australia | Canada | France | Germany | India | UK | USA |
|---|---|---|---|---|---|---|---|
| Home | 238 | 248 | 281 | 264 | 285 | 296 | 260 |
| Product Page | 141 | 153 | 176 | 158 | 195 | 187 | 150 |
| Cart | 29 | 37 | 48 | 40 | 41 | 44 | 40 |
| Checkout | 9 | 13 | 18 | 16 | 22 | 17 | 22 |
| Confirmation | 4 | 11 | 13 | 3 | 10 | 10 | 17 |

<em>Unique users reaching each stage, by country</em></div>

Drop-off patterns are consistent across all seven markets. The product-to-cart stage accounts for the largest loss in six of the seven countries. Germany is the exception: its checkout-to-confirmation stage represents the largest drop-off.

Country-level figures at the later funnel stages are based on small session counts due to high segmentation of a small dataset and should be treated as directional signals rather than confirmed patterns.


### Benchmark Comparison
| Metric | This Analysis | Industry Benchmark | Source |
|---|---|---|---|
| Overall conversion rate | 3.63% | ~1.4%–3% | [Littledata / IRP Commerce / Dynamic Yield, 2026](https://propelcommerce.io/blog/average-ecommerce-conversion-rate-2026) |
| Cart-to-purchase abandonment | 75.63% | ~70.22% (range 55%–84% across 50 studies) | [Baymard Institute, 2026](https://baymard.com/lists/cart-abandonment-rate) |

The overall conversion rate (3.63%) sits slightly above the commonly cited industry range. <br>
Cart-to-purchase abandonment (75.63%) is above Baymard's cross-industry average of 70.22%, and well within the 55–84% range reported across the studies it aggregates.

## Recommendations

**1. Product Page: Where the Most Users Exit**

75.95% of users who reached a product page did not add anything to cart. This is the largest percentage loss in the funnel, which makes it the stage most worth testing first.

A/B test CTA placement, size, and copy; surface pricing, delivery costs, and return policy immediately and transparently; collect and add verified customer reviews, ideally with accompanying photos or video.

**2. Cart to Checkout: Remove Friction at Purchase Initiation**

58.06% of users who added an item to cart did not proceed to checkout. At this stage, users have already declared purchase intent by adding to cart, which suggests the barrier is more likely procedural than motivational.

Commonly cited drivers of cart abandonment at this stage include forced account creation, shipping costs revealed late in the process, and an unclear path to payment. 

These are worth testing here: eliminate guest-checkout barriers, surface all costs upfront, and add a progress indicator so users know how many steps remain.

**3. Checkout to Confirmation: Retain Highest-Intent Users**

41.88% of users who reached checkout did not complete their purchase. These are the highest-intent users in the funnel — they have selected a product, added it to cart, and initiated payment.

Audit for form field overload, payment method gaps, and any technical errors in the payment completion flow. Add security badges, a visible return policy, and clear confirmation of what happens after purchase.

**4. Mobile Experience: Address Systemic Drop-Off Across the Funnel**

Mobile records the highest drop-off rate at three of four funnel stage transitions, with the sharpest divergence at checkout-to-confirmation (57.14% vs ~37% average on other devices). That being said, it's also the stage transition based on a sample that is too small to be conclusive. Regardless, this is not a single friction point, it is a pattern across the entire funnel. 

Audit the mobile experience end-to-end: page load speed, touch target sizing, form field usability, and payment flow on smaller screens. Mobile-specific A/B testing is warranted given the scale of the gap.

**5. Germany: A Signal Worth Tracking**

Germany's checkout-to-confirmation drop-off (81.25%) is the highest in the dataset, but it's based on just 16 sessions, too small to draw conclusions from. Before investing in a Germany-specific fix, the priority here is to confirm the pattern holds on a larger sample.

## Skills

- **Excel**: data cleaning, pivot tables, aggregate functions
- **SQL**: views, aggregate functions, `CASE` statements, window functions (`LAG`, `PARTITION BY`), subqueries
- **Power BI**: data visualisation, dashboard design, funnel charts, bar charts with small multiples, KPI cards, conditional formatting, Power Query (data transformation, replace values, custom/calculated columns, column sort)
- **Analysis**: funnel and drop-off analysis, segmentation (device, country), benchmarking against external industry data

## Files

| File | Description |
|---|---|
| [`customer_journey.xlsx`](customer_journey.xlsx) | Raw data, cleaned data, cleaning log, and exploratory pivot table (4 sheets) |
| [`ecommerce_funnel_analysis.sql`](ecommerce_funnel_analysis.sql) | All SQL queries and views |
| [`ecommerce_funnel_dashboard.pbix`](ecommerce_funnel_dashboard.pbix) | Power BI dashboard |
