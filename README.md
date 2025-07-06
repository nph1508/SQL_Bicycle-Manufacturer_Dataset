# Exploring Sales & Product Performance in Bicycle Manufacturing | SQL
Author: Nguyễn Phương Huy

Date: 2000-15-08

Tools Used: SQL

---
## 📑 Table of Contents

1. [📌 Background & Overview](#-background--overview)  
2. [📂 Dataset Description & Data Structure](#-dataset-description--data-structure)  
3. [🔎 Final Conclusion & Recommendations](#-final-conclusion--recommendations)

---
## 📌 Background & Overview
🎯 Objective
This project aims to support decision-making for the sales and inventory management team at a fictional bicycle manufacturing company. We leverage SQL on BigQuery to uncover:

✔️ Product subcategory sales trends (volume, value, frequency)

✔️ Year-over-year growth by product line

✔️ Regional sales performance

✔️ Customer retention patterns

✔️ Inventory fluctuations and planning signals

All queries were executed using SQL with Common Table Expressions (CTEs), joins, aggregation, and analytic functions.
## 📂 Dataset Description & Data Structure

### 📌 Data Source

- **Source:** Google BigQuery Public Dataset `bigquery-public-data`  
- **Dataset:** Simulated bicycle sales and operations data (AdventureWorks-style)  
- **Format:** `.sql` (Queried directly in BigQuery)

### 📊 Data Structure & Relationships
**Key Tables Used:**
- `Sales.SalesOrderDetail`
- `Production.Product`
- `Production.ProductSubcategory`
- `Sales.SalesTerritory`
- `Sales.SalesOrderHeader`
- `Person.Person`
- `Person.Address`
- `Production.ProductInventory`

**Schema Highlights:**
- `SalesOrderDetail` links with `Product` → `ProductSubcategory`
- `SalesOrderHeader` links with customer and territory info
- `ProductInventory` provides stock levels over time

> 📌 All tables joined via foreign key relationships using `ProductID`, `SalesOrderID`, `CustomerID`, `TerritoryID`.

---
## ⚒️Main Process
### Query 01: Calc Quantity of items, Sales value & Order quantity by each Subcategory in L12M
**Purpose:** Calculates quantity sold, total sales, and number of orders by product subcategory over the last 12 months.  
**Goal:** Understand sales performance by product name to identify strong and weak performers.
```sql
select 
  format_date('%b %Y', sale.ModifiedDate) as period
  , pro.Name as name
  , sum(sale.OrderQty) as qty_item
  , sum(sale.LineTotal) as total_sale
  , count(distinct sale.SalesOrderID) as order_cnt
from `adventureworks2019.Sales.SalesOrderDetail` as sale
join `adventureworks2019.Production.Product` as pro
using (ProductID)
where date(sale.ModifiedDate) >=
(
    select date_sub(max(date(sale.ModifiedDate)), interval 12 month) 
    from `adventureworks2019.Sales.SalesOrderDetail`
)
group by period, pro.Name
order by period;
```
**✅ Results:** 
| month     | Name        | qty_item | total_sales    | order_cnt |
|-----------|-------------|----------|----------------|-----------|
| Apr 2014  | Bib-Shorts  | 4        | 233.974        | 1         |
| Feb 2014  | Bib-Shorts  | 4        | 233.974        | 2         |
| Jul 2013  | Bib-Shorts  | 2        | 116.987        | 1         |
| Jun 2013  | Bib-Shorts  | 2        | 116.987        | 1         |
| Apr 2014  | Bike Racks  | 45       | 5400.0         | 45        |
| Aug 2013  | Bike Racks  | 222      | 17387.183      | 63        |
| Dec 2013  | Bike Racks  | 162      | 12582.288      | 48        |
| Feb 2014  | Bike Racks  | 27       | 3240.0         | 27        |
| Jan 2014  | Bike Racks  | 161      | 12840.0        | 53        |
| Jul 2013  | Bike Racks  | 422      | 29802.3        | 75        |

**📝 Observation:** Bike Racks dominate sales volume, while Bib-Shorts show lower but consistent demand.
### Query 02: Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate. Can use metric: quantity_item. Round results to 2 decimal
**Purpose:** Calculates Year-over-Year growth rate in item quantity by subcategory and identifies top 3 subcategories with highest growth.  
**Goal:** Detect which subcategories are expanding fastest and deserve investment.
```sql
with 
sale_info as (
  select 
      format_timestamp("%Y", a.ModifiedDate) as year,
      c.Name,
      sum(a.OrderQty) as qty_item
  from `adventureworks2019.Sales.SalesOrderDetail` a 
  left join `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
  left join `adventureworks2019.Production.ProductSubcategory` c on cast(b.ProductSubcategoryID as int) = c.ProductSubcategoryID
  group by 1,2
),

sale_diff as (
  select *,
    lead(qty_item) over (partition by Name order by yr desc) as prv_qty,
    round(qty_item / lead(qty_item) over (partition by Name order by yr desc) - 1, 2) as qty_diff
  from sale_info
),

rk_qty_diff as (
  select *,
    dense_rank() over(order by qty_diff desc) as dk
  from sale_diff
)

select 
  Name
  , qty_item
  , prv_qty
  , qty_diff
from (
  select Name, qty_item, prv_qty, qty_diff, dk
  from rk_qty_diff
  where dk <= 3
)
order by dk;
```
**✅ Results:**
| Name            | qty_item | prv_qty | qty_diff |
| --------------- | -------- | ------- | -------- |
| Mountain Frames | 3168     | 510     | 5.21     |
| Socks           | 2724     | 523     | 4.21     |
| Road Frames     | 5564     | 1137    | 3.89     |

**📝 Observation:** Mountain Frames, Socks, and Road Frames exhibit explosive YoY growth (>300%), signaling high market demand.
### Query 3: Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number
**Purpose:** Ranks the top 3 sales territories each year by total order quantity using DENSE_RANK to handle ties.  
**Goal:** Monitor geographical sales performance and territory contribution over time.
```sql
with base_data as (
  select
    extract(year from SH.OrderDate) as year,
    SH.TerritoryID,
    sum(SD.OrderQty) as TotalQty
  from `adventureworks2019.Sales.SalesOrderDetail` as SD
  join `adventureworks2019.Sales.SalesOrderHeader` as SH
    on SD.SalesOrderID = SH.SalesOrderID
  group by year, SH.TerritoryID
),
ranked_data AS (
  select
    year,
    TerritoryID,
    TotalQty,
    dense_rank() over (partition by yr order by TotalQty desc) as rank
  from base_data
)
select 
  year,
  TerritoryID,
  TotalQty AS order_cnt,
  rank
from ranked_data
where rank <= 3
order by year, rank;
```
**✅ Results:**
| year | TerritoryID | order_cnt | rank |
| --- | --- | --- | --- |
| 2011 | 4 | 3238 | 1 |
| 2011 | 6 | 2705 | 2 |
| 2011 | 1 | 1964 | 3 |
| 2012 | 4 | 17553 | 1 |
| 2012 | 6 | 14412 | 2 |
| 2012 | 1 | 8537 | 3 |
| 2013 | 4 | 26682 | 1 |
| 2013 | 6 | 22553 | 2 |
| 2013 | 1 | 17452 | 3 |
| 2014 | 4 | 11632 | 1 |
| 2014 | 6 | 9711 | 2 |
| 2014 | 1 | 8823 | 3 |

**📝 Observation:** Territory 4 consistently ranks #1 annually, suggesting strong regional performance.
### Query 04: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory
**Purpose:** Calculates the total discount cost applied under "Seasonal Discount" for each subcategory and year.  
**Goal:** Measure promotional investment and its cost distribution across subcategories.
```sql
select 
    format_timestamp("%Y", ModifiedDate) as year
    , Name
    , sum(disc_cost) as total_cost
from (
      select distinct a.ModifiedDate 
      , c.Name
      , d.DiscountPct, d.Type
      , a.OrderQty * d.DiscountPct * UnitPrice as disc_cost 
      from `adventureworks2019.Sales.SalesOrderDetail` a
      left join `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
      left join `adventureworks2019.Production.ProductSubcategory` c on cast(b.ProductSubcategoryID as int) = c.ProductSubcategoryID
      left join `adventureworks2019.Sales.SpecialOffer` d on a.SpecialOfferID = d.SpecialOfferID
      where lower(d.Type) like '%seasonal discount%' 
)
group by 1,2;
```
**✅ Results:** 
| yearr | Name | total_cost |
| --- | --- | --- |
| 2012 | Helmets | 149.71669 |
| 2013 | Helmets | 543.21975 |

**📝 Observation:** Seasonal discounts for Helmets peaked in 2013, indicating targeted promotional efforts.
### Query 05: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis)
**Purpose:** Performs cohort analysis to track how many customers in each join-month return to make repeat purchases in later months.  
**Goal:** Analyze retention behavior of customers who had successfully shipped orders during 2014.
```sql
with info as(
  select
    extract(month from ModifiedDate) as mth_order,
    extract(year from ModifiedDate) as yr,
    CustomerID,
    count(distinct SalesOrderID) as sales_cnt
  from `adventureworks2019.Sales.SalesOrderHeader`
  where Status = 5 and extract(year FROM ModifiedDate) = 2014
  Group by 1,2,3   
),
row_num as(
  select 
    *,
    row_number() over (partition by CustomerID order by mth_order asc) as row_nb
  from info
),
first_order as(
  select
    distinct mth_order as mth_join,
    yr,
    CustomerID
  from row_num
  where row_nb=1
),
all_join as(
  select distinct 
    a.mth_order,
    a.yr,
    a.CustomerID,
    b.mth_join,
    concat('M - ', a.mth_order - b.mth_join) as mth_diff
  from info as a
  left join first_order as b 
    using(CustomerID)
  order by 3
)
SELECT
  distinct mth_join,
  mth_diff,
  count(distinct CustomerID) as customer_cnt
from all_join
group by 1,2
order by 1;
```
**✅ Results:**
| mth_join | mth_diff | customer_cnt |
| --- | --- | --- |
| 1 | M - 0 | 2076 |
| 1 | M - 1 | 78 |
| 1 | M - 2 | 89 |
| 1 | M - 3 | 252 |
| 1 | M - 4 | 96 |
| 1 | M - 5 | 61 |
| 1 | M - 6 | 18 |
| 2 | M - 0 | 1805 |
| 2 | M - 2 | 61 |
| 2 | M - 3 | 234 |

**📝 Observation:** Customer retention drops sharply after Month 0, highlighting challenges in repeat purchases.
### Query 06: Trend of Stock level & MoM diff % by all product in 2011. If %gr rate is null then 0. Round to 1 decimal
**Purpose:** Tracks stock quantity for all products monthly in 2011 and computes Month-over-Month % change.  
**Goal:** Identify inventory fluctuations and spot products with inconsistent stock trends (e.g., overstocking or stockouts).
```sql
with 
raw_data as (
  select
      extract(month from a.ModifiedDate) as month 
      , extract(year from a.ModifiedDate) as year 
      , b.Name
      , sum(StockedQty) as stock_qty

  from `adventureworks2019.Production.WorkOrder` a
  left join `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
  where format_timestamp("%Y", a.ModifiedDate) = '2011'
  group by 1,2,3
  order by 1 desc 
)

select  Name
      , month, year 
      , stock_qty
      , stock_prv    
      , round(coalesce((stock_qty /stock_prv -1)*100 ,0) ,1) as diff   
from (                                                               
      select *
      , lead (stock_qty) over (partition by Name order by mth desc) as stock_prv
      from raw_data
      )
order by 1 asc, 2 desc;
```
**✅ Results:**
| Name | month | year | stock_qty | stock_prv | diff |
| --- | --- | --- | --- | --- | --- |
| BB Ball Bearing | 12 | 2011 | 8475 | 14544 | -41.7 |
| BB Ball Bearing | 11 | 2011 | 14544 | 19175 | -24.2 |
| BB Ball Bearing | 10 | 2011 | 19175 | 8845 | 116.8 |
| Blade | 12 | 2011 | 1842 | 3598 | -48.8 |
| Blade | 11 | 2011 | 3598 | 4670 | -23 |
| Blade | 10 | 2011 | 4670 | 2122 | 120.1 |
| Chain Stays | 12 | 2011 | 1842 | 3598 | -48.8 |
| Chain Stays | 11 | 2011 | 3598 | 4670 | -23 |
| Chain Stays | 10 | 2011 | 4670 | 2122 | 120.1 |
| Down Tube | 12 | 2011 | 921 | 1799 | -48.8 |
| Down Tube | 11 | 2011 | 1799 | 2335 | -23 |
| Down Tube | 10 | 2011 | 2335 | 1061 | 120.1 |
| Fork Crown | 12 | 2011 | 921 | 1799 | -48.8 |
| Fork Crown | 11 | 2011 | 1799 | 2335 | -23 |
| Fork Crown | 10 | 2011 | 2335 | 1061 | 120.1 |
| Fork End | 12 | 2011 | 1842 | 3598 | -48.8 |
| Fork End | 11 | 2011 | 3598 | 4670 | -23 |
| Fork End | 10 | 2011 | 4670 | 2122 | 120.1 |

**📝 Observation:** Inventory fluctuates drastically (e.g., BB Ball Bearing: -41.7% in Dec), revealing unstable stock management.
### Query 07: "Calc Ratio of Stock / Sales in 2011 by product name, by month. Order results by month desc, ratio desc. Round Ratio to 1 decimal. mom yoy"
**Purpose:** Identifies product combinations that are frequently purchased together in the same order.
**Goal:** Support bundling strategies and cross-sell opportunities.
```sql
with 
sale_info as (
  select 
      extract(month from a.ModifiedDate) as month 
     , extract(year from a.ModifiedDate) as year 
     , a.ProductId
     , b.Name
     , sum(a.OrderQty) as sales
  from `adventureworks2019.Sales.SalesOrderDetail` a 
  left join `adventureworks2019.Production.Product` b 
    on a.ProductID = b.ProductID
  where format_timestamp("%Y", a.ModifiedDate) = '2011'
  group by 1,2,3,4
), 

stock_info as (
  select
      extract(month from ModifiedDate) as month 
      , extract(year from ModifiedDate) as year 
      , ProductId
      , sum(StockedQty) as stock_cnt
  from `adventureworks2019.Production.WorkOrder`
  where format_timestamp("%Y", ModifiedDate) = '2011'
  group by 1,2,3
)

select
      a.*
    , b.stock_cnt as stock  --(*)
    , round(coalesce(b.stock_cnt,0) / sales,2) as ratio
from sale_info a 
full join stock_info b 
  on a.ProductId = b.ProductId
and a.month = b.month 
and a.year = b.year
order by 1 desc, 7 desc;
```
**✅ Results:** 
| month | year | ProductId | Name | sales | stock | ratio |
| --- | --- | --- | --- | --- | --- | --- |
| 12 | 2011 | 745 | HL Mountain Frame - Black, 48 | 1 | 27 | 27 |
| 12 | 2011 | 743 | HL Mountain Frame - Black, 42 | 1 | 26 | 26 |
| 11 | 2011 | 761 | Road-650 Red, 62 | 1 | 56 | 56 |
| 11 | 2011 | 764 | Road-650 Red, 52 | 1 | 30 | 30 |
| 10 | 2011 | 723 | LL Road Frame - Black, 60 | 1 | 46 | 46 |
| 10 | 2011 | 744 | HL Mountain Frame - Black, 44 | 6 | 100 | 16.67 |
| 9 | 2011 | 763 | Road-650 Red, 48 | 1 | 41 | 41 |
| 9 | 2011 | 761 | Road-650 Red, 62 | 1 | 34 | 34 |
| 8 | 2011 | 744 | HL Mountain Frame - Black, 44 | 3 | 60 | 20 |
| 8 | 2011 | 727 | LL Road Frame - Red, 52 | 1 | 14 | 14 |
| 7 | 2011 | 733 | ML Road Frame - Red, 52 | 8 | 78 | 9.75 |
| 7 | 2011 | 743 | HL Mountain Frame - Black, 42 | 13 | 91 | 7 |
| 6 | 2011 | 762 | Road-650 Red, 44 | 2 | 44 | 22 |
| 6 | 2011 | 763 | Road-650 Red, 48 | 1 | 20 | 20 |
| 5 | 2011 | 745 | HL Mountain Frame - Black, 48 | 1 |  | 0 |
| 5 | 2011 | 714 | Long-Sleeve Logo Jersey, M | 16 |  | 0 |

**📝 Observation:** High stock-to-sales ratios (e.g., 56:1) suggest overstocking for specific products like Road-650 Red.
### "Query 08: No of order and value at Pending status in 2014
**Purpose:** Calculates total number of orders and their total value where the order status is "Pending" in the year 2014.
**Goal:** Quantify backlog impact on operations and potential unrealized revenue.
```sql
select 
    extract (year from ModifiedDate) as year
    , Status
    , count(distinct PurchaseOrderID) as order 
    , round(sum(TotalDue),2)  as value
from `adventureworks2019.Purchasing.PurchaseOrderHeader`
where Status = 1
and extract(year from ModifiedDate) = 2014
group by 1,2;
```
**✅ Results:**
| year | Status | order | value |
| --- | --- | --- | --- |
| 2014 | 1 | 224 | 3,873,579.01 |

**📝 Observation:** 224 pending orders (≈$3.87M) in 2014 point to potential fulfillment bottlenecks.

---
## 🔎 Final Conclusion & Recommendations

👉🏻 Based on the insights and findings above, we would recommend the **Sales & Inventory Management Team** to consider the following:

### 📌 Key Takeaways:

✔️ **Invest in high-growth subcategories** like Mountain Frames and Socks, which show strong YoY demand expansion.  
✔️ **Focus territory-specific campaigns** in consistently top-performing regions (Territory 4, 6, 1) to sustain sales dominance.  
✔️ **Improve inventory planning** by closely monitoring stock volatility and aligning supply with historical monthly patterns to reduce stockouts and overstocking.
