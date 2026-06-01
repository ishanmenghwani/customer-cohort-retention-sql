About the Project
This project models user retention behaviour for a mock subscription-based platform with 12 users across three plan tiers (free, basic, pro) and 20 transactions over four months. The analysis focuses on understanding how well the platform retains users after acquisition — a critical metric in any SaaS or edtech product. It builds a month-by-month cohort retention grid, calculates month-over-month revenue growth, and scores users by churn risk based on recency of activity.

Database Schema:
users — user profile with signup date and subscription plan
transactions — transactional history with date and amount per user

Queries:
#Analysis
1) Transaction ranking by plan tier and cumulative spend per user using window functions
2) Month-over-month revenue growth using LAG()
3) Full cohort retention table — % of users active in each month post-signup
4) Churn risk scoring — users flagged as Active, At Risk, or Churned
5) Users with above-average total spend using a nested subquery


How to Run:
1) Open DB Fiddle and select MySQL 8.0
2) Paste the schema and INSERT statements into the left panel
3) Paste individual SELECT queries into the right panel
4) Click Run
