./talos_lab_cli/cmd/create_master.sh

./talos_lab_cli/scripts/6_join_worker.sh 185.250.36.197 X8Qgk3i2V6RNBb0Et 185.135.137.44 1

./talos_lab_cli/scripts/7_join_all_workers.sh 

ssh-keygen -f "/home/issam/.ssh/known_hosts" -R "185.135.137.44"
ssh-keygen -f "/home/issam/.ssh/known_hosts" -R "185.187.170.182"
ssh-keygen -f "/home/issam/.ssh/known_hosts" -R "45.67.216.224"
ssh-keygen -f "/home/issam/.ssh/known_hosts" -R "185.250.36.197"



     

talosctl version \
--nodes 185.135.137.44 \
--endpoints 185.135.137.44 \
--insecure

export TALOSCONFIG=$PWD/talos-config/talosconfig

talosctl memory -n 185.250.36.197 --endpoints 185.135.137.44

talosctl memory -n 45.67.216.224 --endpoints 185.135.137.44

talosctl memory -n 185.187.170.182 --endpoints 185.135.137.44

Master :

IP: 185.135.137.44

password: ppf21KFIP4845JoYC

Worker 1: 

IP: 185.250.36.197

password: X8Qgk3i2V6RNBb0Et


Worker 2:

IP: 45.67.216.224

password: I0q497OzAGb05bRl3


Worker 3:

IP: 185.187.170.182

password: kk496n7LUJlcVXS7k

ssh-keygen -f "/home/issam/.ssh/known_hosts" -R "185.250.36.197"



----

CLI:

./talos_lab_cli/talos-lab create cluster

./talos_lab_cli/talos-lab status

./talos_lab_cli/talos-lab validate config

./talos_lab_cli/talos-lab destroy cluster