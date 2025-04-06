
--Credit card transaction portfolio

select *
from [Basicsql].[dbo].[credit_card_transcations$]

--1. write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 


with Total_amount as (
select sum(cast(amount as bigint)) as Total_credit
from [Basicsql].[dbo].[credit_card_transcations$])
, total_spend as (
select city, sum(amount) as total_spends
from [Basicsql].[dbo].[credit_card_transcations$]
group by city
)

select top 5 S.*,round(1.0*(total_spends/Total_credit)*100,2) as Percentage
from Total_amount A 
inner join total_spend S on 1=1
order by total_spends desc

--2.write a query to print highest spend month and amount spent in that month for each card type

--For each card type, which month is the highest


with Month_part as (
select card_type,datepart(month,transaction_date) as Month, datepart(year,transaction_date) as Year ,sum(amount) as Total
from [Basicsql].[dbo].[credit_card_transcations$]
group by card_type,datepart(month,transaction_date),datepart(year,transaction_date)
--order by card_type,Total desc
)

select * from (
select *,rank()over(partition by card_type order by Total desc) as rnk
from Month_part)A
where rnk=1

--3. write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)


with Cum_sal as
(select *, 
sum(amount) over(partition by card_type order by transaction_date,transaction_id) as Cumulative_salary
--sum(amount) over(partition by card_type order by transaction_date rows between unbounded preceding and current row) as Cumulative_salary
from [Basicsql].[dbo].[credit_card_transcations$])

select * from (select *, rank() over(partition by card_type order by Cumulative_salary) as rnk
from Cum_sal
where Cumulative_salary > 1000000)A
where rnk=1

--4. write a query to find city which had lowest percentage spend for gold card type
--for each city, find the % of gold card comparing with total amount spent for that city. and find which gold % of city is lowest
--gold card/total card for that city

with gold as (
select city,card_type,sum(amount) as amount
,sum(case when card_type='Gold'then amount else 0 end) as gold_amount
from [Basicsql].[dbo].[credit_card_transcations$]
group by city,card_type
)

select top 1 city,1.0*sum(gold_amount)/sum(amount) as gold_percent
from gold
group by city
having sum(gold_amount) <>0
order by gold_percent


--5. write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with Value as (
select city,exp_type,sum(amount) as total
from [Basicsql].[dbo].[credit_card_transcations$]
group by city,exp_type
--order by city,exp_type
)
,rank_order as (
select *,
rank() over(partition by city order by total asc) as rnk_asc,
rank() over(partition by city order by total desc) as rnk_desc
from Value
)

select city,
min(case when rnk_asc=1 then exp_type end) as Min_item,
max(case when rnk_desc=1 then exp_type end) as Max_item
from rank_order
group by city

--6.  write a query to find percentage contribution of spends by females for each expense type

select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_female_contribution
from [Basicsql].[dbo].[credit_card_transcations$]
group by exp_type
order by percentage_female_contribution desc;

--7. which card and expense type combination saw highest month over month growth in Jan-2014

with Month_total as (
select card_type,exp_type,datepart(month,transaction_date) as Month, datepart(year,transaction_date) as Year ,sum(amount) as Total
from [Basicsql].[dbo].[credit_card_transcations$]
group by card_type,exp_type,datepart(month,transaction_date),datepart(year,transaction_date)
), prev_salary as (
select *,
lag(Total) over (partition by card_type,exp_type order by Year,Month) as previous_salary
from Month_total
)

select top 1 *,Total-previous_salary as MOM_growth
from prev_salary
where Month =1 and Year = 2014
order by MOM_growth desc

--8. during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city,1.0*sum(amount)/count(1) as ratio
from [Basicsql].[dbo].[credit_card_transcations$]
where datepart(weekday,transaction_date) in (1,7) -- datepart execute faster as this is integer
--where datename(weekday,transaction_date) in ('Saturday','Sunday')
group by city
order by ratio desc

--9. which city took least number of days to reach its 500th transaction after the first transaction in that city

with trans_count as (
select *, row_number() over(partition by city order by transaction_date,transaction_id) as rn
from [Basicsql].[dbo].[credit_card_transcations$]
)

select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as Diff_date
from trans_count
where rn = 1 or rn=500 
group by city
having count(1)=2
order by Diff_date


