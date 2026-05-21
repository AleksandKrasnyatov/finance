<?php

declare(strict_types=1);

use App\Kernel;

require_once \dirname(__DIR__).'/vendor/autoload_runtime.php';

return function (array $context) {
    $environment = $context['APP_ENV'] ?? 'dev';

    if (!\is_string($environment)) {
        throw new InvalidArgumentException('APP_ENV must be a string.');
    }

    return new Kernel($environment, (bool) $context['APP_DEBUG']);
};
