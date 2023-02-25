#!/bin/sh

SCRIPT_HOME=$(dirname $0)

source ~/.profile.d/uc3-aws-util.sh

# Check that the SSM_ROOT_PATH has been initialized
check_ssm_root

BUCKET=`get_ssm_value_by_name admintool/s3-bucket`
echo $BUCKET

cd ${SCRIPT_HOME}

if [ -f inventory.txt ]
then
  echo "inventory.txt exists"
else
  aws s3 cp s3://${BUCKET}/merritt-reports/palmu/inventory.txt .
fi

cat files_ingested.sql | uc3-mysql.sh > pm.loaded.txt

ruby merge.rb 

aws s3 cp match.json s3://${BUCKET}/merritt-reports/palmu/match.json
