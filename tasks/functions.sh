# test if file is locked, then cp the script to the target directory
function cp_and_lock {
# $1 : script to copy  # $2 : task name  # $3 : cp target directory
	(
	flock 200 || echo "[task "${2}"]: ${2} lock file is already locked, cp omitted."
	rm -f ${3}
	cp -n ${1} ${3}
	) 200>/var/lock/${2}.lock
}
