# Merritt Cron Scripts

This library is part of the [Merritt Preservation System](https://github.com/CDLUC3/mrt-doc).

## Purpose
The purpose of this repository is to house crons for the Merritt system that can be run from any host.

## Merritt Object Health
- [Merritt Object Health System](coll-health-obj-analysis/README.md)

## Code invoked by this repository
- [Merritt Billing Scripts](https://github.com/CDLUC3/mrt-admin-lambda/tree/main/merrit-billing)
  - Depends on https://github.com/CDLUC3/uc3-aws-cli
- [Merritt Consistency Reports](consistency-driver/README.md)
- Merritt Collection Health
  - [Extract Merritt Billing Data for OpenSearch](viz/README.md) 
  - [Extract Merritt File Data for OpenSearch](coll-health/README.md)
  - [Collection Health Comprehensive Design](coll-health-obj-analysis/README.md)

## Code under development
- [schema extract code](schema) - code to keep the integration test schema files consistent with our production schema

## External Code running on the same server
- [Nuxeo Processing](https://github.com/CDLUC3/mrt-atom)
- [Nuxeo Scripts](https://github.com/CDLUC3/mrt-atom)

