                                     --data preparation and understanding

--1. What is the total number of rows in each of the 3 tables in the database?

select count (*) as cnt  from CUSTOMER union
select count (*) as cnt  from PROD_CAT_INFO union
select count (*) as cnt  from TRANSACTIONS 


--2. What is the total number of transactions that have a return?

select count (distinct (TRANSACTION_ID)) as total_transaction
from TRANSACTIONS 
where QTY<0

--3. As you would have noticed, the dates provided across the datasets are not in a
--correct format. As first steps, pls convert the date variables into valid date formats
--before proceeding ahead.

select convert(date,tran_date,105) as coverted_date
from TRANSACTIONS

--4. What is the time range of the transaction data available for analysis? Show the
--output in number of days, months and years simultaneously in different columns.

select datediff(year ,min(convert( date , tran_date,105)),max(convert( date , tran_date,105))) as year_range ,
datediff(month ,min(convert( date , tran_date,105)),max(convert( date , tran_date,105))) as month_range ,
datediff(DAY ,min(convert( date , tran_date,105)),max(convert( date , tran_date,105))) as day_range 
from TRANSACTIONS 

select max(convert( date , tran_date,105))
from TRANSACTIONS 

--5. Which product category does the sub-category DIY belong to?

select PROD_CAT, PROD_SUBCAT
from PROD_CAT_INFO
where PROD_SUBCAT = 'diy'

                                            --data analysis 


--1. Which channel is most frequently used for transactions?

select STORE_TYPE, count(STORE_TYPE) as cnt 
from TRANSACTIONS
group by STORE_TYPE
order by cnt desc

--2. What is the count of Male and Female customers in the database?

select gender, count(*) as cnt  
from CUSTOMER 
group by gender

--3. From which city do we have the maximum number of customers and how many?

select top 3 count(CUSTOMER_ID) as cnt  , CITY_CODE 
from CUSTOMER
where CITY_CODE is not null
group by CITY_CODE
order by cnt desc

--4. How many sub-categories are there under the Books category?

select PROD_CAT,PROD_SUBCAT
from PROD_CAT_INFO
where PROD_CAT = 'books'

--5. What is the maximum quantity of products ever ordered?

select PROD_CAT_CODE, max (QTY) as max_quantity
from TRANSACTIONS
group by PROD_CAT_CODE

--6. What is the net total revenue generated in categories Electronics and Books?

select PROD_CAT, sum(TOTAL_AMT) as net_revenue 
from PROD_CAT_INFO as a
left join TRANSACTIONS as b on a.PROD_CAT_CODE  = b.PROD_CAT_CODE and a.PROD_SUB_CAT_CODE = b.PROD_SUBCAT_CODE
where PROD_CAT = 'electronics' or PROD_CAT = 'books'
group by a.PROD_CAT

--7. How many customers have >10 transactions with us, excluding returns?

select  count( distinct (TRANSACTION_ID )) as cnt_transation ,CUST_ID
from TRANSACTIONS 
where QTY>0 
group by CUST_ID
having count( distinct (TRANSACTION_ID )) >10

--8. What is the combined revenue earned from the Electronics & Clothing
--categories, from Flagship stores?

select sum(TOTAL_AMT) as combined_revenue
from(
select PROD_CAT , STORE_TYPE , TOTAL_AMT
from PROD_CAT_INFO as a 
left join TRANSACTIONS as b on a.PROD_CAT_CODE = b.PROD_CAT_CODE and a.PROD_SUB_CAT_CODE = b.PROD_SUBCAT_CODE 
where (PROD_CAT = 'clothing' or PROD_CAT = 'electronics') and STORE_TYPE = 'flagship store' 
) as x 

--9. What is the total revenue generated from Male customers in Electronics¯
--category? Output should display total revenue by prod sub-cat.

select gender,  PROD_SUBCAT, PROD_CAT, sum(TOTAL_AMT) total_rev
from CUSTOMER as a
left join TRANSACTIONS as b on a.CUSTOMER_ID = b.CUST_ID 
left join PROD_CAT_INFO as c on b.PROD_SUBCAT_CODE = c.PROD_SUB_CAT_CODE and b.PROD_CAT_CODE = c.PROD_CAT_CODE
where GENDER = 'm' and PROD_CAT = 'electronics'
group by gender,  PROD_SUBCAT, PROD_CAT

--10. What is percentage of sales and returns by product sub category; display only top
--5 sub categories in terms of sales?

select * 
from (
select top 5 PROD_SUBCAT, ( sum(TOTAL_AMT)  / (select sum(total_amt) from TRANSACTIONS) ) *100 as prec_sales
from PROD_CAT_INFO as a
left join TRANSACTIONS as b on a.PROD_CAT_CODE = b.PROD_CAT_CODE and a.PROD_SUB_CAT_CODE = b.PROD_SUBCAT_CODE 
where TOTAL_AMT>0
group by PROD_SUBCAT
order by prec_sales desc
) as x
left join 
(
select PROD_SUBCAT, ( sum(TOTAL_AMT)  / (select sum(total_amt) from TRANSACTIONS) ) *100 as prec_return
from PROD_CAT_INFO as a
left join TRANSACTIONS as b on a.PROD_CAT_CODE = b.PROD_CAT_CODE and a.PROD_SUB_CAT_CODE = b.PROD_SUBCAT_CODE 
where TOTAL_AMT<0
group by PROD_SUBCAT
) as y on x.PROD_SUBCAT = y.PROD_SUBCAT 

--11. For all customers aged between 25 to 35 years find what is the net total revenue
--generated by these consumers in last 30 days of transactions from max transaction
--date available in the data?


-- customers with 25-30 age 
select *
from(
select * , DATEDIFF(YEAR, convert (date ,DOB,105) , max_date ) as age 
from(
select CUSTOMER_ID, DOB, max (convert(date ,tran_date , 105)) as max_date , sum( TOTAL_AMT ) as revenue
from CUSTOMER as a
join TRANSACTIONS as b on a.CUSTOMER_ID = b.CUST_ID
where TOTAL_AMT>0 
group by CUSTOMER_ID, DOB
) as x 
where DATEDIFF(YEAR, convert (date ,DOB,105) , max_date ) between 25 and 35
) as y 

join 

(
-- customer with last 30 days 
select convert(date,tran_date,105) as tran_date,cust_id
from TRANSACTIONS 
where convert(date,tran_date,105)>= (select  dateadd (day ,-30 ,max(convert(date,tran_date,105))) from TRANSACTIONS )
) as z on y.CUSTOMER_ID = z.CUST_ID


--12. Which product category has seen the max value of returns in the last 3 months of
--transactions?

select top 1 PROD_CAT , sum(returns_) as total_returns
from
(
select PROD_CAT, convert(date,TRAN_DATE ,105) as tran_date , sum(QTY) as returns_
from PROD_CAT_INFO as a
join TRANSACTIONS as b on a.PROD_CAT_CODE = b.PROD_CAT_CODE and a.PROD_SUB_CAT_CODE = b.PROD_SUBCAT_CODE 
where QTY<0
group by PROD_CAT,convert(date,TRAN_DATE ,105)
having convert(date,TRAN_DATE ,105) > ( select DATEADD(month,-3,max (convert(date,TRAN_DATE ,105))) from TRANSACTIONS  )
) as x 
group by PROD_CAT
order by total_returns desc 

--13. Which store-type sells the maximum products; by value of sales amount and by
--quantity sold?

select STORE_TYPE , sum(total_amt ) as sum_amount , sum(qty) as sum_qty
from TRANSACTIONS
where QTY> 0
group by STORE_TYPE
order by sum_amount desc , sum_qty desc

--14. What are the categories for which average revenue is above the overall average.

select PROD_CAT , AVG(total_amt) as avg_rev 
from PROD_CAT_INFO as a 
join TRANSACTIONS as b on a.PROD_CAT_CODE = b.PROD_CAT_CODE and a.PROD_SUB_CAT_CODE = b.PROD_SUBCAT_CODE 
where QTY>0
group by PROD_CAT
having AVG(total_amt) > ( select AVG(total_amt) from TRANSACTIONS where qty>0 )

--15. Find the average and total revenue by each subcategory for the categories which
--are among top 5 categories in terms of quantity sold.

select PROD_SUBCAT, sum(TOTAL_AMT) as rev , AVG(TOTAL_AMT) as avg_
from PROD_CAT_INFO as a
join TRANSACTIONS as b on a.PROD_CAT_CODE = b.PROD_CAT_CODE and a.PROD_SUB_CAT_CODE = b.PROD_SUBCAT_CODE 
where QTY > 0 and PROD_CAT in (select top 5 PROD_CAT 
                               from PROD_CAT_INFO as a
                               join TRANSACTIONS as b on a.PROD_CAT_CODE = b.PROD_CAT_CODE and a.PROD_SUB_CAT_CODE = b.PROD_SUBCAT_CODE 
                                where QTY> 0
                                group by PROD_CAT 
                                 order by sum(QTY) desc)

group by PROD_SUBCAT












