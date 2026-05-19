#!/usr/bin/env bash

get_value(){
	busctl --user get-property org.clight.clight /org/clight/clight org.clight.clight "$1" | cut -d" " -f2
}

get_state(){
	state=$(get_value "$1")
	if [[ "$state" =~ "true" ]]; then
		echo "true"
	else
		echo "false"
	fi
}

toggle_inhibit() {
	# Determine the new state
	if [[ "$(get_state Inhibited)" =~ "true" ]]; then
	    new_state="false"
	else
	    new_state="true"	    
	fi
	
	# Toggle the inhibition
	busctl --user call \
		org.clight.clight \
		/org/clight/clight \
		org.clight.clight \
		Inhibit b "$new_state"
}

toggle_pause() {
	# Determine the new state
	if [[ "$(get_state Suspended)" =~ "true" ]]; then
		[[ $(pidof polybar) ]] && polybar-msg action "#autobr.hook.0"
	    new_state="false"
	else
	    [[ $(pidof polybar) ]] && polybar-msg action "#autobr.hook.1"
	    new_state="true"	    
	fi

	# Toggle Pause
	busctl --user call \
		org.clight.clight \
		/org/clight/clight \
		org.clight.clight \
		Pause b "$new_state"
}

increase_brightness() {           
	busctl --user call \
		org.clight.clight \
		/org/clight/clight \
		org.clight.clight \
		IncBl d "0.05"
}

decrease_brightness() {           
	busctl --user call \
		org.clight.clight \
		/org/clight/clight \
		org.clight.clight \
		DecBl d "0.05"
}

capture(){
	busctl --user call \
		org.clight.clight \
		/org/clight/clight \
		org.clight.clight \
		Capture bb "true" "false"
}

toggle_gamma() {
	busctl --user call \
		org.clight.clight \
		/org/clight/clight/Conf/Gamma \
		org.clight.clight.Conf.Gamma \
		Toggle
}

gamma_status(){
	busctl --user get-property \
		org.clight.clight \
		/org/clight/clight/Conf/Gamma \
		org.clight.clight.Conf.Gamma \
		AmbientGamma 2> /dev/null | cut -d" " -f2
}

toggle_ambient_gamma(){
	ambient_stauts="$(gamma_status)"

	if [[ "$ambient_stauts" != "true" ]]; then
		new_state="true"
	else
		new_state="false"
	fi

	busctl --user set-property \
		org.clight.clight \
		/org/clight/clight/Conf/Gamma \
		org.clight.clight.Conf.Gamma \
		AmbientGamma "b" "$new_state"
}

change_temp(){
	busctl --user set-property \
	org.clight.clight /org/clight/clight/Conf/Gamma org.clight.clight.Conf.Gamma DayTemp 'i' "$1"
}

if [[ -z "$(pgrep clight)" ]]; then
	echo "[!] Clight Not Running"
	exit 0
fi

# Command-line argument handling
case "$1" in
    "--inhibit-status")
		get_state Inhibited
    ;;
    "--pause-status")
		get_state Suspended
    ;;
    "--toggle-inhibit")
		toggle_inhibit
    ;;
    "--toggle-pause")
		toggle_pause
    ;;
	"--increase")
    	increase_brightness
    ;;
	"--decrease")
    	decrease_brightness
    ;;
	"--capture")
    	capture
    ;;
    "--gamma")
        get_value Temp
    ;;
    "--toggle-gamma")
        toggle_gamma
    ;;
    "--toggle-ambient-gamma")
        toggle_ambient_gamma
    ;;
    "--gamma-status")
        gamma_status
    ;;
    "--increase-gamma")
       	temperature="$(get_value Temp)"
       	echo $temperature
        change_temp $((temperature + 100))
    ;;
    "--decrease-gamma")
        temperature="$(get_value Temp)"
        change_temp $((temperature - 100))
    ;;
esac
