#!/bin/sh
set -e

php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan storage:link --force

exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
