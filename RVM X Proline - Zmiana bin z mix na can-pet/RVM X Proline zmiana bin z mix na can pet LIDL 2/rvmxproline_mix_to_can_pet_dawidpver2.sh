#!/bin/bash
#
#
# Change Mix/Mix to Can / Pet

PHP=/home/repant/COSMOS/script/updini.php
DCF=/home/repant/COSMOS/CFG/developer_config.ini
RCF=/home/repant/COSMOS/CFG/repant_config.ini
UCFG=/home/repant/COSMOS/CFG/user_config.ini
UINI=/home/repant/COSMOS/CFG/users.ini
FB=/home/repant/COSMOS/outbox/feedback.txt


DATE=`date +"%Y%m%d %H:%M"`

IS_X=`grep -c MachineType=X COSMOS/CFG/developer_config.ini`
echo "RVM X: $IS_X"

if [ "$IS_X" == "0" ] ; then
	echo "error: script will only run on model RVM X  $DATE"
	echo "error: script will only run on model RVM X  $DATE" > /home/repant/COSMOS/outbox/feedback.txt
	exit 0
fi

MIXBINS=`psql -d cosmos_DB -U cosmos_user -A -q -t -c "SELECT COUNT (*) FROM \"t_binConfig\" WHERE description = 'mix';"`
echo "count of MIX bins: $MIXBINS"

if [ "$MIXBINS" != "4" ] ; then
	echo "error: expected 4 mix bins but have $MIXBINS  $DATE"
	echo "error: expected 4 mix bins but have $MIXBINS  $DATE" > /home/repant/COSMOS/outbox/feedback.txt
	exit 0
fi

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
      echo "The machine is in use, wait"
      sleep 5
  else
    echo "Set machine in service mode"
    sh /home/repant/COSMOS/script/service_start -f
    break
  fi
done

/home/repant/COSMOS/script/service_start -f

#Only stop when all bins are full - off as we are now Can / Pet
php $PHP $UCFG Stops Check_accept_other_bintypes false

#for left machine
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET description = 'can' WHERE bin = 2";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET description = 'pet' WHERE bin = 4";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET description = 'pet' WHERE bin = 6";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET description = 'pet' WHERE bin = 8";

psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE bin = 2 AND \"materialID\" NOT IN (3,4,5,6,7)";
psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE bin = 4 AND \"materialID\" IN (3,4,5,6,7)";
psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE bin = 6 AND \"materialID\" IN (3,4,5,6,7)";
psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE bin = 8 AND \"materialID\" IN (3,4,5,6,7)";

#for right machine
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET description = 'can' WHERE bin = 1";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET description = 'pet' WHERE bin = 3";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET description = 'pet' WHERE bin = 5";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET description = 'pet' WHERE bin = 7";

psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE bin = 1 AND \"materialID\" NOT IN (3,4,5,6,7)";
psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE bin = 3 AND \"materialID\" IN (3,4,5,6,7)";
psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE bin = 5 AND \"materialID\" IN (3,4,5,6,7)";
psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE bin = 7 AND \"materialID\" IN (3,4,5,6,7)";

#common to both machines
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET \"inUse\" = 'TRUE' WHERE description = 'can'";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET \"inUse\" = 'TRUE' WHERE description = 'pet' AND \"bin\" = '3'";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET \"inUse\" = 'TRUE' WHERE description = 'pet' AND \"bin\" = '4'";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET \"inUse\" = 'FALSE' WHERE description = 'pet' AND \"bin\" IN (5,6,7,8,9,10)";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET \"isDisabled\" = FALSE";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" SET \"ignoreFULL\" = FALSE";


echo "Binconfig changed from Mix/Mix/Mix/Mix to Can/PET/PET/PET  $DATE"
echo "Binconfig changed from Mix/Mix/Mix/Mix to Can/PET/PET/PET  $DATE" > /home/repant/COSMOS/outbox/feedback.txt

/home/repant/COSMOS/script/service_stop

exit 0