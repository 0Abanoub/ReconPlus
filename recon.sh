#!/usr/bin/env bash

REQUIRED_TOOLS=(jq dig curl nmap dirsearch)

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "[!] Required tool '$tool' is not installed. Please install it."
        exit 1
    fi
done

Today=$(date)
echo "Recon started at $Today"

show_progress() {
    echo -n "[*] $1"
    for i in {1..5}; do
        echo -n "."
        sleep 0.3
    done
    echo
}

nmap_scan() {
    show_progress "Running Nmap scan on $DOMAIN"
    nmap -Pn -n -A -F $DOMAIN > $DIRECTORY/nmap
    echo "the result of nmap scan is saved in $DIRECTORY/nmap"
}

dirsearch_scan() {
    show_progress "Running Dirsearch scan on $DOMAIN"
    dirsearch -u $DOMAIN -e php,html,js,txt -o "$DIRECTORY/dirsearch.txt"
    echo "the result of dirsearch scan is saved in $DIRECTORY/dirsearch.txt"
}

crt_scan() {
    show_progress "Running crt.sh scan on $DOMAIN"
    curl "https://crt.sh/?q=$DOMAIN&output=json" -o $DIRECTORY/crt
    echo "the result of crt scan is saved in $DIRECTORY/crt"

    jq -r ".[].name_value" "$DIRECTORY/crt" | sed 's/\*\.//g' | sort -u > "$DIRECTORY/subdomains.txt"
}

check_takeover_candidates() {
  echo "[*] Checking subdomains for potential takeover..."

  show_progress "Checking for potential subdomain takeover candidates in $DIRECTORY/subdomains.txt"

  CANDIDATES=("github.io" "herokuapp.com" "s3.amazonaws.com" "bitbucket.io" "readthedocs.io")
  RESULTS="$DIRECTORY/takeover.txt"
  echo "" > "$RESULTS"

  if [ ! -f "$DIRECTORY/crt" ]; then
    echo "[*] crt data not found. Running crt_scan first..."
    crt_scan
  fi

  if [ ! -f "$DIRECTORY/subdomains.txt" ]; then
    echo "[!] Subdomain list not found. Aborting takeover check."
    return
  fi

  while read sub; do
    cname=$(dig +short CNAME "$sub")
    for service in "${CANDIDATES[@]}"; do
      if [[ "$cname" == *"$service"* ]]; then
        echo "[+] Potential takeover: $sub -> $cname" | tee -a "$RESULTS"
      fi
    done
  done < "$DIRECTORY/subdomains.txt"
}

while getopts "m:i" OPTION; do
    case $OPTION in
        m)
            MODE=$OPTARG
            ;;
        i)
            INTERACTIVE=true
            ;;
    esac
done

scan_domain(){

    DOMAIN=$1
    DIRECTORY=$HOME/Desktop/${DOMAIN}_recon

    echo "Creating directory $DIRECTORY."
    mkdir -p $DIRECTORY

    case $MODE in
        nmap-only)
        nmap_scan
        ;;
        dirsearch-only)
        dirsearch_scan
        ;;
        crt-only)
        crt_scan
        ;;
        takeover-only)
        crt_scan
        check_takeover_candidates
        ;;
        *)       
        nmap_scan
        dirsearch_scan
        crt_scan
        check_takeover_candidates
        ;;
    esac
}

report_domain(){

    DOMAIN=$1
    DIRECTORY=$HOME/Desktop/${DOMAIN}_recon
    echo "Generating recon report for $DOMAIN..."
    TODAY=$(date)
    echo "This scan was created on $TODAY" > $DIRECTORY/report

    if [ -f $DIRECTORY/nmap ];then
        echo "Results for Nmap:" >> $DIRECTORY/report
        grep -i "open" $DIRECTORY/nmap >> $DIRECTORY/report
    fi

    if [ -f $DIRECTORY/dirsearch.txt ];then
        echo "Results for Dirsearch:" >> $DIRECTORY/report
        cat $DIRECTORY/dirsearch.txt >> $DIRECTORY/report
    fi

    if [ -f $DIRECTORY/crt ];then
        echo "Results for crt.sh:" >> $DIRECTORY/report
        jq -r ".[] | .name_value" $DIRECTORY/crt >> $DIRECTORY/report
    fi

    if [ -s "$DIRECTORY/takeover.txt" ]; then
        echo -e "\n[+] Potential Subdomain Takeover Targets:\n" >> "$DIRECTORY/report"
        cat "$DIRECTORY/takeover.txt" >> "$DIRECTORY/report"
    fi

}

if [ "$INTERACTIVE" = true ];then
INPUT="BLANK"

    while [ "$INPUT" != "quit" ];do
        echo "Please enter a domain!"
        read INPUT 

        if [ "$INPUT" != "quit" ];then
            scan_domain $INPUT
            report_domain $INPUT
        fi

    done

else
    for i in "${@:$OPTIND:$#}";do
        scan_domain $i
        report_domain $i
    done
fi
