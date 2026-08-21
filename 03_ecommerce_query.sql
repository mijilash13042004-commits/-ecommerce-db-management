-- E-COMMERCE DATA MANAGEMENT SYSTEM
-- File: 03_ecommerce_query.sql
-- Purpose: All queries - CRUD, filtering, sorting, aggregates,
--          GROUP BY, HAVING, subqueries, all JOIN types,
--          indexing & optimization, stored procedures,
--          functions, triggers, events, transactions,
--          and security / user management
-- =====================================================

use ecommerce_db;


-- select query-------------

select * from customers;
select * from categories;
select * from carts;
select * from cart_items;
select * from addresses;
select * from order_items;
select * from orders;
select * from payments;
select * from product_images;
select * from products;
select * from reviews;
select * from shipments;
select * from suppliers;

-- basic sql operations (crud, filtering, sorting, limit)---------

-- insert a new customer----------

insert into customers (first_name, last_name, email, phone, password_hash, created_at)
values ('arun', 'kumar', 'arun.kumar999@gmail.com', '+91-9876543210', 'hash_555999', now());

-- select all products under 1000 rupees--------

select product_id, product_name, price, stock_quantity
from products
where price < 10000
order by price asc;

-- update stock quantity after a sale---------

update products set stock_quantity = stock_quantity - 1 where product_id = 10;

-- delete an abandoned cart older than the data ------------

delete from carts where created_at < '2023-01-01';

-- filter customers by state through their address----------

select c.first_name, c.last_name, a.city, a.state
from customers c
join addresses a on c.customer_id = a.customer_id
where a.state = 'tamil nadu' and a.is_default = 1;

-- sort products by price descending, limit to top 10----------

select product_name, price from products order by price desc limit 10;

-- advanced sql queries (aggregates, group by, having, subqueries)

-- total revenue and number of orders per customer----------

select c.customer_id, c.first_name, c.last_name,
       count(o.order_id) as total_orders,
       sum(o.total_amount) as total_spent
from customers c
join orders o on c.customer_id = o.customer_id
group by c.customer_id, c.first_name, c.last_name
order by total_spent desc;

-- average rating and review count per product, only products with 3+ reviews--------

select p.product_id, p.product_name,
       count(r.review_id) as review_count,
       round(avg(r.rating), 2) as avg_rating
from products p
join reviews r on p.product_id = r.product_id
group by p.product_id, p.product_name
having count(r.review_id) >= 3
order by avg_rating desc;

-- customers who spent more than the average order value---------

select customer_id, first_name, last_name
from customers
where customer_id in (
    select customer_id
    from orders
    group by customer_id
    having sum(total_amount) > (select avg(total_amount) from orders)
);

-- products that have never been ordered----------

select product_id, product_name
from products
where product_id not in (select distinct product_id from order_items);

-- category wise stock value------------ 

select cat.category_name,
       sum(p.price * p.stock_quantity) as stock_value,
       count(p.product_id) as product_count
from categories cat
join products p on cat.category_id = p.category_id
group by cat.category_name
order by stock_value desc;

-- joins and relationships----------

-- inner join: order details with customer and product info-----------

select o.order_id, c.first_name, c.last_name, p.product_name, oi.quantity, oi.unit_price
from orders o
inner join customers c on o.customer_id = c.customer_id
inner join order_items oi on o.order_id = oi.order_id
inner join products p on oi.product_id = p.product_id
order by o.order_id;

-- left join: all customers with their orders, including customers with no orders----------

select c.customer_id, c.first_name, c.last_name, o.order_id, o.total_amount
from customers c
left join orders o on c.customer_id = o.customer_id
order by c.customer_id;

-- right join: all products with their order items, including products never ordered-----------

select p.product_id, p.product_name, oi.order_id, oi.quantity
from order_items oi
right join products p on oi.product_id = p.product_id
order by p.product_id;

-- full outer join simulation-------------
 
select c.customer_id, c.first_name, o.order_id
from customers c
left join orders o on c.customer_id = o.customer_id
union
select c.customer_id, c.first_name, o.order_id
from customers c
right join orders o on c.customer_id = o.customer_id;

-- self join: find customers who share the same city----------

select a1.customer_id as customer_1, a2.customer_id as customer_2, a1.city
from addresses a1
join addresses a2 on a1.city = a2.city and a1.customer_id < a2.customer_id;

-- cross join: every category paired with every supplier----------

select cat.category_name, s.supplier_name
from categories cat
cross join suppliers s
limit 20;

-- ======================================================================================================

-- indexing and optimization---------

-- check existing indexes on the orders table----------

show index from orders;

-- use explain to see how the optimizer uses the index on category_id----------

explain select * from products where category_id = 3;

-- composite index example for faster lookups on order_items---------
create index idx_order_product on order_items(order_id, product_id);

-- stored procedures and functions------------

delimiter $$

-- stored procedure---------

create procedure place_order (
    in p_customer_id int,
    in p_address_id int,
    in p_product_id int,
    in p_quantity int
)
begin
    declare v_price decimal(10,2);
    declare v_order_id int;

    select price into v_price from products where product_id = p_product_id;

    insert into orders (customer_id, address_id, order_date, status, total_amount)
    values (p_customer_id, p_address_id, now(), 'pending', v_price * p_quantity);

    set v_order_id = last_insert_id();

    insert into order_items (order_id, product_id, quantity, unit_price)
    values (v_order_id, p_product_id, p_quantity, v_price);

    update products set stock_quantity = stock_quantity - p_quantity
    where product_id = p_product_id;
end$$

-- function: get the total number of orders placed by a customer---------

create function get_customer_order_count (p_customer_id int)
returns int
deterministic
begin
    declare v_count int;
    select count(*) into v_count from orders where customer_id = p_customer_id;
    return v_count;
end$$

delimiter ;

-- calls-----------

call place_order(1, 1, 5, 2);
select get_customer_order_count(1) as order_count;

-- triggers and events
delimiter $$

-- trigger: prevent stock from going negative before an order item is inserted----------

create trigger trg_check_stock
before insert on order_items
for each row
begin
    declare v_stock int;
    select stock_quantity into v_stock from products where product_id = new.product_id;
    if v_stock < new.quantity then
        signal sqlstate '45000'
        set message_text = 'not enough stock for this product';
    end if;
end$$

-- trigger: log every payment status change into a simple audit style update----------

create trigger trg_payment_update
after update on payments
for each row
begin
    if old.payment_status <> new.payment_status then
        update orders
        set status = case
            when new.payment_status = 'completed' then 'processing'
            when new.payment_status = 'failed' then 'cancelled'
            else orders.status
        end
        where order_id = new.order_id;
    end if;
end$$

delimiter ;

-- scheduled event: clear out empty carts every night (needs event_scheduler = on)----------

set global event_scheduler = on;

delimiter $$
create event evt_clear_empty_carts
on schedule every 1 day
starts current_timestamp
do
begin
    delete from carts
    where cart_id not in (select distinct cart_id from cart_items);
end$$
delimiter ;

-- transactions and concurrency control-----

-- transaction: transfer a product purchase with rollback safety------------

start transaction;

update products set stock_quantity = stock_quantity - 1 where product_id = 12;

insert into orders (customer_id, address_id, order_date, status, total_amount)
values (2, 2, now(), 'pending', 1499.00);

savepoint before_payment;

insert into payments (order_id, payment_method, payment_status, amount, payment_date)
values (last_insert_id(), 'upi', 'completed', 1499.00, now());

-- if something goes wrong we can roll back to the savepoint
-- rollback to before_payment;

commit;

start transaction;
update products set stock_quantity = stock_quantity - 100 where product_id = 3;
rollback;

 -- security and user management------------

-- create an application level user with a strong password---------

create user if not exists 'store_app'@'localhost' identified by 'YourStrongPasswordHere!';

-- example: rotate the password later if it needs to change---------

alter user 'store_app'@'localhost' identified by 'YourNewRotatedPasswordHere!';

-- grant limited privileges to the app user-----------

grant select, insert, update, delete on ecommerce_db.* to 'store_app'@'localhost';

-- create a read only user for reporting/analytics------------
create user if not exists 'report_viewer'@'%' identified by 'ReportOnlyPasswordHere!';

grant select on ecommerce_db.* to 'report_viewer'@'%';

-- revoke delete access if no longer needed-----------

revoke delete on ecommerce_db.* from 'store_app'@'localhost';

flush privileges;

-- require ssl for a connection--------

alter user 'report_viewer'@'%' require ssl;
