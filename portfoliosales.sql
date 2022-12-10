---Inspecting data

select * from [dbo].[sales_data_sample]

---Checking unique values

select distinct STATUS from [dbo].[sales_data_sample] ---good to plot
select distinct YEAR_ID from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] ---good to plot
select distinct COUNTRY from [dbo].[sales_data_sample] ---good to plot
select distinct DEALSIZE from [dbo].[sales_data_sample] ---good to plot
select distinct TERRITORY from [dbo].[sales_data_sample] ---good to plot

select distinct MONTH_ID from [dbo].[sales_data_sample]
where YEAR_ID = 2005  ---Because saw very less sales in 2005 and found out they only operated for just 5 months in 2005
select distinct MONTH_ID from [dbo].[sales_data_sample]
where YEAR_ID = 2003  ---In 2004 and 2003 they operated for 12 months

---Analysis
---Grouping sales by productline

select PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc

select YEAR_ID, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

select DEALSIZE, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by DEALSIZE
order by 2 desc

--- what was the best month for sales in a particular year? And how much was earned that month?

select MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2004
group by MONTH_ID
order by 2 desc

---November seems the exceptional month
---What product do they sell in November?

select MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2003 and MONTH_ID = 11
group by MONTH_ID, PRODUCTLINE
order by 3 desc
--- Best product is classic car

--- Who is our best customer? (RFM)
--- Recency - last date of order
--- Frequency - count of total orders
--- Monetary value - total spend

DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from [dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

--- what products are most often sold together?
---select * from [dbo].[sales_data_sample] where ORDERNUMBER = 10411 (9 records for 10411 which is rn)

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn --- n.o records of each ordernumber (shipped) rn is the no items bought together
				FROM [dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3 ---3 items bought together
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[sales_data_sample] s
order by 2 desc

--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from [dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc
