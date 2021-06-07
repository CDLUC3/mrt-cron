# Merritt Cron Scripts

This library is part of the [Merritt Preservation System](https://github.com/CDLUC3/mrt-doc).

## Code invoked by this repository
- [Merritt Billing Scripts](https://github.com/CDLUC3/mrt-admin-lambda/tree/main/merrit-billing)
- [Merritt Consistency Reports](https://github.com/CDLUC3/mrt-admin-lambda)

## Code to be invoked by this repository
- [Nuxeo Feeds](https://github.com/CDLUC3/mrt-dashboard/tree/main/lib)
- Zookeeper Reports
- Storage Reports

## Recommended Crons

```
# Update billing database with updates from the prior day
0 1 * * * .../billing/daily-billing.sh
0 2 * * * cd .../consistency-driver;ruby driver.sh 
```