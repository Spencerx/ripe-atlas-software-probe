. $ATLAS_SCRIPTS/generic-ATLAS.sh

SET_HOSTNAME=set_hostname

set_hostname()
{
	local id=$(cat /sys/class/net/eth0/address 2>/dev/null)
	_wrt_syscall 'action=hostname' "mac=${id}"
}

setup_network()
{
	get_ether_addr

	set_ipv4
	set_ipv6
}

reboot_probe()
{
	_wrt_syscall 'action=reboot'
}

$SET_LEDS_CMD start
