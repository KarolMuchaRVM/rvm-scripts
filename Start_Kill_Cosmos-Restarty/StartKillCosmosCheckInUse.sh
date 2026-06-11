#!/bin/bash
#
# Execute "start_kill_cosmos" if the machine is not in use
# Author: Dawid Palarczyk
# Date: 11.07.2025
DATE=`date +"%Y%m%d %H:%M"`

while true; do
  last_bottle_receipt_id=$(psql -d cosmos_DB -U cosmos_user -c 'select max("receiptID") from "t_bottleList";' -t)
  last_bottle_receipt_id="${last_bottle_receipt_id#"${last_bottle_receipt_id%%[![:space:]]*}"}"   # remove leading whitespace characters
  last_bottle_receipt_id="${last_bottle_receipt_id%"${last_bottle_receipt_id##*[![:space:]]}"}"   # remove trailing whitespace characters

  last_crate_receipt_id=$(psql -d cosmos_DB -U cosmos_user -c 'select max("receiptID") from "t_crateList";' -t)
  last_crate_receipt_id="${last_crate_receipt_id#"${last_crate_receipt_id%%[![:space:]]*}"}"   # remove leading whitespace characters
  last_crate_receipt_id="${last_crate_receipt_id%"${last_crate_receipt_id##*[![:space:]]}"}"   # remove trailing whitespace character

  last_cratebottle_receipt_id=$(psql -d cosmos_DB -U cosmos_user -c 'select max("receiptID") from "t_cratebottleList";' -t)
  last_cratebottle_receipt_id="${last_cratebottle_receipt_id#"${last_cratebottle_receipt_id%%[![:space:]]*}"}"   # remove leading whitespace characters
  last_cratebottle_receipt_id="${last_cratebottle_receipt_id%"${last_cratebottle_receipt_id##*[![:space:]]}"}"   # remove trailing whitespace character

  next_receipt_id=$(psql -d cosmos_DB -U cosmos_user -c 'select "receiptNo" from "t_receiptManagement";' -t)
  next_receipt_id="${next_receipt_id#"${next_receipt_id%%[![:space:]]*}"}"   # remove leading whitespace characters
  next_receipt_id="${next_receipt_id%"${next_receipt_id##*[![:space:]]}"}"   # remove trailing whitespace character

  if [ "$last_bottle_receipt_id" == "$next_receipt_id" ] ; then
	MACHINE_IN_USE=true
  elif [ "$last_crate_receipt_id" == "$next_receipt_id" ] ; then
	MACHINE_IN_USE=true
  elif [ "$last_cratebottle_receipt_id" == "$next_receipt_id" ] ; then
	MACHINE_IN_USE=true
  else
	MACHINE_IN_USE=false
  fi

  if $MACHINE_IN_USE ; then
      echo "The machine is in use, wait $DATE"
      echo "The machine is in use, wait  $DATE" > /home/repant/COSMOS/outbox/feedback.txt
      sleep 5
  else
    echo "execute start_kill_cosmos  $DATE"
    echo "execute start_kill_cosmos  $DATE" >> /home/repant/COSMOS/outbox/feedback.txt
    sh /home/repant/COSMOS/script/start_kill_cosmos
    break
  fi
done
exit 0
