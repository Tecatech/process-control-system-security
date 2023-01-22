shodan_check() {
    hash shodan 2>/dev/null || {
        echo >&2 "Shodan-CLI is not found!"
        sudo apt install python3-shodan
        exit
    }
    
    shodan info 2>/dev/null || {
        echo >&2 "Enter you API key:"
        read api_key
        shodan init $api_key
    }
    
    wget --no-check-certificate --quiet --spider --timeout=8 --tries=2 https://shodan.io
    if [[ $? -ne 0 ]]
    then
        echo "Network is unavailable!"
        exit
    fi
}

input_check() {
    if [ $# -ne 3 ]
    then
        echo "Wrong number of arguments!"
        exit
    fi
}

shodan_check
input_check $1 $2 $3

IFS=$'\n'
for protocol in $(cat $1)
do
    for header in $(cat $2)
    do
        for status_code in $(cat $3)
        do
            target=$(echo target/$protocol/$header | tr -d '"' | tr -d "[:space:]" | sed 's/:/_/g')
            
            shodan download $target $protocol $header $status_code --limit 10000
            gzip -d $target.json.gz
            
            strings $target.json | grep "hacked-by" > $target.hacked.json
            shodan parse --fields ip_str $target.json > $target.txt
            
            for ip_str in $(cat $target.txt)
            do
                curl https://www.shodan.io/host/$ip_str | strings | grep "twitter:title" >> $target.html
                curl https://www.shodan.io/host/$ip_str | strings | grep "twitter:description" >> $target.html
            done
        done
    done
done
