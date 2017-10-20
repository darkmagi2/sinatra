#!/bin/sh
### BEGIN INIT INFO
# Provides:          startup
# Required-Start:    
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: shotgun startup
# Description:       Starts shotgun on system boot
### END INIT INFO

cd /var/www/sinatra
shotgun >>/var/log//sinatra/sinatra.log 2>&1
