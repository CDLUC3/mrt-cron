#!/bin/sh

${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_billing_range();'
${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_object_size();'
${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_audits_processed();'
${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_ingests_processed();'
