. ${ATLAS_SCRIPTS}/generic-common.sh

SET_LEDS_CMD=wrt_set_leds
INSTALL_FIRMWARE_CMD=install_firmware

_wrt_syscall()
{
	local env=''

	while [ -n "${1}" ]; do
		env="${env}, \"${1}\""
		shift
	done

	ubus call hotplug.ripe-atlas call "{ \"env\": [ ${env:2} ] }"
}

wrt_set_leds()
{
	local state="${1}"
	
	_wrt_syscall 'action=leds' "state=${state}"
}

reboot_probe()
{
	_wrt_syscall 'action=reboot'
}
