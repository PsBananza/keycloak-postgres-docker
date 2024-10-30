#!/bin/bash

# Функция для загрузки переменных из .env файла
load_env() {
  export $(grep -v '^#' .env | xargs)
}

# Загрузка переменных из .env файла
load_env

# Получение токена
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$KEYCLOAK_ADMIN" \
  -d "password=$KEYCLOAK_ADMIN_PASSWORD" \
  -d 'grant_type=password' \
  -d 'client_id=admin-cli' | jq -r '.access_token')

# Создание клиента
RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "'$CLIENT_ID'",
    "enabled": true,
    "protocol": "openid-connect",
    "clientAuthenticatorType": "client-secret",
    "redirectUris": ["http://localhost:8080/*"],
    "publicClient": false,
    "standardFlowEnabled": true
  }')

# Получение ID созданного клиента
CLIENT_INTERNAL_ID=$(echo $RESPONSE | jq -r '.id')

# Проверка, что клиент был создан успешно
if [ "$CLIENT_INTERNAL_ID" == "null" ]; then
  echo "Error creating client"
  exit 1
fi

# Получение секретного ключа клиента
CLIENT_SECRET=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/clients/$CLIENT_INTERNAL_ID/client-secret" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq -r '.value')

# Проверка, что секретный ключ был успешно получен
if [ "$CLIENT_SECRET" == "null" ]; then
  echo "Error retrieving client secret"
  exit 1
fi

echo "Client '$CLIENT_ID' created successfully with secret '$CLIENT_SECRET'."

# Сохранение секретного ключа в .env файл
echo "CLIENT_SECRET=$CLIENT_SECRET" >> .env