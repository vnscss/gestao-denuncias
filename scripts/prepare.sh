if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root" >&2
  exit 1
fi


echo "Closing all containers..."

docker stop $(docker ps -q)

echo "Done..."