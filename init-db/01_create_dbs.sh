#!/bin/bash
set -e

# Подключение к базе данных postgres для выполнения команд
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    CREATE DATABASE keycloak;
EOSQL