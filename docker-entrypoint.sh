#!/bin/bash
set -e

DATADIR='/var/lib/mysql'

initialize() {

  MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-dev}"
  MYSQL_PASSWORD="${MYSQL_PASSWORD:-dev}"
  MYSQL_USER="${MYSQL_USER:-dev}"
  MYSQL_ROOT_HOST="${MYSQL_ROOT_HOST:-%}"
  DATADIR="${DATADIR:-/var/lib/mysql}"

  echo "> Initializing database"
  mkdir -p "$DATADIR"
  chown -R mysql:mysql "$DATADIR"

  mysqld --initialize-insecure --user=mysql

  echo "> Starting temporary server"
  if ! mysqld --daemonize --skip-networking --user=mysql; then
    echo "Error starting mysqld"
    exit 1
  fi

  echo "> Setting root password"
  echo
  echo "Password: $MYSQL_ROOT_PASSWORD"
  echo

  INIT_SQL="/tmp/mysql-init.sql"
  : > "$INIT_SQL"

  if [ "$MYSQL_ROOT_HOST" != 'localhost' ]; then
    cat >> "$INIT_SQL" <<SQL
CREATE USER IF NOT EXISTS 'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'${MYSQL_ROOT_HOST}' WITH GRANT OPTION;
SQL
  fi

  cat >> "$INIT_SQL" <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

  if [ -n "$MYSQL_DATABASE" ]; then
    echo "> Creating database $MYSQL_DATABASE"
    echo "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;" >> "$INIT_SQL"
  fi

  if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
    echo "> Creating user"
    echo
    echo "User: $MYSQL_USER"
    echo "Password: $MYSQL_PASSWORD"
    echo

    cat >> "$INIT_SQL" <<SQL
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
SQL

    if [ -n "$MYSQL_DATABASE" ]; then
      echo "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';" >> "$INIT_SQL"
    fi
  fi

  mysql --protocol=socket -uroot < "$INIT_SQL" || {
    echo "Failed to apply initialization SQL"
    cat "$INIT_SQL"
    exit 1
  }

  rm -f "$INIT_SQL"

  echo "> Shutting down temporary server"
  if ! mysqladmin shutdown -uroot -p"$MYSQL_ROOT_PASSWORD" ; then
      echo "Error shutting down mysqld"
      exit 1
  fi

  echo "> Complete"
}

if [ "$1" = 'mysqld' ]; then
  if [ ! -d "$DATADIR/mysql" ]; then
    initialize
  fi
fi

cat <<'EOF'
    __  ___      _____ ____    __
   /  |/  /_  __/ ___// __ \  / /
  / /|_/ / / / /\__ \/ / / / / /
 / /  / / /_/ /___/ / /_/ / / /___
/_/  /_/\__, //____/\___\_\/_____/
       /____/
EOF

if [ "$1" = 'mysqld' ]; then
  exec "$@" "--user=mysql"
else
  exec "$@"
fi
