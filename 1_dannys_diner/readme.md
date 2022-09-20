<h1 align="center">CASE STUDY #1 - Danny's Diner</h1>

## Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:
- sales
- menu
- members


## Case Study Questions and Solutions

#### 1. What is the total amount each customer spent at the restaurant?
```sql
Select customer_id, sum(price) As total_amount
From sales As s
Left Join menu As m on s.product_id = m.product_id
Group by 1
Order by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/1_dannys_diner/Image%20for%20case%20study%201/q1.png" />

#### 2. How many days has each customer visited the restaurant?
```sql
Select customer_id, count(distinct order_date) as total_days_visited
From sales
Group by 1
Order by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/1_dannys_diner/Image%20for%20case%20study%201/q2.png" />

#### 3. What was the first item from the menu purchased by each customer?
```sql
With cte as (
Select customer_id, product_id, 
dense_rank() over (partition by customer_id order by order_date) as first_item
From sales)

Select distinct customer_id, product_name
From cte
Join menu As m on cte.product_id = m.product_id
Where cte.first_item = 1
Order by 1
;
```

<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/1_dannys_diner/Image%20for%20case%20study%201/q3.png" />


#### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
With cte as (
Select product_name, 
rank() over (order by count(s.product_id) desc) as rnk, count(s.product_id) as purchased_time
From sales As s
Left Join menu As m on s.product_id = m.product_id
Group by 1)

Select product_name, purchased_time
From cte
Where rnk = 1
;
```

<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/1_dannys_diner/Image%20for%20case%20study%201/q4.png" />

#### 5. Which item was the most popular for each customer?
```sql
With cte as (
Select customer_id, product_id, 
count(product_id) as cnt, 
rank() over (partition by customer_id order by count(product_id) desc) as rnk
From sales
group by 1,2)

Select customer_id, product_name
From cte c
Left Join menu As m on c.product_id = m.product_id
Where rnk = 1
;
```

<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/1_dannys_diner/Image%20for%20case%20study%201/q5.png" />

#### 6. Which item was purchased first by the customer after they became a member?
```sql
With cte as (
Select s.customer_id, product_id, 
case when order_date > join_date then order_date end as member_purchase, 
rank() over (partition by s.customer_id order by order_date) as rnk
From members as ms
Join sales as s on ms.customer_id = s.customer_id
Where case when order_date > join_date then order_date end is not null)

Select customer_id, product_name
From cte c
Join menu m on c.product_id = m.product_id
Where rnk = 1
Order by 1
;
```

<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/1_dannys_diner/Image%20for%20case%20study%201/q6.png" />

#### 7. Which item was purchased just before the customer became a member?
```sql
With cte as (
Select s.customer_id, product_id, case when order_date < join_date then order_date end as purchase, rank() over (partition by s.customer_id order by order_date desc) as rnk
From members as ms
Join sales as s on ms.customer_id = s.customer_id
Where case when order_date < join_date then order_date end is not null)

Select customer_id, product_name
From cte c
Join menu m on c.product_id = m.product_id
Where rnk = 1
Order by 1
;
```

<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/1_dannys_diner/Image%20for%20case%20study%201/q7.png" />

#### 8. What is the total items and amount spent for each member before they became a member?
```sql
With cte as
(select s.customer_id, product_id, order_date
From sales s 
Join members ms on s.customer_id = ms.customer_id
Where s.order_date < ms.join_date)

Select customer_id, count(product_name) as total_items, sum(price) as total_price
From cte 
Join menu m on cte.product_id = m.product_id
group by cte.customer_id
order by 1
;
```

<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/1_dannys_diner/Image%20for%20case%20study%201/q8.png" />

#### 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
with cte as
(Select s.customer_id, s.product_id, m.price, m.product_name,
(case 
	when product_name in ('curry','ramen') then price*10
    else price*20
end) as points
From sales s 
Join menu m on s.product_id = m.product_id)

Select customer_id, sum(points) as total_points
From cte
Group by 1
;
```

<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/1_dannys_diner/Image%20for%20case%20study%201/q9.png" />


#### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
with cte as
(Select s.customer_id, order_date, product_id, join_date
From sales s 
Join members m on s.customer_id = m.customer_id),
cte2 as
(select customer_id, order_date, product_name, price,join_date,
case 
	when product_name = 'sushi' then price*20
	when datediff(order_date,join_date) <= 6 and datediff(order_date,join_date) >= 0 then price*20
    when datediff(order_date,join_date) >= 7 and product_name in ('curry','ramen') then price*10
    when datediff(order_date,join_date) < 0 then price*10
	else price*10
end as total_points
from cte
join menu m on cte.product_id = m.product_id
order by 1)

select customer_id, sum(total_points)
from cte2 
where order_date < '2021-02-01'
group by 1;
```

<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/1_dannys_diner/Image%20for%20case%20study%201/q10.png" />
