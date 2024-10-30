. $ATLAS_SCRIPTS/generic-reginit.sh

SSH_CMD=hwprobe_ssh
SSH_CMD_EXEC=hwprobe_ssh_exec
SSH_ARGS="-o ServerAliveInterval=60 \
          -o StrictHostKeyChecking=yes \
          -o UserKnownHostsFile=$ATLAS_STATUS/known_hosts"
TRIGGER_MANUAL_UPGRADE_CMD=trigger_manual_upgrade
CHECK_FOR_NEW_KERNEL_CMD=check_for_new_kernel
DEV_FIRMWARE=/tmp/firmware.img
HANDLE_STORAGE_CURRENT_TIME=handle_storage_current_time
LOAD_STORAGE_CURRENT_TIME=load_storage_current_time
FIRMWARE_FETCH_DIR=${ATLAS_STATUS}
FIRMWARE_TARGET_DIR=/tmp
RESOLV_CONF=/tmp/resolv.conf
CHECK_SIG_CMD=check_sig
MODE_FILE=$ATLAS_SYSCONFDIR/mode
KEY_PREFIX_dev_v3=${ATLAS_DATADIR}/2017-11-07-dev.pem
KEY_PREFIX_dev_v4=${ATLAS_DATADIR}/2018-04-23-dev.pem
KEY_PREFIX_dev_v5=${ATLAS_DATADIR}/2021-02-02-dev.pem
KEY_PREFIXES_test_v3=${ATLAS_DATADIR}/2017-11-07-test.pem
KEY_PREFIXES_test_v4=${ATLAS_DATADIR}/2018-04-23-test.pem
KEY_PREFIXES_test_v5=${ATLAS_DATADIR}/2021-02-02-test.pem
KEY_PREFIXES_prod_v3=${ATLAS_DATADIR}/2017-11-07-prod.pem
KEY_PREFIXES_prod_v4=${ATLAS_DATADIR}/2018-04-23-prod.pem
KEY_PREFIXES_prod_v5=${ATLAS_DATADIR}/2021-02-02-prod.pem
STATIC_V4_CMD=set_ipv4
STATIC_V6_CMD=set_ipv6

install_firmware()
{
	_wrt_syscall 'action=upgrade' 'target=application' "firmware=${1}"
}

_get_usb_id()
{
	local blockdev="${1}"
	local oldifs="${IFS}"

	if [ ! -b "/dev/${blockdev}" ]; then
		return
	fi

	IFS='/'
	set -- $(readlink /sys/block/${blockdev})
	IFS="${oldifs}"
	while [ -n "${1}" ]; do
		if [ "${1:0:3}" = 'usb' ]; then
			break
		fi
		shift
	done
	if [ -n "${1}" ]; then
		shift
		echo "${1}"
	fi
}

_get_block_prop()
{
	local blockdev="${1}"
	local property="${2}"

	cat "/sys/block/${blockdev}/${property}" 2>/dev/null
}

_get_usb_prop()
{
	local deviceid="${1}"
	local property="${2}"

	cat "/sys/bus/usb/devices/${deviceid}/${property}" 2>/dev/null
}

p_to_r_init()
{
	local reason="${1}"
	local blockdev='sda'
	local answer='P_TO_R_INIT\n'
	local usbid
	local val

	answer="${answer}TOKEN_SPECS $(get_arch)"

	if [ -f "${ATLAS_DATADIR}/FIRMWARE_KERNEL_VERSION" ]; then
		val=$(cat ${ATLAS_DATADIR}/FIRMWARE_KERNEL_VERSION 2>/dev/null)
	else
		val='1000'
	fi
	answer="${answer} ${val}"

	if [ -f "${ATLAS_DATADIR}/FIRMWARE_APPS_VERSION" ]; then
		val=$(cat ${ATLAS_DATADIR}/FIRMWARE_APPS_VERSION 2>/dev/null)
	else
		val='0'
	fi
	answer="${answer} ${val} $(get_sub_arch)"

	usbid=$(_get_usb_id ${blockdev})
	if [ -n "${usbid}" ]; then
		val=$(_get_block_prop ${blockdev} size)
		val="${val:-0}"
		val=$(( val / 2 ))
		answer="${answer} Size=${val}"
		answer="${answer} ro=$(_get_block_prop ${blockdev} ro)"
		answer="${answer} SerialNumber=$(_get_usb_prop ${usbid} serial)"
		answer="${answer} Vendor=$(_get_usb_prop ${usbid} idVendor)"
		answer="${answer} ProdID=$(_get_usb_prop ${usbid} idProduct)"
		answer="${answer} Rev=$(_get_block_prop ${blockdev} device/rev)"
		answer="${answer} Manufacturer=$(_get_usb_prop ${usbid} manufacturer)"
		answer="${answer} Product=$(_get_usb_prop ${usbid} product)"
		answer="${answer}\n"
	fi
	answer="${answer}\nREASON_FOR_REGISTRATION ${reason}\n"

	echo -e "${answer}" | tee ${P_TO_R_INIT_IN}
}

hwprobe_ssh()
{
	local key_opt
	if [ -f "${ATLAS_SYSCONFDIR}/probe_key" ]; then
		key_opt="-i ${ATLAS_SYSCONFDIR}/probe_key"
	else
		key_opt="-o 'PKCS11Provider /usr/lib/libmox-pkcs11.so'"
	fi
	/usr/bin/ssh ${key_opt} ${SSH_ARGS} "${@}"
}

hwprobe_ssh_exec()
{
	local key_opt
	if [ -f "${ATLAS_SYSCONFDIR}/probe_key" ]; then
		key_opt="-i ${ATLAS_SYSCONFDIR}/probe_key"
	else
		key_opt="-o 'PKCS11Provider /usr/lib/libmox-pkcs11.so'"
	fi
	exec /usr/bin/ssh ${key_opt} ${SSH_ARGS} "${@}"
}

trigger_manual_upgrade()
{
	if [ -f $DEV_FIRMWARE ] ; then
		# Manual firmware upgrade
		rm -f $ATLAS_STATUS/reginit.vol
	fi
}

handle_storage_current_time()
{
	local le
	local se

	se=$(cat ${ATLAS_DATA}/currenttime 2>/dev/null)
	se=${se:-0}
	[ ${se} -gt 0 ] && se=$(( se + 1800 ))

	le=$(cat ${ATLAS_STATUS}/currenttime 2>/dev/null)
	le=${le:-0}
	if ( [ ${se} -eq 0 ] || [ ${le} -gt ${se} ] ); then
		cp ${ATLAS_STATUS}/currenttime.txt ${ATLAS_DATA}/currenttime.txt
	fi
}

load_storage_current_time()
{
	local le
	local ce

	se=$(cat ${ATLAS_DATA}/currenttime 2>/dev/null)
	se=${se:-0}

	ce=$(date +%s)

	if [ ${se} -gt ${ce} ]; then
		cp ${ATLAS_DATA}/currenttime.txt ${ATLAS_STATUS}/currenttime.txt
	fi
}

check_sig()
{
	local mode=$(cat ${MODE_FILE} 2>/dev/null)
	local type
	local key_prefixes

	. /etc/os-release
	case "${OPENWRT_BOARD}" in
		'ath79/tiny') type=v3 ;;
		'sunxi/cortexa53') type=v4 ;;
		'mvebu/cortexa53') type=v5 ;;
	esac
	eval key_prefixes=\${KEY_PREFIXES_${mode}_${type}}

	file="$1"
	fw_hash=$(sha256sum $file | sed 's/ .*//')
	for i in ${key_prefixes}; do
		for j in 1 2 3 4 5; do      # Assume 5 sigs is enough
			grep -q SIGNATURE_APPS${j} ${ATLAS_STATUS}/reg_init_reply.txt || continue

			echo "Checking signature $j for key $i"
			grep SIGNATURE_APPS$j ${ATLAS_STATUS}/reg_init_reply.txt |
				sed "s/SIGNATURE_APPS$j [^ ]* //" |
				base64 -d >/tmp/sig.txt

			openssl rsautl -verify -inkey $i -keyform PEM -pubin -in /tmp/sig.txt > /tmp/hash.txt
			if [ $(cat /tmp/hash.txt) == $fw_hash ]; then
				echo Signature checks out
				return 0
			else
				echo Signature failed, got "$(cat /tmp/hash.txt)", expected $fw_hash
			fi
		done
	done
	echo 'End of check_sig'

	return 1
}

check_for_new_kernel()
{
	## check for new kernel
	if [ -n "${FIRMWARE_KERNEL}" ] ; then
		FIRMWARE_KERNEL_VERSION_MY=`cat ${ATLAS_DATADIR}/FIRMWARE_KERNEL_VERSION`
		FIRMWARE_KERNEL_VERSION_MY=${FIRMWARE_KERNEL_VERSION_MY:-0}
		if [ ${FIRMWARE_KERNEL_VERSION} -gt ${FIRMWARE_KERNEL_VERSION_MY} ]; then
			echo "there is a newer FIRMWARE_KERNEL_VERSION ${FIRMWARE_KERNEL_VERSION}, current one is ${FIRMWARE_KERNEL_VERSION_MY}"

			D=`epoch`
			echo "RESULT 9013 done ${D} ${ETHER_SCANNED} newer kernel firmware ${FIRMWARE_KERNEL_VERSION}, currently running ${FIRMWARE_KERNEL_VERSION_MY}"  >> ${DATA_DIR}/new/simpleping
			echo "RESULT 9011 done ${D} ${ETHER_SCANNED} Starting ${SSH_CMD} -p ${CONTROLLER_1_PORT} atlas@${CONTROLLER_1_HOST} FIRMWARE_KERNEL ${FIRMWARE_KERNEL}"  >> ${DATA_DIR}/new/simpleping
			${SSH_CMD} ${SSH_OPT} -i ${SSH_PVT_KEY} -p ${CONTROLLER_1_PORT} atlas@${CONTROLLER_1_HOST}  "FIRMWARE_KERNEL ${FIRMWARE_KERNEL}" > /tmp/${FIRMWARE_KERNEL} 2>${SSH_ERR}
			ERR=${?}
			if [ ${ERR} -ne 0 ] ; then
				D=`epoch`
				echo "RESULT 9011 done ${D} ${ETHER_SCANNED} ERR ${ERR} stderr" `cat ${SSH_ERR} 2>/dev/null`  >> ${DATA_DIR}/new/simpleping
			fi

			echo "check md5 of ${FIRMWARE_KERNEL}"
			MD5FULL=`md5sum /tmp/${FIRMWARE_KERNEL}`
			set ${MD5FULL}
			MD5=${1}

			if [ "${MD5}" = "${FIRMWARE_KERNEL_CS_COMP}" ] ; then
				# the checksums match schedule an upgrade
				echo "checksums match ${MD5} ${FIRMWARE_KERNEL_CS_COMP}"
				_wrt_syscall 'action=upgrade' 'target=kernel' "firmware=/tmp/${FIRMWARE_KERNEL}"
				exit
			else
				echo "checksums failed. ${FIRMWARE_KERNEL}"
				echo "Ignore upgrade and proceed to Controller for INIT"
			fi
		else
			echo "IGNORE kernel upgrade mine, ${FIRMWARE_KERNEL_VERSION_MY}, is newer or the same as ${FIRMWARE_KERNEL_VERSION}"
		fi
	fi
}

reboot_probe()
{
	# Misnomer. NEED_REBOOT is actually a request to reconfigure the network
	if [ "${NEED_REBOOT}" != '1' ]; then
		# memory error or similar
		_wrt_syscall 'action=reboot'
	fi
}
