#!/bin/bash
#
#
# Change RVM/mix/mix/mix/mix/glass to RVM/pet/pet/pet/can/glass and set maxCount

PHP=/home/repant/COSMOS/script/updini.php
DCF=/home/repant/COSMOS/CFG/developer_config.ini
RCF=/home/repant/COSMOS/CFG/repant_config.ini
UCFG=/home/repant/COSMOS/CFG/user_config.ini
UINI=/home/repant/COSMOS/CFG/users.ini
FB=/home/repant/COSMOS/outbox/feedback.txt


DATE=$(date +"%Y.%m.%d %H:%M:%S:%N")
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Script start - Change RVM/mix/mix/mix/mix/glass to RVM/pet/pet/pet/can/glass and set maxCount for Kaufland Proline RVMs"
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Script start - Change RVM/mix/mix/mix/mix/glass to RVM/pet/pet/pet/can/glass and set maxCount for Kaufland Proline RVMs" > $FB

IS_X=`grep -c MachineType=XC COSMOS/CFG/developer_config.ini`
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") RVM machine type: $IS_X (if 1=true -> start, if 0=false -> stop)"
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") RVM machine type: $IS_X (if 1=true -> start, if 0=false -> stop)" >> $FB

if [ "$IS_X" == "0" ] ; then
	echo "$(date +"%Y.%m.%d %H:%M:%S:%N") error: script will only run on model RVM XC"
	echo "$(date +"%Y.%m.%d %H:%M:%S:%N") error: script will only run on model RVM XC" >> $FB
	exit 0
fi

#MIXBINS=`psql -d cosmos_DB -U cosmos_user -A -q -t -c "SELECT COUNT (*) FROM \"t_binConfig\" WHERE description = 'mix';"`
#echo "count of MIX bins: $MIXBINS , $(date +"%Y.%m.%d %H:%M:%S:%N")"
#echo "count of MIX bins: $MIXBINS , $(date +"%Y.%m.%d %H:%M:%S:%N")" >> $FB
#
#if [ "$MIXBINS" != "4" ] ; then
#	echo "error: expected 4 mix bins but have $MIXBINS , $(date +"%Y.%m.%d %H:%M:%S:%N")"
#	echo "error: expected 4 mix bins but have $MIXBINS , $(date +"%Y.%m.%d %H:%M:%S:%N")" >> $FB
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
      echo "$(date +"%Y.%m.%d %H:%M:%S:%N") The machine is in use, wait"
	  echo "$(date +"%Y.%m.%d %H:%M:%S:%N") The machine is in use, wait" >> $FB
      sleep 5
  else
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Set machine in service mode"
	echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Set machine in service mode" >> $FB
    sh /home/repant/COSMOS/script/service_start -f
    break
  fi
done

/home/repant/COSMOS/script/service_start -f

#Only stop when all bins are full - off as we are now Can / Pet
php $PHP $UCFG Stops Check_accept_other_bintypes false


CHECKFRONT=`psql -d cosmos_DB -U cosmos_user -A -q -t -c "SELECT \"automatNo\" FROM \"t_storeInfo\";"`
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") MACHINE NUMBER: $CHECKFRONT (1=left front, 2=right front)"
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") MACHINE NUMBER: $CHECKFRONT (1=left front, 2=right front)" >> $FB

if [ "$CHECKFRONT" = "1" ] ; then
#for left front: in "t_binConfig":
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Starting t_binConfig update for left front"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Starting t_binConfig update for left front" >> $FB
    psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'can', \"maxCount\" = '2500' WHERE bin = '2';"
    psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'pet', \"maxCount\" = '300' WHERE bin = '4';"
    psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'pet', \"maxCount\" = '300' WHERE bin = '6';"
    psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'pet', \"maxCount\" = '300' WHERE bin = '8';"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") t_binConfig update for left front done"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") t_binConfig update for left front done" >> $FB
#for left front: in "t_bin" delete each binID and insert all new records again
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Starting t_bin update for left front"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Starting t_bin update for left front" >> $FB
    psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE \"binID\" BETWEEN 1 AND 14";
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (1, 8, 3, 1, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (2, 6, 3, 1, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (3, 4, 3, 1, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (4, 2, 3, 3, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (5, 2, 3, 4, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (6, 0, 1, 2, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (7, 0, 1, 1, -1, -1, -1);"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") t_bin update for left front done"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") t_bin update for left front done" >> $FB
elif [ "$CHECKFRONT" = "2" ] ; then
#for right front: in "t_binConfig:
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Starting t_binConfig update for right front"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Starting t_binConfig update for right front" >> $FB
    psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'can', \"maxCount\" = '2500' WHERE bin = '1';"
    psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'pet', \"maxCount\" = '300' WHERE bin = '3';"
    psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'pet', \"maxCount\" = '300' WHERE bin = '5';"
    psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'pet', \"maxCount\" = '300' WHERE bin = '7';"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") t_binConfig update for right front done"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") t_binConfig update for right front done" >> $FB
#for right front: in "t_bin" delete each binID and insert all new records again
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Starting t_bin update for right front"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Starting t_bin update for right front" >> $FB
    psql -d cosmos_DB -U cosmos_user -c "delete FROM \"t_bin\" WHERE \"binID\" BETWEEN 1 AND 14";
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (1, 7, 3, 1, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (2, 5, 3, 1, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (3, 3, 3, 1, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (4, 1, 3, 3, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (5, 1, 3, 4, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (6, 0, 1, 2, -1, -1, -1);"
    psql -d cosmos_DB -U cosmos_user -c "INSERT INTO \"t_bin\" (\"binID\", bin, \"categoryID\", \"materialID\", \"maxVolume\", \"colorID\", \"minVolume\") VALUES (7, 0, 1, 1, -1, -1, -1);"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") t_bin update for right front done"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") t_bin update for right front done" >> $FB
else
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Machine number is not 1 or 2 so I won't change anything"
    echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Machine number is not 1 or 2 so I won't change anything" >> $FB
    exit 0
fi

# for both:
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Starting t_binConfig update (parameters common to both fronts)"
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Starting t_binConfig update (parameters common to both fronts)" >> $FB
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set description = 'glas' WHERE bin = 0";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set \"isDisabled\" = 'FALSE' WHERE description != 'glas'";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set \"inUse\" = 'TRUE' WHERE description = 'can'";
psql -d cosmos_DB -U cosmos_user -c "update \"t_binConfig\" set \"ignoreFULL\" = FALSE";
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") t_binConfig update (parameters common to both fronts) done"
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") t_binConfig update (parameters common to both fronts) done" >> $FB
#export bin config so COSMOS/DB/ files reflect the changes (in case RpContainerDB import is run & would overwrite our changes)
/home/repant/COSMOS/TOOLS/RpContainerDB export

echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Script completed successfully"
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") Script completed successfully" >> $FB

/home/repant/COSMOS/script/service_stop
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") I'm leaving service mode, the machine is almost ready"
echo "$(date +"%Y.%m.%d %H:%M:%S:%N") I'm leaving service mode, the machine is almost ready" >> $FB
exit 0
