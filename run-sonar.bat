
@echo off
setlocal enabledelayedexpansion

set DEFAULT_TOKEN=""
set DEFAULT_URL=""

:: Check if the handle argument is provided
if "%1"=="" (
    echo "Error: Handle is required. Usage: run-sonar.bat [Handle] [ProjectName] [Optional: SonarToken] [Optional: SonarQubeURL]"
    exit /b 1
)

:: Set the handle from the first argument
set HANDLE=%1

:: Check if the project name argument is provided
if "%2"=="" (
    echo "Error: Project name is required."
    exit /b 1
)

:: Set the project name from the first argument
set PROJECT_NAME=%2

:: Set the default token value if not provided
if "%3"=="" (
    set SONAR_TOKEN=%DEFAULT_TOKEN%
) else (
    set SONAR_TOKEN=%3
)

:: Set the default SonarQube URL if not provided
if "%4"=="" (
    set SONAR_URL=%DEFAULT_URL%
) else (
    set SONAR_URL=%4
)

:: Run the appropriate script based on the handle
if /I "%HANDLE%"==".netframework" (
    echo "Running .netframework script..."
    call :run_dotnetframework_script %*
) else if /I "%HANDLE%"==".net" (
    echo "Running .net script..."
    call :run_dotnet_script %*
) else (
    echo "Error: Invalid handle. Use '.netframework' or '.net'."
    exit /b 1
)

exit /b


:: [START] --------------------------------------- CALL DEFINITIONS ---------------------------------------  [START] ::
:run_dotnetframework_script
    :: .NET Framework script to upload SonarScan reports to SonarQube
    :: This script includes the following steps:
    :: 1. Find solution root directory.
    :: 2. Find all projects with the word "Test" in their title.
    :: 3. Run tests and generate code coverage for found test projects.
    :: 4. Build the solution and pass code analysis report to SonarQube.
    :: 5. Pass code coverage reports to SonarQube.

    :: Find the solution root (assuming .sln file is in or above the current directory)
    for /r "%cd%" %%f in (*.sln) do (
        set "SOLUTION_ROOT=%%~dpf"
        goto :found_solution
    )
    :found_solution

    :: Check if solution root was found
    if "%SOLUTION_ROOT%"=="" (
        echo "Error: Could not locate the .sln file. Please ensure you're running this script from a valid project directory."
        exit /b 1
    )

    call :build_dotnetframework_solution
    call :list_test_dlls
    call :run_tests_with_coverlet_and_vstest
    call :run_sonnarscanner_for_dotnetframework

exit /b

:run_sonnarscanner_for_dotnetframework
    :: Start SonarScanner analysis for .NET Framework, now including the coverage reports paths
    echo Using Project Name: %PROJECT_NAME%
    echo Using SonarQube Url: %SonarQubeURL%

    SonarScanner.MSBuild.exe begin /k:"%PROJECT_NAME%" ^
        /d:sonar.host.url=!SONAR_URL! ^
        /d:sonar.token=%SONAR_TOKEN% ^
        /d:sonar.cs.opencover.reportsPaths="%COVERAGE_REPORTS%" ^
        /d:sonar.scanner.scanAll=false

    :: Build the entire solution using MSBuild for .NET Framework with minimal verbosity
    call :build_dotnetframework_solution

    :: Complete SonarScanner analysis (no need to provide the reports here)
    SonarScanner.MSBuild.exe end /d:sonar.token=%SONAR_TOKEN%
goto :eof

:build_dotnetframework_solution
    MSBuild.exe /t:Rebuild /restore /p:Configuration=Release /p:WarningLevel=0 /p:TreatWarningsAsErrors=false /p:NoWarn=all /v:m /clp:ErrorsOnly
goto :eof

:run_tests_with_coverlet_and_vstest
    :: Set the coverage output directory relative to the solution root
    set COVERAGE_OUTPUT_DIR=%SOLUTION_ROOT%\coverage

    :: Create the coverage directory if it doesn't exist
    if not exist "%COVERAGE_OUTPUT_DIR%" (
        mkdir "%COVERAGE_OUTPUT_DIR%"
    )

    :: Initialize the variable for holding the comma-separated coverage reports
    set COVERAGE_REPORTS=

    :: Loop over each DLL found and run Coverlet + SonarScanner
    for %%d in (!TEST_DLLS!) do (
        :: Strip the first and last character (quotes) from %%d
        set "RAW_DLL_PATH=%%d"
        set "RAW_DLL_PATH=!RAW_DLL_PATH:~1,-1!"

        :: Extract the test project name from the DLL path for unique naming
        set "DLL_PROJECT_NAME=%%~nd"

        :: Set unique coverage report path using project name
        set COVERAGE_REPORT_PATH=%COVERAGE_OUTPUT_DIR%\!DLL_PROJECT_NAME!.opencover.xml

        echo Running Coverlet for "!RAW_DLL_PATH!" and saving to "!COVERAGE_REPORT_PATH!"

        :: Generate the coverage report in OpenCover format using Coverlet
        coverlet "!RAW_DLL_PATH!" --target "vstest.console.exe" --targetargs "\"!RAW_DLL_PATH!\"" --output "!COVERAGE_REPORT_PATH!" --format opencover

        :: If Coverlet fails, exit with error
        if errorlevel 1 (
            echo "Error: Coverlet failed for !RAW_DLL_PATH!"
            exit /b 1
        )

        :: Append the generated coverage report path to COVERAGE_REPORTS
        if not "!COVERAGE_REPORTS!"=="" (
            set COVERAGE_REPORTS=!COVERAGE_REPORTS!,!COVERAGE_REPORT_PATH!
        ) else (
            set COVERAGE_REPORTS=!COVERAGE_REPORT_PATH!
        )
    )
goto :eof

:list_test_dlls
    set TEST_DLLS=
    for /r "%cd%" %%f in (*.csproj) do (
        set "projName=%%~nf"
        if not "!projName!"=="!projName:Test=!" (
            echo Project !projName! contains "Test" in the name

            pushd "%%~dpf"
            if exist "bin\Debug" (
                set "dllDir=%%~dpfbin\Debug"
                if exist "!dllDir!\!projName!.dll" (
                    set TEST_DLLS=!TEST_DLLS! "!dllDir!\!projName!.dll"
                )
            ) else if exist "bin\Release" (
                set "dllDir=%%~dpfbin\Release"
                if exist "!dllDir!\!projName!.dll" (
                    set TEST_DLLS=!TEST_DLLS! "!dllDir!\!projName!.dll"
                )
            )
            popd
        )
    )
goto :eof

:run_dotnet_script
    :: .NET script to upload SonarScan reports to SonarQube
    :: This script includes the following steps:
    :: 1. Install dotnet tools if not present.
    :: 2. Build the solution and pass code analysis report to SonarQube.
    :: 3. Run tests, gather code coverage and pass to SonarQube.

    echo Using Project Name: %PROJECT_NAME%
    echo Using SonarQube Url: %SonarQubeURL%

    call :run_sonarscanner_for_dotnet

exit /b

:run_sonarscanner_for_dotnet
    dotnet sonarscanner begin /k:"%PROJECT_NAME%" ^
        /d:sonar.host.url="%SONAR_URL%" ^
        /d:sonar.token=%SONAR_TOKEN% ^
        /d:sonar.cs.vscoveragexml.reportsPaths=coverage.xml

    dotnet build -clp:ErrorsOnly

    dotnet-coverage collect "dotnet test --no-build" -f xml -o "coverage.xml"

    dotnet sonarscanner end /d:sonar.token=%SONAR_TOKEN%
goto :eof
:: [END]  ----------------------------------------- CALL DEFINITIONS -----------------------------------------  [END] ::
