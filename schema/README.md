~/uc3-aws-cli/bin/uc3-mysqldump.sh -rp /uc3/mrt/prd/ -- --no-data --no-data --compact |grep -v 40101 > schema.prd
~/uc3-aws-cli/bin/uc3-mysqldump.sh -rp /uc3/mrt/stg/ -- --no-data --no-data --compact |grep -v 40101 > schema.stg

sed -e 's/AUTO_INCREMENT=[0-9][0-9]*/AUTO_INCREMENT=1/' schema.prd > schema.prd.norm
sed -e 's/AUTO_INCREMENT=[0-9][0-9]*/AUTO_INCREMENT=1/' schema.stg > schema.stg.norm
