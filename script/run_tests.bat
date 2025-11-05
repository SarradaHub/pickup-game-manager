@echo off
REM Script to run RSpec tests using docker-compose on Windows
REM Usage:
REM   script\run_tests.bat                    # Run all tests
REM   script\run_tests.bat --reset             # Reset test DB and run all tests
REM   script\run_tests.bat spec/models         # Run specific test directory
REM   script\run_tests.bat spec/models/user_spec.rb  # Run specific test file

setlocal enabledelayedexpansion

set RESET_DB=false
set FORCE_RESET=false
set TEST_ARGS=

REM Parse arguments
:parse_args
if "%~1"=="" goto end_parse
if "%~1"=="--reset" (
    set RESET_DB=true
    shift
    goto parse_args
)
if "%~1"=="-r" (
    set RESET_DB=true
    shift
    goto parse_args
)
if "%~1"=="--force-reset" (
    set FORCE_RESET=true
    set RESET_DB=true
    shift
    goto parse_args
)
if "%~1"=="-f" (
    set FORCE_RESET=true
    set RESET_DB=true
    shift
    goto parse_args
)
if "%~1"=="--help" (
    echo Usage: %~nx0 [OPTIONS] [TEST_PATH]
    echo.
    echo Options:
    echo   --reset, -r          Reset test database before running tests
    echo   --force-reset, -f   Force full reset (drop, create, load schema)
    echo   --help               Show this help message
    echo.
    echo Examples:
    echo   %~nx0                           # Run all tests
    echo   %~nx0 --reset                   # Reset DB and run all tests
    echo   %~nx0 --force-reset             # Force full DB reset and run all tests
    echo   %~nx0 spec/models               # Run tests in spec/models
    echo   %~nx0 spec/models/user_spec.rb  # Run specific test file
    exit /b 0
)
if "%~1"=="-h" (
    goto :parse_args
)
set TEST_ARGS=%~1
shift
goto parse_args
:end_parse

echo [INFO] Checking docker-compose...

REM Check if docker-compose is available
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] docker-compose is not installed or not in PATH
    exit /b 1
)

REM Check if containers are running
docker-compose ps | findstr /C:"Up" >nul
if errorlevel 1 (
    echo [WARN] Docker containers don't appear to be running.
    echo [INFO] Starting containers...
    docker-compose up -d
    timeout /t 5 /nobreak >nul
)

REM Reset test database if requested
if "%RESET_DB%"=="true" (
    echo [STEP] Resetting test database...
    
    if "%FORCE_RESET%"=="true" (
        echo [INFO] Force reset: Dropping test database...
        docker-compose exec -T app bundle exec rails db:drop RAILS_ENV=test >nul 2>&1 || echo [WARN] Database may not exist (this is OK)
        
        echo [INFO] Creating test database...
        docker-compose exec -T app bundle exec rails db:create RAILS_ENV=test
        if errorlevel 1 (
            echo [ERROR] Failed to create test database
            exit /b 1
        )
        
        echo [INFO] Loading test database schema...
        docker-compose exec -T app bundle exec rails db:schema:load RAILS_ENV=test
        if errorlevel 1 (
            echo [ERROR] Failed to load test database schema
            exit /b 1
        )
    ) else (
        echo [INFO] Resetting test database (this may take a moment)...
        docker-compose exec -T app bundle exec rails db:reset RAILS_ENV=test
        if errorlevel 1 (
            echo [WARN] db:reset failed, trying alternative method...
            docker-compose exec -T app bundle exec rails db:drop RAILS_ENV=test >nul 2>&1
            docker-compose exec -T app bundle exec rails db:create RAILS_ENV=test
            if errorlevel 1 (
                echo [ERROR] Failed to create test database
                exit /b 1
            )
            docker-compose exec -T app bundle exec rails db:schema:load RAILS_ENV=test
            if errorlevel 1 (
                echo [ERROR] Failed to load test database schema
                exit /b 1
            )
        )
    )
    
    echo [INFO] Test database reset complete ^✓
    echo.
)

REM Prepare test database
echo [STEP] Preparing test database...
docker-compose exec -T app bundle exec rails db:test:prepare RAILS_ENV=test
if errorlevel 1 (
    echo [WARN] db:test:prepare failed, trying alternative methods...
    echo [INFO] Ensuring test database exists...
    docker-compose exec -T app bundle exec rails db:create RAILS_ENV=test >nul 2>&1 || echo [INFO] Test database may already exist
    echo [INFO] Loading test database schema...
    docker-compose exec -T app bundle exec rails db:schema:load RAILS_ENV=test
    if errorlevel 1 (
        echo [ERROR] Failed to prepare test database
        echo [ERROR] Try running with --force-reset flag: script\run_tests.bat --force-reset
        exit /b 1
    )
)

REM Clean up any stale data by truncating all tables
echo [INFO] Cleaning test database (removing stale data)...
docker-compose exec -T app bundle exec rails runner "conn = ActiveRecord::Base.connection; conn.execute('SET session_replication_role = replica'); conn.execute('TRUNCATE TABLE athlete_matches, payments, incomes, athletes, matches, expenses, transaction_categories RESTART IDENTITY CASCADE'); conn.execute('SET session_replication_role = DEFAULT')" RAILS_ENV=test >nul 2>&1
if errorlevel 1 (
    echo [WARN] Could not truncate tables (this is OK if database is already clean or needs reset)
    echo [INFO] If you see fixture errors, try: script\run_tests.bat --force-reset
)

REM Verify database is ready
echo [INFO] Verifying test database connection...
docker-compose exec -T app bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" RAILS_ENV=test >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Test database connection failed
    exit /b 1
)

REM Run the tests
echo [STEP] Running RSpec tests...
echo.

if "%TEST_ARGS%"=="" (
    REM Run all tests
    docker-compose exec app bundle exec rspec
) else (
    REM Run specific tests
    docker-compose exec app bundle exec rspec %TEST_ARGS%
)

set TEST_EXIT_CODE=%ERRORLEVEL%

echo.
if %TEST_EXIT_CODE% equ 0 (
    echo [INFO] All tests passed! ^✓
) else (
    echo [ERROR] Some tests failed. Exit code: %TEST_EXIT_CODE%
    echo [INFO] Tip: Try running with --force-reset if you're seeing fixture errors
)

exit /b %TEST_EXIT_CODE%

