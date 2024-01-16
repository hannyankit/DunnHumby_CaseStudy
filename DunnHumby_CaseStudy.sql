Create database Dunnhumby;



select * from `Dunnhumby.transaction_data` limit 10 ;



------------------------------------------------------------------------------------------------------------------
# Find the number of orders that are small, medium or large order value(small:0-5$, medium:5-10$, large:10+)
----------------------------------------------------------------------------------------------------------------------------

select category , count(distinct basket_id) from (
select *,
      case 
      when cost between 0 and 5 then 'Small'
      when cost between 5 and 10 then 'Medium'
      when cost >= 10 then 'Large'
      end as Category
from (select basket_id , sum(sales_value) as cost from `Dunnhumby.transaction_data` group by 1))
group by 1;

------------------------------------------------------------------------------------------------------------------
# Find week over week top 3 stores with highest foot traffic (Foot traffic: number of households transacting )
----------------------------------------------------------------------------------------------------------------------------


select * from `Dunnhumby.transaction_data` limit 5 ;

with base1 as (
select week_no , STORE_ID ,count(household_key) as foot_traffic
from `Dunnhumby.transaction_data`
group by 1, 2
),
base2 as (
  select * , dense_rank() over (partition by week_no order by base1.foot_traffic desc ) as ranked_store
  from base1
)
select week_no , store_id , base2.foot_traffic
from base2
where ranked_store <= 3
order by week_no asc;



----------------------------------------------------------------------------------------------------------------------------------------------------
# Create a basic Customer profiling with first , last visit week, number of visits,average money spent per visit and total money spent order by highest avg Money.
------------------------------------------------------------------------------------------------------------------------------------------------------------------

select  household_key , 
        min(WEEK_NO) as first_visit,
        max(week_no) as last_visit, 
        count(BASKET_ID) as total_visit , 
        sum(SALES_VALUE * QUANTITY) as total_money ,
        sum(SALES_VALUE * QUANTITY) / count(basket_id) as avg_money
from `Dunnhumby.transaction_data`
group by 1;



------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Do a single customer analysis selecting most spending customer for whom we have demographic information(because not all customers in transaction data are present in demographic table)(show the demographic as well as profiling data)
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

with base as (
    select T.household_key , sum(T.QUANTITY*T.SALES_VALUE) as total_spent 
    from `Dunnhumby.transaction_data` as T
    group by 1
    order by T.household_key asc),
base2 as (
    select distinct B.*, D.* , row_number() over (order by B.total_spent Desc) as Top_C
    from base as B
    join `Dunnhumby.hh_demographics` as D on B.household_key=D.household_key
    order by B.total_spent desc)

select * from base2 
where Top_C <= 3
order by base2.Top_C ASC;



--------------------------------------------------------------------------------------------------------------------------------
# Find products(“product” table, col: “SUB_COMMODITY_DESC”) which are most frequently bought together
------------------------------------------------------------------------------------------------------------------------------------------------

select * from `Dunnhumby.product` limit 10;

with base1 as (
    select P.commodity_desc , T.BASKET_ID
    from `Dunnhumby.product` as P
    inner join `Dunnhumby.transaction_data` as T
    on P.PRODUCT_ID = T.PRODUCT_ID
),
base2 as (
  select  b1.commodity_desc as product1 , b2.commodity_desc as product2 , count(b1.basket_id)
  from base1 as b1
  inner join base1 as b2
  on b1.basket_id = b2.basket_id and b1.commodity_desc < b2.commodity_desc
  group by 1,2
)
select * from base2;

