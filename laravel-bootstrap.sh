#/bin/bash

# php repo - need to hit ENTER!
sudo add-apt-repository ppa:ondrej/php

# update
sudo apt update -qq

# php
sudo apt install -y php7.3-fpm php7.3-bcmath php7.3-cli php7.3-curl php7.3-json php7.3-mbstring php7.3-xml php7.3-zip
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 256M/g' /etc/php/7.3/fpm/php.ini

# more tools
sudo apt install -y unzip git nginx mysql-server

# composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# add composer to $PATH
echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc

# mysql
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password root"
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password root"
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server



# laravel vhosts
sudo adduser $USER www-data

sudo mkdir /www
sudo chown www-data:www-data /www
sudo chmod 775 /www



