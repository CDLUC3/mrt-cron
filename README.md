# Merritt Cron Scripts

This library is part of the [Merritt Preservation System](https://github.com/CDLUC3/mrt-doc).

## Purpose
The purpose of this repository is to house crons for the Merritt system that can be run from any host.
## Code invoked by this repository
- [Merritt Billing Scripts](https://github.com/CDLUC3/mrt-admin-lambda/tree/main/merrit-billing)
  - Depends on https://github.com/CDLUC3/uc3-aws-cli
- [Merritt Consistency Reports](https://github.com/CDLUC3/mrt-admin-lambda)
- Merritt Collection Health
  - [Initial prototype using billing data](viz) 
  - [Prototype using 20M file records](coll-health)
  - [Collection Health Comprehensive Design](coll-health-obj-analysis)

## Code under development
- [schema extract code](schema) - code to keep the integration test schema files consistent with our production schema

## External Code running on the same server
- [Nuxeo Processing](https://github.com/CDLUC3/mrt-atom)

