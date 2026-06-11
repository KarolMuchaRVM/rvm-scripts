#!/bin/bash

# 20250410 LHS Added
#FORCE_S6
#       FORCE 10.4in TSD touchscreen (alternative supplier) will be calibrated in 800 by 600 resolution inverted touch axis
#FORCE_S7
#       FORCE 10.4in TSD touchscreen (alternative supplier) will be calibrated in 800 by 600 resolution normal touch axis"
#FORCE_S8
#       FORCE 10.4in TSD touchscreen (alternative supplier) will be calibrated in 800 by 600 rotation right resolution normal touch axis"
#FORCE_S3
#       FORCE 21.5 CCE touchscreen in 1280 by 720 resolution and do not setresolution based on alternate res variable"
#FORCE_S9
#       FORCE 21.5in eGalax touchscreen will be calibrated in 1280 by 720 resolution rotation right
#FORCE_S10
#       FORCE 10.4in eGalax P80H46 touchscreen will be calibrated in 800 by 600 resolution rotation right

# 20230719 LHS    Updated add missing mode script with "adjusted" timing and sync parameters to prevent shifted picture, and add this mode even if the mode exist during calibration
#                 Added support for 10.4" TSD screen as screen_type=6

# Make sure only non root can run our script
	if [ "$(id -u)" == "0" ]; then
		echo "This script must not be run as root"
		exit 2
	fi
DATO=`date +"%Y%m%d_%T"`

AZVGA=`lspci |grep -c "VGA compatible controller: Intel Corporation Device 5906"`

if [ "$AZVGA" == "1" ] ; then
    # Antrazit blue PC (IBOX 701 PLus)
    VDEV="DP-1"
else
    VDEV="VGA1"
fi
DISPLAY=:0 xrandr --output eDP-1 --off
VDEV2=`DISPLAY=:0 xrandr --listactivemonitors|tail -1|cut -d ' ' -f6`
if [ "$VDEV2" != "" ] ; then
    VDEV=$VDEV2
fi
VSEP=`echo "$VDEV" |grep -c '-'`
if [ $VSEP == "1" ] ; then
    VD2="LVDS-1"
    VD1="VGA-1"
    VDeDP="eDP-1"
else
    VD2="LVDS1"
    VD1="VGA1"
    VDeDP="eDP1"
fi
LVDSP=`DISPLAY=:0 xrandr |grep -c LVDS`

cosmos_dir="/home/repant/COSMOS/"
if [[ "${R_APP_DIR}" ]]; then
  cosmos_dir="${R_APP_DIR}/"
fi

cosmos_autostart_dir="/home/repant/.kde/Autostart/"
if [[ "${R_AUTOSTART_DIR}" ]]; then
	cosmos_autostart_dir="${R_AUTOSTART_DIR}/"
fi


ILITEK=`DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --list|grep -c 'ILITEK ILITEK-TP'`
eGalax=`DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --list|grep -c 'eGalax Inc'`
eGalaxP80H84=`DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --list|grep -c 'eGalaxTouch P80H84'`
eGalaxP80H46=`DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --list|grep -c 'eGalaxTouch P80H46'`
eGalName=`DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --list|grep 'eGalax'|grep -v 'Pen'|head -1|cut -d '"' -f2`
TSHARC=`DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --list|grep -c 'Hampshire Company TSHARC Analog Resistive'`
AltArch=`grep -c AltArch /etc/redhat-release`

HIRES=`DISPLAY=:0 xrandr |grep -c "1920\|1680\|1280"`
CHROMIUM_REMOTION=`grep 'RunReMotionInChromium=true' ${cosmos_dir}/CFG/developer_config.ini -c`
URL_MENU=`grep 'URL_Menu=' ${cosmos_dir}/CFG/developer_config.ini | sed 's/URL_Menu=//g'`


if [ "$eGalax" -gt 0 ] ; then
    if [ "$eGalaxP80H84" -gt 0 ] ; then
        #Calibrates 21.5" eGalax touchscreen in 1280 by 720 resolution.
        screen_type=9
        echo "21.5in eGalax touchscreen will be calibrated in 1280x720 resolution"
        echo "Screen model: $eGalName"
    elif [ "$eGalaxP80H46" -gt 0 ] ; then
        #Calibrates 10.4" eGalax P80H46 touchscreen in 800 by 600, rotation right.
        screen_type=10
        echo "10.4in eGalax P80H46 touchscreen will be calibrated in 800 by 600 resolution rotation right"
        echo "Screen model: $eGalName"
    else
        #Calibrates 10.4" CCE touchscreen in 800 by 600 resolution.
        screen_type=1
        echo "10.4in CCE touchscreen will be calibrated in 800 by 600 resolution"
    fi
elif [ "$ILITEK" -gt 0 ] ; then
    if [ "$HIRES" -gt 2 ] ; then
	if [ "$CHROMIUM_REMOTION" == "1" ] && [ ! -z "$URL_MENU" ]; then
	  #Calibrates 21.5" CCE touchscreen in 1280 by 720 resolution.
	  echo "21.5in CCE touchscreen will be calibrated in 1280x720 resolution"
	  screen_type=3
	else 
	  #Calibrates 21.5" CCE touchscreen in 800 by 600 resolution.
	  screen_type=4
	  echo "21.5in CCE touchscreen will be calibrated in 800 by 600 resolution"
	fi
    else
        #Calibrates 10.4" CCE touchscreen in 800 by 600 resolution.
        screen_type=6
        echo "10.4in TSD touchscreen (alternative supplier) will be calibrated in 800 by 600 resolution"
    fi
elif [ "$TSHARC" -gt 0 ] && [ "$AltArch" -gt 0 ] ; then
    #Calibrates 8.4" LVDS touchscreen in 800 by 480 resolution on old PC hardware with 32bit CentOS 7 altarch image.
    screen_type=5
    echo "8.4in LVDS touchscreen will be calibrated in 800 by 480 resolution for AltArch old 32bit PC"
else
    # If all else fails we will assume old LVDS screen
    screen_type=2
    echo "No screen detected will assume old 8.4in LVDS touchscreen"
fi

# Parse commands and parameters


#screen_type=0
echo "$1" 
case $1 in

       FORCE_S6)
  	           echo "FORCE 10.4in TSD touchscreen (alternative supplier) will be calibrated in 800 by 600 resolution inverted touch axis"
               screen_type=6;; #Force screen type 6
       FORCE_S7)
               echo "FORCE 10.4in TSD touchscreen (alternative supplier) will be calibrated in 800 by 600 resolution normal touch axis"
               screen_type=7;; #Force screen type 7

       FORCE_S8)
               echo "FORCE 10.4in TSD touchscreen (alternative supplier) will be calibrated in 800 by 600 rotation right, inverted touch axis"
               screen_type=8;; #Force screen type 8
       FORCE_S3)
               echo "FORCE 21.5 CCE touchscreen in 1280 by 720 resolution and no setting of resolution based on alternate res variable"
               screen_type=3;; #Force screen type 3
       FORCE_S9)
               echo "FORCE 21.5in eGalax touchscreen in 1280 by 720 resolution rotation right"
               screen_type=9;; #Force screen type 9
       FORCE_S10)
               echo "FORCE 10.4in eGalax P80H46 touchscreen in 800 by 600 resolution rotation right"
               screen_type=10;; #Force screen type 10

#	CCE)
#		screen_type=1;;

#	CCE2)
#		screen_type=3;; #Calibrates 21.5" CCE touchscreen in 1920 by 1080 resolution.

#	CCE3)
#		screen_type=4;; #Calibrates 21.5" CCE touchscreen in 800 by 600 resolution.

#	LVDS)
#		screen_type=2;;

#   LVDS2)
#       screen_type=5;;

#	*)
#		screen_type=0;;
esac

if [ $screen_type -eq 1 ]
then

	#Calibrates CCE touchscreen.

	DISPLAY=:0 xrandr --output $VDEV --mode 800x600 -r 60 --rotation left
	DISPLAY=:0 xrandr --output $VD2 --off
	#DISPLAY=:0 xrandr --output LVDS1 --transform 1,0,0,0,1,0,0,0,1
	echo '#!/bin/bash' > ${cosmos_autostart_dir}/set_display_settings
	echo '#Script to set 10.4in display resoulution and rotation' >> ${cosmos_autostart_dir}/set_display_settings
    echo '' >> ${cosmos_autostart_dir}/set_display_settings
    echo "DISPLAY=:0 xrandr --output $VDeDP --off" >> ${cosmos_autostart_dir}/set_display_settings
    echo "DISPLAY=:0 xrandr --output $VDEV --mode 800x600 -r 60 --rotation left" >> ${cosmos_autostart_dir}/set_display_settings
    chmod 775 ${cosmos_autostart_dir}/set_display_settings
	rm -f ${cosmos_autostart_dir}/LVDS_Screen_Transform
	# Calibrate screen
	rm -f ${cosmos_dir}/LOG/touch-calib.txt
	DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --geometry 600x800 --device "$eGalName" >> ${cosmos_dir}/LOG/touch-calib.txt
	cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf_$DATO
	OK=`grep -c "InputClass" ${cosmos_dir}/LOG/touch-calib.txt`
	if [ "$OK" == "1" ] ; then

		# Set touch calibration permanent
		sed -i '/EndSection/i        Option  "TransformationMatrix"  "0 -1 1 1 0 0 0 0 1"' ${cosmos_dir}/LOG/touch-calib.txt
		sed -i '/EndSection/i        Option  "SwapAxes"  "0"' ${cosmos_dir}/LOG/touch-calib.txt
#	sed -n '/Section/,/EndSection/p' ${cosmos_dir}/LOG/touch-calib.txt >> /etc/X11/xorg.conf.d/99-calibration.conf
		grep -A 18 "InputClass" ${cosmos_dir}/LOG/touch-calib.txt >/etc/X11/xorg.conf.d/99-calibration.conf
		cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf
	else
		echo "Calibration failed" >> ${cosmos_dir}/LOG/touch-calib.txt
		exit 2
	fi
	exit 0

elif [ $screen_type -eq 2 ]
then

	#Calibrates LVDS touchscreen.
	if [ "$LVDSP" -gt 0 ] ; then
        $VDeDP="LVDS1"
    fi
	# Side shift for old display on new PC
	DISPLAY=:0 xrandr --output $VDeDP --mode 1024x768 --rotation left
	DISPLAY=:0 xrandr --output $VDeDP --transform 1,0,-288,0,1,0,0,0,1

	# Create script to set transformation matrix permanent
	echo '#!/bin/bash' > ${cosmos_autostart_dir}/LVDS_Screen_Transform
	echo '#Script to set LVDS display transformation matrix on a BlueDevil PC' >> ${cosmos_autostart_dir}/LVDS_Screen_Transform
	echo '' >> ${cosmos_autostart_dir}/LVDS_Screen_Transform
	echo "/bin/xrandr --output $VDeDP --transform 1,0,-288,0,1,0,0,0,1" >> ${cosmos_autostart_dir}/LVDS_Screen_Transform
	chmod 775 ${cosmos_autostart_dir}/LVDS_Screen_Transform

        cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf_$DATO

	# Calibrate screen
	rm ${cosmos_dir}/LOG/touch-calib.txt
    rm -f ${cosmos_autostart_dir}/set_display_settings
	#DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --geometry 480x800 >> ${cosmos_dir}/LOG/touch-calib.txt

        #OK=`grep -c "InputClass" ${cosmos_dir}/LOG/touch-calib.txt`
        #if [ "$OK" == "1" ] ; then
                # Set touch calibration permanent
                #grep -A 18 "InputClass" ${cosmos_dir}/LOG/touch-calib.txt >/etc/X11/xorg.conf.d/99-calibration.conf
                echo 'Section "InputClass"' > /etc/X11/xorg.conf.d/99-calibration.conf
                echo '        Identifier      "calibration"' >> /etc/X11/xorg.conf.d/99-calibration.conf
                echo '        MatchProduct    "Hampshire Company TSHARC Analog Resistive"' >> /etc/X11/xorg.conf.d/99-calibration.conf
                echo '        Option  "Calibration"   "3982 157 70 5088"' >> /etc/X11/xorg.conf.d/99-calibration.conf
                echo 'EndSection' >> /etc/X11/xorg.conf.d/99-calibration.conf

                cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf
        #else
        #        echo "Calibration failed" >> ${cosmos_dir}/LOG/touch-calib.txt
        #fi


	exit 0

elif [ $screen_type -eq 3 ]
then
        #Calibrates 21.5" CCE touchscreen in 1280 by 720 resolution.
        DISPLAY=:0 xrandr --output $VDEV --mode 1280x720 -r 60 --rotation right
        DISPLAY=:0 xrandr --output $VD2 --off
        DISPLAY=:0 xrandr --output eDP-1 --off
        # Add 1280x720 mode if missing
        E1280=`DISPLAY=:0 xrandr |grep -e "^$VDEV" -A 30|grep "1280x720" -c`
#        if [ "$E1280" == "0" ] ; then
            echo '#!/bin/bash' > ${cosmos_autostart_dir}/add_display_mode
            echo '# Script to add missing mode 1280x720 on RVMs with big screen / do this even if the mode exist' >> ${cosmos_autostart_dir}/add_display_mode
            echo '' >> ${cosmos_autostart_dir}/add_display_mode
#            echo '/usr/bin/xrandr --newmode "1280x720" 74.50  1280 1344 1472 1664  720 723 728 748 -hsync +vsync' >> ${cosmos_autostart_dir}/add_display_mode
            echo '/usr/bin/xrandr --newmode "1280x720" 74.25  1280 1390 1430 1650  720 725 730 750 +hsync +vsync' >> ${cosmos_autostart_dir}/add_display_mode
            echo "/usr/bin/xrandr --addmode $VDEV \"1280x720\"" >> ${cosmos_autostart_dir}/add_display_mode
	    if [ "$1" == "FORCE_S3" ] ; then
                echo "  DISPLAY=:0 /usr/bin/xrandr --output $VDEV --mode 1280x720 -r 60 --rotation right" >> ${cosmos_autostart_dir}/add_display_mode
            else
		echo "ALTERNATE_RESOLUTION=\`grep 'AlternateResolution=1' ${cosmos_dir}/CFG/developer_config.ini -c\`" >> ${cosmos_autostart_dir}/add_display_mode
                echo 'if [ "$ALTERNATE_RESOLUTION" == "1" ]; then' >> ${cosmos_autostart_dir}/add_display_mode
                echo "  DISPLAY=:0 /usr/bin/xrandr --output $VDEV --mode 1280x720 -r 60 --rotation right" >> ${cosmos_autostart_dir}/add_display_mode
                echo "else" >> ${cosmos_autostart_dir}/add_display_mode
                echo "  DISPLAY=:0 /usr/bin/xrandr --output $VDEV --mode 800x600 --rotation right -r 60" >> ${cosmos_autostart_dir}/add_display_mode
                echo "fi" >> ${cosmos_autostart_dir}/add_display_mode
	    fi
            echo 'exit 0' >> ${cosmos_autostart_dir}/add_display_mode
            chmod 775 ${cosmos_autostart_dir}/add_display_mode
            DISPLAY=:0 /usr/bin/xrandr --newmode "1280x720" 74.25  1280 1390 1430 1650  720 725 730 750 +hsync +vsync
            DISPLAY=:0 /usr/bin/xrandr --addmode $VDEV "1280x720"
#        fi

        # Calibrate screen
        rm -f ${cosmos_autostart_dir}/LVDS_Screen_Transform
        rm -f ${cosmos_dir}/LOG/touch-calib.txt
        rm -f ${cosmos_autostart_dir}/set_display_settings
        DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --geometry 720x1280 >> ${cosmos_dir}/LOG/touch-calib.txt
        cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf_$DATO
        OK=`grep -c "InputClass" ${cosmos_dir}/LOG/touch-calib.txt`
        if [ "$OK" == "1" ] ; then
                # Set touch calibration permanent
                sed -i '/SwapXY/d' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/InvertX/d' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/InvertY/d' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/EndSection/i        Option  "SwapXY"        "1" ' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/EndSection/i        Option  "InvertX"       "1" ' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/EndSection/i        Option  "InvertY"       "1" ' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/EndSection/i        Option  "TransformationMatrix"  "0 -1 1 1 0 0 0 0 1"' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/EndSection/i        Option  "SwapAxes"  "0"' ${cosmos_dir}/LOG/touch-calib.txt
                grep -A 18 "InputClass" ${cosmos_dir}/LOG/touch-calib.txt >/etc/X11/xorg.conf.d/99-calibration.conf
                cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf
        else
                echo "Calibration failed" >> ${cosmos_dir}/LOG/touch-calib.txt
                exit 2
        fi
        exit 0
elif [ $screen_type -eq 4 ]
then
        #Calibrates 21.5" CCE touchscreen in 800 by 600 resolution.
        DISPLAY=:0 xrandr --output $VDEV --mode 800x600 -r 60 --rotation right
        DISPLAY=:0 xrandr --output $VD2 --off
        DISPLAY=:0 xrandr --output eDP-1 --off
        # Add 1280x720 mode if missing
        E1280=`DISPLAY=:0 xrandr |grep -e "^$VDEV" -A 30|grep "1280x720" -c`
#        if [ "$E1280" == "0" ] ; then
            echo '#!/bin/bash' > ${cosmos_autostart_dir}/add_display_mode
            echo '# Script to add missing mode 1280x720 on RVMs with big screen / do this even if the mode exist' >> ${cosmos_autostart_dir}/add_display_mode
            echo '' >> ${cosmos_autostart_dir}/add_display_mode
#            echo '/usr/bin/xrandr --newmode "1280x720" 74.50  1280 1344 1472 1664  720 723 728 748 -hsync +vsync' >> ${cosmos_autostart_dir}/add_display_mode
            echo '/usr/bin/xrandr --newmode "1280x720" 74.25  1280 1390 1430 1650  720 725 730 750 +hsync +vsync' >> ${cosmos_autostart_dir}/add_display_mode
            echo "/usr/bin/xrandr --addmode $VDEV \"1280x720\"" >> ${cosmos_autostart_dir}/add_display_mode
            echo "ALTERNATE_RESOLUTION=\`grep 'AlternateResolution=1' ${cosmos_dir}/CFG/developer_config.ini -c\`" >> ${cosmos_autostart_dir}/add_display_mode
            echo 'if [ "$ALTERNATE_RESOLUTION" == "1" ]; then' >> ${cosmos_autostart_dir}/add_display_mode
            echo "	DISPLAY=:0 /usr/bin/xrandr --output $VDEV --mode 1280x720 -r 60 --rotation right" >> ${cosmos_autostart_dir}/add_display_mode
            echo "else" >> ${cosmos_autostart_dir}/add_display_mode
            echo "	DISPLAY=:0 /usr/bin/xrandr --output $VDEV --mode 800x600 --rotation right -r 60" >> ${cosmos_autostart_dir}/add_display_mode
            echo "fi" >> ${cosmos_autostart_dir}/add_display_mode
            echo 'exit 0' >> ${cosmos_autostart_dir}/add_display_mode
            chmod 775 ${cosmos_autostart_dir}/add_display_mode
            DISPLAY=:0 /usr/bin/xrandr --newmode "1280x720" 74.25  1280 1390 1430 1650  720 725 730 750 +hsync +vsync
            DISPLAY=:0 /usr/bin/xrandr --addmode $VDEV "1280x720"
#        fi

        # Calibrate screen
        rm -f ${cosmos_autostart_dir}/LVDS_Screen_Transform
        rm -f ${cosmos_dir}/LOG/touch-calib.txt
        rm -f ${cosmos_autostart_dir}/set_display_settings
        DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --geometry 600x800 >> ${cosmos_dir}/LOG/touch-calib.txt
        cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf_$DATO
        OK=`grep -c "InputClass" ${cosmos_dir}/LOG/touch-calib.txt`
        if [ "$OK" == "1" ] ; then
                # Set touch calibration permanent
                sed -i '/SwapXY/d' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/InvertX/d' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/InvertY/d' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/EndSection/i        Option  "SwapXY"        "1" ' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/EndSection/i        Option  "InvertX"       "1" ' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/EndSection/i        Option  "InvertY"       "1" ' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/EndSection/i        Option  "TransformationMatrix"  "0 -1 1 1 0 0 0 0 1"' ${cosmos_dir}/LOG/touch-calib.txt
                sed -i '/EndSection/i        Option  "SwapAxes"  "0"' ${cosmos_dir}/LOG/touch-calib.txt
                grep -A 18 "InputClass" ${cosmos_dir}/LOG/touch-calib.txt >/etc/X11/xorg.conf.d/99-calibration.conf
                cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf
        else
                echo "Calibration failed" >> ${cosmos_dir}/LOG/touch-calib.txt
                exit 2
        fi
        exit 0
elif [ $screen_type -eq 5 ]
then

    #Calibrates LVDS touchscreen on OLD 32 bit PC hardware with CentOS7 Altarch 32bit



        cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf_$DATO

    # Calibrate screen
    rm ${cosmos_dir}/LOG/touch-calib.txt
    rm -f ${cosmos_autostart_dir}/set_display_settings
    DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --geometry 480x800 >> ${cosmos_dir}/LOG/touch-calib.txt

    OK=`grep -c "InputClass" ${cosmos_dir}/LOG/touch-calib.txt`
    if [ "$OK" == "1" ] ; then
                # Set touch calibration permanent
                #grep -A 18 "InputClass" ${cosmos_dir}/LOG/touch-calib.txt >/etc/X11/xorg.conf.d/99-calibration.conf
                echo 'Section "InputClass"' > /etc/X11/xorg.conf.d/99-calibration.conf
                echo '        Identifier      "calibration"' >> /etc/X11/xorg.conf.d/99-calibration.conf
                echo '        MatchProduct    "Hampshire Company TSHARC Analog Resistive"' >> /etc/X11/xorg.conf.d/99-calibration.conf
                echo '        Option  "Calibration"   "3982 157 70 5088"' >> /etc/X11/xorg.conf.d/99-calibration.conf
                echo 'EndSection' >> /etc/X11/xorg.conf.d/99-calibration.conf

                cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf
    else
                echo "Calibration failed" >> ${cosmos_dir}/LOG/touch-calib.txt
                exit 2
    fi


    exit 0

elif [ $screen_type -eq 6 ]
then
    #Calibrates TSD touchscreen. opposite invert x and y axis compared to CCE

    DISPLAY=:0 xrandr --output $VDEV --mode 800x600 -r 60 --rotation left
    DISPLAY=:0 xrandr --output $VD2 --off
    #DISPLAY=:0 xrandr --output LVDS1 --transform 1,0,0,0,1,0,0,0,1
    echo '#!/bin/bash' > ${cosmos_autostart_dir}/set_display_settings
    echo '#Script to set 10.4in display resoulution and rotation' >> ${cosmos_autostart_dir}/set_display_settings
    echo '' >> ${cosmos_autostart_dir}/set_display_settings
    echo "DISPLAY=:0 xrandr --output $VDeDP --off" >> ${cosmos_autostart_dir}/set_display_settings
    echo "DISPLAY=:0 xrandr --output $VDEV --mode 800x600 -r 60 --rotation left" >> ${cosmos_autostart_dir}/set_display_settings
    chmod 775 ${cosmos_autostart_dir}/set_display_settings
    rm -f ${cosmos_autostart_dir}/LVDS_Screen_Transform
    # Calibrate screen
    rm -f ${cosmos_dir}/LOG/touch-calib.txt
    DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --geometry 600x800 >> ${cosmos_dir}/LOG/touch-calib.txt
    cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf_$DATO
    OK=`grep -c "InputClass" ${cosmos_dir}/LOG/touch-calib.txt`
    if [ "$OK" == "1" ] ; then
            # Set touch calibration permanent
            sed -i '/SwapXY/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/InvertX/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/InvertY/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "SwapXY"        "1" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "InvertX"       "0" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "InvertY"       "0" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "TransformationMatrix"  "0 -1 1 1 0 0 0 0 1"' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "SwapAxes"  "0"' ${cosmos_dir}/LOG/touch-calib.txt
            grep -A 18 "InputClass" ${cosmos_dir}/LOG/touch-calib.txt >/etc/X11/xorg.conf.d/99-calibration.conf
            cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf
    else
            echo "Calibration failed" >> ${cosmos_dir}/LOG/touch-calib.txt
            exit 2
    fi
    exit 0
elif [ $screen_type -eq 7 ]
then
    #Calibrates TSD touchscreen. normal invert x and y axis as CCE

    DISPLAY=:0 xrandr --output $VDEV --mode 800x600 -r 60 --rotation left
    DISPLAY=:0 xrandr --output $VD2 --off
    #DISPLAY=:0 xrandr --output LVDS1 --transform 1,0,0,0,1,0,0,0,1
    echo '#!/bin/bash' > ${cosmos_autostart_dir}/set_display_settings
    echo '#Script to set 10.4in display resoulution and rotation' >> ${cosmos_autostart_dir}/set_display_settings
    echo '' >> ${cosmos_autostart_dir}/set_display_settings
    echo "DISPLAY=:0 xrandr --output $VDeDP --off" >> ${cosmos_autostart_dir}/set_display_settings
    echo "DISPLAY=:0 xrandr --output $VDEV --mode 800x600 -r 60 --rotation left" >> ${cosmos_autostart_dir}/set_display_settings
    chmod 775 ${cosmos_autostart_dir}/set_display_settings
    rm -f ${cosmos_autostart_dir}/LVDS_Screen_Transform
    # Calibrate screen
    rm -f ${cosmos_dir}/LOG/touch-calib.txt
    DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --geometry 600x800 >> ${cosmos_dir}/LOG/touch-calib.txt
    cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf_$DATO
    OK=`grep -c "InputClass" ${cosmos_dir}/LOG/touch-calib.txt`
    if [ "$OK" == "1" ] ; then
            # Set touch calibration permanent
            sed -i '/SwapXY/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/InvertX/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/InvertY/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "SwapXY"        "0" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "InvertX"       "0" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "InvertY"       "0" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "TransformationMatrix"  "0 -1 1 1 0 0 0 0 1"' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "SwapAxes"  "0"' ${cosmos_dir}/LOG/touch-calib.txt
            grep -A 18 "InputClass" ${cosmos_dir}/LOG/touch-calib.txt >/etc/X11/xorg.conf.d/99-calibration.conf
            cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf
    else
            echo "Calibration failed" >> ${cosmos_dir}/LOG/touch-calib.txt
            exit 2
    fi
    exit 0

elif [ $screen_type -eq 8 ]
then
    #Calibrates TSD touchscreen. rotate right,invert x and y axis compared to CCE

    DISPLAY=:0 xrandr --output $VDEV --mode 800x600 -r 60 --rotation right
    DISPLAY=:0 xrandr --output $VD2 --off
    #DISPLAY=:0 xrandr --output LVDS1 --transform 1,0,0,0,1,0,0,0,1
    echo '#!/bin/bash' > ${cosmos_autostart_dir}/set_display_settings
    echo '#Script to set 10.4in display resoulution and rotation' >> ${cosmos_autostart_dir}/set_display_settings
    echo '' >> ${cosmos_autostart_dir}/set_display_settings
    echo "DISPLAY=:0 xrandr --output $VDeDP --off" >> ${cosmos_autostart_dir}/set_display_settings
    echo "DISPLAY=:0 xrandr --output $VDEV --mode 800x600 -r 60 --rotation right" >> ${cosmos_autostart_dir}/set_display_settings
    chmod 775 ${cosmos_autostart_dir}/set_display_settings
    rm -f ${cosmos_autostart_dir}/LVDS_Screen_Transform
    # Calibrate screen
    rm -f ${cosmos_dir}/LOG/touch-calib.txt
    DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --geometry 600x800 >> ${cosmos_dir}/LOG/touch-calib.txt
    cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf_$DATO
    OK=`grep -c "InputClass" ${cosmos_dir}/LOG/touch-calib.txt`
    if [ "$OK" == "1" ] ; then
            # Set touch calibration permanent
            sed -i '/SwapXY/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/InvertX/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/InvertY/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "SwapXY"        "0" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "InvertX"       "1" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "InvertY"       "1" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "TransformationMatrix"  "0 -1 1 1 0 0 0 0 1"' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "SwapAxes"  "0"' ${cosmos_dir}/LOG/touch-calib.txt
            grep -A 18 "InputClass" ${cosmos_dir}/LOG/touch-calib.txt >/etc/X11/xorg.conf.d/99-calibration.conf
            cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf
    else
            echo "Calibration failed" >> ${cosmos_dir}/LOG/touch-calib.txt
            exit 2
    fi
    exit 0

elif [ $screen_type -eq 9 ]
then
    #Calibrates 21.5" eGalax touchscreen in 1280x720 resolution, rotate right.

    DISPLAY=:0 xrandr --output $VDEV --mode 1280x720 -r 60 --rotation right
    DISPLAY=:0 xrandr --output $VD2 --off
    DISPLAY=:0 xrandr --output eDP-1 --off
    # Add 1280x720 mode if missing / do this even if the mode exists
    echo '#!/bin/bash' > ${cosmos_autostart_dir}/add_display_mode
    echo '# Script to add missing mode 1280x720 on RVMs with 21.5in eGalax screen' >> ${cosmos_autostart_dir}/add_display_mode
    echo '' >> ${cosmos_autostart_dir}/add_display_mode
    echo '/usr/bin/xrandr --newmode "1280x720" 74.25  1280 1390 1430 1650  720 725 730 750 +hsync +vsync' >> ${cosmos_autostart_dir}/add_display_mode
    echo "/usr/bin/xrandr --addmode $VDEV \"1280x720\"" >> ${cosmos_autostart_dir}/add_display_mode
    echo "DISPLAY=:0 /usr/bin/xrandr --output $VDEV --mode 1280x720 -r 60 --rotation right" >> ${cosmos_autostart_dir}/add_display_mode
    echo 'exit 0' >> ${cosmos_autostart_dir}/add_display_mode
    chmod 775 ${cosmos_autostart_dir}/add_display_mode
    DISPLAY=:0 /usr/bin/xrandr --newmode "1280x720" 74.25  1280 1390 1430 1650  720 725 730 750 +hsync +vsync
    DISPLAY=:0 /usr/bin/xrandr --addmode $VDEV "1280x720"

    # Calibrate screen
    rm -f ${cosmos_autostart_dir}/LVDS_Screen_Transform
    rm -f ${cosmos_dir}/LOG/touch-calib.txt
    rm -f ${cosmos_autostart_dir}/set_display_settings
    DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --geometry 720x1280 >> ${cosmos_dir}/LOG/touch-calib.txt
    cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf_$DATO
    OK=`grep -c "InputClass" ${cosmos_dir}/LOG/touch-calib.txt`
    if [ "$OK" == "1" ] ; then
            # Set touch calibration permanent
            sed -i '/SwapXY/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/InvertX/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/InvertY/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "SwapXY"        "0" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "InvertX"       "0" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "InvertY"       "1" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "TransformationMatrix"  "0 -1 1 1 0 0 0 0 1"' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "SwapAxes"  "1"' ${cosmos_dir}/LOG/touch-calib.txt
            grep -A 18 "InputClass" ${cosmos_dir}/LOG/touch-calib.txt >/etc/X11/xorg.conf.d/99-calibration.conf
            cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf
    else
            echo "Calibration failed" >> ${cosmos_dir}/LOG/touch-calib.txt
            exit 2
    fi
    exit 0

elif [ $screen_type -eq 10 ]
then
    #Calibrates 10.4" eGalax P80H46 touchscreen in 800 by 600 resolution, rotation right.
    #800x600 is in EDID, so no --newmode is needed. --primary --auto are required to force
    #the output on when it has been left in a half-configured state by a previous run.

    DISPLAY=:0 xrandr --output $VDEV --mode 800x600 --rate 60 --primary --auto --rotate right
    DISPLAY=:0 xrandr --output $VD2 --off
    echo '#!/bin/bash' > ${cosmos_autostart_dir}/set_display_settings
    echo '#Script to set 10.4in eGalax P80H46 display resolution and rotation' >> ${cosmos_autostart_dir}/set_display_settings
    echo '' >> ${cosmos_autostart_dir}/set_display_settings
    echo "DISPLAY=:0 xrandr --output $VDeDP --off" >> ${cosmos_autostart_dir}/set_display_settings
    echo "DISPLAY=:0 xrandr --output $VDEV --mode 800x600 --rate 60 --primary --auto --rotate right" >> ${cosmos_autostart_dir}/set_display_settings
    chmod 775 ${cosmos_autostart_dir}/set_display_settings
    rm -f ${cosmos_autostart_dir}/LVDS_Screen_Transform
    # Calibrate screen
    rm -f ${cosmos_dir}/LOG/touch-calib.txt
    DISPLAY=:0 ${cosmos_dir}/TOOLS/xinput_calibrator --geometry 600x800 --device "$eGalName" >> ${cosmos_dir}/LOG/touch-calib.txt
    cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf_$DATO
    OK=`grep -c "InputClass" ${cosmos_dir}/LOG/touch-calib.txt`
    if [ "$OK" == "1" ] ; then
            # Set touch calibration permanent
            sed -i '/SwapXY/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/InvertX/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/InvertY/d' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "SwapXY"        "0" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "InvertX"       "1" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "InvertY"       "1" ' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "TransformationMatrix"  "0 -1 1 1 0 0 0 0 1"' ${cosmos_dir}/LOG/touch-calib.txt
            sed -i '/EndSection/i        Option  "SwapAxes"  "0"' ${cosmos_dir}/LOG/touch-calib.txt
            grep -A 18 "InputClass" ${cosmos_dir}/LOG/touch-calib.txt >/etc/X11/xorg.conf.d/99-calibration.conf
            cp /etc/X11/xorg.conf.d/99-calibration.conf ${cosmos_dir}/CFG/99-calibration.conf
    else
            echo "Calibration failed" >> ${cosmos_dir}/LOG/touch-calib.txt
            exit 2
    fi
    exit 0

else
	echo "Usage: $0     (no parameters and it will autodetect which type of screen is installed) "
	exit 1

fi

