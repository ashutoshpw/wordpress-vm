#!/bin/bash

SCRIPTS=/var/scripts

# Acitvate the new config
        echo -e "\e[0m"
        echo "Apache will now reboot"
        echo -e "\e[32m"
        read -p "Press any key to continue... " -n1 -s
        echo -e "\e[0m"
        a2ensite wordpress_ssl_domain.conf
        a2dissite wordpress_port_443.conf
        service apache2 restart
if [[ "$?" == "0" ]];
then
        echo -e "\e[42m"
        echo "New settings works! SSL is now activated and OK!"
        echo -e "\e[0m"
	echo
	echo "This cert will expire in 90 days, so you have to renew it."
	echo "There are several ways of doing so, here are some tips and tricks: https://goo.gl/c1JHR0"
	echo "This script will add a renew cronjob to get you started, edit it by typing:"
	echo "'crontab -u root -e'"
	echo "Feel free to contribute to this project: https://goo.gl/vEsWjb"
	echo -e "\e[32m"
    	read -p "Press any key to continue... " -n1 -s
    	echo -e "\e[0m"
	crontab -u root -l | { cat; echo "@monthly $SCRIPTS/letsencryptrenew.sh"; } | crontab -u root -
cat << CRONTAB > "/var/scripts/letsencryptrenew.sh"
#!/bin/sh
set -x
systemctl stop apache2.service
if ! /etc/letsencrypt/letsencrypt-auto renew > /var/log/letsencrypt/renew.log 2>&1 ; then
        echo Automated renewal failed:
        cat /var/log/letsencrypt/renew.log
        exit 1
fi
systemctl start apache2.service
if [[ $? == 0 ]]
then
        echo "Let's Encrypt SUCCESS!"--$(date +%Y-%m-%d_%H:%M) >> /var/log/letsencrypt/cronjob.log
else
        echo "Let's Encrypt FAILED!"--$(date +%Y-%m-%d_%H:%M) >> /var/log/letsencrypt/cronjob.log
        reboot
fi
CRONTAB

# Makeletsencryptrenew.sh executable
chmod +x $SCRIPTS/letsencryptrenew.sh

# Cleanup
rm $SCRIPTS/test-new-config.sh
rm $SCRIPTS/activate-ssl.sh

else
# If it fails, revert changes back to normal
        a2dissite wordpress_ssl_domain.conf
        a2ensite wordpress_port_443.conf
        service apache2 restart
        echo -e "\e[96m"
        echo "Couldn't load new config, reverted to old settings. SSL is OK!"
        echo -e "\e[0m"
        echo -e "\e[32m"
        read -p "Press any key to continue... " -n1 -s
        echo -e "\e[0m"
	exit 1
fi

exit 0

