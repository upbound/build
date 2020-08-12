################################# setup colors
# setting up colors
BLU='\033[0;34m'
YLW='\033[0;33m'
GRN='\033[0;32m'
RED='\033[0;31m'
NOC='\033[0m' # No Color

echo_info(){
    printf "${BLU}%s${NOC}\n" "$1"
}

echo_success(){
    printf "\n${GRN}%s${NOC}\n" "$1"
}
echo_warn(){
    printf "${YLW}%s${NOC}\n" "$1"
}
echo_error(){
    printf "\n${RED}%s${NOC}\n" "$1"
    return 1
}
#################################

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}