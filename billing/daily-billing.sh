#!/bin/sh

for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_billing_range();' && break || echo "Retry Q1-${i}" && sleep 15; done
for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_object_size();' && break || echo "Retry Q2-${i}" && sleep 15; done
for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_audits_processed();' && break || echo "Retry Q3-${i}" && sleep 15; done
for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_ingests_processed();' && break || echo "Retry Q4-${i}" && sleep 15; done
for i in 1 2 3 4 5; do ${HOME}/bin/uc3-mysql.sh billing -- -e 'call update_node_counts();' && break || echo "Retry Q5-${i}" && sleep 15; done
