<?php

declare(strict_types=1);

use Symfony\Component\Dotenv\Dotenv;

require \dirname(__DIR__).'/vendor/autoload.php';

$_SERVER['APP_ENV'] = 'test';
$_ENV['APP_ENV'] = 'test';

(new Dotenv())->bootEnv(\dirname(__DIR__).'/.env', 'test');

if ($_SERVER['APP_DEBUG'] ?? false) {
    umask(0000);
}
