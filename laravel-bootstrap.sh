#/bin/bash

# php repo - need to hit ENTER!
sudo add-apt-repository ppa:ondrej/php

# update
sudo apt update

# php
sudo apt install php7.3 php7.3-bcmath php7.3-cli php7.3-curl php7.3-json php7.3-mbstring php7.3-xml php7.3-zip

# composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
