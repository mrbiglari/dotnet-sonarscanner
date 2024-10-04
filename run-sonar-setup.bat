@echo off

:: Dependencies for dotnet
call :check_dotnet_coverage
call :check_dotnet_sonarscanner

:: Dependencies for dotnet framework
call :check_dotnet_coverlet

echo All dependencies checked and installed if necessary.
goto :eof

:check_dotnet_sonarscanner
:: Check if dotnet-sonarscanner is installed, and install if not
dotnet tool list -g | findstr /I "dotnet-sonarscanner" >nul
if errorlevel 1 (
    echo dotnet-sonarscanner is not installed. Installing now...
    dotnet tool install --global dotnet-sonarscanner
    if errorlevel 1 (
        echo Error: Failed to install dotnet-sonarscanner.
        exit /b 1
    )
) else (
    echo dotnet-sonarscanner is already installed.
)
goto :eof

:check_dotnet_coverage
:: Check if dotnet-coverage is installed, and install if not
dotnet tool list -g | findstr /I "dotnet-coverage" >nul
if errorlevel 1 (
    echo dotnet-coverage is not installed. Installing now...
    dotnet tool install --global dotnet-coverage
    if errorlevel 1 (
        echo Error: Failed to install dotnet-coverage.
        exit /b 1
    )
) else (
    echo dotnet-coverage is already installed.
)
goto :eof

:check_dotnet_coverlet
:: Check if Coverlet is installed
dotnet tool list -g | findstr /I "coverlet.console" >nul
if errorlevel 1 (
    echo Coverlet is not installed. Installing Coverlet...
    dotnet tool install --global coverlet.console
    if errorlevel 1 (
        echo Error: Failed to install Coverlet.
        exit /b 1
    )
    echo Coverlet installed successfully.
) else (
    echo Coverlet is already installed.
)
goto :eof
