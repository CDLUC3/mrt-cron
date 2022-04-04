#!/bin/sh

for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_billing_range();' && break || sleep 15; done
for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_object_size();' && break || sleep 15; done
for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_audits_processed();' && break || sleep 15; done
for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_ingests_processed();' && break || sleep 15; done

for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing readwrite < daily_node_counts.sql && break || sleep 15; done