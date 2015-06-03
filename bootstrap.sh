#!/usr/bin/env bash
set -Eeux
set -o posix
set -o pipefail

declare -r guest_log="/vagrant/guest_logs/vagrant_mmc_bootstrap.log"
declare -r dogecoin_target_dir="/opt/dogecoin"

echo "$0 will append logs to $guest_log"
echo "$0 will install dogecoin to $dogecoin_target_dir"
sleep 2

mkdir -p "$(dirname "$guest_log")"

declare -r exe_name="$0"
echo_log() {
	local log_target="$guest_log"
 	echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $exe_name: $@" >> $log_target
}

echo_log "start"
echo_log "uname: $(uname -a)"
echo_log "current procs: $(ps -aux)"
echo_log "current df: $(df -h /)"

# baseline system prep
echo_log "base system update"
apt-get update
apt-get install -y vim #always nice to have!

# MySQL
echo_log "getting MySQL stuff"
apt-get install -y mysql-client
export DEBIAN_FRONTEND=noninteractive
apt-get install -y mysql-server-5.5

# Python stuff
echo_log "getting Python stuff"
apt-get install -y python2.7 python-crypto python-mysqldb python-pip
apt-get install -y python-dev # needed for things like building python profiling

# Dogecoin
echo_log "prepping dogecoin stuff"
sudo -u vagrant mkdir -p /home/vagrant/.dogecoin
sudo -u vagrant cp /vagrant/dogecoin.conf /home/vagrant/.dogecoin/.
mkdir /opt/dogecoin
cp /vagrant/dogecoin_bin/dogecoind-1.8.2-linux64 "$dogecoin_target_dir/dogecoind"
cp /vagrant/dogecoin_bin/dogecoin-cli-1.8.2-linux64 "$dogecoin_target_dir/dogecoin-cli"
chown -R vagrant:vagrant "$dogecoin_target_dir"
chmod 755 "$dogecoin_target_dir/dogecoind"
chmod 755 "$dogecoin_target_dir/dogecoin-cli"
echo_log "starting dogecoind"
sudo -H -u vagrant "$dogecoin_target_dir/dogecoind" #note the -H... important
echo "Sleeping a while to let dogecoind get going..."
sleep 5

# Prep abe
echo_log "Set up DB"
mysql -u root < /vagrant/setup_mysql.sql

echo_log "dogecoind progress: $(tail /home/vagrant/.dogecoin/testnet3/debug.log || true)"
echo_log "current procs: $(ps -aux)"
echo_log "current df: $(df -h /)"

echo_log "complete"
echo "$0 all done!"
