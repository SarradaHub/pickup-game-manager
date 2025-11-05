@echo off
REM Development environment management script using docker-compose for Windows
REM Usage:
REM   script\dev.bat start          # Start development environment
REM   script\dev.bat stop           # Stop development environment
REM   script\dev.bat restart        # Restart development environment
REM   script\dev.bat build          # Build containers
REM   script\dev.bat logs           # View logs
REM   script\dev.bat console        # Open Rails console
REM   script\dev.bat db:migrate     # Run database migrations
REM   script\dev.bat db:seed        # Seed database
REM   script\dev.bat clean          # Clean up containers and volumes

setlocal enabledelayedexpansion

set COMMAND=%1
if "%COMMAND%"=="" set COMMAND=start

REM Check if docker-compose is available
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] docker-compose is not installed or not in PATH
    exit /b 1
)

REM Check if we're in the project directory
if not exist "docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found. Are you in the project root?
    exit /b 1
)

goto %COMMAND%

:start
echo [STEP] Starting development environment...
docker-compose up -d
if errorlevel 1 (
    echo [ERROR] Failed to start containers
    exit /b 1
)
echo [INFO] Development environment is ready!
echo [INFO] Application is available at: http://localhost:3000
echo [INFO] Use 'script\dev.bat logs' to view logs
goto end

:stop
echo [STEP] Stopping development environment...
docker-compose stop
echo [INFO] Development environment stopped ^✓
goto end

:restart
echo [STEP] Restarting development environment...
docker-compose restart
echo [INFO] Development environment restarted ^✓
goto end

:build
echo [STEP] Building containers...
if "%2"=="--no-cache" (
    docker-compose build --no-cache
) else (
    docker-compose build
)
if errorlevel 1 (
    echo [ERROR] Failed to build containers
    exit /b 1
)
echo [INFO] Containers built ^✓
goto end

:logs
if "%2"=="" (
    docker-compose logs -f
) else (
    docker-compose logs -f %2
)
goto end

:console
echo [STEP] Opening Rails console...
docker-compose exec app bundle exec rails console
goto end

:shell
echo [STEP] Opening shell in container...
docker-compose exec app bash
goto end

:status
echo [STEP] Development environment status:
echo.
docker-compose ps
echo.
goto end

:clean
echo [STEP] Cleaning up development environment...
echo [WARN] This will remove containers, volumes, and data!
set /p CONFIRM="Are you sure? [y/N] "
if /i not "%CONFIRM%"=="y" (
    echo [INFO] Cleanup cancelled
    goto end
)
docker-compose down --volumes --remove-orphans
echo [INFO] Development environment cleaned up ^✓
goto end

:db:*
set RAILS_CMD=%COMMAND%
docker-compose exec app bundle exec rails %RAILS_CMD%
goto end

:rails:*
set RAILS_CMD=%COMMAND:~6%
docker-compose exec app bundle exec rails %RAILS_CMD%
goto end

:help
echo Development Environment Management Script
echo.
echo Usage: %~nx0 [COMMAND] [OPTIONS]
echo.
echo Commands:
echo   start              Start development environment (default)
echo   stop               Stop development environment
echo   restart            Restart development environment
echo   build [--no-cache] Build containers
echo   logs [service]     View logs
echo   console            Open Rails console
echo   shell              Open shell in container
echo   status             Show status of containers
echo   clean              Clean up containers and volumes
echo   db:*               Run database commands
echo   rails:*            Run Rails commands
echo.
echo Examples:
echo   %~nx0 start                    # Start development environment
echo   %~nx0 stop                     # Stop development environment
echo   %~nx0 restart                  # Restart everything
echo   %~nx0 build                    # Build containers
echo   %~nx0 logs                     # View all logs
echo   %~nx0 console                  # Open Rails console
echo   %~nx0 db:migrate               # Run migrations
echo   %~nx0 db:seed                 # Seed database
goto end

:end
exit /b 0
