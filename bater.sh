#!/bin/bash

function auto(){
	if (( $(echo "$t_air <= $t_sp_min" | bc) ))
	then
		heat_on
	fi

	if (( $(echo "$t_air >= $t_sp_max" | bc) ))
	then
		heat_off
	fi
}

function heat_on(){
	if [ ! $h_state == "up" ]
	then
		#mosquitto_pub -h 192.168.0.249 -t home/f0/tr/lights/cmnd/POWER1 -m ON
		mosquitto_pub -h 192.168.0.249 -t home/f0/mysgw-sub/10/0/1/0/48 -m 15
		sleep 5
		mosquitto_pub -h 192.168.0.249 -t home/f0/mysgw-sub/10/0/1/0/48 -m 16
		h_state="up"
		echo $h_state > ~/scripts/bater/heating_state
		echo -e "$(printf '%(%d-%m %H:%M:%S)T\n') C state:${h_state}\tmode:${t_mode}\tsp:${t_sp}\tair:${t_air}\floor:${t_flor}\ttoh:${toh}" >> ~/scripts/bater/heating.log
	fi
}

function heat_off(){
	if [ ! $h_state == "dn" ]
	then
		#mosquitto_pub -h 192.168.0.249 -t home/f0/tr/lights/cmnd/POWER1 -m OFF
		mosquitto_pub -h 192.168.0.249 -t home/f0/mysgw-sub/10/0/1/0/48 -m -16
		sleep 45
		mosquitto_pub -h 192.168.0.249 -t home/f0/mysgw-sub/10/0/1/0/48 -m -15
		h_state="dn"
		echo $h_state > ~/scripts/bater/heating_state
		echo -e "$(printf '%(%d-%m %H:%M:%S)T\n') C state:${h_state}\tmode:${t_mode}\tsp:${t_sp}\tair:${t_air}\floor:${t_flor}\ttoh:${toh}" >> ~/scripts/bater/heating.log
	fi
}

### START ###
t_ui=($(cat ~/scripts/bater/thermostat_state))
h_state=$(cat ~/scripts/bater/heating_state)
t_mode=${t_ui[0]}
t_sp=${t_ui[1]}
t_sp_min=$(echo "$t_sp - .5" | bc)
t_sp_max=$(echo "$t_sp + .5" | bc)
t_air=$(mosquitto_sub -C 1 -h 192.168.0.249 -t home/f0/sr/thermostat/stat/temperature)
t_floor=$(mosquitto_sub -C 1 -h 192.168.0.249 -t home/f0/sr/thermostat/stat/floorTemperature)

if (( $(echo "$t_flor >= 33 | bc) ))
then
	toh=true
else
	toh=false
fi

echo -e "$(printf '%(%d-%m %H:%M:%S)T\n') I state:${h_state}\tmode:${t_mode}\tsp:${t_sp}\tair:${t_air}\floor:${t_flor}\ttoh:${toh}" >> ~/scripts/bater/heating.log

case $t_mode in
    "off")
        heat_off
        ;;
    "auto")
        auto
        ;;
esac