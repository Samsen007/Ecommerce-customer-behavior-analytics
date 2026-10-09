# E-Commerce Customer Behavior & Conversion Intelligence

## Project Overview

An end-to-end data analytics project analyzing real-world e-commerce behavioral data to understand customer engagement, purchase behavior, cart outcomes, and conversion opportunities.

The project uses DuckDB and SQL for large-scale data processing, Python for exploratory data analysis and visualization, and Power BI for interactive business intelligence reporting.

## Business Problem

E-commerce businesses need to understand how customers interact with their platforms, which behaviors are associated with purchasing, and where potential conversion opportunities exist.

This project investigates:

- How purchasing and non-purchasing customers differ in engagement.
- How customers can be segmented based on observed behavior.
- What happens after a product is added to a cart.
- How quickly purchases follow cart additions.
- Which products and categories have relatively strong or weak purchase follow-up.

## Dataset

The project uses the Synerise RecSys Challenge e-commerce dataset.

- **Observation period:** June–December 2022
- **Behavioral events:** Approximately 225.2 million
- **Product records:** Approximately 1.53 million
- **Event types:** Page visits, search queries, cart additions, cart removals, and purchases.

The dataset contains event timestamps, client identifiers, product identifiers and product attributes.

## Technology Stack

- **SQL:** DuckDB for data extraction, transformation, aggregation and analytical modeling.
- **Python:** Pandas, NumPy and Matplotlib for exploratory analysis and visualizations.
- **Power BI:** Interactive dashboards, KPI cards and customer behavior reporting.
- **Data formats:** Parquet and CSV.

## Project Workflow

1. Inspected Parquet schemas, row counts, date ranges and missing values.
2. Created analytical customer and product behavior tables using DuckDB.
3. Investigated duplicate event records without blindly deleting potentially meaningful events.
4. Developed rule-based customer segments using engagement, purchase activity and recency.
5. Analyzed cart outcomes within a 24-hour observation window.
6. Examined purchase timing after cart additions.
7. Performed Python exploratory data analysis and generated charts.
8. Exported aggregate datasets for Power BI.
9. Developed dashboards for executive reporting and customer intelligence.

## Key Findings

### Customer Engagement

Purchasers exhibited higher average engagement than non-purchasers:

- Average page visits: 54.86 versus 6.99.
- Average searches: 5.90 versus 0.37.
- Average cart additions: 3.97 versus 0.18.

These are observed associations and do not establish that engagement alone causes purchases.

### Customer Segmentation

The analysis identified several behavioral groups, including:

- High-Engagement Purchasers
- Repeat Buyers
- At-Risk Purchasers
- Cart-Heavy Non-Purchasers
- Search-Heavy Non-Purchasers
- Recently Active Non-Purchasers
- Low-Engagement Non-Purchasers

The segmentation helps identify customer groups that may benefit from different engagement, conversion or retention strategies.

### Cart Outcome Analysis

Within the 24-hour cart-event analysis:

- 57.61% had no recorded follow-up outcome.
- 26.95% were followed by a cart removal.
- 15.44% were followed by a purchase.

These percentages describe cart-add events, not unique orders or unique customers.

### Purchase Timing

Among cart-add events classified as followed by a purchase within 24 hours, approximately 51.5% had a recorded purchase within five minutes. The median observed time to purchase was approximately 4.75 minutes.

### Product and Category Analysis

Product-level and category-level analyses were used to identify differences in cart activity, purchase activity and observed purchase follow-up. Products with substantial cart activity but no recorded purchases were flagged for further investigation.

## Business Recommendations

- Investigate checkout friction and other potential barriers affecting cart-heavy non-purchasers.
- Evaluate search relevance and product discovery for search-heavy non-purchasers.
- Develop engagement and retention strategies for previously purchasing customers with long periods since their last recorded activity.
- Review high-cart, low-purchase products and categories for possible product, availability, pricing or customer-experience issues.
- Monitor conversion metrics using clearly defined observation windows and event-level denominators.

These recommendations are hypotheses for further business investigation rather than proven explanations of customer behavior.

## Power BI Dashboards

Page 1 — Executive Overview

Summarizes customer counts, purchaser counts, customer segments, 24-hour cart outcomes, and observed purchase timing.

Executive Overview

Page 2 — Customer Intelligence

Explores customer recency, behavioral segments, and engagement differences between purchasers and non-purchasers.

Customer Intelligence

## Limitations

- The behavioral observation period is June–December 2022, not the current period.
- Customer and product identifiers are numeric, and category identifiers are encoded.
- Exact duplicate event records exist; raw events were not automatically deduplicated.
- The 24-hour cart analysis is event-level, and repeated cart additions may be associated with the same purchase event.
- The product price field ranges from 0 to 99; its meaning was not established as a currency amount, so revenue was not inferred from it.
- Historical recency segments should not be interpreted as current customer activity.

## Project Outcome

This project demonstrates practical skills in SQL-based analytics, large-scale data processing, behavioral segmentation, exploratory data analysis, KPI development, data visualization and business-oriented interpretation.

## Skills Demonstrated

SQL | DuckDB | Python | Pandas | NumPy | Matplotlib | Power BI | Data Cleaning | Exploratory Data Analysis | Customer Segmentation | Conversion Analysis | Data Visualization | Business Intelligence
