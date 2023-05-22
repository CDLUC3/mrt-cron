# Tools to keep the integration test database schema up to date with the production database schema

~/uc3-aws-cli/bin/uc3-mysqldump.sh -rp /uc3/mrt/prd/ -- --no-data --no-data --compact |grep -v "^\/\*.401[0-9][0-9]" > schema.prd
~/uc3-aws-cli/bin/uc3-mysqldump.sh -rp /uc3/mrt/stg/ -- --no-data --no-data --compact |grep -v "^\/\*.401[0-9][0-9]" > schema.stg

sed -e 's/AUTO_INCREMENT=[0-9][0-9]*/AUTO_INCREMENT=1/' schema.prd > schema.prd.norm
sed -e 's/AUTO_INCREMENT=[0-9][0-9]*/AUTO_INCREMENT=1/' schema.stg > schema.stg.norm
