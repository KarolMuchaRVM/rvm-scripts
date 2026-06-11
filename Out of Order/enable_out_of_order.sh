#!/bin/bash
#
# Set machine out of order
# Author: Vilde Olsen
# Date: 28.11.2023
# 

php /home/repant/COSMOS/script/updini.php /home/repant/COSMOS/CFG/user_config.ini Stops Check_rvm_out_of_order true
/home/repant/COSMOS/script/start_kill_cosmos -c

exit 0
