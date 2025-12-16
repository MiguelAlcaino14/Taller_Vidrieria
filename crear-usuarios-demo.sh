#!/bin/bash

# Script para crear usuarios demo
# Este script llama a la edge function que crea los usuarios correctamente

echo "Creando usuarios demo..."

curl -X POST \
  "https://zeijbhdpmrgllqdbysrd.supabase.co/functions/v1/setup-demo-users" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplaWpiaGRwbXJnbGxxZGJ5c3JkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4ODY2ODIsImV4cCI6MjA4MTQ2MjY4Mn0.XXSTXIO2iNsVDfiCGiy6xpEk2ffy9El5U0vOprKci9g" \
  -H "Content-Type: application/json"

echo ""
echo "Usuarios creados!"
echo ""
echo "Credenciales:"
echo "- admin@vidrios.com / Admin123!"
echo "- manager@vidrios.com / Manager123!"
echo "- usuario1@vidrios.com / Usuario123!"
echo "- usuario2@vidrios.com / Usuario123!"
