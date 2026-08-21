-- E-COMMERCE DATA MANAGEMENT SYSTEM
-- File: 01_ecommerce_creation.sql
-- Purpose: Database creation + all table structures + indexes
-- =====================================================

-- creation database

create database ecommerce_db;
use ecommerce_db;

-- customers

create table customers (
    customer_id int auto_increment primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    email varchar(100) not null unique,
    phone varchar(20),
    password_hash varchar(255) not null,
    created_at datetime not null
);

-- addresses

create table addresses (
    address_id int auto_increment primary key,
    customer_id int not null,
    address_line varchar(150) not null,
    city varchar(50) not null,
    state varchar(50) not null,
    zip_code varchar(10) not null,
    country varchar(50) not null,
    is_default tinyint(1) default 0,
    foreign key (customer_id) references customers(customer_id) on delete cascade
);

-- categories 

create table categories (
    category_id int auto_increment primary key,
    category_name varchar(100) not null unique,
    parent_category_id int default null,
    foreign key (parent_category_id) references categories(category_id) on delete set null
);

-- suppliers

create table suppliers (
    supplier_id int auto_increment primary key,
    supplier_name varchar(100) not null,
    contact_email varchar(100),
    phone varchar(20),
    country varchar(50)
);

-- products

create table products (
    product_id int auto_increment primary key,
    product_name varchar(150) not null,
    category_id int not null,
    supplier_id int not null,
    price decimal(10,2) not null,
    stock_quantity int not null default 0,
    description varchar(255),
    created_at datetime not null,
    foreign key (category_id) references categories(category_id),
    foreign key (supplier_id) references suppliers(supplier_id)
);

-- product_images

create table product_images (
    image_id int auto_increment primary key,
    product_id int not null,
    image_url varchar(255) not null,
    is_primary tinyint(1) default 0,
    foreign key (product_id) references products(product_id) on delete cascade
);

-- carts

create table carts (
    cart_id int auto_increment primary key,
    customer_id int not null,
    created_at datetime not null,
    foreign key (customer_id) references customers(customer_id) on delete cascade
);

-- cart_items

create table cart_items (
    cart_item_id int auto_increment primary key,
    cart_id int not null,
    product_id int not null,
    quantity int not null default 1,
    foreign key (cart_id) references carts(cart_id) on delete cascade,
    foreign key (product_id) references products(product_id)
);

-- orders

create table orders (
    order_id int auto_increment primary key,
    customer_id int not null,
    address_id int not null,
    order_date datetime not null,
    status varchar(20) not null default 'pending',
    total_amount decimal(10,2) not null default 0,
    foreign key (customer_id) references customers(customer_id),
    foreign key (address_id) references addresses(address_id)
);

-- order_items

create table order_items (
    order_item_id int auto_increment primary key,
    order_id int not null,
    product_id int not null,
    quantity int not null,
    unit_price decimal(10,2) not null,
    foreign key (order_id) references orders(order_id) on delete cascade,
    foreign key (product_id) references products(product_id)
);

-- payments

create table payments (
    payment_id int auto_increment primary key,
    order_id int not null,
    payment_method varchar(30) not null,
    payment_status varchar(20) not null default 'pending',
    amount decimal(10,2) not null,
    payment_date datetime not null,
    foreign key (order_id) references orders(order_id) on delete cascade
);

-- shipments

create table shipments (
    shipment_id int auto_increment primary key,
    order_id int not null,
    shipment_date datetime,
    carrier varchar(50),
    tracking_number varchar(50),
    delivery_status varchar(20) default 'not shipped',
    foreign key (order_id) references orders(order_id) on delete cascade
);

-- reviews

create table reviews (
    review_id int auto_increment primary key,
    product_id int not null,
    customer_id int not null,
    rating tinyint not null,
    comment varchar(255),
    review_date datetime not null,
    foreign key (product_id) references products(product_id) on delete cascade,
    foreign key (customer_id) references customers(customer_id) on delete cascade,
    check (rating between 1 and 5)
);

-- indexes 

create index idx_products_category on products(category_id);
create index idx_products_supplier on products(supplier_id);
create index idx_orders_customer on orders(customer_id);
create index idx_order_items_order on order_items(order_id);
create index idx_order_items_product on order_items(product_id);
create index idx_reviews_product on reviews(product_id);
create index idx_payments_order on payments(order_id);

