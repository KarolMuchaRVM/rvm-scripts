#!/bin/sh

COSMOS=/home/repant/COSMOS
if [[ "${R_APP_DIR}" ]]; then
  COSMOS="${R_APP_DIR}/"
fi

OUTBOX="${COSMOS}/outbox"
CURRENT_TIME=`date +"%Y-%m-%d %H:%M:%S"`

echo $CURRENT_TIME

if [ -e "${COSMOS}/inbox/460_importBarcodeDatabase.OK" ] ; then
  echo "Database update started"
else
  echo "Database update failed, OK file missing"
   exit 1
fi

Country=`grep "Edit_CountryCode" ${COSMOS}/CFG/repant_config.ini | cut -f 2 -d '='`
NotReturpack=`rpm -q clearing-system-sweden | grep 'not installed' -c`

if [ -e "${COSMOS}/TOOLS/RpImportRepantDB" ] ; then
	echo "Correct Clearing system"
elif [ "$NotReturpack" != "1" ] ; then
	echo "Clearing system Returpack"
else
	echo "Unable to import bottle database. Correct clearing system not installed"
	echo "Unable to import bottle database. Correct clearing system not installed" > ${COSMOS}/outbox/feedback.txt
	exit 1
fi

if [ -e "${COSMOS}/inbox/repant_barcodes.txt" ] ; then
  echo "Ok repant_barcodes.txt"
else
  echo "Not ready to start script yet, missing barcode file"
  exit 1
fi

#Check pending updates to reVend
CountPending=`psql -d cosmos_DB -U cosmos_user -A -q -t -c "select count(*) from revend_receipts_view;"`  
echo "Pending receipts=$CountPending"

if [ -e "${OUTBOX}/feedback.txt" ] ; then
	WarningCount=`cat ${OUTBOX}/feedback.txt | grep "WARNING: Barcode database not updated" -c`
fi

if [ $CountPending -gt 0 ] ; then
  echo "Not ready to start script yet, waiting for revend to sync"
  echo "WARNING: Barcode database not updated, revend sync pending $CountPending. $CURRENT_TIME" > ${OUTBOX}/feedback.txt
  exit 1
elif [[ $WarningCount == "1" ]] ; then
  echo "revend synced"
  echo "revend synced. $CURRENT_TIME" > ${OUTBOX}/feedback.txt
fi

rm -f ${COSMOS}/inbox/460_importBarcodeDatabase.OK

if [ "$NotReturpack" != "1" ] ; then
	${COSMOS}/script/returpack_clearing_and_import
	exit 1
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
    sh ${COSMOS}/script/service_start -f
    break
  fi
done

COUNTCOLOR=`psql -d cosmos_DB -U cosmos_user -A -q -t -c  "Select count(*) from \"t_bottle\" WHERE \"colorID\" = -1;"`
if [ $COUNTCOLOR -gt 0 ] ; then
	echo "UPDATING BOTTLES WITH colorID = -1, Count: $COUNTCOLOR";
	RESULTCOLOR=`psql -d cosmos_DB -U cosmos_user -c "UPDATE \"t_bottle\" SET \"colorID\" = 5 WHERE \"colorID\" = -1;"`
	echo "UPDATING BOTTLES WITH colorID = -1 RESULTS: $RESULTCOLOR";
fi

DATE=`date +"%Y%m%d%H%M"`
mv ${COSMOS}/new_db_files/repant_barcodes.txt ${COSMOS}/new_db_files/repant_barcodes$DATE.txt
mv ${COSMOS}/inbox/repant_barcodes.txt ${COSMOS}/new_db_files/

echo "Import new database"

if [ "$NotReturpack" != "1" ] ; then
	echo "Returpack Database"
	${COSMOS}/script/returpack_clearing_and_import
else
	if [ -e "${COSMOS}/TOOLS/RpImportRepantDB" ] ; then
		${COSMOS}/TOOLS/RpImportRepantDB
	else
		echo "Failed to import bottle database. Correct clearing system not installed"
		echo "Failed to import bottle database. Correct clearing system not installed" > ${COSMOS}/outbox/feedback.txt
	fi
fi


sh ${COSMOS}/script/service_stop


#echo "Barcode database updated $CURRENT_TIME" > ${COSMOS}/outbox/feedback.txt

exit 0