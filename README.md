# E-Commerce Database Management System

This is a MySQL project I built to practice database design and SQL — a full backend schema for an e-commerce site, from scratch.

## What's in it

13 tables covering the usual e-commerce flow: customers, addresses, product categories (with sub-categories), suppliers, products, carts, orders, payments, shipments, and reviews. All connected properly with foreign keys.

## ER Diagram

![ER Diagram](https://github.com/mijilash13042004-commits/-ecommerce-db-management/blob/962a749618ea3876cdb3640b26e70a32c01cec19/ecommerce_ER_diagram.png)

## Things I implemented

- Indexes on the columns that actually get queried a lot, plus a composite index for order_items — checked with EXPLAIN to make sure they're actually being used
- All the join types (inner, left, right, self join, cross join, and a workaround for full outer join since MySQL doesn't have one natively)
- Subqueries for things like finding customers who spend more than average
- A stored procedure (`place_order`) that handles placing an order and updating stock in one go
- Triggers — one stops stock from going negative, another updates order status automatically when payment goes through
- A scheduled event that clears out empty carts
- Transactions with rollback/commit, so I could test what happens if something fails mid-order
- Two separate MySQL users — one for the app, one read-only for reports

## Files

- `E_commerce_data_management.sql` — the whole thing: schema, sample data, queries

## Built with

MySQL 8.0 / MySQL Workbench
