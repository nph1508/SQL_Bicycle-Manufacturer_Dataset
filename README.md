# SQL_Bicycle-Manufacturer_Dataset
## DATASET

## Query 01: 

```sql

```
### ✅ Results:


**📝 Observation:** 
## Query 02: 
```sql
with 
sale_info as (
  SELECT 
      FORMAT_TIMESTAMP("%Y", a.ModifiedDate) as yr,
      c.Name,
      sum(a.OrderQty) as qty_item
  FROM `adventureworks2019.Sales.SalesOrderDetail` a 
  LEFT JOIN `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
  LEFT JOIN `adventureworks2019.Production.ProductSubcategory` c on cast(b.ProductSubcategoryID as int) = c.ProductSubcategoryID
  GROUP BY 1,2
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
### ✅ Results:
| Name            | qty_item | prv_qty | qty_diff |
| --------------- | -------- | ------- | -------- |
| Mountain Frames | 3168     | 510     | 5.21     |
| Socks           | 2724     | 523     | 4.21     |
| Road Frames     | 5564     | 1137    | 3.89     |

**📝 Observation:** 
## Query 3: 
```sql
WITH base_data AS (
  SELECT
    EXTRACT(YEAR FROM SH.OrderDate) AS yr,
    SH.TerritoryID,
    SUM(SD.OrderQty) AS TotalQty
  FROM `adventureworks2019.Sales.SalesOrderDetail` AS SD
  JOIN `adventureworks2019.Sales.SalesOrderHeader` AS SH
    ON SD.SalesOrderID = SH.SalesOrderID
  GROUP BY yr, SH.TerritoryID
),
ranked_data AS (
  SELECT
    yr,
    TerritoryID,
    TotalQty,
    DENSE_RANK() OVER (PARTITION BY yr ORDER BY TotalQty DESC) AS rk
  FROM base_data
)
SELECT 
  yr,
  TerritoryID,
  TotalQty AS order_cnt,
  rk
FROM ranked_data
WHERE rk <= 3
ORDER BY yr, rk;
```
### ✅ Results:
| yr | TerritoryID | order_cnt | rk |
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

**📝 Observation:** 
## Query 04: 
```sql
select 
    FORMAT_TIMESTAMP("%Y", ModifiedDate)
    , Name
    , sum(disc_cost) as total_cost
from (
      select distinct a.ModifiedDate
      , c.Name
      , d.DiscountPct, d.Type
      , a.OrderQty * d.DiscountPct * UnitPrice as disc_cost 
      from `adventureworks2019.Sales.SalesOrderDetail` a
      LEFT JOIN `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
      LEFT JOIN `adventureworks2019.Production.ProductSubcategory` c on cast(b.ProductSubcategoryID as int) = c.ProductSubcategoryID
      LEFT JOIN `adventureworks2019.Sales.SpecialOffer` d on a.SpecialOfferID = d.SpecialOfferID
      WHERE lower(d.Type) like '%seasonal discount%' 
)
group by 1,2;
```
### ✅ Results:
| f0_ | Name | total_cost |
| --- | --- | --- |
| 2012 | Helmets | 149.71669 |
| 2013 | Helmets | 543.21975 |

**📝 Observation:** 
## Query 05: 
```sql
with info as(
  select
    extract(month from ModifiedDate) AS mth_order,
    extract(year from ModifiedDate) AS yr,
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
### ✅ Results:
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
| 2 | M - 4 | 58 |
| 2 | M - 1 | 51 |
| 2 | M - 5 | 8 |
| 3 | M - 0 | 1918 |
| 3 | M - 1 | 43 |
| 3 | M - 2 | 58 |
| 3 | M - 3 | 44 |
| 3 | M - 4 | 11 |
| 4 | M - 0 | 1906 |
| 4 | M - 1 | 34 |
| 4 | M - 2 | 44 |
| 4 | M - 3 | 7 |
| 5 | M - 0 | 1947 |
| 5 | M - 1 | 40 |
| 5 | M - 2 | 7 |
| 6 | M - 0 | 909 |
| 6 | M - 1 | 10 |
| 7 | M - 0 | 148 |

**📝 Observation:** 
## Query 06: 
```sql
with 
raw_data as (
  select
      extract(month from a.ModifiedDate) as mth 
      , extract(year from a.ModifiedDate) as yr 
      , b.Name
      , sum(StockedQty) as stock_qty

  from `adventureworks2019.Production.WorkOrder` a
  left join `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
  where FORMAT_TIMESTAMP("%Y", a.ModifiedDate) = '2011'
  group by 1,2,3
  order by 1 desc 
)

select  Name
      , mth, yr 
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
### ✅ Results:
| Name | mth | yr | stock_qty | stock_prv | diff |
| --- | --- | --- | --- | --- | --- |
| BB Ball Bearing | 12 | 2011 | 8475 | 14544 | -41.7 |
| BB Ball Bearing | 11 | 2011 | 14544 | 19175 | -24.2 |
| BB Ball Bearing | 10 | 2011 | 19175 | 8845 | 116.8 |
| BB Ball Bearing | 9 | 2011 | 8845 | 9666 | -8.5 |
| BB Ball Bearing | 8 | 2011 | 9666 | 12837 | -24.7 |
| BB Ball Bearing | 7 | 2011 | 12837 | 5259 | 144.1 |
| BB Ball Bearing | 6 | 2011 | 5259 |  | 0 |
| Blade | 12 | 2011 | 1842 | 3598 | -48.8 |
| Blade | 11 | 2011 | 3598 | 4670 | -23 |
| Blade | 10 | 2011 | 4670 | 2122 | 120.1 |
| Blade | 9 | 2011 | 2122 | 2382 | -10.9 |
| Blade | 8 | 2011 | 2382 | 3166 | -24.8 |
| Blade | 7 | 2011 | 3166 | 1280 | 147.3 |
| Blade | 6 | 2011 | 1280 |  | 0 |
| Chain Stays | 12 | 2011 | 1842 | 3598 | -48.8 |
| Chain Stays | 11 | 2011 | 3598 | 4670 | -23 |
| Chain Stays | 10 | 2011 | 4670 | 2122 | 120.1 |
| Chain Stays | 9 | 2011 | 2122 | 2341 | -9.4 |
| Chain Stays | 8 | 2011 | 2341 | 3166 | -26.1 |
| Chain Stays | 7 | 2011 | 3166 | 1280 | 147.3 |
| Chain Stays | 6 | 2011 | 1280 |  | 0 |
| Down Tube | 12 | 2011 | 921 | 1799 | -48.8 |
| Down Tube | 11 | 2011 | 1799 | 2335 | -23 |
| Down Tube | 10 | 2011 | 2335 | 1061 | 120.1 |
| Down Tube | 9 | 2011 | 1061 | 1191 | -10.9 |
| Down Tube | 8 | 2011 | 1191 | 1541 | -22.7 |
| Down Tube | 7 | 2011 | 1541 | 640 | 140.8 |
| Down Tube | 6 | 2011 | 640 |  | 0 |
| Fork Crown | 12 | 2011 | 921 | 1799 | -48.8 |
| Fork Crown | 11 | 2011 | 1799 | 2335 | -23 |
| Fork Crown | 10 | 2011 | 2335 | 1061 | 120.1 |
| Fork Crown | 9 | 2011 | 1061 | 1191 | -10.9 |
| Fork Crown | 8 | 2011 | 1191 | 1583 | -24.8 |
| Fork Crown | 7 | 2011 | 1583 | 640 | 147.3 |
| Fork Crown | 6 | 2011 | 640 |  | 0 |
| Fork End | 12 | 2011 | 1842 | 3598 | -48.8 |
| Fork End | 11 | 2011 | 3598 | 4670 | -23 |
| Fork End | 10 | 2011 | 4670 | 2122 | 120.1 |
| Fork End | 9 | 2011 | 2122 | 2382 | -10.9 |
| Fork End | 8 | 2011 | 2382 | 3166 | -24.8 |
| Fork End | 7 | 2011 | 3166 | 1280 | 147.3 |
| Fork End | 6 | 2011 | 1280 |  | 0 |
| Front Derailleur | 12 | 2011 | 861 | 1440 | -40.2 |
| Front Derailleur | 11 | 2011 | 1440 | 1918 | -24.9 |
| Front Derailleur | 10 | 2011 | 1918 | 874 | 119.5 |
| Front Derailleur | 9 | 2011 | 874 | 969 | -9.8 |
| Front Derailleur | 8 | 2011 | 969 | 1257 | -22.9 |
| Front Derailleur | 7 | 2011 | 1257 | 501 | 150.9 |
| Front Derailleur | 6 | 2011 | 501 |  | 0 |
| HL Bottom Bracket | 12 | 2011 | 426 | 719 | -40.8 |
| HL Bottom Bracket | 11 | 2011 | 719 | 938 | -23.3 |
| HL Bottom Bracket | 10 | 2011 | 938 | 395 | 137.5 |
| HL Bottom Bracket | 9 | 2011 | 395 | 534 | -26 |
| HL Bottom Bracket | 8 | 2011 | 534 | 670 | -20.3 |
| HL Bottom Bracket | 7 | 2011 | 670 | 176 | 280.7 |
| HL Bottom Bracket | 6 | 2011 | 176 |  | 0 |
| HL Crankset | 12 | 2011 | 426 | 719 | -40.8 |
| HL Crankset | 11 | 2011 | 719 | 938 | -23.3 |
| HL Crankset | 10 | 2011 | 938 | 395 | 137.5 |
| HL Crankset | 9 | 2011 | 395 | 548 | -27.9 |
| HL Crankset | 8 | 2011 | 548 | 670 | -18.2 |
| HL Crankset | 7 | 2011 | 670 | 176 | 280.7 |
| HL Crankset | 6 | 2011 | 176 |  | 0 |
| HL Fork | 12 | 2011 | 441 | 856 | -48.5 |
| HL Fork | 11 | 2011 | 856 | 1064 | -19.5 |
| HL Fork | 10 | 2011 | 1064 | 441 | 141.3 |
| HL Fork | 9 | 2011 | 441 | 650 | -32.2 |
| HL Fork | 8 | 2011 | 650 | 753 | -13.7 |
| HL Fork | 7 | 2011 | 753 | 189 | 298.4 |
| HL Fork | 6 | 2011 | 189 |  | 0 |
| HL Headset | 12 | 2011 | 426 | 719 | -40.8 |
| HL Headset | 11 | 2011 | 719 | 938 | -23.3 |
| HL Headset | 10 | 2011 | 938 | 395 | 137.5 |
| HL Headset | 9 | 2011 | 395 | 548 | -27.9 |
| HL Headset | 8 | 2011 | 548 | 670 | -18.2 |
| HL Headset | 7 | 2011 | 670 | 176 | 280.7 |
| HL Headset | 6 | 2011 | 176 |  | 0 |
| HL Hub | 12 | 2011 | 1044 | 1886 | -44.6 |
| HL Hub | 11 | 2011 | 1886 | 2454 | -23.1 |
| HL Hub | 10 | 2011 | 2454 | 1032 | 137.8 |
| HL Hub | 9 | 2011 | 1032 | 1346 | -23.3 |
| HL Hub | 8 | 2011 | 1346 | 1648 | -18.3 |
| HL Hub | 7 | 2011 | 1648 | 594 | 177.4 |
| HL Hub | 6 | 2011 | 594 |  | 0 |
| HL Mountain Frame - Black, 38 | 12 | 2011 | 31 | 90 | -65.6 |
| HL Mountain Frame - Black, 38 | 11 | 2011 | 90 | 94 | -4.3 |
| HL Mountain Frame - Black, 38 | 10 | 2011 | 94 | 34 | 176.5 |
| HL Mountain Frame - Black, 38 | 9 | 2011 | 34 | 69 | -50.7 |
| HL Mountain Frame - Black, 38 | 8 | 2011 | 69 | 85 | -18.8 |
| HL Mountain Frame - Black, 38 | 7 | 2011 | 85 | 26 | 226.9 |
| HL Mountain Frame - Black, 38 | 6 | 2011 | 26 |  | 0 |
| HL Mountain Frame - Black, 42 | 12 | 2011 | 26 | 90 | -71.1 |
| HL Mountain Frame - Black, 42 | 11 | 2011 | 90 | 96 | -6.3 |
| HL Mountain Frame - Black, 42 | 10 | 2011 | 96 | 40 | 140 |
| HL Mountain Frame - Black, 42 | 9 | 2011 | 40 | 64 | -37.5 |
| HL Mountain Frame - Black, 42 | 8 | 2011 | 64 | 91 | -29.7 |
| HL Mountain Frame - Black, 42 | 7 | 2011 | 91 | 17 | 435.3 |
| HL Mountain Frame - Black, 42 | 6 | 2011 | 17 |  | 0 |
| HL Mountain Frame - Black, 44 | 12 | 2011 | 29 | 72 | -59.7 |
| HL Mountain Frame - Black, 44 | 11 | 2011 | 72 | 100 | -28 |
| HL Mountain Frame - Black, 44 | 10 | 2011 | 100 | 28 | 257.1 |
| HL Mountain Frame - Black, 44 | 9 | 2011 | 28 | 60 | -53.3 |
| HL Mountain Frame - Black, 44 | 8 | 2011 | 60 | 64 | -6.3 |
| HL Mountain Frame - Black, 44 | 7 | 2011 | 64 | 26 | 146.2 |
| HL Mountain Frame - Black, 44 | 6 | 2011 | 26 |  | 0 |
| HL Mountain Frame - Black, 48 | 12 | 2011 | 27 | 76 | -64.5 |
| HL Mountain Frame - Black, 48 | 11 | 2011 | 76 | 96 | -20.8 |
| HL Mountain Frame - Black, 48 | 10 | 2011 | 96 | 26 | 269.2 |
| HL Mountain Frame - Black, 48 | 9 | 2011 | 26 | 61 | -57.4 |
| HL Mountain Frame - Black, 48 | 8 | 2011 | 61 | 83 | -26.5 |
| HL Mountain Frame - Black, 48 | 7 | 2011 | 83 | 22 | 277.3 |
| HL Mountain Frame - Black, 48 | 6 | 2011 | 22 |  | 0 |
| HL Mountain Frame - Silver, 38 | 12 | 2011 | 32 | 77 | -58.4 |
| HL Mountain Frame - Silver, 38 | 11 | 2011 | 77 | 112 | -31.3 |
| HL Mountain Frame - Silver, 38 | 10 | 2011 | 112 | 33 | 239.4 |
| HL Mountain Frame - Silver, 38 | 9 | 2011 | 33 | 73 | -54.8 |
| HL Mountain Frame - Silver, 38 | 8 | 2011 | 73 | 96 | -24 |
| HL Mountain Frame - Silver, 38 | 7 | 2011 | 96 | 13 | 638.5 |
| HL Mountain Frame - Silver, 38 | 6 | 2011 | 13 |  | 0 |
| HL Mountain Frame - Silver, 42 | 12 | 2011 | 16 | 52 | -69.2 |
| HL Mountain Frame - Silver, 42 | 11 | 2011 | 52 | 97 | -46.4 |
| HL Mountain Frame - Silver, 42 | 10 | 2011 | 97 | 29 | 234.5 |
| HL Mountain Frame - Silver, 42 | 9 | 2011 | 29 | 49 | -40.8 |
| HL Mountain Frame - Silver, 42 | 8 | 2011 | 49 | 59 | -16.9 |
| HL Mountain Frame - Silver, 42 | 7 | 2011 | 59 | 5 | 1,080 |
| HL Mountain Frame - Silver, 42 | 6 | 2011 | 5 |  | 0 |
| HL Mountain Frame - Silver, 44 | 12 | 2011 | 33 | 65 | -49.2 |
| HL Mountain Frame - Silver, 44 | 11 | 2011 | 65 | 71 | -8.5 |
| HL Mountain Frame - Silver, 44 | 10 | 2011 | 71 | 24 | 195.8 |
| HL Mountain Frame - Silver, 44 | 9 | 2011 | 24 | 50 | -52 |
| HL Mountain Frame - Silver, 44 | 8 | 2011 | 50 | 59 | -15.3 |
| HL Mountain Frame - Silver, 44 | 7 | 2011 | 59 | 21 | 181 |
| HL Mountain Frame - Silver, 44 | 6 | 2011 | 21 |  | 0 |
| HL Mountain Frame - Silver, 46 | 12 | 2011 | 3 | 15 | -80 |
| HL Mountain Frame - Silver, 46 | 11 | 2011 | 15 | 17 | -11.8 |
| HL Mountain Frame - Silver, 46 | 10 | 2011 | 17 | 3 | 466.7 |
| HL Mountain Frame - Silver, 46 | 9 | 2011 | 3 | 18 | -83.3 |
| HL Mountain Frame - Silver, 46 | 8 | 2011 | 18 | 15 | 20 |
| HL Mountain Frame - Silver, 46 | 7 | 2011 | 15 | 3 | 400 |
| HL Mountain Frame - Silver, 46 | 6 | 2011 | 3 |  | 0 |
| HL Mountain Frame - Silver, 48 | 12 | 2011 | 27 | 78 | -65.4 |
| HL Mountain Frame - Silver, 48 | 11 | 2011 | 78 | 90 | -13.3 |
| HL Mountain Frame - Silver, 48 | 10 | 2011 | 90 | 30 | 200 |
| HL Mountain Frame - Silver, 48 | 9 | 2011 | 30 | 57 | -47.4 |
| HL Mountain Frame - Silver, 48 | 8 | 2011 | 57 | 58 | -1.7 |
| HL Mountain Frame - Silver, 48 | 7 | 2011 | 58 | 10 | 480 |
| HL Mountain Frame - Silver, 48 | 6 | 2011 | 10 |  | 0 |
| HL Mountain Front Wheel | 12 | 2011 | 209 | 483 | -56.7 |
| HL Mountain Front Wheel | 11 | 2011 | 483 | 659 | -26.7 |
| HL Mountain Front Wheel | 10 | 2011 | 659 | 208 | 216.8 |
| HL Mountain Front Wheel | 9 | 2011 | 208 | 396 | -47.5 |
| HL Mountain Front Wheel | 8 | 2011 | 396 | 520 | -23.8 |
| HL Mountain Front Wheel | 7 | 2011 | 520 | 124 | 319.4 |
| HL Mountain Front Wheel | 6 | 2011 | 124 |  | 0 |
| HL Mountain Handlebars | 12 | 2011 | 204 | 483 | -57.8 |
| HL Mountain Handlebars | 11 | 2011 | 483 | 659 | -26.7 |
| HL Mountain Handlebars | 10 | 2011 | 659 | 203 | 224.6 |
| HL Mountain Handlebars | 9 | 2011 | 203 | 396 | -48.7 |
| HL Mountain Handlebars | 8 | 2011 | 396 | 520 | -23.8 |
| HL Mountain Handlebars | 7 | 2011 | 520 | 121 | 329.8 |
| HL Mountain Handlebars | 6 | 2011 | 121 |  | 0 |
| HL Mountain Rear Wheel | 12 | 2011 | 209 | 483 | -56.7 |
| HL Mountain Rear Wheel | 11 | 2011 | 483 | 659 | -26.7 |
| HL Mountain Rear Wheel | 10 | 2011 | 659 | 208 | 216.8 |
| HL Mountain Rear Wheel | 9 | 2011 | 208 | 396 | -47.5 |
| HL Mountain Rear Wheel | 8 | 2011 | 396 | 520 | -23.8 |
| HL Mountain Rear Wheel | 7 | 2011 | 520 | 124 | 319.4 |
| HL Mountain Rear Wheel | 6 | 2011 | 124 |  | 0 |
| HL Mountain Seat Assembly | 12 | 2011 | 204 | 483 | -57.8 |
| HL Mountain Seat Assembly | 11 | 2011 | 483 | 659 | -26.7 |
| HL Mountain Seat Assembly | 10 | 2011 | 659 | 202 | 226.2 |
| HL Mountain Seat Assembly | 9 | 2011 | 202 | 396 | -49 |
| HL Mountain Seat Assembly | 8 | 2011 | 396 | 520 | -23.8 |
| HL Mountain Seat Assembly | 7 | 2011 | 520 | 124 | 319.4 |
| HL Mountain Seat Assembly | 6 | 2011 | 124 |  | 0 |
| HL Road Frame - Red, 44 | 12 | 2011 | 33 | 53 | -37.7 |
| HL Road Frame - Red, 44 | 11 | 2011 | 53 | 41 | 29.3 |
| HL Road Frame - Red, 44 | 10 | 2011 | 41 | 42 | -2.4 |
| HL Road Frame - Red, 44 | 9 | 2011 | 42 | 19 | 121.1 |
| HL Road Frame - Red, 44 | 8 | 2011 | 19 | 18 | 5.6 |
| HL Road Frame - Red, 44 | 7 | 2011 | 18 | 14 | 28.6 |
| HL Road Frame - Red, 44 | 6 | 2011 | 14 |  | 0 |
| HL Road Frame - Red, 48 | 12 | 2011 | 41 | 47 | -12.8 |
| HL Road Frame - Red, 48 | 11 | 2011 | 47 | 45 | 4.4 |
| HL Road Frame - Red, 48 | 10 | 2011 | 45 | 36 | 25 |
| HL Road Frame - Red, 48 | 9 | 2011 | 36 | 18 | 100 |
| HL Road Frame - Red, 48 | 8 | 2011 | 18 | 32 | -43.8 |
| HL Road Frame - Red, 48 | 7 | 2011 | 32 | 10 | 220 |
| HL Road Frame - Red, 48 | 6 | 2011 | 10 |  | 0 |
| HL Road Frame - Red, 52 | 12 | 2011 | 33 | 43 | -23.3 |
| HL Road Frame - Red, 52 | 11 | 2011 | 43 | 54 | -20.4 |
| HL Road Frame - Red, 52 | 10 | 2011 | 54 | 28 | 92.9 |
| HL Road Frame - Red, 52 | 9 | 2011 | 28 | 26 | 7.7 |
| HL Road Frame - Red, 52 | 8 | 2011 | 26 | 15 | 73.3 |
| HL Road Frame - Red, 52 | 7 | 2011 | 15 | 7 | 114.3 |
| HL Road Frame - Red, 52 | 6 | 2011 | 7 |  | 0 |
| HL Road Frame - Red, 56 | 12 | 2011 | 44 | 56 | -21.4 |
| HL Road Frame - Red, 56 | 11 | 2011 | 56 | 78 | -28.2 |
| HL Road Frame - Red, 56 | 10 | 2011 | 78 | 44 | 77.3 |
| HL Road Frame - Red, 56 | 9 | 2011 | 44 | 44 | 0 |
| HL Road Frame - Red, 56 | 8 | 2011 | 44 | 57 | -22.8 |
| HL Road Frame - Red, 56 | 7 | 2011 | 57 | 23 | 147.8 |
| HL Road Frame - Red, 56 | 6 | 2011 | 23 |  | 0 |
| HL Road Frame - Red, 62 | 12 | 2011 | 51 | 59 | -13.6 |
| HL Road Frame - Red, 62 | 11 | 2011 | 59 | 66 | -10.6 |
| HL Road Frame - Red, 62 | 10 | 2011 | 66 | 55 | 20 |
| HL Road Frame - Red, 62 | 9 | 2011 | 55 | 42 | 31 |
| HL Road Frame - Red, 62 | 8 | 2011 | 42 | 34 | 23.5 |
| HL Road Frame - Red, 62 | 7 | 2011 | 34 | 15 | 126.7 |
| HL Road Frame - Red, 62 | 6 | 2011 | 15 |  | 0 |
| HL Road Front Wheel | 12 | 2011 | 217 | 236 | -8.1 |
| HL Road Front Wheel | 11 | 2011 | 236 | 279 | -15.4 |
| HL Road Front Wheel | 10 | 2011 | 279 | 187 | 49.2 |
| HL Road Front Wheel | 9 | 2011 | 187 | 152 | 23 |
| HL Road Front Wheel | 8 | 2011 | 152 | 150 | 1.3 |
| HL Road Front Wheel | 7 | 2011 | 150 | 52 | 188.5 |
| HL Road Front Wheel | 6 | 2011 | 52 |  | 0 |
| HL Road Handlebars | 12 | 2011 | 217 | 236 | -8.1 |
| HL Road Handlebars | 11 | 2011 | 236 | 279 | -15.4 |
| HL Road Handlebars | 10 | 2011 | 279 | 187 | 49.2 |
| HL Road Handlebars | 9 | 2011 | 187 | 152 | 23 |
| HL Road Handlebars | 8 | 2011 | 152 | 150 | 1.3 |
| HL Road Handlebars | 7 | 2011 | 150 | 52 | 188.5 |
| HL Road Handlebars | 6 | 2011 | 52 |  | 0 |
| HL Road Rear Wheel | 12 | 2011 | 217 | 236 | -8.1 |
| HL Road Rear Wheel | 11 | 2011 | 236 | 276 | -14.5 |
| HL Road Rear Wheel | 10 | 2011 | 276 | 187 | 47.6 |
| HL Road Rear Wheel | 9 | 2011 | 187 | 152 | 23 |
| HL Road Rear Wheel | 8 | 2011 | 152 | 150 | 1.3 |
| HL Road Rear Wheel | 7 | 2011 | 150 | 52 | 188.5 |
| HL Road Rear Wheel | 6 | 2011 | 52 |  | 0 |
| HL Road Seat Assembly | 12 | 2011 | 217 | 236 | -8.1 |
| HL Road Seat Assembly | 11 | 2011 | 236 | 279 | -15.4 |
| HL Road Seat Assembly | 10 | 2011 | 279 | 187 | 49.2 |
| HL Road Seat Assembly | 9 | 2011 | 187 | 152 | 23 |
| HL Road Seat Assembly | 8 | 2011 | 152 | 150 | 1.3 |
| HL Road Seat Assembly | 7 | 2011 | 150 | 52 | 188.5 |
| HL Road Seat Assembly | 6 | 2011 | 52 |  | 0 |
| Handlebar Tube | 12 | 2011 | 848 | 1455 | -41.7 |
| Handlebar Tube | 11 | 2011 | 1455 | 1918 | -24.1 |
| Handlebar Tube | 10 | 2011 | 1918 | 885 | 116.7 |
| Handlebar Tube | 9 | 2011 | 885 | 967 | -8.5 |
| Handlebar Tube | 8 | 2011 | 967 | 1284 | -24.7 |
| Handlebar Tube | 7 | 2011 | 1284 | 526 | 144.1 |
| Handlebar Tube | 6 | 2011 | 526 |  | 0 |
| Head Tube | 12 | 2011 | 921 | 1799 | -48.8 |
| Head Tube | 11 | 2011 | 1799 | 2335 | -23 |
| Head Tube | 10 | 2011 | 2335 | 1061 | 120.1 |
| Head Tube | 9 | 2011 | 1061 | 1165 | -8.9 |
| Head Tube | 8 | 2011 | 1165 | 1583 | -26.4 |
| Head Tube | 7 | 2011 | 1583 | 640 | 147.3 |
| Head Tube | 6 | 2011 | 640 |  | 0 |
| LL Bottom Bracket | 12 | 2011 | 316 | 514 | -38.5 |
| LL Bottom Bracket | 11 | 2011 | 514 | 689 | -25.4 |
| LL Bottom Bracket | 10 | 2011 | 689 | 362 | 90.3 |
| LL Bottom Bracket | 9 | 2011 | 362 | 293 | 23.5 |
| LL Bottom Bracket | 8 | 2011 | 293 | 439 | -33.3 |
| LL Bottom Bracket | 7 | 2011 | 439 | 223 | 96.9 |
| LL Bottom Bracket | 6 | 2011 | 223 |  | 0 |
| LL Fork | 12 | 2011 | 370 | 679 | -45.5 |
| LL Fork | 11 | 2011 | 679 | 926 | -26.7 |
| LL Fork | 10 | 2011 | 926 | 479 | 93.3 |
| LL Fork | 9 | 2011 | 479 | 383 | 25.1 |
| LL Fork | 8 | 2011 | 383 | 609 | -37.1 |
| LL Fork | 7 | 2011 | 609 | 308 | 97.7 |
| LL Fork | 6 | 2011 | 308 |  | 0 |
| LL Hub | 12 | 2011 | 652 | 1024 | -36.3 |
| LL Hub | 11 | 2011 | 1024 | 1382 | -25.9 |
| LL Hub | 10 | 2011 | 1382 | 738 | 87.3 |
| LL Hub | 9 | 2011 | 738 | 588 | 25.5 |
| LL Hub | 8 | 2011 | 588 | 878 | -33 |
| LL Hub | 7 | 2011 | 878 | 458 | 91.7 |
| LL Hub | 6 | 2011 | 458 |  | 0 |
| LL Road Frame - Black, 44 | 12 | 2011 | 21 | 33 | -36.4 |
| LL Road Frame - Black, 44 | 11 | 2011 | 33 | 45 | -26.7 |
| LL Road Frame - Black, 44 | 10 | 2011 | 45 | 30 | 50 |
| LL Road Frame - Black, 44 | 9 | 2011 | 30 | 18 | 66.7 |
| LL Road Frame - Black, 44 | 8 | 2011 | 18 | 19 | -5.3 |
| LL Road Frame - Black, 44 | 7 | 2011 | 19 | 13 | 46.2 |
| LL Road Frame - Black, 44 | 6 | 2011 | 13 |  | 0 |
| LL Road Frame - Black, 48 | 12 | 2011 | 8 | 15 | -46.7 |
| LL Road Frame - Black, 48 | 11 | 2011 | 15 | 30 | -50 |
| LL Road Frame - Black, 48 | 10 | 2011 | 30 | 19 | 57.9 |
| LL Road Frame - Black, 48 | 9 | 2011 | 19 |  | 0 |
| LL Road Frame - Black, 52 | 12 | 2011 | 64 | 82 | -22 |
| LL Road Frame - Black, 52 | 11 | 2011 | 82 | 133 | -38.3 |
| LL Road Frame - Black, 52 | 10 | 2011 | 133 | 71 | 87.3 |
| LL Road Frame - Black, 52 | 9 | 2011 | 71 | 71 | 0 |
| LL Road Frame - Black, 52 | 8 | 2011 | 71 | 126 | -43.7 |
| LL Road Frame - Black, 52 | 7 | 2011 | 126 | 48 | 162.5 |
| LL Road Frame - Black, 52 | 6 | 2011 | 48 |  | 0 |
| LL Road Frame - Black, 58 | 12 | 2011 | 47 | 68 | -30.9 |
| LL Road Frame - Black, 58 | 11 | 2011 | 68 | 107 | -36.4 |
| LL Road Frame - Black, 58 | 10 | 2011 | 107 | 59 | 81.4 |
| LL Road Frame - Black, 58 | 9 | 2011 | 59 | 34 | 73.5 |
| LL Road Frame - Black, 58 | 8 | 2011 | 34 | 67 | -49.3 |
| LL Road Frame - Black, 58 | 7 | 2011 | 67 | 41 | 63.4 |
| LL Road Frame - Black, 58 | 6 | 2011 | 41 |  | 0 |
| LL Road Frame - Black, 60 | 12 | 2011 | 20 | 25 | -20 |
| LL Road Frame - Black, 60 | 11 | 2011 | 25 | 46 | -45.7 |
| LL Road Frame - Black, 60 | 10 | 2011 | 46 | 31 | 48.4 |
| LL Road Frame - Black, 60 | 9 | 2011 | 31 | 19 | 63.2 |
| LL Road Frame - Black, 60 | 8 | 2011 | 19 | 16 | 18.8 |
| LL Road Frame - Black, 60 | 7 | 2011 | 16 | 11 | 45.5 |
| LL Road Frame - Black, 60 | 6 | 2011 | 11 |  | 0 |
| LL Road Frame - Black, 62 | 12 | 2011 | 9 | 19 | -52.6 |
| LL Road Frame - Black, 62 | 11 | 2011 | 19 | 37 | -48.6 |
| LL Road Frame - Black, 62 | 10 | 2011 | 37 | 17 | 117.6 |
| LL Road Frame - Black, 62 | 9 | 2011 | 17 | 2 | 750 |
| LL Road Frame - Black, 62 | 8 | 2011 | 2 | 1 | 100 |
| LL Road Frame - Black, 62 | 7 | 2011 | 1 | 2 | -50 |
| LL Road Frame - Black, 62 | 6 | 2011 | 2 |  | 0 |
| LL Road Frame - Red, 44 | 12 | 2011 | 53 | 118 | -55.1 |
| LL Road Frame - Red, 44 | 11 | 2011 | 118 | 106 | 11.3 |
| LL Road Frame - Red, 44 | 10 | 2011 | 106 | 62 | 71 |
| LL Road Frame - Red, 44 | 9 | 2011 | 62 | 78 | -20.5 |
| LL Road Frame - Red, 44 | 8 | 2011 | 78 | 104 | -25 |
| LL Road Frame - Red, 44 | 7 | 2011 | 104 | 59 | 76.3 |
| LL Road Frame - Red, 44 | 6 | 2011 | 59 |  | 0 |
| LL Road Frame - Red, 48 | 12 | 2011 | 36 | 78 | -53.8 |
| LL Road Frame - Red, 48 | 11 | 2011 | 78 | 107 | -27.1 |
| LL Road Frame - Red, 48 | 10 | 2011 | 107 | 53 | 101.9 |
| LL Road Frame - Red, 48 | 9 | 2011 | 53 | 41 | 29.3 |
| LL Road Frame - Red, 48 | 8 | 2011 | 41 | 73 | -43.8 |
| LL Road Frame - Red, 48 | 7 | 2011 | 73 | 29 | 151.7 |
| LL Road Frame - Red, 48 | 6 | 2011 | 29 |  | 0 |
| LL Road Frame - Red, 52 | 12 | 2011 | 23 | 33 | -30.3 |
| LL Road Frame - Red, 52 | 11 | 2011 | 33 | 50 | -34 |
| LL Road Frame - Red, 52 | 10 | 2011 | 50 | 23 | 117.4 |
| LL Road Frame - Red, 52 | 9 | 2011 | 23 | 14 | 64.3 |
| LL Road Frame - Red, 52 | 8 | 2011 | 14 | 16 | -12.5 |
| LL Road Frame - Red, 52 | 7 | 2011 | 16 | 15 | 6.7 |
| LL Road Frame - Red, 52 | 6 | 2011 | 15 |  | 0 |
| LL Road Frame - Red, 58 | 12 | 2011 | 12 | 20 | -40 |
| LL Road Frame - Red, 58 | 11 | 2011 | 20 | 33 | -39.4 |
| LL Road Frame - Red, 58 | 10 | 2011 | 33 | 7 | 371.4 |
| LL Road Frame - Red, 58 | 9 | 2011 | 7 | 1 | 600 |
| LL Road Frame - Red, 58 | 8 | 2011 | 1 |  | 0 |
| LL Road Frame - Red, 60 | 12 | 2011 | 43 | 98 | -56.1 |
| LL Road Frame - Red, 60 | 11 | 2011 | 98 | 126 | -22.2 |
| LL Road Frame - Red, 60 | 10 | 2011 | 126 | 58 | 117.2 |
| LL Road Frame - Red, 60 | 9 | 2011 | 58 | 72 | -19.4 |
| LL Road Frame - Red, 60 | 8 | 2011 | 72 | 112 | -35.7 |
| LL Road Frame - Red, 60 | 7 | 2011 | 112 | 59 | 89.8 |
| LL Road Frame - Red, 60 | 6 | 2011 | 59 |  | 0 |
| LL Road Frame - Red, 62 | 12 | 2011 | 38 | 87 | -56.3 |
| LL Road Frame - Red, 62 | 11 | 2011 | 87 | 105 | -17.1 |
| LL Road Frame - Red, 62 | 10 | 2011 | 105 | 49 | 114.3 |
| LL Road Frame - Red, 62 | 9 | 2011 | 49 | 44 | 11.4 |
| LL Road Frame - Red, 62 | 8 | 2011 | 44 | 75 | -41.3 |
| LL Road Frame - Red, 62 | 7 | 2011 | 75 | 33 | 127.3 |
| LL Road Frame - Red, 62 | 6 | 2011 | 33 |  | 0 |
| LL Road Front Wheel | 12 | 2011 | 322 | 514 | -37.4 |
| LL Road Front Wheel | 11 | 2011 | 514 | 689 | -25.4 |
| LL Road Front Wheel | 10 | 2011 | 689 | 369 | 86.7 |
| LL Road Front Wheel | 9 | 2011 | 369 | 293 | 25.9 |
| LL Road Front Wheel | 8 | 2011 | 293 | 439 | -33.3 |
| LL Road Front Wheel | 7 | 2011 | 439 | 227 | 93.4 |
| LL Road Front Wheel | 6 | 2011 | 227 |  | 0 |
| LL Road Handlebars | 12 | 2011 | 322 | 514 | -37.4 |
| LL Road Handlebars | 11 | 2011 | 514 | 689 | -25.4 |
| LL Road Handlebars | 10 | 2011 | 689 | 369 | 86.7 |
| LL Road Handlebars | 9 | 2011 | 369 | 293 | 25.9 |
| LL Road Handlebars | 8 | 2011 | 293 | 439 | -33.3 |
| LL Road Handlebars | 7 | 2011 | 439 | 227 | 93.4 |
| LL Road Handlebars | 6 | 2011 | 227 |  | 0 |
| LL Road Rear Wheel | 12 | 2011 | 322 | 497 | -35.2 |
| LL Road Rear Wheel | 11 | 2011 | 497 | 689 | -27.9 |
| LL Road Rear Wheel | 10 | 2011 | 689 | 369 | 86.7 |
| LL Road Rear Wheel | 9 | 2011 | 369 | 293 | 25.9 |
| LL Road Rear Wheel | 8 | 2011 | 293 | 439 | -33.3 |
| LL Road Rear Wheel | 7 | 2011 | 439 | 227 | 93.4 |
| LL Road Rear Wheel | 6 | 2011 | 227 |  | 0 |
| LL Road Seat Assembly | 12 | 2011 | 322 | 514 | -37.4 |
| LL Road Seat Assembly | 11 | 2011 | 514 | 689 | -25.4 |
| LL Road Seat Assembly | 10 | 2011 | 689 | 369 | 86.7 |
| LL Road Seat Assembly | 9 | 2011 | 369 | 293 | 25.9 |
| LL Road Seat Assembly | 8 | 2011 | 293 | 427 | -31.4 |
| LL Road Seat Assembly | 7 | 2011 | 427 | 227 | 88.1 |
| LL Road Seat Assembly | 6 | 2011 | 227 |  | 0 |
| ML Bottom Bracket | 12 | 2011 | 113 | 207 | -45.4 |
| ML Bottom Bracket | 11 | 2011 | 207 | 291 | -28.9 |
| ML Bottom Bracket | 10 | 2011 | 291 | 110 | 164.5 |
| ML Bottom Bracket | 9 | 2011 | 110 | 128 | -14.1 |
| ML Bottom Bracket | 8 | 2011 | 128 | 169 | -24.3 |
| ML Bottom Bracket | 7 | 2011 | 169 | 98 | 72.4 |
| ML Bottom Bracket | 6 | 2011 | 98 |  | 0 |
| ML Crankset | 12 | 2011 | 435 | 721 | -39.7 |
| ML Crankset | 11 | 2011 | 721 | 980 | -26.4 |
| ML Crankset | 10 | 2011 | 980 | 479 | 104.6 |
| ML Crankset | 9 | 2011 | 479 | 409 | 17.1 |
| ML Crankset | 8 | 2011 | 409 | 608 | -32.7 |
| ML Crankset | 7 | 2011 | 608 | 325 | 87.1 |
| ML Crankset | 6 | 2011 | 325 |  | 0 |
| ML Fork | 12 | 2011 | 123 | 249 | -50.6 |
| ML Fork | 11 | 2011 | 249 | 345 | -27.8 |
| ML Fork | 10 | 2011 | 345 | 130 | 165.4 |
| ML Fork | 9 | 2011 | 130 | 150 | -13.3 |
| ML Fork | 8 | 2011 | 150 | 203 | -26.1 |
| ML Fork | 7 | 2011 | 203 | 118 | 72 |
| ML Fork | 6 | 2011 | 118 |  | 0 |
| ML Headset | 12 | 2011 | 435 | 721 | -39.7 |
| ML Headset | 11 | 2011 | 721 | 980 | -26.4 |
| ML Headset | 10 | 2011 | 980 | 479 | 104.6 |
| ML Headset | 9 | 2011 | 479 | 407 | 17.7 |
| ML Headset | 8 | 2011 | 407 | 608 | -33.1 |
| ML Headset | 7 | 2011 | 608 | 325 | 87.1 |
| ML Headset | 6 | 2011 | 325 |  | 0 |
| ML Road Frame - Red, 44 | 12 | 2011 | 23 | 36 | -36.1 |
| ML Road Frame - Red, 44 | 11 | 2011 | 36 | 46 | -21.7 |
| ML Road Frame - Red, 44 | 10 | 2011 | 46 | 19 | 142.1 |
| ML Road Frame - Red, 44 | 9 | 2011 | 19 | 21 | -9.5 |
| ML Road Frame - Red, 44 | 8 | 2011 | 21 | 21 | 0 |
| ML Road Frame - Red, 44 | 7 | 2011 | 21 | 14 | 50 |
| ML Road Frame - Red, 44 | 6 | 2011 | 14 |  | 0 |
| ML Road Frame - Red, 48 | 12 | 2011 | 16 | 45 | -64.4 |
| ML Road Frame - Red, 48 | 11 | 2011 | 45 | 68 | -33.8 |
| ML Road Frame - Red, 48 | 10 | 2011 | 68 | 20 | 240 |
| ML Road Frame - Red, 48 | 9 | 2011 | 20 | 14 | 42.9 |
| ML Road Frame - Red, 48 | 8 | 2011 | 14 | 26 | -46.2 |
| ML Road Frame - Red, 48 | 7 | 2011 | 26 | 16 | 62.5 |
| ML Road Frame - Red, 48 | 6 | 2011 | 16 |  | 0 |
| ML Road Frame - Red, 52 | 12 | 2011 | 37 | 81 | -54.3 |
| ML Road Frame - Red, 52 | 11 | 2011 | 81 | 102 | -20.6 |
| ML Road Frame - Red, 52 | 10 | 2011 | 102 | 43 | 137.2 |
| ML Road Frame - Red, 52 | 9 | 2011 | 43 | 51 | -15.7 |
| ML Road Frame - Red, 52 | 8 | 2011 | 51 | 78 | -34.6 |
| ML Road Frame - Red, 52 | 7 | 2011 | 78 | 50 | 56 |
| ML Road Frame - Red, 52 | 6 | 2011 | 50 |  | 0 |
| ML Road Frame - Red, 58 | 12 | 2011 | 29 | 55 | -47.3 |
| ML Road Frame - Red, 58 | 11 | 2011 | 55 | 81 | -32.1 |
| ML Road Frame - Red, 58 | 10 | 2011 | 81 | 26 | 211.5 |
| ML Road Frame - Red, 58 | 9 | 2011 | 26 | 37 | -29.7 |
| ML Road Frame - Red, 58 | 8 | 2011 | 37 | 54 | -31.5 |
| ML Road Frame - Red, 58 | 7 | 2011 | 54 | 27 | 100 |
| ML Road Frame - Red, 58 | 6 | 2011 | 27 |  | 0 |
| ML Road Frame - Red, 60 | 12 | 2011 | 18 | 32 | -43.8 |
| ML Road Frame - Red, 60 | 11 | 2011 | 32 | 47 | -31.9 |
| ML Road Frame - Red, 60 | 10 | 2011 | 47 | 22 | 113.6 |
| ML Road Frame - Red, 60 | 9 | 2011 | 22 | 27 | -18.5 |
| ML Road Frame - Red, 60 | 8 | 2011 | 27 | 22 | 22.7 |
| ML Road Frame - Red, 60 | 7 | 2011 | 22 | 11 | 100 |
| ML Road Frame - Red, 60 | 6 | 2011 | 11 |  | 0 |
| ML Road Front Wheel | 12 | 2011 | 113 | 202 | -44.1 |
| ML Road Front Wheel | 11 | 2011 | 202 | 291 | -30.6 |
| ML Road Front Wheel | 10 | 2011 | 291 | 110 | 164.5 |
| ML Road Front Wheel | 9 | 2011 | 110 | 128 | -14.1 |
| ML Road Front Wheel | 8 | 2011 | 128 | 169 | -24.3 |
| ML Road Front Wheel | 7 | 2011 | 169 | 98 | 72.4 |
| ML Road Front Wheel | 6 | 2011 | 98 |  | 0 |
| ML Road Handlebars | 12 | 2011 | 113 | 207 | -45.4 |
| ML Road Handlebars | 11 | 2011 | 207 | 291 | -28.9 |
| ML Road Handlebars | 10 | 2011 | 291 | 110 | 164.5 |
| ML Road Handlebars | 9 | 2011 | 110 | 125 | -12 |
| ML Road Handlebars | 8 | 2011 | 125 | 169 | -26 |
| ML Road Handlebars | 7 | 2011 | 169 | 98 | 72.4 |
| ML Road Handlebars | 6 | 2011 | 98 |  | 0 |
| ML Road Rear Wheel | 12 | 2011 | 113 | 207 | -45.4 |
| ML Road Rear Wheel | 11 | 2011 | 207 | 291 | -28.9 |
| ML Road Rear Wheel | 10 | 2011 | 291 | 110 | 164.5 |
| ML Road Rear Wheel | 9 | 2011 | 110 | 128 | -14.1 |
| ML Road Rear Wheel | 8 | 2011 | 128 | 169 | -24.3 |
| ML Road Rear Wheel | 7 | 2011 | 169 | 98 | 72.4 |
| ML Road Rear Wheel | 6 | 2011 | 98 |  | 0 |
| ML Road Seat Assembly | 12 | 2011 | 113 | 207 | -45.4 |
| ML Road Seat Assembly | 11 | 2011 | 207 | 291 | -28.9 |
| ML Road Seat Assembly | 10 | 2011 | 291 | 110 | 164.5 |
| ML Road Seat Assembly | 9 | 2011 | 110 | 128 | -14.1 |
| ML Road Seat Assembly | 8 | 2011 | 128 | 169 | -24.3 |
| ML Road Seat Assembly | 7 | 2011 | 169 | 97 | 74.2 |
| ML Road Seat Assembly | 6 | 2011 | 97 |  | 0 |
| Mountain End Caps | 12 | 2011 | 408 | 974 | -58.1 |
| Mountain End Caps | 11 | 2011 | 974 | 1314 | -25.9 |
| Mountain End Caps | 10 | 2011 | 1314 | 415 | 216.6 |
| Mountain End Caps | 9 | 2011 | 415 | 792 | -47.6 |
| Mountain End Caps | 8 | 2011 | 792 | 1040 | -23.8 |
| Mountain End Caps | 7 | 2011 | 1040 | 256 | 306.3 |
| Mountain End Caps | 6 | 2011 | 256 |  | 0 |
| Mountain-100 Black, 38 | 12 | 2011 | 28 | 66 | -57.6 |
| Mountain-100 Black, 38 | 11 | 2011 | 66 | 82 | -19.5 |
| Mountain-100 Black, 38 | 10 | 2011 | 82 | 34 | 141.2 |
| Mountain-100 Black, 38 | 9 | 2011 | 34 | 52 | -34.6 |
| Mountain-100 Black, 38 | 8 | 2011 | 52 | 71 | -26.8 |
| Mountain-100 Black, 38 | 7 | 2011 | 71 | 22 | 222.7 |
| Mountain-100 Black, 38 | 6 | 2011 | 22 |  | 0 |
| Mountain-100 Black, 42 | 12 | 2011 | 22 | 67 | -67.2 |
| Mountain-100 Black, 42 | 11 | 2011 | 67 | 76 | -11.8 |
| Mountain-100 Black, 42 | 10 | 2011 | 76 | 30 | 153.3 |
| Mountain-100 Black, 42 | 9 | 2011 | 30 | 44 | -31.8 |
| Mountain-100 Black, 42 | 8 | 2011 | 44 | 77 | -42.9 |
| Mountain-100 Black, 42 | 7 | 2011 | 77 | 16 | 381.3 |
| Mountain-100 Black, 42 | 6 | 2011 | 16 |  | 0 |
| Mountain-100 Black, 44 | 12 | 2011 | 28 | 69 | -59.4 |
| Mountain-100 Black, 44 | 11 | 2011 | 69 | 96 | -28.1 |
| Mountain-100 Black, 44 | 10 | 2011 | 96 | 26 | 269.2 |
| Mountain-100 Black, 44 | 9 | 2011 | 26 | 58 | -55.2 |
| Mountain-100 Black, 44 | 8 | 2011 | 58 | 68 | -14.7 |
| Mountain-100 Black, 44 | 7 | 2011 | 68 | 23 | 195.7 |
| Mountain-100 Black, 44 | 6 | 2011 | 23 |  | 0 |
| Mountain-100 Black, 48 | 12 | 2011 | 27 | 59 | -54.2 |
| Mountain-100 Black, 48 | 11 | 2011 | 59 | 79 | -25.3 |
| Mountain-100 Black, 48 | 10 | 2011 | 79 | 23 | 243.5 |
| Mountain-100 Black, 48 | 9 | 2011 | 23 | 46 | -50 |
| Mountain-100 Black, 48 | 8 | 2011 | 46 | 63 | -27 |
| Mountain-100 Black, 48 | 7 | 2011 | 63 | 21 | 200 |
| Mountain-100 Black, 48 | 6 | 2011 | 21 |  | 0 |
| Mountain-100 Silver, 38 | 12 | 2011 | 30 | 55 | -45.5 |
| Mountain-100 Silver, 38 | 11 | 2011 | 55 | 88 | -37.5 |
| Mountain-100 Silver, 38 | 10 | 2011 | 88 | 25 | 252 |
| Mountain-100 Silver, 38 | 9 | 2011 | 25 | 60 | -58.3 |
| Mountain-100 Silver, 38 | 8 | 2011 | 60 | 76 | -21.1 |
| Mountain-100 Silver, 38 | 7 | 2011 | 76 | 11 | 590.9 |
| Mountain-100 Silver, 38 | 6 | 2011 | 11 |  | 0 |
| Mountain-100 Silver, 42 | 12 | 2011 | 17 | 48 | -64.6 |
| Mountain-100 Silver, 42 | 11 | 2011 | 48 | 96 | -50 |
| Mountain-100 Silver, 42 | 10 | 2011 | 96 | 20 | 380 |
| Mountain-100 Silver, 42 | 9 | 2011 | 20 | 49 | -59.2 |
| Mountain-100 Silver, 42 | 8 | 2011 | 49 | 59 | -16.9 |
| Mountain-100 Silver, 42 | 7 | 2011 | 59 | 5 | 1,080 |
| Mountain-100 Silver, 42 | 6 | 2011 | 5 |  | 0 |
| Mountain-100 Silver, 44 | 12 | 2011 | 36 | 63 | -42.9 |
| Mountain-100 Silver, 44 | 11 | 2011 | 63 | 70 | -10 |
| Mountain-100 Silver, 44 | 10 | 2011 | 70 | 24 | 191.7 |
| Mountain-100 Silver, 44 | 9 | 2011 | 24 | 50 | -52 |
| Mountain-100 Silver, 44 | 8 | 2011 | 50 | 62 | -19.4 |
| Mountain-100 Silver, 44 | 7 | 2011 | 62 | 18 | 244.4 |
| Mountain-100 Silver, 44 | 6 | 2011 | 18 |  | 0 |
| Mountain-100 Silver, 48 | 12 | 2011 | 21 | 55 | -61.8 |
| Mountain-100 Silver, 48 | 11 | 2011 | 55 | 68 | -19.1 |
| Mountain-100 Silver, 48 | 10 | 2011 | 68 | 26 | 161.5 |
| Mountain-100 Silver, 48 | 9 | 2011 | 26 | 37 | -29.7 |
| Mountain-100 Silver, 48 | 8 | 2011 | 37 | 44 | -15.9 |
| Mountain-100 Silver, 48 | 7 | 2011 | 44 | 8 | 450 |
| Mountain-100 Silver, 48 | 6 | 2011 | 8 |  | 0 |
| Rear Derailleur | 12 | 2011 | 861 | 1440 | -40.2 |
| Rear Derailleur | 11 | 2011 | 1440 | 1918 | -24.9 |
| Rear Derailleur | 10 | 2011 | 1918 | 874 | 119.5 |
| Rear Derailleur | 9 | 2011 | 874 | 969 | -9.8 |
| Rear Derailleur | 8 | 2011 | 969 | 1278 | -24.2 |
| Rear Derailleur | 7 | 2011 | 1278 | 501 | 155.1 |
| Rear Derailleur | 6 | 2011 | 501 |  | 0 |
| Road End Caps | 12 | 2011 | 1282 | 1936 | -33.8 |
| Road End Caps | 11 | 2011 | 1936 | 2522 | -23.2 |
| Road End Caps | 10 | 2011 | 2522 | 1348 | 87.1 |
| Road End Caps | 9 | 2011 | 1348 | 1142 | 18 |
| Road End Caps | 8 | 2011 | 1142 | 1528 | -25.3 |
| Road End Caps | 7 | 2011 | 1528 | 792 | 92.9 |
| Road End Caps | 6 | 2011 | 792 |  | 0 |
| Road-150 Red, 44 | 12 | 2011 | 38 | 45 | -15.6 |
| Road-150 Red, 44 | 11 | 2011 | 45 | 40 | 12.5 |
| Road-150 Red, 44 | 10 | 2011 | 40 | 35 | 14.3 |
| Road-150 Red, 44 | 9 | 2011 | 35 | 20 | 75 |
| Road-150 Red, 44 | 8 | 2011 | 20 | 17 | 17.6 |
| Road-150 Red, 44 | 7 | 2011 | 17 | 10 | 70 |
| Road-150 Red, 44 | 6 | 2011 | 10 |  | 0 |
| Road-150 Red, 48 | 12 | 2011 | 47 | 41 | 14.6 |
| Road-150 Red, 48 | 11 | 2011 | 41 | 45 | -8.9 |
| Road-150 Red, 48 | 10 | 2011 | 45 | 35 | 28.6 |
| Road-150 Red, 48 | 9 | 2011 | 35 | 18 | 94.4 |
| Road-150 Red, 48 | 8 | 2011 | 18 | 34 | -47.1 |
| Road-150 Red, 48 | 7 | 2011 | 34 | 4 | 750 |
| Road-150 Red, 48 | 6 | 2011 | 4 |  | 0 |
| Road-150 Red, 52 | 12 | 2011 | 35 | 41 | -14.6 |
| Road-150 Red, 52 | 11 | 2011 | 41 | 53 | -22.6 |
| Road-150 Red, 52 | 10 | 2011 | 53 | 29 | 82.8 |
| Road-150 Red, 52 | 9 | 2011 | 29 | 24 | 20.8 |
| Road-150 Red, 52 | 8 | 2011 | 24 | 15 | 60 |
| Road-150 Red, 52 | 7 | 2011 | 15 | 4 | 275 |
| Road-150 Red, 52 | 6 | 2011 | 4 |  | 0 |
| Road-150 Red, 56 | 12 | 2011 | 46 | 55 | -16.4 |
| Road-150 Red, 56 | 11 | 2011 | 55 | 74 | -25.7 |
| Road-150 Red, 56 | 10 | 2011 | 74 | 44 | 68.2 |
| Road-150 Red, 56 | 9 | 2011 | 44 | 46 | -4.3 |
| Road-150 Red, 56 | 8 | 2011 | 46 | 55 | -16.4 |
| Road-150 Red, 56 | 7 | 2011 | 55 | 21 | 161.9 |
| Road-150 Red, 56 | 6 | 2011 | 21 |  | 0 |
| Road-150 Red, 62 | 12 | 2011 | 51 | 54 | -5.6 |
| Road-150 Red, 62 | 11 | 2011 | 54 | 67 | -19.4 |
| Road-150 Red, 62 | 10 | 2011 | 67 | 44 | 52.3 |
| Road-150 Red, 62 | 9 | 2011 | 44 | 44 | 0 |
| Road-150 Red, 62 | 8 | 2011 | 44 | 29 | 51.7 |
| Road-150 Red, 62 | 7 | 2011 | 29 | 13 | 123.1 |
| Road-150 Red, 62 | 6 | 2011 | 13 |  | 0 |
| Road-450 Red, 44 | 12 | 2011 | 23 | 36 | -36.1 |
| Road-450 Red, 44 | 11 | 2011 | 36 | 46 | -21.7 |
| Road-450 Red, 44 | 10 | 2011 | 46 | 19 | 142.1 |
| Road-450 Red, 44 | 9 | 2011 | 19 | 21 | -9.5 |
| Road-450 Red, 44 | 8 | 2011 | 21 | 21 | 0 |
| Road-450 Red, 44 | 7 | 2011 | 21 | 14 | 50 |
| Road-450 Red, 44 | 6 | 2011 | 14 |  | 0 |
| Road-450 Red, 48 | 12 | 2011 | 6 | 14 | -57.1 |
| Road-450 Red, 48 | 11 | 2011 | 14 | 29 | -51.7 |
| Road-450 Red, 48 | 10 | 2011 | 29 | 9 | 222.2 |
| Road-450 Red, 48 | 9 | 2011 | 9 |  | 0 |
| Road-450 Red, 52 | 12 | 2011 | 37 | 70 | -47.1 |
| Road-450 Red, 52 | 11 | 2011 | 70 | 87 | -19.5 |
| Road-450 Red, 52 | 10 | 2011 | 87 | 34 | 155.9 |
| Road-450 Red, 52 | 9 | 2011 | 34 | 43 | -20.9 |
| Road-450 Red, 52 | 8 | 2011 | 43 | 72 | -40.3 |
| Road-450 Red, 52 | 7 | 2011 | 72 | 46 | 56.5 |
| Road-450 Red, 52 | 6 | 2011 | 46 |  | 0 |
| Road-450 Red, 58 | 12 | 2011 | 29 | 55 | -47.3 |
| Road-450 Red, 58 | 11 | 2011 | 55 | 82 | -32.9 |
| Road-450 Red, 58 | 10 | 2011 | 82 | 26 | 215.4 |
| Road-450 Red, 58 | 9 | 2011 | 26 | 37 | -29.7 |
| Road-450 Red, 58 | 8 | 2011 | 37 | 54 | -31.5 |
| Road-450 Red, 58 | 7 | 2011 | 54 | 27 | 100 |
| Road-450 Red, 58 | 6 | 2011 | 27 |  | 0 |
| Road-450 Red, 60 | 12 | 2011 | 18 | 32 | -43.8 |
| Road-450 Red, 60 | 11 | 2011 | 32 | 47 | -31.9 |
| Road-450 Red, 60 | 10 | 2011 | 47 | 22 | 113.6 |
| Road-450 Red, 60 | 9 | 2011 | 22 | 27 | -18.5 |
| Road-450 Red, 60 | 8 | 2011 | 27 | 22 | 22.7 |
| Road-450 Red, 60 | 7 | 2011 | 22 | 11 | 100 |
| Road-450 Red, 60 | 6 | 2011 | 11 |  | 0 |
| Road-650 Black, 44 | 12 | 2011 | 21 | 27 | -22.2 |
| Road-650 Black, 44 | 11 | 2011 | 27 | 42 | -35.7 |
| Road-650 Black, 44 | 10 | 2011 | 42 | 27 | 55.6 |
| Road-650 Black, 44 | 9 | 2011 | 27 | 17 | 58.8 |
| Road-650 Black, 44 | 8 | 2011 | 17 | 19 | -10.5 |
| Road-650 Black, 44 | 7 | 2011 | 19 | 13 | 46.2 |
| Road-650 Black, 44 | 6 | 2011 | 13 |  | 0 |
| Road-650 Black, 48 | 12 | 2011 | 8 | 15 | -46.7 |
| Road-650 Black, 48 | 11 | 2011 | 15 | 30 | -50 |
| Road-650 Black, 48 | 10 | 2011 | 30 | 19 | 57.9 |
| Road-650 Black, 48 | 9 | 2011 | 19 |  | 0 |
| Road-650 Black, 52 | 12 | 2011 | 53 | 56 | -5.4 |
| Road-650 Black, 52 | 11 | 2011 | 56 | 89 | -37.1 |
| Road-650 Black, 52 | 10 | 2011 | 89 | 51 | 74.5 |
| Road-650 Black, 52 | 9 | 2011 | 51 | 48 | 6.3 |
| Road-650 Black, 52 | 8 | 2011 | 48 | 86 | -44.2 |
| Road-650 Black, 52 | 7 | 2011 | 86 | 29 | 196.6 |
| Road-650 Black, 52 | 6 | 2011 | 29 |  | 0 |
| Road-650 Black, 58 | 12 | 2011 | 43 | 49 | -12.2 |
| Road-650 Black, 58 | 11 | 2011 | 49 | 70 | -30 |
| Road-650 Black, 58 | 10 | 2011 | 70 | 43 | 62.8 |
| Road-650 Black, 58 | 9 | 2011 | 43 | 27 | 59.3 |
| Road-650 Black, 58 | 8 | 2011 | 27 | 49 | -44.9 |
| Road-650 Black, 58 | 7 | 2011 | 49 | 31 | 58.1 |
| Road-650 Black, 58 | 6 | 2011 | 31 |  | 0 |
| Road-650 Black, 60 | 12 | 2011 | 18 | 25 | -28 |
| Road-650 Black, 60 | 11 | 2011 | 25 | 45 | -44.4 |
| Road-650 Black, 60 | 10 | 2011 | 45 | 32 | 40.6 |
| Road-650 Black, 60 | 9 | 2011 | 32 | 18 | 77.8 |
| Road-650 Black, 60 | 8 | 2011 | 18 | 16 | 12.5 |
| Road-650 Black, 60 | 7 | 2011 | 16 | 11 | 45.5 |
| Road-650 Black, 60 | 6 | 2011 | 11 |  | 0 |
| Road-650 Black, 62 | 12 | 2011 | 9 | 21 | -57.1 |
| Road-650 Black, 62 | 11 | 2011 | 21 | 35 | -40 |
| Road-650 Black, 62 | 10 | 2011 | 35 | 16 | 118.8 |
| Road-650 Black, 62 | 9 | 2011 | 16 | 2 | 700 |
| Road-650 Black, 62 | 8 | 2011 | 2 | 1 | 100 |
| Road-650 Black, 62 | 7 | 2011 | 1 | 2 | -50 |
| Road-650 Black, 62 | 6 | 2011 | 2 |  | 0 |
| Road-650 Red, 44 | 12 | 2011 | 40 | 92 | -56.5 |
| Road-650 Red, 44 | 11 | 2011 | 92 | 64 | 43.8 |
| Road-650 Red, 44 | 10 | 2011 | 64 | 38 | 68.4 |
| Road-650 Red, 44 | 9 | 2011 | 38 | 49 | -22.4 |
| Road-650 Red, 44 | 8 | 2011 | 49 | 66 | -25.8 |
| Road-650 Red, 44 | 7 | 2011 | 66 | 44 | 50 |
| Road-650 Red, 44 | 6 | 2011 | 44 |  | 0 |
| Road-650 Red, 48 | 12 | 2011 | 31 | 54 | -42.6 |
| Road-650 Red, 48 | 11 | 2011 | 54 | 68 | -20.6 |
| Road-650 Red, 48 | 10 | 2011 | 68 | 41 | 65.9 |
| Road-650 Red, 48 | 9 | 2011 | 41 | 34 | 20.6 |
| Road-650 Red, 48 | 8 | 2011 | 34 | 54 | -37 |
| Road-650 Red, 48 | 7 | 2011 | 54 | 20 | 170 |
| Road-650 Red, 48 | 6 | 2011 | 20 |  | 0 |
| Road-650 Red, 52 | 12 | 2011 | 23 | 30 | -23.3 |
| Road-650 Red, 52 | 11 | 2011 | 30 | 50 | -40 |
| Road-650 Red, 52 | 10 | 2011 | 50 | 21 | 138.1 |
| Road-650 Red, 52 | 9 | 2011 | 21 | 14 | 50 |
| Road-650 Red, 52 | 8 | 2011 | 14 | 16 | -12.5 |
| Road-650 Red, 52 | 7 | 2011 | 16 | 15 | 6.7 |
| Road-650 Red, 52 | 6 | 2011 | 15 |  | 0 |
| Road-650 Red, 58 | 12 | 2011 | 12 | 19 | -36.8 |
| Road-650 Red, 58 | 11 | 2011 | 19 | 33 | -42.4 |
| Road-650 Red, 58 | 10 | 2011 | 33 | 7 | 371.4 |
| Road-650 Red, 58 | 9 | 2011 | 7 | 1 | 600 |
| Road-650 Red, 58 | 8 | 2011 | 1 |  | 0 |
| Road-650 Red, 60 | 12 | 2011 | 33 | 67 | -50.7 |
| Road-650 Red, 60 | 11 | 2011 | 67 | 88 | -23.9 |
| Road-650 Red, 60 | 10 | 2011 | 88 | 40 | 120 |
| Road-650 Red, 60 | 9 | 2011 | 40 | 47 | -14.9 |
| Road-650 Red, 60 | 8 | 2011 | 47 | 70 | -32.9 |
| Road-650 Red, 60 | 7 | 2011 | 70 | 43 | 62.8 |
| Road-650 Red, 60 | 6 | 2011 | 43 |  | 0 |
| Road-650 Red, 62 | 12 | 2011 | 31 | 56 | -44.6 |
| Road-650 Red, 62 | 11 | 2011 | 56 | 73 | -23.3 |
| Road-650 Red, 62 | 10 | 2011 | 73 | 34 | 114.7 |
| Road-650 Red, 62 | 9 | 2011 | 34 | 36 | -5.6 |
| Road-650 Red, 62 | 8 | 2011 | 36 | 62 | -41.9 |
| Road-650 Red, 62 | 7 | 2011 | 62 | 19 | 226.3 |
| Road-650 Red, 62 | 6 | 2011 | 19 |  | 0 |
| Seat Stays | 12 | 2011 | 3682 | 7195 | -48.8 |
| Seat Stays | 11 | 2011 | 7195 | 9340 | -23 |
| Seat Stays | 10 | 2011 | 9340 | 4243 | 120.1 |
| Seat Stays | 9 | 2011 | 4243 | 4764 | -10.9 |
| Seat Stays | 8 | 2011 | 4764 | 6332 | -24.8 |
| Seat Stays | 7 | 2011 | 6332 | 2560 | 147.3 |
| Seat Stays | 6 | 2011 | 2560 |  | 0 |
| Seat Tube | 12 | 2011 | 921 | 1799 | -48.8 |
| Seat Tube | 11 | 2011 | 1799 | 2335 | -23 |
| Seat Tube | 10 | 2011 | 2335 | 1061 | 120.1 |
| Seat Tube | 9 | 2011 | 1061 | 1191 | -10.9 |
| Seat Tube | 8 | 2011 | 1191 | 1583 | -24.8 |
| Seat Tube | 7 | 2011 | 1583 | 640 | 147.3 |
| Seat Tube | 6 | 2011 | 640 |  | 0 |
| Steerer | 12 | 2011 | 921 | 1799 | -48.8 |
| Steerer | 11 | 2011 | 1799 | 2270 | -20.7 |
| Steerer | 10 | 2011 | 2270 | 1061 | 113.9 |
| Steerer | 9 | 2011 | 1061 | 1191 | -10.9 |
| Steerer | 8 | 2011 | 1191 | 1583 | -24.8 |
| Steerer | 7 | 2011 | 1583 | 640 | 147.3 |
| Steerer | 6 | 2011 | 640 |  | 0 |
| Stem | 12 | 2011 | 848 | 1455 | -41.7 |
| Stem | 11 | 2011 | 1455 | 1918 | -24.1 |
| Stem | 10 | 2011 | 1918 | 885 | 116.7 |
| Stem | 9 | 2011 | 885 | 967 | -8.5 |
| Stem | 8 | 2011 | 967 | 1284 | -24.7 |
| Stem | 7 | 2011 | 1284 | 526 | 144.1 |
| Stem | 6 | 2011 | 526 |  | 0 |
| Top Tube | 12 | 2011 | 921 | 1767 | -47.9 |
| Top Tube | 11 | 2011 | 1767 | 2335 | -24.3 |
| Top Tube | 10 | 2011 | 2335 | 1061 | 120.1 |
| Top Tube | 9 | 2011 | 1061 | 1191 | -10.9 |
| Top Tube | 8 | 2011 | 1191 | 1583 | -24.8 |
| Top Tube | 7 | 2011 | 1583 | 640 | 147.3 |
| Top Tube | 6 | 2011 | 640 |  | 0 |

**📝 Observation:** 
## Query 07: 
```sql
with 
sale_info as (
  select 
      extract(month from a.ModifiedDate) as mth 
     , extract(year from a.ModifiedDate) as yr 
     , a.ProductId
     , b.Name
     , sum(a.OrderQty) as sales
  from `adventureworks2019.Sales.SalesOrderDetail` a 
  left join `adventureworks2019.Production.Product` b 
    on a.ProductID = b.ProductID
  where FORMAT_TIMESTAMP("%Y", a.ModifiedDate) = '2011'
  group by 1,2,3,4
), 

stock_info as (
  select
      extract(month from ModifiedDate) as mth 
      , extract(year from ModifiedDate) as yr 
      , ProductId
      , sum(StockedQty) as stock_cnt
  from `adventureworks2019.Production.WorkOrder`
  where FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2011'
  group by 1,2,3
)

select
      a.*
    , b.stock_cnt as stock  --(*)
    , round(coalesce(b.stock_cnt,0) / sales,2) as ratio
from sale_info a 
full join stock_info b 
  on a.ProductId = b.ProductId
and a.mth = b.mth 
and a.yr = b.yr
order by 1 desc, 7 desc;
```
### ✅ Results:
| mth | yr | ProductId | Name | sales | stock | ratio |
| --- | --- | --- | --- | --- | --- | --- |
| 12 | 2011 | 745 | HL Mountain Frame - Black, 48 | 1 | 27 | 27 |
| 12 | 2011 | 743 | HL Mountain Frame - Black, 42 | 1 | 26 | 26 |
| 12 | 2011 | 748 | HL Mountain Frame - Silver, 38 | 2 | 32 | 16 |
| 12 | 2011 | 722 | LL Road Frame - Black, 58 | 4 | 47 | 11.75 |
| 12 | 2011 | 747 | HL Mountain Frame - Black, 38 | 3 | 31 | 10.33 |
| 12 | 2011 | 726 | LL Road Frame - Red, 48 | 5 | 36 | 7.2 |
| 12 | 2011 | 738 | LL Road Frame - Black, 52 | 10 | 64 | 6.4 |
| 12 | 2011 | 730 | LL Road Frame - Red, 62 | 7 | 38 | 5.43 |
| 12 | 2011 | 741 | HL Mountain Frame - Silver, 48 | 5 | 27 | 5.4 |
| 12 | 2011 | 725 | LL Road Frame - Red, 44 | 12 | 53 | 4.42 |
| 12 | 2011 | 729 | LL Road Frame - Red, 60 | 10 | 43 | 4.3 |
| 12 | 2011 | 732 | ML Road Frame - Red, 48 | 10 | 16 | 1.6 |
| 12 | 2011 | 750 | Road-150 Red, 44 | 25 | 38 | 1.52 |
| 12 | 2011 | 751 | Road-150 Red, 48 | 32 | 47 | 1.47 |
| 12 | 2011 | 775 | Mountain-100 Black, 38 | 23 | 28 | 1.22 |
| 12 | 2011 | 773 | Mountain-100 Silver, 44 | 32 | 36 | 1.13 |
| 12 | 2011 | 749 | Road-150 Red, 62 | 45 | 51 | 1.13 |
| 12 | 2011 | 768 | Road-650 Black, 44 | 19 | 21 | 1.11 |
| 12 | 2011 | 765 | Road-650 Black, 58 | 39 | 43 | 1.1 |
| 12 | 2011 | 752 | Road-150 Red, 52 | 32 | 35 | 1.09 |
| 12 | 2011 | 778 | Mountain-100 Black, 48 | 25 | 27 | 1.08 |
| 12 | 2011 | 760 | Road-650 Red, 60 | 31 | 33 | 1.06 |
| 12 | 2011 | 770 | Road-650 Black, 52 | 52 | 53 | 1.02 |
| 12 | 2011 | 756 | Road-450 Red, 44 | 23 | 23 | 1 |
| 12 | 2011 | 757 | Road-450 Red, 48 | 6 | 6 | 1 |
| 12 | 2011 | 755 | Road-450 Red, 60 | 18 | 18 | 1 |
| 12 | 2011 | 754 | Road-450 Red, 58 | 29 | 29 | 1 |
| 12 | 2011 | 742 | HL Mountain Frame - Silver, 46 | 3 | 3 | 1 |
| 12 | 2011 | 758 | Road-450 Red, 52 | 37 | 37 | 1 |
| 12 | 2011 | 764 | Road-650 Red, 52 | 23 | 23 | 1 |
| 12 | 2011 | 759 | Road-650 Red, 58 | 12 | 12 | 1 |
| 12 | 2011 | 761 | Road-650 Red, 62 | 31 | 31 | 1 |
| 12 | 2011 | 762 | Road-650 Red, 44 | 41 | 40 | 0.98 |
| 12 | 2011 | 777 | Mountain-100 Black, 44 | 29 | 28 | 0.97 |
| 12 | 2011 | 774 | Mountain-100 Silver, 48 | 22 | 21 | 0.95 |
| 12 | 2011 | 772 | Mountain-100 Silver, 42 | 18 | 17 | 0.94 |
| 12 | 2011 | 763 | Road-650 Red, 48 | 33 | 31 | 0.94 |
| 12 | 2011 | 753 | Road-150 Red, 56 | 49 | 46 | 0.94 |
| 12 | 2011 | 776 | Mountain-100 Black, 42 | 24 | 22 | 0.92 |
| 12 | 2011 | 771 | Mountain-100 Silver, 38 | 33 | 30 | 0.91 |
| 12 | 2011 | 767 | Road-650 Black, 62 | 10 | 9 | 0.9 |
| 12 | 2011 | 769 | Road-650 Black, 48 | 9 | 8 | 0.89 |
| 12 | 2011 | 766 | Road-650 Black, 60 | 22 | 18 | 0.82 |
| 12 | 2011 | 715 | Long-Sleeve Logo Jersey, L | 29 |  | 0 |
| 12 | 2011 | 714 | Long-Sleeve Logo Jersey, M | 9 |  | 0 |
| 12 | 2011 | 708 | Sport-100 Helmet, Black | 10 |  | 0 |
| 12 | 2011 | 716 | Long-Sleeve Logo Jersey, XL | 6 |  | 0 |
| 12 | 2011 | 709 | Mountain Bike Socks, M | 45 |  | 0 |
| 12 | 2011 | 711 | Sport-100 Helmet, Blue | 7 |  | 0 |
| 12 | 2011 | 712 | AWC Logo Cap | 25 |  | 0 |
| 12 | 2011 | 707 | Sport-100 Helmet, Red | 12 |  | 0 |
| 11 | 2011 | 761 | Road-650 Red, 62 | 1 | 56 | 56 |
| 11 | 2011 | 764 | Road-650 Red, 52 | 1 | 30 | 30 |
| 11 | 2011 | 772 | Mountain-100 Silver, 42 | 2 | 48 | 24 |
| 11 | 2011 | 767 | Road-650 Black, 62 | 1 | 21 | 21 |
| 11 | 2011 | 763 | Road-650 Red, 48 | 3 | 54 | 18 |
| 11 | 2011 | 760 | Road-650 Red, 60 | 4 | 67 | 16.75 |
| 11 | 2011 | 769 | Road-650 Black, 48 | 1 | 15 | 15 |
| 11 | 2011 | 770 | Road-650 Black, 52 | 4 | 56 | 14 |
| 11 | 2011 | 771 | Mountain-100 Silver, 38 | 4 | 55 | 13.75 |
| 11 | 2011 | 776 | Mountain-100 Black, 42 | 5 | 67 | 13.4 |
| 11 | 2011 | 766 | Road-650 Black, 60 | 2 | 25 | 12.5 |
| 11 | 2011 | 765 | Road-650 Black, 58 | 4 | 49 | 12.25 |
| 11 | 2011 | 778 | Mountain-100 Black, 48 | 5 | 59 | 11.8 |
| 11 | 2011 | 773 | Mountain-100 Silver, 44 | 6 | 63 | 10.5 |
| 11 | 2011 | 759 | Road-650 Red, 58 | 2 | 19 | 9.5 |
| 11 | 2011 | 777 | Mountain-100 Black, 44 | 8 | 69 | 8.63 |
| 11 | 2011 | 775 | Mountain-100 Black, 38 | 8 | 66 | 8.25 |
| 11 | 2011 | 768 | Road-650 Black, 44 | 4 | 27 | 6.75 |
| 11 | 2011 | 753 | Road-150 Red, 56 | 31 | 55 | 1.77 |
| 11 | 2011 | 752 | Road-150 Red, 52 | 25 | 41 | 1.64 |
| 11 | 2011 | 749 | Road-150 Red, 62 | 35 | 54 | 1.54 |
| 11 | 2011 | 750 | Road-150 Red, 44 | 34 | 45 | 1.32 |
| 11 | 2011 | 751 | Road-150 Red, 48 | 40 | 41 | 1.02 |
| 10 | 2011 | 723 | LL Road Frame - Black, 60 | 1 | 46 | 46 |
| 10 | 2011 | 744 | HL Mountain Frame - Black, 44 | 6 | 100 | 16.67 |
| 10 | 2011 | 739 | HL Mountain Frame - Silver, 42 | 7 | 97 | 13.86 |
| 10 | 2011 | 727 | LL Road Frame - Red, 52 | 4 | 50 | 12.5 |
| 10 | 2011 | 717 | HL Road Frame - Red, 62 | 8 | 66 | 8.25 |
| 10 | 2011 | 718 | HL Road Frame - Red, 44 | 6 | 41 | 6.83 |
| 10 | 2011 | 736 | LL Road Frame - Black, 44 | 9 | 45 | 5 |
| 10 | 2011 | 733 | ML Road Frame - Red, 52 | 26 | 102 | 3.92 |
| 10 | 2011 | 745 | HL Mountain Frame - Black, 48 | 33 | 96 | 2.91 |
| 10 | 2011 | 747 | HL Mountain Frame - Black, 38 | 35 | 94 | 2.69 |
| 10 | 2011 | 748 | HL Mountain Frame - Silver, 38 | 46 | 112 | 2.43 |
| 10 | 2011 | 743 | HL Mountain Frame - Black, 42 | 45 | 96 | 2.13 |
| 10 | 2011 | 741 | HL Mountain Frame - Silver, 48 | 45 | 90 | 2 |
| 10 | 2011 | 738 | LL Road Frame - Black, 52 | 69 | 133 | 1.93 |
| 10 | 2011 | 722 | LL Road Frame - Black, 58 | 57 | 107 | 1.88 |
| 10 | 2011 | 729 | LL Road Frame - Red, 60 | 70 | 126 | 1.8 |
| 10 | 2011 | 726 | LL Road Frame - Red, 48 | 63 | 107 | 1.7 |
| 10 | 2011 | 730 | LL Road Frame - Red, 62 | 62 | 105 | 1.69 |
| 10 | 2011 | 725 | LL Road Frame - Red, 44 | 67 | 106 | 1.58 |
| 10 | 2011 | 732 | ML Road Frame - Red, 48 | 70 | 68 | 0.97 |
| 10 | 2011 | 751 | Road-150 Red, 48 | 57 | 45 | 0.79 |
| 10 | 2011 | 749 | Road-150 Red, 62 | 92 | 67 | 0.73 |
| 10 | 2011 | 752 | Road-150 Red, 52 | 75 | 53 | 0.71 |
| 10 | 2011 | 753 | Road-150 Red, 56 | 104 | 74 | 0.71 |
| 10 | 2011 | 772 | Mountain-100 Silver, 42 | 141 | 96 | 0.68 |
| 10 | 2011 | 766 | Road-650 Black, 60 | 66 | 45 | 0.68 |
| 10 | 2011 | 759 | Road-650 Red, 58 | 49 | 33 | 0.67 |
| 10 | 2011 | 757 | Road-450 Red, 48 | 43 | 29 | 0.67 |
| 10 | 2011 | 769 | Road-650 Black, 48 | 45 | 30 | 0.67 |
| 10 | 2011 | 764 | Road-650 Red, 52 | 78 | 50 | 0.64 |
| 10 | 2011 | 767 | Road-650 Black, 62 | 55 | 35 | 0.64 |
| 10 | 2011 | 768 | Road-650 Black, 44 | 68 | 42 | 0.62 |
| 10 | 2011 | 750 | Road-150 Red, 44 | 65 | 40 | 0.62 |
| 10 | 2011 | 771 | Mountain-100 Silver, 38 | 141 | 88 | 0.62 |
| 10 | 2011 | 770 | Road-650 Black, 52 | 145 | 89 | 0.61 |
| 10 | 2011 | 777 | Mountain-100 Black, 44 | 158 | 96 | 0.61 |
| 10 | 2011 | 765 | Road-650 Black, 58 | 117 | 70 | 0.6 |
| 10 | 2011 | 754 | Road-450 Red, 58 | 137 | 82 | 0.6 |
| 10 | 2011 | 778 | Mountain-100 Black, 48 | 134 | 79 | 0.59 |
| 10 | 2011 | 755 | Road-450 Red, 60 | 79 | 47 | 0.59 |
| 10 | 2011 | 763 | Road-650 Red, 48 | 120 | 68 | 0.57 |
| 10 | 2011 | 775 | Mountain-100 Black, 38 | 145 | 82 | 0.57 |
| 10 | 2011 | 761 | Road-650 Red, 62 | 129 | 73 | 0.57 |
| 10 | 2011 | 760 | Road-650 Red, 60 | 154 | 88 | 0.57 |
| 10 | 2011 | 756 | Road-450 Red, 44 | 82 | 46 | 0.56 |
| 10 | 2011 | 758 | Road-450 Red, 52 | 157 | 87 | 0.55 |
| 10 | 2011 | 774 | Mountain-100 Silver, 48 | 123 | 68 | 0.55 |
| 10 | 2011 | 776 | Mountain-100 Black, 42 | 140 | 76 | 0.54 |
| 10 | 2011 | 773 | Mountain-100 Silver, 44 | 132 | 70 | 0.53 |
| 10 | 2011 | 742 | HL Mountain Frame - Silver, 46 | 32 | 17 | 0.53 |
| 10 | 2011 | 762 | Road-650 Red, 44 | 156 | 64 | 0.41 |
| 10 | 2011 | 712 | AWC Logo Cap | 240 |  | 0 |
| 10 | 2011 | 714 | Long-Sleeve Logo Jersey, M | 101 |  | 0 |
| 10 | 2011 | 715 | Long-Sleeve Logo Jersey, L | 239 |  | 0 |
| 10 | 2011 | 709 | Mountain Bike Socks, M | 224 |  | 0 |
| 10 | 2011 | 708 | Sport-100 Helmet, Black | 162 |  | 0 |
| 10 | 2011 | 711 | Sport-100 Helmet, Blue | 181 |  | 0 |
| 10 | 2011 | 710 | Mountain Bike Socks, L | 29 |  | 0 |
| 10 | 2011 | 716 | Long-Sleeve Logo Jersey, XL | 117 |  | 0 |
| 10 | 2011 | 707 | Sport-100 Helmet, Red | 141 |  | 0 |
| 9 | 2011 | 763 | Road-650 Red, 48 | 1 | 41 | 41 |
| 9 | 2011 | 761 | Road-650 Red, 62 | 1 | 34 | 34 |
| 9 | 2011 | 771 | Mountain-100 Silver, 38 | 1 | 25 | 25 |
| 9 | 2011 | 773 | Mountain-100 Silver, 44 | 1 | 24 | 24 |
| 9 | 2011 | 765 | Road-650 Black, 58 | 2 | 43 | 21.5 |
| 9 | 2011 | 760 | Road-650 Red, 60 | 2 | 40 | 20 |
| 9 | 2011 | 762 | Road-650 Red, 44 | 2 | 38 | 19 |
| 9 | 2011 | 775 | Mountain-100 Black, 38 | 2 | 34 | 17 |
| 9 | 2011 | 774 | Mountain-100 Silver, 48 | 2 | 26 | 13 |
| 9 | 2011 | 766 | Road-650 Black, 60 | 3 | 32 | 10.67 |
| 9 | 2011 | 764 | Road-650 Red, 52 | 2 | 21 | 10.5 |
| 9 | 2011 | 776 | Mountain-100 Black, 42 | 3 | 30 | 10 |
| 9 | 2011 | 777 | Mountain-100 Black, 44 | 3 | 26 | 8.67 |
| 9 | 2011 | 767 | Road-650 Black, 62 | 2 | 16 | 8 |
| 9 | 2011 | 778 | Mountain-100 Black, 48 | 7 | 23 | 3.29 |
| 9 | 2011 | 772 | Mountain-100 Silver, 42 | 7 | 20 | 2.86 |
| 9 | 2011 | 753 | Road-150 Red, 56 | 23 | 44 | 1.91 |
| 9 | 2011 | 759 | Road-650 Red, 58 | 4 | 7 | 1.75 |
| 9 | 2011 | 750 | Road-150 Red, 44 | 21 | 35 | 1.67 |
| 9 | 2011 | 749 | Road-150 Red, 62 | 27 | 44 | 1.63 |
| 9 | 2011 | 752 | Road-150 Red, 52 | 18 | 29 | 1.61 |
| 9 | 2011 | 751 | Road-150 Red, 48 | 23 | 35 | 1.52 |
| 8 | 2011 | 744 | HL Mountain Frame - Black, 44 | 3 | 60 | 20 |
| 8 | 2011 | 727 | LL Road Frame - Red, 52 | 1 | 14 | 14 |
| 8 | 2011 | 717 | HL Road Frame - Red, 62 | 5 | 42 | 8.4 |
| 8 | 2011 | 739 | HL Mountain Frame - Silver, 42 | 6 | 49 | 8.17 |
| 8 | 2011 | 736 | LL Road Frame - Black, 44 | 4 | 18 | 4.5 |
| 8 | 2011 | 747 | HL Mountain Frame - Black, 38 | 17 | 69 | 4.06 |
| 8 | 2011 | 718 | HL Road Frame - Red, 44 | 5 | 19 | 3.8 |
| 8 | 2011 | 748 | HL Mountain Frame - Silver, 38 | 21 | 73 | 3.48 |
| 8 | 2011 | 745 | HL Mountain Frame - Black, 48 | 18 | 61 | 3.39 |
| 8 | 2011 | 733 | ML Road Frame - Red, 52 | 17 | 51 | 3 |
| 8 | 2011 | 741 | HL Mountain Frame - Silver, 48 | 24 | 57 | 2.38 |
| 8 | 2011 | 743 | HL Mountain Frame - Black, 42 | 28 | 64 | 2.29 |
| 8 | 2011 | 726 | LL Road Frame - Red, 48 | 18 | 41 | 2.28 |
| 8 | 2011 | 730 | LL Road Frame - Red, 62 | 23 | 44 | 1.91 |
| 8 | 2011 | 729 | LL Road Frame - Red, 60 | 44 | 72 | 1.64 |
| 8 | 2011 | 738 | LL Road Frame - Black, 52 | 44 | 71 | 1.61 |
| 8 | 2011 | 722 | LL Road Frame - Black, 58 | 23 | 34 | 1.48 |
| 8 | 2011 | 725 | LL Road Frame - Red, 44 | 53 | 78 | 1.47 |
| 8 | 2011 | 742 | HL Mountain Frame - Silver, 46 | 21 | 18 | 0.86 |
| 8 | 2011 | 749 | Road-150 Red, 62 | 55 | 44 | 0.8 |
| 8 | 2011 | 771 | Mountain-100 Silver, 38 | 77 | 60 | 0.78 |
| 8 | 2011 | 778 | Mountain-100 Black, 48 | 61 | 46 | 0.75 |
| 8 | 2011 | 772 | Mountain-100 Silver, 42 | 66 | 49 | 0.74 |
| 8 | 2011 | 752 | Road-150 Red, 52 | 33 | 24 | 0.73 |
| 8 | 2011 | 777 | Mountain-100 Black, 44 | 80 | 58 | 0.72 |
| 8 | 2011 | 753 | Road-150 Red, 56 | 66 | 46 | 0.7 |
| 8 | 2011 | 773 | Mountain-100 Silver, 44 | 74 | 50 | 0.68 |
| 8 | 2011 | 776 | Mountain-100 Black, 42 | 69 | 44 | 0.64 |
| 8 | 2011 | 775 | Mountain-100 Black, 38 | 82 | 52 | 0.63 |
| 8 | 2011 | 774 | Mountain-100 Silver, 48 | 61 | 37 | 0.61 |
| 8 | 2011 | 754 | Road-450 Red, 58 | 63 | 37 | 0.59 |
| 8 | 2011 | 750 | Road-150 Red, 44 | 34 | 20 | 0.59 |
| 8 | 2011 | 762 | Road-650 Red, 44 | 86 | 49 | 0.57 |
| 8 | 2011 | 732 | ML Road Frame - Red, 48 | 25 | 14 | 0.56 |
| 8 | 2011 | 758 | Road-450 Red, 52 | 77 | 43 | 0.56 |
| 8 | 2011 | 755 | Road-450 Red, 60 | 49 | 27 | 0.55 |
| 8 | 2011 | 760 | Road-650 Red, 60 | 86 | 47 | 0.55 |
| 8 | 2011 | 756 | Road-450 Red, 44 | 40 | 21 | 0.53 |
| 8 | 2011 | 761 | Road-650 Red, 62 | 69 | 36 | 0.52 |
| 8 | 2011 | 770 | Road-650 Black, 52 | 95 | 48 | 0.51 |
| 8 | 2011 | 751 | Road-150 Red, 48 | 39 | 18 | 0.46 |
| 8 | 2011 | 763 | Road-650 Red, 48 | 74 | 34 | 0.46 |
| 8 | 2011 | 768 | Road-650 Black, 44 | 42 | 17 | 0.4 |
| 8 | 2011 | 764 | Road-650 Red, 52 | 35 | 14 | 0.4 |
| 8 | 2011 | 765 | Road-650 Black, 58 | 70 | 27 | 0.39 |
| 8 | 2011 | 766 | Road-650 Black, 60 | 49 | 18 | 0.37 |
| 8 | 2011 | 759 | Road-650 Red, 58 | 5 | 1 | 0.2 |
| 8 | 2011 | 767 | Road-650 Black, 62 | 16 | 2 | 0.13 |
| 8 | 2011 | 757 | Road-450 Red, 48 | 9 |  | 0 |
| 8 | 2011 | 716 | Long-Sleeve Logo Jersey, XL | 65 |  | 0 |
| 8 | 2011 | 709 | Mountain Bike Socks, M | 167 |  | 0 |
| 8 | 2011 | 708 | Sport-100 Helmet, Black | 86 |  | 0 |
| 8 | 2011 | 712 | AWC Logo Cap | 137 |  | 0 |
| 8 | 2011 | 711 | Sport-100 Helmet, Blue | 75 |  | 0 |
| 8 | 2011 | 714 | Long-Sleeve Logo Jersey, M | 65 |  | 0 |
| 8 | 2011 | 710 | Mountain Bike Socks, L | 19 |  | 0 |
| 8 | 2011 | 707 | Sport-100 Helmet, Red | 96 |  | 0 |
| 8 | 2011 | 769 | Road-650 Black, 48 | 19 |  | 0 |
| 8 | 2011 | 715 | Long-Sleeve Logo Jersey, L | 113 |  | 0 |
| 7 | 2011 | 733 | ML Road Frame - Red, 52 | 8 | 78 | 9.75 |
| 7 | 2011 | 743 | HL Mountain Frame - Black, 42 | 13 | 91 | 7 |
| 7 | 2011 | 747 | HL Mountain Frame - Black, 38 | 14 | 85 | 6.07 |
| 7 | 2011 | 730 | LL Road Frame - Red, 62 | 13 | 75 | 5.77 |
| 7 | 2011 | 748 | HL Mountain Frame - Silver, 38 | 20 | 96 | 4.8 |
| 7 | 2011 | 745 | HL Mountain Frame - Black, 48 | 19 | 83 | 4.37 |
| 7 | 2011 | 741 | HL Mountain Frame - Silver, 48 | 14 | 58 | 4.14 |
| 7 | 2011 | 726 | LL Road Frame - Red, 48 | 19 | 73 | 3.84 |
| 7 | 2011 | 722 | LL Road Frame - Black, 58 | 20 | 67 | 3.35 |
| 7 | 2011 | 738 | LL Road Frame - Black, 52 | 39 | 126 | 3.23 |
| 7 | 2011 | 725 | LL Road Frame - Red, 44 | 38 | 104 | 2.74 |
| 7 | 2011 | 729 | LL Road Frame - Red, 60 | 41 | 112 | 2.73 |
| 7 | 2011 | 751 | Road-150 Red, 48 | 18 | 34 | 1.89 |
| 7 | 2011 | 750 | Road-150 Red, 44 | 15 | 17 | 1.13 |
| 7 | 2011 | 773 | Mountain-100 Silver, 44 | 57 | 62 | 1.09 |
| 7 | 2011 | 764 | Road-650 Red, 52 | 15 | 16 | 1.07 |
| 7 | 2011 | 774 | Mountain-100 Silver, 48 | 42 | 44 | 1.05 |
| 7 | 2011 | 765 | Road-650 Black, 58 | 47 | 49 | 1.04 |
| 7 | 2011 | 772 | Mountain-100 Silver, 42 | 57 | 59 | 1.04 |
| 7 | 2011 | 762 | Road-650 Red, 44 | 64 | 66 | 1.03 |
| 7 | 2011 | 777 | Mountain-100 Black, 44 | 66 | 68 | 1.03 |
| 7 | 2011 | 761 | Road-650 Red, 62 | 61 | 62 | 1.02 |
| 7 | 2011 | 768 | Road-650 Black, 44 | 19 | 19 | 1 |
| 7 | 2011 | 756 | Road-450 Red, 44 | 21 | 21 | 1 |
| 7 | 2011 | 763 | Road-650 Red, 48 | 54 | 54 | 1 |
| 7 | 2011 | 732 | ML Road Frame - Red, 48 | 26 | 26 | 1 |
| 7 | 2011 | 775 | Mountain-100 Black, 38 | 71 | 71 | 1 |
| 7 | 2011 | 742 | HL Mountain Frame - Silver, 46 | 15 | 15 | 1 |
| 7 | 2011 | 754 | Road-450 Red, 58 | 54 | 54 | 1 |
| 7 | 2011 | 758 | Road-450 Red, 52 | 72 | 72 | 1 |
| 7 | 2011 | 755 | Road-450 Red, 60 | 22 | 22 | 1 |
| 7 | 2011 | 760 | Road-650 Red, 60 | 71 | 70 | 0.99 |
| 7 | 2011 | 778 | Mountain-100 Black, 48 | 64 | 63 | 0.98 |
| 7 | 2011 | 770 | Road-650 Black, 52 | 88 | 86 | 0.98 |
| 7 | 2011 | 776 | Mountain-100 Black, 42 | 81 | 77 | 0.95 |
| 7 | 2011 | 771 | Mountain-100 Silver, 38 | 81 | 76 | 0.94 |
| 7 | 2011 | 766 | Road-650 Black, 60 | 17 | 16 | 0.94 |
| 7 | 2011 | 753 | Road-150 Red, 56 | 61 | 55 | 0.9 |
| 7 | 2011 | 752 | Road-150 Red, 52 | 21 | 15 | 0.71 |
| 7 | 2011 | 749 | Road-150 Red, 62 | 41 | 29 | 0.71 |
| 7 | 2011 | 767 | Road-650 Black, 62 | 2 | 1 | 0.5 |
| 7 | 2011 | 711 | Sport-100 Helmet, Blue | 64 |  | 0 |
| 7 | 2011 | 708 | Sport-100 Helmet, Black | 56 |  | 0 |
| 7 | 2011 | 712 | AWC Logo Cap | 103 |  | 0 |
| 7 | 2011 | 714 | Long-Sleeve Logo Jersey, M | 37 |  | 0 |
| 7 | 2011 | 715 | Long-Sleeve Logo Jersey, L | 114 |  | 0 |
| 7 | 2011 | 710 | Mountain Bike Socks, L | 13 |  | 0 |
| 7 | 2011 | 759 | Road-650 Red, 58 | 1 |  | 0 |
| 7 | 2011 | 709 | Mountain Bike Socks, M | 134 |  | 0 |
| 7 | 2011 | 707 | Sport-100 Helmet, Red | 58 |  | 0 |
| 7 | 2011 | 716 | Long-Sleeve Logo Jersey, XL | 48 |  | 0 |
| 6 | 2011 | 762 | Road-650 Red, 44 | 2 | 44 | 22 |
| 6 | 2011 | 763 | Road-650 Red, 48 | 1 | 20 | 20 |
| 6 | 2011 | 761 | Road-650 Red, 62 | 1 | 19 | 19 |
| 6 | 2011 | 776 | Mountain-100 Black, 42 | 1 | 16 | 16 |
| 6 | 2011 | 770 | Road-650 Black, 52 | 2 | 29 | 14.5 |
| 6 | 2011 | 765 | Road-650 Black, 58 | 3 | 31 | 10.33 |
| 6 | 2011 | 764 | Road-650 Red, 52 | 2 | 15 | 7.5 |
| 6 | 2011 | 775 | Mountain-100 Black, 38 | 3 | 22 | 7.33 |
| 6 | 2011 | 778 | Mountain-100 Black, 48 | 3 | 21 | 7 |
| 6 | 2011 | 768 | Road-650 Black, 44 | 2 | 13 | 6.5 |
| 6 | 2011 | 777 | Mountain-100 Black, 44 | 6 | 23 | 3.83 |
| 6 | 2011 | 773 | Mountain-100 Silver, 44 | 6 | 18 | 3 |
| 6 | 2011 | 771 | Mountain-100 Silver, 38 | 4 | 11 | 2.75 |
| 6 | 2011 | 774 | Mountain-100 Silver, 48 | 3 | 8 | 2.67 |
| 6 | 2011 | 772 | Mountain-100 Silver, 42 | 2 | 5 | 2.5 |
| 6 | 2011 | 767 | Road-650 Black, 62 | 1 | 2 | 2 |
| 6 | 2011 | 753 | Road-150 Red, 56 | 15 | 21 | 1.4 |
| 6 | 2011 | 749 | Road-150 Red, 62 | 21 | 13 | 0.62 |
| 6 | 2011 | 750 | Road-150 Red, 44 | 23 | 10 | 0.43 |
| 6 | 2011 | 752 | Road-150 Red, 52 | 12 | 4 | 0.33 |
| 6 | 2011 | 751 | Road-150 Red, 48 | 28 | 4 | 0.14 |
| 5 | 2011 | 745 | HL Mountain Frame - Black, 48 | 1 |  | 0 |
| 5 | 2011 | 714 | Long-Sleeve Logo Jersey, M | 16 |  | 0 |
| 5 | 2011 | 707 | Sport-100 Helmet, Red | 24 |  | 0 |
| 5 | 2011 | 755 | Road-450 Red, 60 | 11 |  | 0 |
| 5 | 2011 | 748 | HL Mountain Frame - Silver, 38 | 2 |  | 0 |
| 5 | 2011 | 773 | Mountain-100 Silver, 44 | 17 |  | 0 |
| 5 | 2011 | 749 | Road-150 Red, 62 | 4 |  | 0 |
| 5 | 2011 | 758 | Road-450 Red, 52 | 46 |  | 0 |
| 5 | 2011 | 747 | HL Mountain Frame - Black, 38 | 4 |  | 0 |
| 5 | 2011 | 777 | Mountain-100 Black, 44 | 23 |  | 0 |
| 5 | 2011 | 761 | Road-650 Red, 62 | 19 |  | 0 |
| 5 | 2011 | 766 | Road-650 Black, 60 | 11 |  | 0 |
| 5 | 2011 | 722 | LL Road Frame - Black, 58 | 8 |  | 0 |
| 5 | 2011 | 710 | Mountain Bike Socks, L | 5 |  | 0 |
| 5 | 2011 | 715 | Long-Sleeve Logo Jersey, L | 49 |  | 0 |
| 5 | 2011 | 716 | Long-Sleeve Logo Jersey, XL | 19 |  | 0 |
| 5 | 2011 | 760 | Road-650 Red, 60 | 43 |  | 0 |
| 5 | 2011 | 776 | Mountain-100 Black, 42 | 16 |  | 0 |
| 5 | 2011 | 774 | Mountain-100 Silver, 48 | 7 |  | 0 |
| 5 | 2011 | 729 | LL Road Frame - Red, 60 | 16 |  | 0 |
| 5 | 2011 | 762 | Road-650 Red, 44 | 44 |  | 0 |
| 5 | 2011 | 741 | HL Mountain Frame - Silver, 48 | 2 |  | 0 |
| 5 | 2011 | 763 | Road-650 Red, 48 | 20 |  | 0 |
| 5 | 2011 | 738 | LL Road Frame - Black, 52 | 19 |  | 0 |
| 5 | 2011 | 711 | Sport-100 Helmet, Blue | 33 |  | 0 |
| 5 | 2011 | 712 | AWC Logo Cap | 40 |  | 0 |
| 5 | 2011 | 778 | Mountain-100 Black, 48 | 20 |  | 0 |
| 5 | 2011 | 754 | Road-450 Red, 58 | 27 |  | 0 |
| 5 | 2011 | 730 | LL Road Frame - Red, 62 | 14 |  | 0 |
| 5 | 2011 | 726 | LL Road Frame - Red, 48 | 9 |  | 0 |
| 5 | 2011 | 743 | HL Mountain Frame - Black, 42 | 1 |  | 0 |
| 5 | 2011 | 709 | Mountain Bike Socks, M | 38 |  | 0 |
| 5 | 2011 | 733 | ML Road Frame - Red, 52 | 4 |  | 0 |
| 5 | 2011 | 775 | Mountain-100 Black, 38 | 22 |  | 0 |
| 5 | 2011 | 764 | Road-650 Red, 52 | 14 |  | 0 |
| 5 | 2011 | 771 | Mountain-100 Silver, 38 | 10 |  | 0 |
| 5 | 2011 | 772 | Mountain-100 Silver, 42 | 5 |  | 0 |
| 5 | 2011 | 753 | Road-150 Red, 56 | 14 |  | 0 |
| 5 | 2011 | 768 | Road-650 Black, 44 | 13 |  | 0 |
| 5 | 2011 | 708 | Sport-100 Helmet, Black | 27 |  | 0 |
| 5 | 2011 | 770 | Road-650 Black, 52 | 29 |  | 0 |
| 5 | 2011 | 742 | HL Mountain Frame - Silver, 46 | 3 |  | 0 |
| 5 | 2011 | 725 | LL Road Frame - Red, 44 | 15 |  | 0 |
| 5 | 2011 | 756 | Road-450 Red, 44 | 14 |  | 0 |
| 5 | 2011 | 732 | ML Road Frame - Red, 48 | 16 |  | 0 |
| 5 | 2011 | 765 | Road-650 Black, 58 | 30 |  | 0 |
| 5 | 2011 | 767 | Road-650 Black, 62 | 1 |  | 0 |
|  |  |  |  |  | 279 |  |
|  |  |  |  |  | 150 |  |
|  |  |  |  |  | 12 |  |
|  |  |  |  |  | 514 |  |
|  |  |  |  |  | 33 |  |
|  |  |  |  |  | 659 |  |
|  |  |  |  |  | 885 |  |
|  |  |  |  |  | 21 |  |
|  |  |  |  |  | 514 |  |
|  |  |  |  |  | 439 |  |
|  |  |  |  |  | 45 |  |
|  |  |  |  |  | 53 |  |
|  |  |  |  |  | 22 |  |
|  |  |  |  |  | 1044 |  |
|  |  |  |  |  | 719 |  |
|  |  |  |  |  | 1528 |  |
|  |  |  |  |  | 55 |  |
|  |  |  |  |  | 1061 |  |
|  |  |  |  |  | 1455 |  |
|  |  |  |  |  | 18 |  |
|  |  |  |  |  | 640 |  |
|  |  |  |  |  | 1061 |  |
|  |  |  |  |  | 848 |  |
|  |  |  |  |  | 2382 |  |
|  |  |  |  |  | 395 |  |
|  |  |  |  |  | 57 |  |
|  |  |  |  |  | 32 |  |
|  |  |  |  |  | 110 |  |
|  |  |  |  |  | 407 |  |
|  |  |  |  |  | 1767 |  |
|  |  |  |  |  | 59 |  |
|  |  |  |  |  | 1278 |  |
|  |  |  |  |  | 1583 |  |
|  |  |  |  |  | 207 |  |
|  |  |  |  |  | 21 |  |
|  |  |  |  |  | 1061 |  |
|  |  |  |  |  | 204 |  |
|  |  |  |  |  | 721 |  |
|  |  |  |  |  | 396 |  |
|  |  |  |  |  | 483 |  |
|  |  |  |  |  | 9340 |  |
|  |  |  |  |  | 652 |  |
|  |  |  |  |  | 113 |  |
|  |  |  |  |  | 1061 |  |
|  |  |  |  |  | 383 |  |
|  |  |  |  |  | 1165 |  |
|  |  |  |  |  | 44 |  |
|  |  |  |  |  | 118 |  |
|  |  |  |  |  | 19 |  |
|  |  |  |  |  | 169 |  |
|  |  |  |  |  | 885 |  |
|  |  |  |  |  | 2122 |  |
|  |  |  |  |  | 217 |  |
|  |  |  |  |  | 27 |  |
|  |  |  |  |  | 128 |  |
|  |  |  |  |  | 90 |  |
|  |  |  |  |  | 8475 |  |
|  |  |  |  |  | 44 |  |
|  |  |  |  |  | 98 |  |
|  |  |  |  |  | 207 |  |
|  |  |  |  |  | 4670 |  |
|  |  |  |  |  | 3598 |  |
|  |  |  |  |  | 2 |  |
|  |  |  |  |  | 169 |  |
|  |  |  |  |  | 1061 |  |
|  |  |  |  |  | 2122 |  |
|  |  |  |  |  | 435 |  |
|  |  |  |  |  | 1191 |  |
|  |  |  |  |  | 719 |  |
|  |  |  |  |  | 17 |  |
|  |  |  |  |  | 27 |  |
|  |  |  |  |  | 659 |  |
|  |  |  |  |  | 65 |  |
|  |  |  |  |  | 43 |  |
|  |  |  |  |  | 1918 |  |
|  |  |  |  |  | 59 |  |
|  |  |  |  |  | 878 |  |
|  |  |  |  |  | 291 |  |
|  |  |  |  |  | 36 |  |
|  |  |  |  |  | 5259 |  |
|  |  |  |  |  | 362 |  |
|  |  |  |  |  | 41 |  |
|  |  |  |  |  | 16 |  |
|  |  |  |  |  | 439 |  |
|  |  |  |  |  | 9 |  |
|  |  |  |  |  | 20 |  |
|  |  |  |  |  | 26 |  |
|  |  |  |  |  | 640 |  |
|  |  |  |  |  | 861 |  |
|  |  |  |  |  | 4764 |  |
|  |  |  |  |  | 3598 |  |
|  |  |  |  |  | 26 |  |
|  |  |  |  |  | 396 |  |
|  |  |  |  |  | 45 |  |
|  |  |  |  |  | 1061 |  |
|  |  |  |  |  | 3682 |  |
|  |  |  |  |  | 848 |  |
|  |  |  |  |  | 152 |  |
|  |  |  |  |  | 534 |  |
|  |  |  |  |  | 5 |  |
|  |  |  |  |  | 128 |  |
|  |  |  |  |  | 479 |  |
|  |  |  |  |  | 2122 |  |
|  |  |  |  |  | 861 |  |
|  |  |  |  |  | 426 |  |
|  |  |  |  |  | 20 |  |
|  |  |  |  |  | 2335 |  |
|  |  |  |  |  | 2335 |  |
|  |  |  |  |  | 1842 |  |
|  |  |  |  |  | 291 |  |
|  |  |  |  |  | 1 |  |
|  |  |  |  |  | 1918 |  |
|  |  |  |  |  | 44 |  |
|  |  |  |  |  | 34 |  |
|  |  |  |  |  | 71 |  |
|  |  |  |  |  | 370 |  |
|  |  |  |  |  | 152 |  |
|  |  |  |  |  | 3 |  |
|  |  |  |  |  | 23 |  |
|  |  |  |  |  | 32 |  |
|  |  |  |  |  | 1280 |  |
|  |  |  |  |  | 16 |  |
|  |  |  |  |  | 640 |  |
|  |  |  |  |  | 23 |  |
|  |  |  |  |  | 98 |  |
|  |  |  |  |  | 483 |  |
|  |  |  |  |  | 26 |  |
|  |  |  |  |  | 659 |  |
|  |  |  |  |  | 19175 |  |
|  |  |  |  |  | 874 |  |
|  |  |  |  |  | 435 |  |
|  |  |  |  |  | 1440 |  |
|  |  |  |  |  | 483 |  |
|  |  |  |  |  | 3 |  |
|  |  |  |  |  | 938 |  |
|  |  |  |  |  | 753 |  |
|  |  |  |  |  | 479 |  |
|  |  |  |  |  | 52 |  |
|  |  |  |  |  | 322 |  |
|  |  |  |  |  | 921 |  |
|  |  |  |  |  | 13 |  |
|  |  |  |  |  | 13 |  |
|  |  |  |  |  | 46 |  |
|  |  |  |  |  | 98 |  |
|  |  |  |  |  | 36 |  |
|  |  |  |  |  | 19 |  |
|  |  |  |  |  | 31 |  |
|  |  |  |  |  | 187 |  |
|  |  |  |  |  | 408 |  |
|  |  |  |  |  | 293 |  |
|  |  |  |  |  | 679 |  |
|  |  |  |  |  | 14544 |  |
|  |  |  |  |  | 27 |  |
|  |  |  |  |  | 30 |  |
|  |  |  |  |  | 1 |  |
|  |  |  |  |  | 640 |  |
|  |  |  |  |  | 369 |  |
|  |  |  |  |  | 1648 |  |
|  |  |  |  |  | 55 |  |
|  |  |  |  |  | 608 |  |
|  |  |  |  |  | 345 |  |
|  |  |  |  |  | 77 |  |
|  |  |  |  |  | 19 |  |
|  |  |  |  |  | 4670 |  |
|  |  |  |  |  | 1541 |  |
|  |  |  |  |  | 670 |  |
|  |  |  |  |  | 1348 |  |
|  |  |  |  |  | 293 |  |
|  |  |  |  |  | 3598 |  |
|  |  |  |  |  | 291 |  |
|  |  |  |  |  | 169 |  |
|  |  |  |  |  | 938 |  |
|  |  |  |  |  | 426 |  |
|  |  |  |  |  | 1191 |  |
|  |  |  |  |  | 11 |  |
|  |  |  |  |  | 279 |  |
|  |  |  |  |  | 123 |  |
|  |  |  |  |  | 293 |  |
|  |  |  |  |  | 28 |  |
|  |  |  |  |  | 59 |  |
|  |  |  |  |  | 609 |  |
|  |  |  |  |  | 54 |  |
|  |  |  |  |  | 1918 |  |
|  |  |  |  |  | 29 |  |
|  |  |  |  |  | 1282 |  |
|  |  |  |  |  | 969 |  |
|  |  |  |  |  | 483 |  |
|  |  |  |  |  | 16 |  |
|  |  |  |  |  | 236 |  |
|  |  |  |  |  | 1799 |  |
|  |  |  |  |  | 980 |  |
|  |  |  |  |  | 52 |  |
|  |  |  |  |  | 15 |  |
|  |  |  |  |  | 110 |  |
|  |  |  |  |  | 23 |  |
|  |  |  |  |  | 520 |  |
|  |  |  |  |  | 640 |  |
|  |  |  |  |  | 479 |  |
|  |  |  |  |  | 325 |  |
|  |  |  |  |  | 55 |  |
|  |  |  |  |  | 792 |  |
|  |  |  |  |  | 526 |  |
|  |  |  |  |  | 49 |  |
|  |  |  |  |  | 43 |  |
|  |  |  |  |  | 1936 |  |
|  |  |  |  |  | 189 |  |
|  |  |  |  |  | 33 |  |
|  |  |  |  |  | 1040 |  |
|  |  |  |  |  | 37 |  |
|  |  |  |  |  | 30 |  |
|  |  |  |  |  | 15 |  |
|  |  |  |  |  | 169 |  |
|  |  |  |  |  | 1280 |  |
|  |  |  |  |  | 8845 |  |
|  |  |  |  |  | 650 |  |
|  |  |  |  |  | 1024 |  |
|  |  |  |  |  | 501 |  |
|  |  |  |  |  | 594 |  |
|  |  |  |  |  | 1191 |  |
|  |  |  |  |  | 1382 |  |
|  |  |  |  |  | 1455 |  |
|  |  |  |  |  | 427 |  |
|  |  |  |  |  | 369 |  |
|  |  |  |  |  | 1842 |  |
|  |  |  |  |  | 497 |  |
|  |  |  |  |  | 176 |  |
|  |  |  |  |  | 81 |  |
|  |  |  |  |  | 113 |  |
|  |  |  |  |  | 526 |  |
|  |  |  |  |  | 980 |  |
|  |  |  |  |  | 59 |  |
|  |  |  |  |  | 25 |  |
|  |  |  |  |  | 207 |  |
|  |  |  |  |  | 426 |  |
|  |  |  |  |  | 974 |  |
|  |  |  |  |  | 78 |  |
|  |  |  |  |  | 169 |  |
|  |  |  |  |  | 1064 |  |
|  |  |  |  |  | 415 |  |
|  |  |  |  |  | 316 |  |
|  |  |  |  |  | 18 |  |
|  |  |  |  |  | 967 |  |
|  |  |  |  |  | 1583 |  |
|  |  |  |  |  | 249 |  |
|  |  |  |  |  | 19 |  |
|  |  |  |  |  | 71 |  |
|  |  |  |  |  | 82 |  |
|  |  |  |  |  | 34 |  |
|  |  |  |  |  | 2335 |  |
|  |  |  |  |  | 2522 |  |
|  |  |  |  |  | 113 |  |
|  |  |  |  |  | 72 |  |
|  |  |  |  |  | 128 |  |
|  |  |  |  |  | 110 |  |
|  |  |  |  |  | 395 |  |
|  |  |  |  |  | 921 |  |
|  |  |  |  |  | 227 |  |
|  |  |  |  |  | 608 |  |
|  |  |  |  |  | 2560 |  |
|  |  |  |  |  | 51 |  |
|  |  |  |  |  | 520 |  |
|  |  |  |  |  | 921 |  |
|  |  |  |  |  | 1142 |  |
|  |  |  |  |  | 2 |  |
|  |  |  |  |  | 52 |  |
|  |  |  |  |  | 395 |  |
|  |  |  |  |  | 1191 |  |
|  |  |  |  |  | 47 |  |
|  |  |  |  |  | 15 |  |
|  |  |  |  |  | 176 |  |
|  |  |  |  |  | 76 |  |
|  |  |  |  |  | 19 |  |
|  |  |  |  |  | 42 |  |
|  |  |  |  |  | 217 |  |
|  |  |  |  |  | 293 |  |
|  |  |  |  |  | 14 |  |
|  |  |  |  |  | 36 |  |
|  |  |  |  |  | 78 |  |
|  |  |  |  |  | 921 |  |
|  |  |  |  |  | 236 |  |
|  |  |  |  |  | 1799 |  |
|  |  |  |  |  | 19 |  |
|  |  |  |  |  | 1314 |  |
|  |  |  |  |  | 33 |  |
|  |  |  |  |  | 689 |  |
|  |  |  |  |  | 11 |  |
|  |  |  |  |  | 128 |  |
|  |  |  |  |  | 4243 |  |
|  |  |  |  |  | 439 |  |
|  |  |  |  |  | 22 |  |
|  |  |  |  |  | 150 |  |
|  |  |  |  |  | 514 |  |
|  |  |  |  |  | 1799 |  |
|  |  |  |  |  | 22 |  |
|  |  |  |  |  | 14 |  |
|  |  |  |  |  | 150 |  |
|  |  |  |  |  | 670 |  |
|  |  |  |  |  | 152 |  |
|  |  |  |  |  | 719 |  |
|  |  |  |  |  | 29 |  |
|  |  |  |  |  | 118 |  |
|  |  |  |  |  | 409 |  |
|  |  |  |  |  | 56 |  |
|  |  |  |  |  | 33 |  |
|  |  |  |  |  | 124 |  |
|  |  |  |  |  | 227 |  |
|  |  |  |  |  | 110 |  |
|  |  |  |  |  | 20 |  |
|  |  |  |  |  | 325 |  |
|  |  |  |  |  | 124 |  |
|  |  |  |  |  | 70 |  |
|  |  |  |  |  | 276 |  |
|  |  |  |  |  | 1799 |  |
|  |  |  |  |  | 3166 |  |
|  |  |  |  |  | 28 |  |
|  |  |  |  |  | 967 |  |
|  |  |  |  |  | 1191 |  |
|  |  |  |  |  | 14 |  |
|  |  |  |  |  | 98 |  |
|  |  |  |  |  | 47 |  |
|  |  |  |  |  | 738 |  |
|  |  |  |  |  | 322 |  |
|  |  |  |  |  | 1799 |  |
|  |  |  |  |  | 21 |  |
|  |  |  |  |  | 26 |  |
|  |  |  |  |  | 1257 |  |
|  |  |  |  |  | 187 |  |
|  |  |  |  |  | 152 |  |
|  |  |  |  |  | 50 |  |
|  |  |  |  |  | 90 |  |
|  |  |  |  |  | 46 |  |
|  |  |  |  |  | 55 |  |
|  |  |  |  |  | 279 |  |
|  |  |  |  |  | 2454 |  |
|  |  |  |  |  | 7195 |  |
|  |  |  |  |  | 150 |  |
|  |  |  |  |  | 33 |  |
|  |  |  |  |  | 3166 |  |
|  |  |  |  |  | 33 |  |
|  |  |  |  |  | 81 |  |
|  |  |  |  |  | 659 |  |
|  |  |  |  |  | 203 |  |
|  |  |  |  |  | 53 |  |
|  |  |  |  |  | 721 |  |
|  |  |  |  |  | 33 |  |
|  |  |  |  |  | 15 |  |
|  |  |  |  |  | 14 |  |
|  |  |  |  |  | 15 |  |
|  |  |  |  |  | 21 |  |
|  |  |  |  |  | 7 |  |
|  |  |  |  |  | 256 |  |
|  |  |  |  |  | 97 |  |
|  |  |  |  |  | 19 |  |
|  |  |  |  |  | 62 |  |
|  |  |  |  |  | 187 |  |
|  |  |  |  |  | 874 |  |
|  |  |  |  |  | 588 |  |
|  |  |  |  |  | 34 |  |
|  |  |  |  |  | 322 |  |
|  |  |  |  |  | 51 |  |
|  |  |  |  |  | 9 |  |
|  |  |  |  |  | 29 |  |
|  |  |  |  |  | 3166 |  |
|  |  |  |  |  | 227 |  |
|  |  |  |  |  | 227 |  |
|  |  |  |  |  | 27 |  |
|  |  |  |  |  | 202 |  |
|  |  |  |  |  | 441 |  |
|  |  |  |  |  | 217 |  |
|  |  |  |  |  | 1583 |  |
|  |  |  |  |  | 110 |  |
|  |  |  |  |  | 9666 |  |
|  |  |  |  |  | 236 |  |
|  |  |  |  |  | 32 |  |
|  |  |  |  |  | 792 |  |
|  |  |  |  |  | 22 |  |
|  |  |  |  |  | 548 |  |
|  |  |  |  |  | 54 |  |
|  |  |  |  |  | 59 |  |
|  |  |  |  |  | 10 |  |
|  |  |  |  |  | 52 |  |
|  |  |  |  |  | 291 |  |
|  |  |  |  |  | 208 |  |
|  |  |  |  |  | 17 |  |
|  |  |  |  |  | 43 |  |
|  |  |  |  |  | 223 |  |
|  |  |  |  |  | 207 |  |
|  |  |  |  |  | 187 |  |
|  |  |  |  |  | 322 |  |
|  |  |  |  |  | 78 |  |
|  |  |  |  |  | 41 |  |
|  |  |  |  |  | 396 |  |
|  |  |  |  |  | 2270 |  |
|  |  |  |  |  | 856 |  |
|  |  |  |  |  | 308 |  |
|  |  |  |  |  | 938 |  |
|  |  |  |  |  | 2335 |  |
|  |  |  |  |  | 1842 |  |
|  |  |  |  |  | 689 |  |
|  |  |  |  |  | 439 |  |
|  |  |  |  |  | 125 |  |
|  |  |  |  |  | 1918 |  |
|  |  |  |  |  | 501 |  |
|  |  |  |  |  | 26 |  |
|  |  |  |  |  | 92 |  |
|  |  |  |  |  | 640 |  |
|  |  |  |  |  | 23 |  |
|  |  |  |  |  | 2382 |  |
|  |  |  |  |  | 176 |  |
|  |  |  |  |  | 16 |  |
|  |  |  |  |  | 1886 |  |
|  |  |  |  |  | 458 |  |
|  |  |  |  |  | 1346 |  |
|  |  |  |  |  | 689 |  |
|  |  |  |  |  | 7 |  |
|  |  |  |  |  | 291 |  |
|  |  |  |  |  | 204 |  |
|  |  |  |  |  | 209 |  |
|  |  |  |  |  | 921 |  |
|  |  |  |  |  | 10 |  |
|  |  |  |  |  | 121 |  |
|  |  |  |  |  | 130 |  |
|  |  |  |  |  | 2335 |  |
|  |  |  |  |  | 1032 |  |
|  |  |  |  |  | 40 |  |
|  |  |  |  |  | 68 |  |
|  |  |  |  |  | 26 |  |
|  |  |  |  |  | 689 |  |
|  |  |  |  |  | 2341 |  |
|  |  |  |  |  | 6332 |  |
|  |  |  |  |  | 11 |  |
|  |  |  |  |  | 30 |  |
|  |  |  |  |  | 87 |  |
|  |  |  |  |  | 64 |  |
|  |  |  |  |  | 520 |  |
|  |  |  |  |  | 8 |  |
|  |  |  |  |  | 113 |  |
|  |  |  |  |  | 59 |  |
|  |  |  |  |  | 37 |  |
|  |  |  |  |  | 113 |  |
|  |  |  |  |  | 921 |  |
|  |  |  |  |  | 12837 |  |
|  |  |  |  |  | 926 |  |
|  |  |  |  |  | 48 |  |
|  |  |  |  |  | 37 |  |
|  |  |  |  |  | 670 |  |
|  |  |  |  |  | 18 |  |
|  |  |  |  |  | 548 |  |
|  |  |  |  |  | 514 |  |
|  |  |  |  |  | 1583 |  |
|  |  |  |  |  | 124 |  |
|  |  |  |  |  | 396 |  |
|  |  |  |  |  | 29 |  |
|  |  |  |  |  | 293 |  |
|  |  |  |  |  | 11 |  |
|  |  |  |  |  | 520 |  |
|  |  |  |  |  | 1583 |  |
|  |  |  |  |  | 203 |  |
|  |  |  |  |  | 1280 |  |
|  |  |  |  |  | 202 |  |
|  |  |  |  |  | 209 |  |
|  |  |  |  |  | 689 |  |
|  |  |  |  |  | 4670 |  |
|  |  |  |  |  | 369 |  |
|  |  |  |  |  | 1284 |  |
|  |  |  |  |  | 98 |  |
|  |  |  |  |  | 217 |  |
|  |  |  |  |  | 208 |  |
|  |  |  |  |  | 33 |  |
|  |  |  |  |  | 1284 |  |
|  |  |  |  |  | 52 |  |
|  |  |  |  |  | 24 |  |
|  |  |  |  |  | 50 |  |
|  |  |  |  |  | 369 |  |
|  |  |  |  |  | 441 |  |
|  |  |  |  |  | 969 |  |
|  |  |  |  |  | 236 |  |
|  |  |  |  |  | 1440 |  |
|  |  |  |  |  | 58 |  |
|  |  |  |  |  | 150 |  |

**📝 Observation:** 
## "Query 08:
```sql
select 
    extract (year from ModifiedDate) as yr
    , Status
    , count(distinct PurchaseOrderID) as order_Cnt 
    , round(sum(TotalDue),2)  as value
from `adventureworks2019.Purchasing.PurchaseOrderHeader`
where Status = 1
and extract(year from ModifiedDate) = 2014
group by 1,2;
```
### ✅ Results:
| yr | Status | order_Cnt | value |
| --- | --- | --- | --- |
| 2014 | 1 | 224 | 3,873,579.01 |

**📝 Observation:** 
