#!/bin/bash
#
#
# Change Mix/Mix to Can / Pet
# requested by Lidl Poland ticket #7579
# BW 2025-01-30 changed so that we delete all materials in t_bin and insert correct values. See ticket #8876

PHP=/home/repant/COSMOS/script/updini.php
DCF=/home/repant/COSMOS/CFG/developer_config.ini
RCF=/home/repant/COSMOS/CFG/repant_config.ini
UCFG=/home/repant/COSMOS/CFG/user_config.ini
UINI=/home/repant/COSMOS/CFG/users.ini
FB=/home/repant/COSMOS/outbox/feedback.txt


DATE=`date +"%Y%m%d %H:%M"`

IS_EXTEND=`grep -c MachineType=eXtend COSMOS/CFG/developer_config.ini`
echo "eXtend: $IS_EXTEND"

if [ "$IS_EXTEND" == "0" ] ; then
	echo "error: script will only run on model eXtend  $DATE"
	echo "error: script will only run on model eXtend  $DATE" > /home/repant/COSMOS/outbox/feedback.txt
	exit 0
fi

MIXBINS=`psql -d cosmos_DB -U cosmos_user -A -q -t -c "SELECT COUNT (*) FROM \"t_binConfig\" WHERE description = 'mix';"`
echo "count of MIX bins: $MIXBINS"

#if [ "$MIXBINS" != "2" ] ; then
#	echo "error: expected 2 mix bins but have $MIXBINS  $DATE"
#	echo "error: expected 2 mix bins but have $MIXBINS  $DATE" > /home/repant/COSMOS/outbox/feedback.txt
#	exit 0
#fi

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

psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'can' WHERE bin = 201";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'pet' WHERE bin = 202";

#bin201 can
psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE bin = 201";
psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\") VALUES (1, 201, 3, 3);"
psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\") VALUES (2, 201, 3, 4);"
psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\") VALUES (3, 201, 3, 5);"
psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\") VALUES (4, 201, 3, 6);"
psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\") VALUES (5, 201, 3, 7);"

#bin202 pet
psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE bin = 202";
psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\") VALUES (6, 202, 3, 1);"

psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set \"inUse\" = TRUE";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set \"isDisabled\" = FALSE";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set \"ignoreFULL\" = FALSE";

#export bin config so COSMOS/DB/ files reflect the changes (in case RpContainerDB import is run & would overwrite our changes)
/home/repant/COSMOS/TOOLS/RpContainerDB export

echo "eXtend Binconfig set to Can/PET  $DATE"
echo "eXtend Binconfig set to Can/PET  $DATE" > /home/repant/COSMOS/outbox/feedback.txt

/home/repant/COSMOS/script/service_stop

exit 0