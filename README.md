# SQL portfolio

SQL behind the dashboards on my portfolio site, [annakostiuchenko.github.io](https://annakostiuchenko.github.io).
All queries run in **DuckDB** (via DBeaver) on public data.

| Project | What the SQL does | Techniques |
| --- | --- | --- |
| [Customer retention](customer_retention.sql) | Cleans ~1M order lines of a UK online retailer, builds monthly cohorts and RFM customer segments | CTEs, window functions (`FIRST_VALUE`, `NTILE`), `FILTER` aggregates, data-quality checks |
| [Dutch housing market](nl_housing.sql) | Joins 30 years of CBS house-price data for all municipalities, handles merged municipalities, ranks growth with 3-year averages | Joins on code tables, `FILTER` pivots, `RANK()`, `UNION ALL`, sanity checks |

## Data
- **Online Retail II**: UCI Machine Learning Repository, https://archive.ics.uci.edu/dataset/502/online+retail+ii
- **CBS 83625NED**: Bestaande koopwoningen; gemiddelde verkoopprijzen, regio, https://www.cbs.nl/nl-nl/cijfers/detail/83625NED

The raw data isn't stored here. Download it from the links above and update the file paths at the top of each script.

## Notes
- Online Retail data ends on 9 Dec 2011, so each cohort's last month is incomplete.
- CBS figures are average sale prices of existing homes, not a price index; changes in which homes are sold affect them.
