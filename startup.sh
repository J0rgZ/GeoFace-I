#!/bin/bash
# Script de inicio para Azure App Service
gunicorn --bind=0.0.0.0:8000 --timeout=600 --workers=2 --worker-class=gevent app.main:app

