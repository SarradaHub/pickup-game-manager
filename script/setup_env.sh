#!/bin/bash

# Setup environment variables for PostgreSQL
export POSTGRES_HOST=localhost
export POSTGRES_USER=lmafra
export POSTGRES_PASSWORD=password
export POSTGRES_DB=pickup_game_manager_development
export POSTGRES_TEST_DB=pickup_game_manager_test

echo "Environment variables set:"
echo "POSTGRES_HOST: $POSTGRES_HOST"
echo "POSTGRES_USER: $POSTGRES_USER"
echo "POSTGRES_DB: $POSTGRES_DB"
echo "POSTGRES_TEST_DB: $POSTGRES_TEST_DB"
echo ""
echo "To use these variables in your current shell, run:"
echo "source setup_env.sh"
echo ""
echo "Or copy env.example to .env and run: bundle install"
