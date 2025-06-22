--q1
SELECT 
  FORMAT_DATE('%b %Y', sale.ModifiedDate) as period
  , pro.Name as name
  , sum(sale.OrderQty) as qty_item
  , sum(sale.LineTotal) as total_sale
  , count(distinct sale.SalesOrderID) as order_cnt
FROM `adventureworks2019.Sales.SalesOrderDetail` as sale
JOIN `adventureworks2019.Production.Product` as pro
USING (ProductID)
WHERE DATE(sale.ModifiedDate) >= (
    SELECT DATE_SUB(MAX(DATE(sale.ModifiedDate)), INTERVAL 12 MONTH) 
    FROM `adventureworks2019.Sales.SalesOrderDetail`
)
Group by period, pro.Name
order by period;

--q2
with 
sale_info as (
  SELECT 
      FORMAT_TIMESTAMP("%Y", a.ModifiedDate) as yr
      , c.Name
      , sum(a.OrderQty) as qty_item

  FROM `adventureworks2019.Sales.SalesOrderDetail` a 
  LEFT JOIN `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
  LEFT JOIN `adventureworks2019.Production.ProductSubcategory` c on cast(b.ProductSubcategoryID as int) = c.ProductSubcategoryID

  GROUP BY 1,2
  ORDER BY 2 asc , 1 desc
),

sale_diff as (
  select *
  , lead (qty_item) over (partition by Name order by yr desc) as prv_qty
  , round(qty_item / (lead (qty_item) over (partition by Name order by yr desc)) -1,2) as qty_diff
  from sale_info
  order by 5 desc 
),

rk_qty_diff as (
  select *
      ,dense_rank() over( order by qty_diff desc) dk
  from sale_diff
)

select distinct Name
      , qty_item
      , prv_qty
      , qty_diff
from rk_qty_diff 
where dk <=3
order by dk ;


--q3
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

--q4
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


--q5
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

--q6
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

--q7
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
  from 'adventureworks2019.Production.WorkOrder'
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

--q8
SELECT
  2014 AS Year,
  1 AS Status,
  COALESCE(COUNT(DISTINCT PurchaseOrderID), 0) AS Order_Cnt,
  COALESCE(SUM(TotalDue), 0) AS Value
FROM `adventureworks2019.Purchasing.PurchaseOrderHeader`
WHERE Status = 1 AND extract(YEAR from OrderDate) = 2014;

-->
select 
    extract (year from ModifiedDate) as yr
    , Status
    , count(distinct PurchaseOrderID) as order_Cnt 
    , sum(TotalDue) as value
from `adventureworks2019.Purchasing.PurchaseOrderHeader`
where Status = 1
and extract(year from ModifiedDate) = 2014
group by 1,2
;
