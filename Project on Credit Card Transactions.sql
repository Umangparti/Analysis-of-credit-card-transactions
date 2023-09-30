--Project on Analysing Credit Card Transactions
--Our Data
select * from credit_card_transactions;

--Creating a backup
select * into credit_card_transaction_backup from credit_card_transactions;

--..............................................................................................................
--Exploring the dataset
--Getting only top 5 rows
select top 5* from credit_card_transactions;

--Different Cities we have in our data
select distinct city from credit_card_transactions
order by city;

--Different Types of Credit Card Used we have in our data
select distinct card_type from credit_card_transactions;

--Different Expnediture type we have in our data
select distinct exp_type from credit_card_transactions;

--The duration of our dataset
select min(transaction_date) as minimum_date
,max(transaction_date) as maximum_date
from credit_card_transactions;

--...............................................................................................................
--Cleaning the dataset
--Changing transaction_date datetime into date
alter table credit_card_transactions alter column transaction_date date;

--Finding the Null Values
select * from credit_card_transactions
where transaction_id is null or transaction_date is null or city is null 
or card_type is null or exp_type is null or gender is null or amount is null;

--............................................................................................................
--Extracting Insights
--Q: Query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
select top 5 city
, sum(amount) as credit_card_spends
, sum(amount) * 100/(select sum(amount) from credit_card_transactions) as percentage_contribution
from credit_card_transactions
group by city
order by sum(amount) desc;

--Q: Query to print highest spend month and amount spent in that month for each card type
With A as (select card_type, datepart(year, transaction_date) as transaction_year
, datepart(month, transaction_date) as transaction_month
, sum(amount) as sales
from credit_card_transactions
group by card_type,  datepart(year, transaction_date), datepart(month, transaction_date))
, B as ( Select *, row_number() over( partition by card_type order by sales desc) as part_sales
from A)
select * from B
where part_sales = 1

/*Q: Query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
*/
 with A as (Select *,
sum(amount) over( partition by card_type order by transaction_id) as cumulative_amount
from credit_card_transactions)
select * from (select *, row_number() over(partition by card_type order by cumulative_amount) as rn
from A where cumulative_amount>= 1000000)a where rn = 1

--Q: Query to find city which had lowest percentage spend for gold card type
select top 1 city
, sum(amount) as credit_card_spends
, sum(amount) * 100/(select sum(amount) from credit_card_transactions) as percentage_contribution
from credit_card_transactions
where card_type = 'Gold'
group by city
order by sum(amount) ;

--Q: Query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
 With A as (select city 
,exp_type
, sum(amount) as sum_amount
from credit_card_transactions
group by city, exp_type)
, B as ( Select *, rank()over( partition by city order by sum_amount) as rn_asc
, rank() over( partition by city order by sum_amount desc ) as rn_desc
from A)
Select city
, max( case when rn_asc = 1 then exp_type end) as lowest_expense_type
, min ( case when rn_desc = 1 then exp_type end) as highest_expense_type
from B
group by city

--Q: Query to find percentage contribution of spends by females for each expense type
select exp_type
,sum(case when gender = 'F' then amount else 0 end) * 100/ sum(amount) as spend_amount
from credit_card_transactions
group by exp_type

--Q: Which card and expense type combination saw highest month over month growth in Jan-2014
with A as (select card_type, exp_type
,datepart(year, transaction_date) as transaction_year
,datepart(month, transaction_date) as transaction_month
, sum(amount) as total_transaction
from credit_card_transactions
group by  card_type, exp_type , datepart(year, transaction_date) ,datepart(month, transaction_date))
, B as 
( Select *, lag(total_transaction, 1)  over(partition by card_type, exp_type order by transaction_year, 
transaction_month) as previous_transaction from A)
select top 1 *,
total_transaction - previous_transaction as month_growth
from B
where  transaction_year = 2014 and transaction_month = 1 and previous_transaction is not null
order by month_growth desc

--Q: During weekends which city has highest total spend to total no of transcations ratio 
select top 1 city
, sum(amount) *1/ count(1) as total_ratio
from credit_card_transactions
where datename(weekday, transaction_date) in ('Sunday', 'Saturday')
group by city
order by total_ratio desc ;

--Q: Which city took least number of days to reach its 500th transaction after the first transaction in that city
with A as (select * 
, row_number() over( partition by city order by transaction_date, transaction_id) as rn
from credit_card_transactions)

select top 1 city, datediff(day, min(transaction_date), max(transaction_date)) as no_of_days
 from A
where rn = 1 or rn = 500
group by city
having count(1) = 2
order by no_of_days

--......................................................................................................................
