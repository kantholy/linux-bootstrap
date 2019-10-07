<?php

$nginx_stub = 'https://raw.githubusercontent.com/kantholy/linux-bootstrap/master/nginx/laravel.stub';
$nginx_config = '/etc/nginx/sites-enabled'; //no trailing slash

# get PHP FPM version
preg_match('/php([0-9.]+)-fpm/', `apt list --installed php*`, $matches);

[$fpm_version] = $matches;

# list all folders
$folders = glob('/www/*', GLOB_ONLYDIR);

# nginx config
$template = file_get_contents($nginx_stub);


foreach($folders as $root) {
    $file = basename($root);
    $server = $file . '.test';

    # build config file
    $config = str_replace(
        ['{server}', '{root}', '{fpm-version}'],
        [$server, $root, $fpm_version],
        $template
    );

    # save config file
    file_put_contents($nginx_config . DIRECTORY_SEPARATOR . $file, $config);
}
