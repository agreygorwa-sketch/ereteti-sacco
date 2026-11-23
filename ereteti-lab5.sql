-- ---------------------------------------------------------------------------
-- Ereteti Dairy Sacco — the database for Lab 5 (DBT 1305)
--
-- phpMyAdmin → Import → Choose File → this file → Import (bottom of the page).
-- It creates the database ereteti_web, six tables, and October 2026's data:
-- 3 routes, 8 farmers, 474 milk deliveries.
--
-- Importing it again is safe: it deletes ereteti_web and builds it afresh.
-- ---------------------------------------------------------------------------

DROP DATABASE IF EXISTS ereteti_web;
CREATE DATABASE ereteti_web
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE ereteti_web;


-- --- Manage farmers --------------------------------------------------------

-- A collection route is the morning run a sacco vehicle makes. Every farmer
-- belongs to exactly one, and route totals are the first report the manager
-- asks for.
CREATE TABLE route (
    route_id          INT AUTO_INCREMENT PRIMARY KEY,
    route_name        VARCHAR(50)  NOT NULL UNIQUE,
    collection_centre VARCHAR(60)  NOT NULL
);

CREATE TABLE farmer (
    farmer_id   INT AUTO_INCREMENT PRIMARY KEY,
    member_no   VARCHAR(10)  NOT NULL UNIQUE,   -- ER-0001, issued by the sacco
    first_name  VARCHAR(40)  NOT NULL,
    last_name   VARCHAR(40)  NOT NULL,
    national_id VARCHAR(20)  NOT NULL UNIQUE,
    phone       VARCHAR(20)  NOT NULL,
    route_id    INT          NOT NULL,
    date_joined DATE         NOT NULL,
    active      TINYINT(1)   NOT NULL DEFAULT 1,

    CONSTRAINT fk_farmer_route
        FOREIGN KEY (route_id) REFERENCES route(route_id)
);

-- Look-ups by member number are what the delivery form does on every submit,
-- so index the column the user actually types.
CREATE INDEX idx_farmer_route ON farmer(route_id);


-- --- Manage milk deliveries ------------------------------------------------

-- Cows are milked twice a day, so a farmer may deliver twice a day and no more.
-- The unique key enforces that; it is also the first constraint violation
-- students will meet, and a good one to report to the user in Week 12 rather
-- than letting it reach the page as a raw MySQLi error.
CREATE TABLE milk_delivery (
    delivery_id   INT AUTO_INCREMENT PRIMARY KEY,
    farmer_id     INT           NOT NULL,
    delivery_date DATE          NOT NULL,
    session       ENUM('MORNING','EVENING') NOT NULL,
    litres        DECIMAL(6,2)  NOT NULL,
    accepted      TINYINT(1)    NOT NULL DEFAULT 1,   -- 0 = rejected on quality
    remarks       VARCHAR(100)  NULL,

    CONSTRAINT fk_delivery_farmer
        FOREIGN KEY (farmer_id) REFERENCES farmer(farmer_id),
    CONSTRAINT uq_delivery_once_per_session
        UNIQUE (farmer_id, delivery_date, session),
    CONSTRAINT chk_delivery_litres
        CHECK (litres > 0 AND litres <= 200)
);

CREATE INDEX idx_delivery_date ON milk_delivery(delivery_date);


-- --- Manage payments -------------------------------------------------------

-- The price per litre changes during the year. Storing it with the date it
-- takes effect means an old payment can still be recalculated correctly.
CREATE TABLE milk_rate (
    rate_id         INT AUTO_INCREMENT PRIMARY KEY,
    effective_from  DATE          NOT NULL UNIQUE,
    price_per_litre DECIMAL(6,2)  NOT NULL,

    CONSTRAINT chk_rate_positive CHECK (price_per_litre > 0)
);

-- What the sacco holds back before paying: AI (artificial insemination) call-
-- outs, feeds taken on credit, loan instalments, share contributions.
CREATE TABLE deduction (
    deduction_id   INT AUTO_INCREMENT PRIMARY KEY,
    farmer_id      INT           NOT NULL,
    period_year    SMALLINT      NOT NULL,
    period_month   TINYINT       NOT NULL,
    deduction_type ENUM('AI_SERVICE','FEEDS','LOAN','SHARES') NOT NULL,
    amount         DECIMAL(10,2) NOT NULL,
    note           VARCHAR(100)  NULL,

    CONSTRAINT fk_deduction_farmer
        FOREIGN KEY (farmer_id) REFERENCES farmer(farmer_id),
    CONSTRAINT chk_deduction_month CHECK (period_month BETWEEN 1 AND 12),
    CONSTRAINT chk_deduction_amount CHECK (amount > 0)
);

-- One payment row per farmer per month. The totals are stored rather than
-- recalculated on demand: once a farmer has been paid, the figure must not
-- change because a delivery was edited afterwards.
CREATE TABLE payment (
    payment_id       INT AUTO_INCREMENT PRIMARY KEY,
    farmer_id        INT           NOT NULL,
    period_year      SMALLINT      NOT NULL,
    period_month     TINYINT       NOT NULL,
    total_litres     DECIMAL(8,2)  NOT NULL,
    rate_per_litre   DECIMAL(6,2)  NOT NULL,
    gross_amount     DECIMAL(10,2) NOT NULL,
    total_deductions DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    net_amount       DECIMAL(10,2) NOT NULL,
    status           ENUM('DRAFT','PAID') NOT NULL DEFAULT 'DRAFT',
    paid_on          DATE          NULL,

    CONSTRAINT fk_payment_farmer
        FOREIGN KEY (farmer_id) REFERENCES farmer(farmer_id),
    CONSTRAINT uq_payment_once_per_month
        UNIQUE (farmer_id, period_year, period_month),
    CONSTRAINT chk_payment_month CHECK (period_month BETWEEN 1 AND 12)
);


-- --- Generate reports ------------------------------------------------------
-- Report 1 is what report-monthly.php answers in Week 13. Reports 2 and 3 are
-- DBT 1201's; they are kept here so the schema can be checked against
-- everything it has to answer. Students write these as MySQLi prepared
-- statements — never as concatenated strings.

-- 1. Monthly collection per farmer
--    SELECT f.member_no, f.first_name, f.last_name,
--           SUM(d.litres) AS total_litres
--    FROM farmer f
--    JOIN milk_delivery d ON d.farmer_id = f.farmer_id
--    WHERE d.accepted = 1
--      AND YEAR(d.delivery_date) = ? AND MONTH(d.delivery_date) = ?
--    GROUP BY f.farmer_id
--    ORDER BY total_litres DESC;

-- 2. Payment schedule for a month
--    SELECT f.member_no, f.first_name, f.last_name,
--           p.total_litres, p.rate_per_litre,
--           p.gross_amount, p.total_deductions, p.net_amount, p.status
--    FROM payment p
--    JOIN farmer f ON f.farmer_id = p.farmer_id
--    WHERE p.period_year = ? AND p.period_month = ?
--    ORDER BY f.member_no;

-- 3. Route performance
--    SELECT r.route_name, COUNT(DISTINCT f.farmer_id) AS farmers,
--           SUM(d.litres) AS total_litres
--    FROM route r
--    JOIN farmer f ON f.route_id = r.route_id
--    JOIN milk_delivery d ON d.farmer_id = f.farmer_id
--    WHERE d.accepted = 1
--      AND YEAR(d.delivery_date) = ? AND MONTH(d.delivery_date) = ?
--    GROUP BY r.route_id
--    ORDER BY total_litres DESC;

-- --- Routes ----------------------------------------------------------------

-- DBT 1305 only (renamed 12 November 2026): the routes are the ones the
-- students' site has named since Week 2 — Kiserian, Ngong, Rongai, in that
-- order, so route_id 1, 2, 3 matches the register form's <select> values.
-- DBT 1201's seed still says Gatundu North, Gatundu South and Kamwangi; the
-- schema, the farmers and the deliveries are unchanged and identical in both.
INSERT INTO route (route_name, collection_centre) VALUES
    ('Kiserian', 'Kiserian Cooling Plant'),
    ('Ngong', 'Ngong Cooling Plant'),
    ('Rongai', 'Rongai Cooling Plant');


-- --- Farmers ---------------------------------------------------------------

INSERT INTO farmer (member_no, first_name, last_name, national_id, phone, route_id, date_joined) VALUES
    ('ER-0001', 'Peter', 'Mwangi', '22145678', '0722145678', 1, '2019-03-14'),
    ('ER-0002', 'Grace', 'Wanjiku', '24587013', '0733587013', 1, '2019-07-02'),
    ('ER-0003', 'Joseph', 'Kamau', '19874321', '0721874321', 1, '2020-01-20'),
    ('ER-0004', 'Esther', 'Njeri', '27431905', '0710431905', 2, '2020-06-11'),
    ('ER-0005', 'Daniel', 'Kariuki', '23098776', '0745098776', 2, '2021-02-08'),
    ('ER-0006', 'Mercy', 'Nyambura', '28776341', '0798776341', 2, '2021-09-27'),
    ('ER-0007', 'Samuel', 'Gitau', '21456098', '0723456098', 3, '2022-04-05'),
    ('ER-0008', 'Lucy', 'Wairimu', '29001234', '0787001234', 3, '2023-08-16');


-- --- Rates -----------------------------------------------------------------
-- The rate rose in October. A payment run must use the rate in force for the
-- period it is paying, not simply the newest one.

INSERT INTO milk_rate (effective_from, price_per_litre) VALUES
    ('2026-01-01', 48.50),
    ('2026-10-01', 52.00);


-- --- Deliveries ------------------------------------------------------------
-- Morning and evening through October 2026. A few collections are missing (a
-- cow dried off, a farmer travelled) and three loads were rejected on quality,
-- so the data is uneven and the reports are worth reading.

INSERT INTO milk_delivery (farmer_id, delivery_date, session, litres, accepted, remarks) VALUES
    (1, '2026-10-01', 'MORNING', 6.08, 1, NULL),
    (1, '2026-10-01', 'EVENING', 5.34, 1, NULL),
    (2, '2026-10-01', 'MORNING', 3.87, 1, NULL),
    (2, '2026-10-01', 'EVENING', 3.26, 1, NULL),
    (3, '2026-10-01', 'MORNING', 9.15, 1, NULL),
    (3, '2026-10-01', 'EVENING', 6.91, 1, NULL),
    (4, '2026-10-01', 'MORNING', 2.41, 1, NULL),
    (4, '2026-10-01', 'EVENING', 1.9, 1, NULL),
    (5, '2026-10-01', 'MORNING', 6.01, 1, NULL),
    (5, '2026-10-01', 'EVENING', 3.88, 1, NULL),
    (6, '2026-10-01', 'MORNING', 3.94, 1, NULL),
    (6, '2026-10-01', 'EVENING', 2.64, 1, NULL),
    (7, '2026-10-01', 'MORNING', 9.36, 1, NULL),
    (7, '2026-10-01', 'EVENING', 7.43, 1, NULL),
    (8, '2026-10-01', 'MORNING', 2.43, 1, NULL),
    (8, '2026-10-01', 'EVENING', 2.2, 1, NULL),
    (1, '2026-10-02', 'MORNING', 7.31, 1, NULL),
    (1, '2026-10-02', 'EVENING', 4.95, 1, NULL),
    (2, '2026-10-02', 'MORNING', 4.62, 1, NULL),
    (2, '2026-10-02', 'EVENING', 3.12, 1, NULL),
    (3, '2026-10-02', 'MORNING', 7.72, 1, NULL),
    (3, '2026-10-02', 'EVENING', 5.56, 1, NULL),
    (4, '2026-10-02', 'MORNING', 3.08, 1, NULL),
    (4, '2026-10-02', 'EVENING', 1.87, 1, NULL),
    (5, '2026-10-02', 'MORNING', 6.02, 1, NULL),
    (5, '2026-10-02', 'EVENING', 4.56, 1, NULL),
    (6, '2026-10-02', 'MORNING', 3.34, 1, NULL),
    (6, '2026-10-02', 'EVENING', 2.65, 1, NULL),
    (7, '2026-10-02', 'MORNING', 11.03, 1, NULL),
    (7, '2026-10-02', 'EVENING', 8.23, 1, NULL),
    (8, '2026-10-02', 'MORNING', 2.69, 1, NULL),
    (1, '2026-10-03', 'MORNING', 7.21, 1, NULL),
    (1, '2026-10-03', 'EVENING', 5.24, 1, NULL),
    (2, '2026-10-03', 'MORNING', 4.33, 1, NULL),
    (2, '2026-10-03', 'EVENING', 3.58, 1, NULL),
    (3, '2026-10-03', 'MORNING', 8.12, 1, NULL),
    (4, '2026-10-03', 'MORNING', 2.98, 1, NULL),
    (4, '2026-10-03', 'EVENING', 1.8, 1, NULL),
    (5, '2026-10-03', 'MORNING', 4.77, 1, NULL),
    (5, '2026-10-03', 'EVENING', 3.87, 1, NULL),
    (6, '2026-10-03', 'MORNING', 3.59, 1, NULL),
    (6, '2026-10-03', 'EVENING', 2.61, 1, NULL),
    (7, '2026-10-03', 'MORNING', 9.6, 1, NULL),
    (7, '2026-10-03', 'EVENING', 7.93, 1, NULL),
    (8, '2026-10-03', 'MORNING', 2.55, 1, NULL),
    (8, '2026-10-03', 'EVENING', 2.08, 1, NULL),
    (1, '2026-10-04', 'MORNING', 6.84, 1, NULL),
    (1, '2026-10-04', 'EVENING', 5.43, 1, NULL),
    (2, '2026-10-04', 'MORNING', 5.1, 1, NULL),
    (2, '2026-10-04', 'EVENING', 3.52, 1, NULL),
    (3, '2026-10-04', 'MORNING', 9.28, 1, NULL),
    (3, '2026-10-04', 'EVENING', 5.84, 1, NULL),
    (4, '2026-10-04', 'MORNING', 3.39, 1, NULL),
    (4, '2026-10-04', 'EVENING', 1.84, 1, NULL),
    (5, '2026-10-04', 'MORNING', 6.37, 1, NULL),
    (5, '2026-10-04', 'EVENING', 3.57, 1, NULL),
    (6, '2026-10-04', 'MORNING', 4.08, 1, NULL),
    (6, '2026-10-04', 'EVENING', 2.68, 1, NULL),
    (7, '2026-10-04', 'MORNING', 11.74, 1, NULL),
    (7, '2026-10-04', 'EVENING', 8.06, 1, NULL),
    (8, '2026-10-04', 'MORNING', 3.07, 1, NULL),
    (8, '2026-10-04', 'EVENING', 2.0, 1, NULL),
    (1, '2026-10-05', 'MORNING', 5.35, 1, NULL),
    (1, '2026-10-05', 'EVENING', 5.07, 1, NULL),
    (2, '2026-10-05', 'MORNING', 4.82, 1, NULL),
    (2, '2026-10-05', 'EVENING', 2.96, 1, NULL),
    (3, '2026-10-05', 'MORNING', 9.14, 1, NULL),
    (3, '2026-10-05', 'EVENING', 6.58, 1, NULL),
    (4, '2026-10-05', 'MORNING', 2.84, 1, NULL),
    (4, '2026-10-05', 'EVENING', 2.45, 1, NULL),
    (5, '2026-10-05', 'MORNING', 5.86, 1, NULL),
    (5, '2026-10-05', 'EVENING', 4.62, 1, NULL),
    (6, '2026-10-05', 'MORNING', 3.1, 1, NULL),
    (6, '2026-10-05', 'EVENING', 2.14, 1, NULL),
    (7, '2026-10-05', 'MORNING', 11.42, 1, NULL),
    (7, '2026-10-05', 'EVENING', 7.84, 1, NULL),
    (8, '2026-10-05', 'MORNING', 2.75, 1, NULL),
    (8, '2026-10-05', 'EVENING', 2.07, 1, NULL),
    (1, '2026-10-06', 'EVENING', 5.32, 1, NULL),
    (2, '2026-10-06', 'MORNING', 4.78, 1, NULL),
    (2, '2026-10-06', 'EVENING', 3.54, 1, NULL),
    (3, '2026-10-06', 'MORNING', 7.2, 1, NULL),
    (3, '2026-10-06', 'EVENING', 5.76, 1, NULL),
    (4, '2026-10-06', 'MORNING', 2.43, 1, NULL),
    (4, '2026-10-06', 'EVENING', 2.14, 1, NULL),
    (5, '2026-10-06', 'MORNING', 5.96, 1, NULL),
    (5, '2026-10-06', 'EVENING', 4.64, 1, NULL),
    (6, '2026-10-06', 'MORNING', 3.51, 1, NULL),
    (7, '2026-10-06', 'MORNING', 8.62, 1, NULL),
    (7, '2026-10-06', 'EVENING', 6.64, 1, NULL),
    (8, '2026-10-06', 'MORNING', 2.84, 1, NULL),
    (8, '2026-10-06', 'EVENING', 1.66, 1, NULL),
    (1, '2026-10-07', 'MORNING', 5.59, 1, NULL),
    (2, '2026-10-07', 'MORNING', 4.42, 1, NULL),
    (2, '2026-10-07', 'EVENING', 3.13, 1, NULL),
    (3, '2026-10-07', 'MORNING', 9.4, 1, NULL),
    (3, '2026-10-07', 'EVENING', 4.84, 1, NULL),
    (4, '2026-10-07', 'MORNING', 3.07, 1, NULL),
    (4, '2026-10-07', 'EVENING', 1.93, 1, NULL),
    (5, '2026-10-07', 'MORNING', 5.28, 1, NULL),
    (5, '2026-10-07', 'EVENING', 3.61, 1, NULL),
    (6, '2026-10-07', 'MORNING', 3.79, 1, NULL),
    (6, '2026-10-07', 'EVENING', 2.3, 1, NULL),
    (7, '2026-10-07', 'MORNING', 9.28, 1, NULL),
    (7, '2026-10-07', 'EVENING', 7.43, 1, NULL),
    (8, '2026-10-07', 'MORNING', 2.47, 1, NULL),
    (8, '2026-10-07', 'EVENING', 1.87, 1, NULL),
    (1, '2026-10-08', 'MORNING', 6.51, 1, NULL),
    (1, '2026-10-08', 'EVENING', 4.92, 1, NULL),
    (2, '2026-10-08', 'MORNING', 5.0, 1, NULL),
    (2, '2026-10-08', 'EVENING', 2.7, 1, NULL),
    (3, '2026-10-08', 'MORNING', 8.92, 1, NULL),
    (3, '2026-10-08', 'EVENING', 5.79, 1, NULL),
    (4, '2026-10-08', 'MORNING', 2.69, 1, NULL),
    (4, '2026-10-08', 'EVENING', 1.92, 1, NULL),
    (5, '2026-10-08', 'MORNING', 5.21, 1, NULL),
    (5, '2026-10-08', 'EVENING', 4.25, 1, NULL),
    (6, '2026-10-08', 'EVENING', 2.28, 1, NULL),
    (7, '2026-10-08', 'MORNING', 10.34, 1, NULL),
    (7, '2026-10-08', 'EVENING', 8.16, 1, NULL),
    (8, '2026-10-08', 'MORNING', 3.01, 1, NULL),
    (8, '2026-10-08', 'EVENING', 2.21, 1, NULL),
    (1, '2026-10-09', 'MORNING', 6.25, 1, NULL),
    (1, '2026-10-09', 'EVENING', 4.45, 1, NULL),
    (2, '2026-10-09', 'MORNING', 4.96, 1, NULL),
    (3, '2026-10-09', 'MORNING', 7.64, 1, NULL),
    (3, '2026-10-09', 'EVENING', 6.23, 1, NULL),
    (4, '2026-10-09', 'MORNING', 2.9, 1, NULL),
    (5, '2026-10-09', 'MORNING', 5.33, 1, NULL),
    (5, '2026-10-09', 'EVENING', 4.25, 1, NULL),
    (6, '2026-10-09', 'MORNING', 3.68, 1, NULL),
    (6, '2026-10-09', 'EVENING', 2.33, 1, NULL),
    (7, '2026-10-09', 'MORNING', 9.01, 1, NULL),
    (7, '2026-10-09', 'EVENING', 8.8, 1, NULL),
    (8, '2026-10-09', 'MORNING', 2.72, 1, NULL),
    (8, '2026-10-09', 'EVENING', 1.86, 1, NULL),
    (1, '2026-10-10', 'MORNING', 7.08, 1, NULL),
    (1, '2026-10-10', 'EVENING', 4.1, 1, NULL),
    (2, '2026-10-10', 'MORNING', 3.95, 1, NULL),
    (2, '2026-10-10', 'EVENING', 2.94, 1, NULL),
    (3, '2026-10-10', 'MORNING', 7.43, 1, NULL),
    (3, '2026-10-10', 'EVENING', 5.03, 1, NULL),
    (4, '2026-10-10', 'MORNING', 3.25, 1, NULL),
    (5, '2026-10-10', 'MORNING', 5.59, 1, NULL),
    (5, '2026-10-10', 'EVENING', 4.52, 1, NULL),
    (6, '2026-10-10', 'MORNING', 3.56, 1, NULL),
    (6, '2026-10-10', 'EVENING', 2.72, 1, NULL),
    (7, '2026-10-10', 'MORNING', 9.53, 1, NULL),
    (7, '2026-10-10', 'EVENING', 7.01, 1, NULL),
    (8, '2026-10-10', 'MORNING', 2.56, 1, NULL),
    (8, '2026-10-10', 'EVENING', 2.06, 1, NULL),
    (1, '2026-10-11', 'MORNING', 5.46, 1, NULL),
    (1, '2026-10-11', 'EVENING', 4.12, 1, NULL),
    (2, '2026-10-11', 'MORNING', 3.6, 1, NULL),
    (2, '2026-10-11', 'EVENING', 3.09, 1, NULL),
    (3, '2026-10-11', 'EVENING', 6.01, 1, NULL),
    (4, '2026-10-11', 'MORNING', 3.37, 1, NULL),
    (4, '2026-10-11', 'EVENING', 2.02, 1, NULL),
    (5, '2026-10-11', 'MORNING', 4.69, 1, NULL),
    (5, '2026-10-11', 'EVENING', 3.7, 1, NULL),
    (6, '2026-10-11', 'MORNING', 3.38, 1, NULL),
    (6, '2026-10-11', 'EVENING', 2.57, 1, NULL),
    (7, '2026-10-11', 'MORNING', 9.91, 1, NULL),
    (7, '2026-10-11', 'EVENING', 8.64, 1, NULL),
    (8, '2026-10-11', 'MORNING', 2.27, 1, NULL),
    (8, '2026-10-11', 'EVENING', 2.06, 1, NULL),
    (1, '2026-10-12', 'MORNING', 5.38, 1, NULL),
    (1, '2026-10-12', 'EVENING', 4.29, 1, NULL),
    (2, '2026-10-12', 'MORNING', 4.39, 1, NULL),
    (2, '2026-10-12', 'EVENING', 3.02, 1, NULL),
    (3, '2026-10-12', 'MORNING', 7.73, 0, 'Failed alcohol test'),
    (3, '2026-10-12', 'EVENING', 6.75, 1, NULL),
    (4, '2026-10-12', 'MORNING', 3.13, 1, NULL),
    (4, '2026-10-12', 'EVENING', 1.83, 1, NULL),
    (5, '2026-10-12', 'MORNING', 5.03, 1, NULL),
    (5, '2026-10-12', 'EVENING', 4.68, 1, NULL),
    (6, '2026-10-12', 'MORNING', 3.76, 1, NULL),
    (6, '2026-10-12', 'EVENING', 2.85, 1, NULL),
    (7, '2026-10-12', 'MORNING', 11.64, 1, NULL),
    (7, '2026-10-12', 'EVENING', 8.39, 1, NULL),
    (8, '2026-10-12', 'MORNING', 3.07, 1, NULL),
    (8, '2026-10-12', 'EVENING', 2.08, 1, NULL),
    (1, '2026-10-13', 'MORNING', 5.94, 1, NULL),
    (1, '2026-10-13', 'EVENING', 4.01, 1, NULL),
    (2, '2026-10-13', 'MORNING', 5.02, 1, NULL),
    (2, '2026-10-13', 'EVENING', 2.79, 1, NULL),
    (3, '2026-10-13', 'MORNING', 8.22, 1, NULL),
    (3, '2026-10-13', 'EVENING', 5.09, 1, NULL),
    (4, '2026-10-13', 'MORNING', 2.81, 1, NULL),
    (4, '2026-10-13', 'EVENING', 1.98, 1, NULL),
    (5, '2026-10-13', 'MORNING', 5.72, 1, NULL),
    (5, '2026-10-13', 'EVENING', 3.7, 1, NULL),
    (6, '2026-10-13', 'MORNING', 3.98, 1, NULL),
    (6, '2026-10-13', 'EVENING', 2.3, 1, NULL),
    (7, '2026-10-13', 'MORNING', 9.15, 1, NULL),
    (7, '2026-10-13', 'EVENING', 6.53, 1, NULL),
    (8, '2026-10-13', 'MORNING', 2.89, 1, NULL),
    (8, '2026-10-13', 'EVENING', 1.72, 1, NULL),
    (1, '2026-10-14', 'MORNING', 6.95, 1, NULL),
    (1, '2026-10-14', 'EVENING', 5.36, 1, NULL),
    (2, '2026-10-14', 'MORNING', 4.46, 1, NULL),
    (2, '2026-10-14', 'EVENING', 2.71, 1, NULL),
    (3, '2026-10-14', 'MORNING', 7.33, 1, NULL),
    (3, '2026-10-14', 'EVENING', 6.35, 1, NULL),
    (4, '2026-10-14', 'MORNING', 2.54, 1, NULL),
    (4, '2026-10-14', 'EVENING', 2.37, 1, NULL),
    (5, '2026-10-14', 'MORNING', 6.42, 1, NULL),
    (5, '2026-10-14', 'EVENING', 3.72, 1, NULL),
    (6, '2026-10-14', 'MORNING', 3.07, 1, NULL),
    (6, '2026-10-14', 'EVENING', 2.6, 1, NULL),
    (7, '2026-10-14', 'MORNING', 9.23, 1, NULL),
    (7, '2026-10-14', 'EVENING', 7.66, 1, NULL),
    (8, '2026-10-14', 'MORNING', 2.95, 1, NULL),
    (8, '2026-10-14', 'EVENING', 2.02, 1, NULL),
    (1, '2026-10-15', 'MORNING', 7.02, 1, NULL),
    (1, '2026-10-15', 'EVENING', 4.97, 1, NULL),
    (2, '2026-10-15', 'MORNING', 3.92, 1, NULL),
    (2, '2026-10-15', 'EVENING', 3.08, 1, NULL),
    (3, '2026-10-15', 'MORNING', 7.22, 1, NULL),
    (3, '2026-10-15', 'EVENING', 5.58, 1, NULL),
    (4, '2026-10-15', 'MORNING', 2.91, 1, NULL),
    (5, '2026-10-15', 'MORNING', 5.83, 1, NULL),
    (5, '2026-10-15', 'EVENING', 4.0, 1, NULL),
    (6, '2026-10-15', 'MORNING', 3.73, 1, NULL),
    (6, '2026-10-15', 'EVENING', 2.82, 1, NULL),
    (7, '2026-10-15', 'MORNING', 9.31, 1, NULL),
    (7, '2026-10-15', 'EVENING', 8.71, 1, NULL),
    (8, '2026-10-15', 'MORNING', 2.79, 1, NULL),
    (8, '2026-10-15', 'EVENING', 1.62, 1, NULL),
    (1, '2026-10-16', 'MORNING', 7.41, 1, NULL),
    (1, '2026-10-16', 'EVENING', 4.7, 1, NULL),
    (2, '2026-10-16', 'MORNING', 3.9, 1, NULL),
    (2, '2026-10-16', 'EVENING', 3.1, 1, NULL),
    (3, '2026-10-16', 'MORNING', 7.21, 1, NULL),
    (3, '2026-10-16', 'EVENING', 5.38, 1, NULL),
    (4, '2026-10-16', 'EVENING', 2.19, 1, NULL),
    (5, '2026-10-16', 'MORNING', 6.23, 1, NULL),
    (5, '2026-10-16', 'EVENING', 4.63, 1, NULL),
    (6, '2026-10-16', 'MORNING', 3.55, 1, NULL),
    (6, '2026-10-16', 'EVENING', 2.14, 1, NULL),
    (7, '2026-10-16', 'MORNING', 10.69, 1, NULL),
    (7, '2026-10-16', 'EVENING', 6.47, 1, NULL),
    (8, '2026-10-16', 'MORNING', 2.24, 1, NULL),
    (8, '2026-10-16', 'EVENING', 1.79, 1, NULL),
    (1, '2026-10-17', 'MORNING', 6.85, 1, NULL),
    (1, '2026-10-17', 'EVENING', 4.68, 1, NULL),
    (2, '2026-10-17', 'MORNING', 4.18, 1, NULL),
    (2, '2026-10-17', 'EVENING', 3.41, 1, NULL),
    (3, '2026-10-17', 'MORNING', 8.8, 1, NULL),
    (3, '2026-10-17', 'EVENING', 5.99, 1, NULL),
    (4, '2026-10-17', 'MORNING', 2.97, 1, NULL),
    (4, '2026-10-17', 'EVENING', 1.79, 1, NULL),
    (5, '2026-10-17', 'MORNING', 5.33, 1, NULL),
    (6, '2026-10-17', 'MORNING', 2.92, 1, NULL),
    (7, '2026-10-17', 'MORNING', 10.89, 1, NULL),
    (7, '2026-10-17', 'EVENING', 6.28, 1, NULL),
    (8, '2026-10-17', 'MORNING', 2.85, 1, NULL),
    (8, '2026-10-17', 'EVENING', 1.91, 1, NULL),
    (1, '2026-10-18', 'EVENING', 5.0, 1, NULL),
    (2, '2026-10-18', 'MORNING', 4.31, 1, NULL),
    (2, '2026-10-18', 'EVENING', 2.96, 1, NULL),
    (3, '2026-10-18', 'MORNING', 9.32, 1, NULL),
    (3, '2026-10-18', 'EVENING', 6.59, 1, NULL),
    (4, '2026-10-18', 'MORNING', 2.62, 1, NULL),
    (4, '2026-10-18', 'EVENING', 1.85, 1, NULL),
    (5, '2026-10-18', 'MORNING', 5.81, 1, NULL),
    (5, '2026-10-18', 'EVENING', 4.5, 1, NULL),
    (6, '2026-10-18', 'MORNING', 2.91, 1, NULL),
    (6, '2026-10-18', 'EVENING', 2.61, 1, NULL),
    (7, '2026-10-18', 'MORNING', 8.93, 1, NULL),
    (7, '2026-10-18', 'EVENING', 7.73, 1, NULL),
    (8, '2026-10-18', 'MORNING', 2.93, 1, NULL),
    (8, '2026-10-18', 'EVENING', 1.92, 1, NULL),
    (1, '2026-10-19', 'MORNING', 6.6, 1, NULL),
    (1, '2026-10-19', 'EVENING', 4.56, 1, NULL),
    (2, '2026-10-19', 'MORNING', 3.9, 1, NULL),
    (2, '2026-10-19', 'EVENING', 2.84, 1, NULL),
    (3, '2026-10-19', 'MORNING', 9.28, 1, NULL),
    (3, '2026-10-19', 'EVENING', 5.97, 1, NULL),
    (4, '2026-10-19', 'MORNING', 3.34, 1, NULL),
    (4, '2026-10-19', 'EVENING', 1.95, 1, NULL),
    (5, '2026-10-19', 'MORNING', 4.6, 1, NULL),
    (5, '2026-10-19', 'EVENING', 3.36, 1, NULL),
    (6, '2026-10-19', 'MORNING', 3.58, 0, 'Failed alcohol test'),
    (6, '2026-10-19', 'EVENING', 2.95, 1, NULL),
    (7, '2026-10-19', 'MORNING', 11.03, 1, NULL),
    (7, '2026-10-19', 'EVENING', 8.68, 1, NULL),
    (8, '2026-10-19', 'MORNING', 2.83, 1, NULL),
    (8, '2026-10-19', 'EVENING', 1.74, 1, NULL),
    (1, '2026-10-20', 'MORNING', 6.15, 1, NULL),
    (1, '2026-10-20', 'EVENING', 4.89, 1, NULL),
    (2, '2026-10-20', 'MORNING', 5.03, 1, NULL),
    (2, '2026-10-20', 'EVENING', 2.63, 1, NULL),
    (3, '2026-10-20', 'MORNING', 8.57, 1, NULL),
    (3, '2026-10-20', 'EVENING', 5.91, 1, NULL),
    (4, '2026-10-20', 'MORNING', 3.23, 1, NULL),
    (4, '2026-10-20', 'EVENING', 2.02, 1, NULL),
    (5, '2026-10-20', 'MORNING', 4.83, 1, NULL),
    (5, '2026-10-20', 'EVENING', 3.54, 1, NULL),
    (6, '2026-10-20', 'MORNING', 4.03, 1, NULL),
    (6, '2026-10-20', 'EVENING', 2.41, 1, NULL),
    (7, '2026-10-20', 'MORNING', 9.78, 1, NULL),
    (7, '2026-10-20', 'EVENING', 8.23, 1, NULL),
    (8, '2026-10-20', 'MORNING', 2.88, 1, NULL),
    (8, '2026-10-20', 'EVENING', 1.68, 1, NULL),
    (1, '2026-10-21', 'MORNING', 5.67, 1, NULL),
    (1, '2026-10-21', 'EVENING', 4.7, 1, NULL),
    (2, '2026-10-21', 'MORNING', 4.97, 1, NULL),
    (2, '2026-10-21', 'EVENING', 3.53, 1, NULL),
    (3, '2026-10-21', 'MORNING', 7.36, 1, NULL),
    (3, '2026-10-21', 'EVENING', 5.81, 1, NULL),
    (4, '2026-10-21', 'MORNING', 2.52, 1, NULL),
    (4, '2026-10-21', 'EVENING', 2.42, 1, NULL),
    (5, '2026-10-21', 'MORNING', 5.37, 0, 'Failed alcohol test'),
    (5, '2026-10-21', 'EVENING', 3.51, 1, NULL),
    (6, '2026-10-21', 'MORNING', 3.24, 1, NULL),
    (6, '2026-10-21', 'EVENING', 2.34, 1, NULL),
    (7, '2026-10-21', 'EVENING', 8.35, 1, NULL),
    (8, '2026-10-21', 'MORNING', 2.9, 1, NULL),
    (8, '2026-10-21', 'EVENING', 2.11, 1, NULL),
    (1, '2026-10-22', 'MORNING', 5.57, 1, NULL),
    (1, '2026-10-22', 'EVENING', 4.27, 1, NULL),
    (2, '2026-10-22', 'MORNING', 4.25, 1, NULL),
    (2, '2026-10-22', 'EVENING', 2.68, 1, NULL),
    (3, '2026-10-22', 'MORNING', 8.87, 1, NULL),
    (3, '2026-10-22', 'EVENING', 4.91, 1, NULL),
    (4, '2026-10-22', 'MORNING', 2.57, 1, NULL),
    (4, '2026-10-22', 'EVENING', 1.94, 1, NULL),
    (5, '2026-10-22', 'MORNING', 5.46, 1, NULL),
    (5, '2026-10-22', 'EVENING', 3.46, 1, NULL),
    (6, '2026-10-22', 'EVENING', 2.24, 1, NULL),
    (7, '2026-10-22', 'MORNING', 8.75, 1, NULL),
    (7, '2026-10-22', 'EVENING', 8.74, 1, NULL),
    (8, '2026-10-22', 'MORNING', 2.39, 1, NULL),
    (8, '2026-10-22', 'EVENING', 2.04, 1, NULL),
    (1, '2026-10-23', 'MORNING', 7.31, 1, NULL),
    (1, '2026-10-23', 'EVENING', 5.08, 1, NULL),
    (2, '2026-10-23', 'MORNING', 4.89, 1, NULL),
    (2, '2026-10-23', 'EVENING', 3.01, 1, NULL),
    (3, '2026-10-23', 'MORNING', 7.3, 1, NULL),
    (3, '2026-10-23', 'EVENING', 6.71, 1, NULL),
    (4, '2026-10-23', 'MORNING', 3.13, 1, NULL),
    (4, '2026-10-23', 'EVENING', 1.81, 1, NULL),
    (5, '2026-10-23', 'MORNING', 5.93, 1, NULL),
    (5, '2026-10-23', 'EVENING', 4.57, 1, NULL),
    (6, '2026-10-23', 'MORNING', 2.98, 1, NULL),
    (6, '2026-10-23', 'EVENING', 2.27, 1, NULL),
    (7, '2026-10-23', 'MORNING', 9.71, 1, NULL),
    (7, '2026-10-23', 'EVENING', 8.26, 1, NULL),
    (8, '2026-10-23', 'MORNING', 2.48, 1, NULL),
    (8, '2026-10-23', 'EVENING', 2.17, 1, NULL),
    (1, '2026-10-24', 'MORNING', 5.33, 1, NULL),
    (1, '2026-10-24', 'EVENING', 5.27, 1, NULL),
    (2, '2026-10-24', 'MORNING', 3.81, 1, NULL),
    (2, '2026-10-24', 'EVENING', 3.55, 1, NULL),
    (3, '2026-10-24', 'MORNING', 6.71, 1, NULL),
    (3, '2026-10-24', 'EVENING', 6.21, 1, NULL),
    (4, '2026-10-24', 'MORNING', 2.62, 1, NULL),
    (4, '2026-10-24', 'EVENING', 2.07, 1, NULL),
    (5, '2026-10-24', 'MORNING', 5.37, 1, NULL),
    (5, '2026-10-24', 'EVENING', 3.48, 1, NULL),
    (6, '2026-10-24', 'MORNING', 3.99, 1, NULL),
    (6, '2026-10-24', 'EVENING', 2.9, 1, NULL),
    (7, '2026-10-24', 'MORNING', 10.84, 1, NULL),
    (7, '2026-10-24', 'EVENING', 6.73, 1, NULL),
    (8, '2026-10-24', 'MORNING', 3.06, 1, NULL),
    (1, '2026-10-25', 'MORNING', 5.97, 1, NULL),
    (1, '2026-10-25', 'EVENING', 3.86, 1, NULL),
    (2, '2026-10-25', 'MORNING', 4.37, 1, NULL),
    (2, '2026-10-25', 'EVENING', 3.48, 1, NULL),
    (3, '2026-10-25', 'MORNING', 8.71, 1, NULL),
    (3, '2026-10-25', 'EVENING', 6.37, 1, NULL),
    (4, '2026-10-25', 'MORNING', 3.35, 1, NULL),
    (4, '2026-10-25', 'EVENING', 1.83, 1, NULL),
    (5, '2026-10-25', 'MORNING', 5.0, 1, NULL),
    (5, '2026-10-25', 'EVENING', 4.03, 1, NULL),
    (6, '2026-10-25', 'MORNING', 3.65, 1, NULL),
    (6, '2026-10-25', 'EVENING', 2.85, 1, NULL),
    (7, '2026-10-25', 'MORNING', 12.1, 1, NULL),
    (7, '2026-10-25', 'EVENING', 7.7, 1, NULL),
    (8, '2026-10-25', 'MORNING', 2.34, 1, NULL),
    (1, '2026-10-26', 'MORNING', 7.23, 1, NULL),
    (2, '2026-10-26', 'MORNING', 5.11, 1, NULL),
    (2, '2026-10-26', 'EVENING', 3.03, 1, NULL),
    (3, '2026-10-26', 'MORNING', 7.44, 1, NULL),
    (3, '2026-10-26', 'EVENING', 6.45, 1, NULL),
    (4, '2026-10-26', 'MORNING', 2.88, 1, NULL),
    (4, '2026-10-26', 'EVENING', 1.99, 1, NULL),
    (5, '2026-10-26', 'MORNING', 4.9, 1, NULL),
    (5, '2026-10-26', 'EVENING', 4.62, 1, NULL),
    (6, '2026-10-26', 'MORNING', 3.2, 1, NULL),
    (6, '2026-10-26', 'EVENING', 2.45, 1, NULL),
    (7, '2026-10-26', 'MORNING', 10.26, 1, NULL),
    (7, '2026-10-26', 'EVENING', 7.47, 1, NULL),
    (8, '2026-10-26', 'MORNING', 2.72, 1, NULL),
    (8, '2026-10-26', 'EVENING', 2.08, 1, NULL),
    (1, '2026-10-27', 'MORNING', 6.55, 1, NULL),
    (1, '2026-10-27', 'EVENING', 5.07, 1, NULL),
    (2, '2026-10-27', 'EVENING', 2.79, 1, NULL),
    (3, '2026-10-27', 'MORNING', 8.73, 1, NULL),
    (3, '2026-10-27', 'EVENING', 5.84, 1, NULL),
    (4, '2026-10-27', 'MORNING', 3.01, 1, NULL),
    (4, '2026-10-27', 'EVENING', 2.37, 1, NULL),
    (5, '2026-10-27', 'MORNING', 5.02, 1, NULL),
    (5, '2026-10-27', 'EVENING', 3.29, 1, NULL),
    (6, '2026-10-27', 'MORNING', 3.98, 1, NULL),
    (6, '2026-10-27', 'EVENING', 2.78, 1, NULL),
    (7, '2026-10-27', 'MORNING', 9.28, 1, NULL),
    (7, '2026-10-27', 'EVENING', 7.52, 1, NULL),
    (8, '2026-10-27', 'MORNING', 3.08, 1, NULL),
    (8, '2026-10-27', 'EVENING', 2.01, 1, NULL),
    (1, '2026-10-28', 'MORNING', 6.77, 1, NULL),
    (1, '2026-10-28', 'EVENING', 4.06, 1, NULL),
    (2, '2026-10-28', 'MORNING', 3.95, 1, NULL),
    (2, '2026-10-28', 'EVENING', 3.28, 1, NULL),
    (3, '2026-10-28', 'MORNING', 7.49, 1, NULL),
    (3, '2026-10-28', 'EVENING', 6.81, 1, NULL),
    (4, '2026-10-28', 'MORNING', 3.42, 1, NULL),
    (4, '2026-10-28', 'EVENING', 2.22, 1, NULL),
    (5, '2026-10-28', 'MORNING', 5.52, 1, NULL),
    (5, '2026-10-28', 'EVENING', 4.28, 1, NULL),
    (6, '2026-10-28', 'MORNING', 4.08, 1, NULL),
    (7, '2026-10-28', 'MORNING', 10.07, 1, NULL),
    (7, '2026-10-28', 'EVENING', 6.79, 1, NULL),
    (8, '2026-10-28', 'MORNING', 2.19, 1, NULL),
    (8, '2026-10-28', 'EVENING', 1.98, 1, NULL),
    (1, '2026-10-29', 'MORNING', 6.13, 1, NULL),
    (1, '2026-10-29', 'EVENING', 4.86, 1, NULL),
    (2, '2026-10-29', 'MORNING', 4.6, 1, NULL),
    (2, '2026-10-29', 'EVENING', 2.95, 1, NULL),
    (3, '2026-10-29', 'MORNING', 7.64, 1, NULL),
    (3, '2026-10-29', 'EVENING', 6.05, 1, NULL),
    (4, '2026-10-29', 'MORNING', 2.71, 1, NULL),
    (4, '2026-10-29', 'EVENING', 1.99, 1, NULL),
    (5, '2026-10-29', 'MORNING', 5.1, 1, NULL),
    (5, '2026-10-29', 'EVENING', 4.27, 1, NULL),
    (6, '2026-10-29', 'MORNING', 2.94, 1, NULL),
    (6, '2026-10-29', 'EVENING', 2.19, 1, NULL),
    (7, '2026-10-29', 'MORNING', 11.92, 1, NULL),
    (7, '2026-10-29', 'EVENING', 7.57, 1, NULL),
    (8, '2026-10-29', 'MORNING', 2.74, 1, NULL),
    (8, '2026-10-29', 'EVENING', 2.01, 1, NULL),
    (1, '2026-10-30', 'MORNING', 6.45, 1, NULL),
    (1, '2026-10-30', 'EVENING', 4.17, 1, NULL),
    (2, '2026-10-30', 'MORNING', 3.79, 1, NULL),
    (2, '2026-10-30', 'EVENING', 3.11, 1, NULL),
    (3, '2026-10-30', 'MORNING', 7.69, 1, NULL),
    (3, '2026-10-30', 'EVENING', 6.89, 1, NULL),
    (4, '2026-10-30', 'MORNING', 2.65, 1, NULL),
    (4, '2026-10-30', 'EVENING', 2.14, 1, NULL),
    (5, '2026-10-30', 'MORNING', 4.89, 1, NULL),
    (5, '2026-10-30', 'EVENING', 3.82, 1, NULL),
    (6, '2026-10-30', 'MORNING', 3.71, 1, NULL),
    (6, '2026-10-30', 'EVENING', 2.29, 1, NULL),
    (7, '2026-10-30', 'MORNING', 9.53, 1, NULL),
    (7, '2026-10-30', 'EVENING', 7.91, 1, NULL),
    (8, '2026-10-30', 'MORNING', 2.24, 1, NULL),
    (8, '2026-10-30', 'EVENING', 2.02, 1, NULL),
    (1, '2026-10-31', 'MORNING', 5.98, 1, NULL),
    (1, '2026-10-31', 'EVENING', 3.81, 1, NULL),
    (2, '2026-10-31', 'MORNING', 3.6, 1, NULL),
    (2, '2026-10-31', 'EVENING', 2.92, 1, NULL),
    (3, '2026-10-31', 'MORNING', 8.1, 1, NULL),
    (3, '2026-10-31', 'EVENING', 5.71, 1, NULL),
    (4, '2026-10-31', 'MORNING', 2.89, 1, NULL),
    (4, '2026-10-31', 'EVENING', 1.76, 1, NULL),
    (5, '2026-10-31', 'MORNING', 4.63, 1, NULL),
    (5, '2026-10-31', 'EVENING', 4.42, 1, NULL),
    (6, '2026-10-31', 'MORNING', 2.87, 1, NULL),
    (6, '2026-10-31', 'EVENING', 2.16, 1, NULL),
    (7, '2026-10-31', 'MORNING', 8.74, 1, NULL),
    (7, '2026-10-31', 'EVENING', 7.51, 1, NULL),
    (8, '2026-10-31', 'MORNING', 2.74, 1, NULL),
    (8, '2026-10-31', 'EVENING', 1.56, 1, NULL);


-- --- Deductions ------------------------------------------------------------
-- What the sacco holds back from the October payment.

INSERT INTO deduction (farmer_id, period_year, period_month, deduction_type, amount, note) VALUES
    (1, 2026, 10, 'FEEDS',      4500.00, '3 bags dairy meal'),
    (1, 2026, 10, 'SHARES',      500.00, 'Monthly share contribution'),
    (2, 2026, 10, 'SHARES',      500.00, 'Monthly share contribution'),
    (3, 2026, 10, 'AI_SERVICE', 2500.00, 'AI call-out, 12 Oct'),
    (3, 2026, 10, 'LOAN',       6000.00, 'Instalment 4 of 12'),
    (4, 2026, 10, 'SHARES',      500.00, 'Monthly share contribution'),
    (5, 2026, 10, 'FEEDS',      3000.00, '2 bags dairy meal'),
    (7, 2026, 10, 'LOAN',       8000.00, 'Instalment 2 of 10'),
    (7, 2026, 10, 'SHARES',      500.00, 'Monthly share contribution'),
    (8, 2026, 10, 'AI_SERVICE', 2500.00, 'AI call-out, 03 Oct');


-- --- Payments --------------------------------------------------------------
-- Left empty on purpose. Generating these rows from the deliveries and the
-- deductions above IS the Week 13 payment run.
