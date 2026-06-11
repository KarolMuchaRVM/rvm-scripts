	#!/bin/bash
base_dir="/home/repant"
if [[ "${R_BASE_DIR}" ]]; then
  base_dir="${R_BASE_DIR}/"
fi

if [ -e "$base_dir/COSMOS/inbox/downgrade_firmware_CM4680.OK" ] ; then
  echo "Ok to start script"
else
  echo "Not ready to start script yet"
  exit 1
fi
DOW=`date +'%u%I' `
chmod +x  $base_dir/COSMOS/inbox/HsmFirmwareReplaceCmd
CM46PRESENT=`lsusb |grep -c "0c2e:10ca"`
if [ $CM46PRESENT -gt "0" ] ; then
    $base_dir/COSMOS/script/service_start
    OK="OK"
	let downgrade=0
    let count=0
	let fwo=0
    SOFT_D="RI000445BAA"
    SOFT="RI000490BAA"
    for port in $(grep "BCS._Port" /home/repant/COSMOS/CFG/developer_config.ini |cut -d '=' -f2); do
    	BCTTY=`ls /sys/bus/usb/devices/$port/tty`
    	echo -e "\n$BCTTY"
    	SEDE="/dev/$BCTTY"
    	stty -F "$SEDE" 38400 raw -echo   #CONFIGURE SERIAL PORT
    	exec 3<"$SEDE"                     #REDIRECT SERIAL OUTPUT TO FD 3
        	cat <&3 > /tmp/ttyDump.dat &          #REDIRECT SERIAL OUTPUT TO FILE
        	PID=$!                                #SAVE PID TO KILL CAT
        	echo -e "\x16M\x0d"'REV?.' > "$SEDE"             #SEND COMMAND STRING TO SERIAL PORT
        	sleep 0.2s                          #WAIT FOR RESPONSE
        	kill $PID                             #KILL CAT PROCESS
        	wait $PID 2>/dev/null                 #SUPRESS "Terminated" output
    	exec 3<&-                               #FREE FD 3
	    FWOK=`grep "$SOFT_D" -c  /tmp/ttyDump.dat`
	    if [ $FWOK != "1" ] ; then
        	OK="Wrong FW!!"
			sleep 5
		    $base_dir/COSMOS/inbox/HsmFirmwareReplaceCmd -d $SEDE -c $base_dir/COSMOS/inbox/downgrade.txt
			sleep 3
		    $base_dir/COSMOS/inbox/HsmFirmwareReplaceCmd -d $SEDE -c $base_dir/COSMOS/inbox/downgrade.txt
			#echo -e "\x16REV_RL1.\r" >$SEDE
			sleep 1
			$base_dir/COSMOS/inbox//HsmFirmwareReplaceCmd -d $SEDE -f $base_dir/COSMOS/inbox/$SOFT_D.smoc
        	$base_dir/COSMOS/inbox//HsmFirmwareReplaceCmd -d $SEDE -c $base_dir/COSMOS/inbox/reset.txt
   	    	sleep 1
			echo "$SEDE downgraded to $SOFT_D"
			BCTTY=`ls /sys/bus/usb/devices/$port/tty`
    		echo -e "\n$BCTTY"
    		SEDE="/dev/$BCTTY"
			#Check fw after downgrade
			stty -F "$SEDE" 38400 raw -echo   #CONFIGURE SERIAL PORT
			exec 3<"$SEDE"                     #REDIRECT SERIAL OUTPUT TO FD 3
				cat <&3 > /tmp/ttyDump.dat &          #REDIRECT SERIAL OUTPUT TO FILE
				PID=$!                                #SAVE PID TO KILL CAT
				echo -e "\x16M\x0d"'REV?.' > "$SEDE"             #SEND COMMAND STRING TO SERIAL PORT
				sleep 0.2s                          #WAIT FOR RESPONSE
				kill $PID                             #KILL CAT PROCESS
				wait $PID 2>/dev/null                 #SUPRESS "Terminated" output
			exec 3<&-                               #FREE FD 3
			FWOK=`grep "$SOFT_D" -c  /tmp/ttyDump.dat`
			FVER=`cat /tmp/ttyDump.dat|cut -d ',' -f9|cut -c4-`
			echo "$FVER"
			if [ $FWOK = "1" ] ; then
				let downgrade++
				let fwo++
			fi
		else
		    let fwo++
	    fi
    	let count++
    	#  cat /tmp/ttyDump.dat                    #DUMP CAPTURED DATA
    done

    $base_dir/COSMOS/script/service_stop
    echo ""
    echo "$DOW $fwo OK, $downgrade downgraded of $count CM4680 barcode readers. Firmware $SOFT_D"
    echo "$DOW $fwo OK, $downgrade downgraded of $count CM4680 barcode readers. Firmware $SOFT_D" > $base_dir/COSMOS/outbox/feedback.txt
else
    echo "$DOW No CM4680 installed"
    echo  "$DOW No CM4680 installed" > $base_dir/COSMOS/outbox/feedback.txt
fi
# Clean-up
rm -rf  $base_dir/COSMOS/inbox/downgrade_firmware_CM4680.OK $base_dir/COSMOS/inbox/downgrade.txt $base_dir/COSMOS/inbox/$SOFT_D.smoc $base_dir/COSMOS/inbox/reset.txt $base_dir/COSMOS/inbox/HsmFirmwareReplaceCmd

