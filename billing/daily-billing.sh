#!/bin/sh

echo 'script start'
${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_billing_range();'
echo 'after billing range'
${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_object_size();'
echo 'after object size'
${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_audits_processed();'
echo 'after audits processed'
${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_ingests_processed();'
echo 'after ingests processed'