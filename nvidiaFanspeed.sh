#!/bin/bash
set -e
#echo "Nya" > /home/asayu/Desktop/first.txt
#echo "Nya" > /root/first.txt
# This is the path to the PWM controlled fan (use lm_sensors/fancontrol to help you identify this)
fan=/sys/class/hwmon/hwmon0/pwm2
fan2=/sys/class/hwmon/hwmon0/pwm3
# Read https://www.kernel.org/doc/Documentation/hwmon/ for your PWM chip to find the correct values (I have a nct6792)
#echo $(((($1 * 255)) / 100)) > ${fan}
automatic=5
manual=1
# Temperature at which to run fan at 100% speed
max=90
min=45
minSpeed=77
maxSpeed=200
cRatio=$(( (($maxSpeed - $minSpeed) * 100) / ($max - $min) ))
minSpeed=$(($minSpeed * 100))
echo Ratio $cRatio

# Re-enable automatic fan control on exit
trap "echo ${automatic} > ${fan}_enable; echo ${automatic} > ${fan2}_enable; exit" SIGHUP SIGINT SIGTERM ERR EXIT

# Enable manual fan control
echo ${manual} > ${fan}_enable
echo ${manual} > ${fan2}_enable

function temperature() {
	nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits
        #nvidia-settings -q [gpu:0]/gpucoretemp -t
}

function cputemperature() {
	cat /sys/class/hwmon/hwmon1/temp1_input
}

function fan_speed() {
        temp=$(( ((cRatio * ( $1 - $min )) + $minSpeed) / 100 ))
        echo Temperature $1 Setting FAN Speed to $temp
        echo $temp > ${fan}
        echo $temp > ${fan2}
}

while true; do
	cputemp=$((`cputemperature` / 1000))
        temp=`temperature`   
        #echo "Nyaaaaaaaaaaa" > /home/asayu/Desktop/first.txt
        echo GPU Temperature: $temp
        echo CPU Temperature: $cputemp       
        if [ "$cputemp" -ge "$temp" ] ; then
        	temp=$cputemp
        fi 
        if [ "$temp" -ge "$max" ] ; then
                fan_speed $max
        elif [ "$temp" -lt "$min" ] ; then
        	fan_speed $min
        else
                fan_speed $temp
        fi
        sleep 1
done
