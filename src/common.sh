usage()
{
cat << EOF

usage: $0 options

OPTIONS:
-h	Show this message
-v	Verbose

EOF
}

parse_command_line()
{
	while getopts "vh" opt; do
		case $opt in
			v)
				LOG_LEVEL=2;;
			h)
				usage
				exit 0;;
			\?)
				usage
				exit 1;;
		esac
	done
}

redirect_output_and_error()
{
	case $1 in
		1) exec 3>&1	4>/dev/null	1> /dev/null	2> /dev/null;;
		2) exec 3>&1	4>/dev/null;;
	esac
}
