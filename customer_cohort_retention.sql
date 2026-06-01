CREATE TABLE users (
    user_id     INT PRIMARY KEY,
    signup_date DATE,
    plan        VARCHAR(20)
);

CREATE TABLE transactions (
    txn_id   INT PRIMARY KEY,
    user_id  INT,
    txn_date DATE,
    amount   DECIMAL(10, 2),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);


INSERT INTO users VALUES
(1,  '2023-01-05', 'pro'),
(2,  '2023-01-12', 'basic'),
(3,  '2023-01-20', 'free'),
(4,  '2023-01-28', 'pro'),
(5,  '2023-02-03', 'basic'),
(6,  '2023-02-14', 'pro'),
(7,  '2023-02-22', 'free'),
(8,  '2023-03-01', 'pro'),
(9,  '2023-03-10', 'basic'),
(10, '2023-03-18', 'free'),
(11, '2023-03-25', 'pro'),
(12, '2023-04-02', 'basic');

INSERT INTO transactions VALUES
(1,  1,  '2023-01-10', 999.00),
(2,  2,  '2023-01-15', 499.00),
(3,  3,  '2023-01-22', 0.00),
(4,  4,  '2023-01-30', 999.00),
(5,  1,  '2023-02-08', 999.00),
(6,  2,  '2023-02-16', 499.00),
(7,  4,  '2023-02-24', 999.00),
(8,  1,  '2023-03-05', 999.00),
(9,  4,  '2023-03-15', 999.00),
(10, 5,  '2023-02-05', 499.00),
(11, 6,  '2023-02-16', 999.00),
(12, 7,  '2023-02-24', 0.00),
(13, 5,  '2023-03-07', 499.00),
(14, 6,  '2023-03-18', 999.00),
(15, 8,  '2023-03-03', 999.00),
(16, 9,  '2023-03-12', 499.00),
(17, 10, '2023-03-20', 0.00),
(18, 11, '2023-03-27', 999.00),
(19, 8,  '2023-04-04', 999.00),
(20, 12, '2023-04-05', 499.00);


-- Transaction ranking and cumulative spend
SELECT
    t.user_id,
    u.plan,
    t.txn_date,
    t.amount,
    ROW_NUMBER() OVER (
        PARTITION BY u.plan
        ORDER BY t.amount DESC
    ) AS rank_within_plan,
    SUM(t.amount) OVER (
        PARTITION BY t.user_id
        ORDER BY t.txn_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_spend
FROM transactions t
JOIN users u ON t.user_id = u.user_id
ORDER BY u.plan, t.amount DESC;


-- Month-over-month revenue growth 
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(txn_date, '%Y-%m') AS month,
        SUM(amount)                    AS revenue
    FROM transactions
    GROUP BY DATE_FORMAT(txn_date, '%Y-%m')
)
SELECT
    month,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue, 1) OVER (ORDER BY month))
        / LAG(revenue, 1) OVER (ORDER BY month) * 100,
    1) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;


-- Cohort retention analysis
WITH cohorts AS (
    SELECT
        user_id,
        DATE_FORMAT(signup_date, '%Y-%m') AS cohort_month
    FROM users
),
user_activity AS (
    SELECT
        t.user_id,
        c.cohort_month,
        DATE_FORMAT(t.txn_date, '%Y-%m') AS activity_month,
        PERIOD_DIFF(
            DATE_FORMAT(t.txn_date, '%Y%m'),
            DATE_FORMAT(c.cohort_month, '%Y%m')
        ) AS months_since_signup
    FROM transactions t
    JOIN cohorts c ON t.user_id = c.user_id
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM cohorts
    GROUP BY cohort_month
)
SELECT
    ua.cohort_month,
    cs.cohort_size,
    ua.months_since_signup,
    COUNT(DISTINCT ua.user_id)                                   AS active_users,
    ROUND(COUNT(DISTINCT ua.user_id) / cs.cohort_size * 100, 1) AS retention_pct
FROM user_activity ua
JOIN cohort_sizes cs ON ua.cohort_month = cs.cohort_month
WHERE ua.months_since_signup >= 0
GROUP BY ua.cohort_month, cs.cohort_size, ua.months_since_signup
ORDER BY ua.cohort_month, ua.months_since_signup;


-- Churn risk scoring
WITH last_activity AS (
    SELECT
        user_id,
        MAX(txn_date) AS last_txn_date
    FROM transactions
    GROUP BY user_id
)
SELECT
    u.user_id,
    u.plan,
    u.signup_date,
    la.last_txn_date,
    DATEDIFF('2023-05-01', la.last_txn_date) AS days_inactive,
    CASE
        WHEN DATEDIFF('2023-05-01', la.last_txn_date) > 60 THEN 'Churned'
        WHEN DATEDIFF('2023-05-01', la.last_txn_date) > 30 THEN 'At Risk'
        ELSE 'Active'
    END AS churn_status
FROM users u
JOIN last_activity la ON u.user_id = la.user_id
ORDER BY days_inactive DESC;


-- Users with above-average total spend
SELECT
    u.user_id,
    u.plan,
    SUM(t.amount) AS total_spent
FROM users u
JOIN transactions t ON u.user_id = t.user_id
GROUP BY u.user_id, u.plan
HAVING SUM(t.amount) > (
    SELECT AVG(user_total)
    FROM (
        SELECT user_id, SUM(amount) AS user_total
        FROM transactions
        GROUP BY user_id
    ) AS user_totals
)
ORDER BY total_spent DESC;
