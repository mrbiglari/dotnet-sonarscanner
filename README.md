
# SonarQube Scanner Batch Script

This repository contains a Windows batch script (`run-sonar.bat`) that automates the process of running SonarQube analysis for .NET Framework and .NET Core projects. The script handles test project detection, code coverage generation, and report submission to SonarQube.

## Usage

```bash
run-sonar.bat [Handle] [ProjectName] [Optional: SonarToken] [Optional: SonarQubeURL]
```

### Parameters

- **Handle**: Specifies the target framework. Accepted values are `.netframework` for .NET Framework projects and `.net` for .NET Core projects.
- **ProjectName**: The SonarQube project key. This is a required parameter.
- **SonarToken** (optional): The authentication token for SonarQube. If not provided, a default value will be used.
- **SonarQubeURL** (optional): The URL of the SonarQube server. If not provided, a default value will be used.

## How It Works

### For .NET Framework Projects
1. The script locates the solution file (.sln).
2. Identifies all test projects (those containing "Test" in their names).
3. Generates code coverage reports using Coverlet.
4. Runs the SonarQube analysis with the reports.
5. Submits both code analysis and coverage reports to the SonarQube server.

### For .NET Core Projects
1. The script builds the solution.
2. Runs tests and collects code coverage using `dotnet-coverage`.
3. Submits both code analysis and coverage reports to the SonarQube server.

## Example Commands

### Running for .NET Framework:
```bash
run-sonar.bat .netframework MyProjectName YourSonarToken http://your-sonarqube-url
```

### Running for .NET Core:
```bash
run-sonar.bat .net MyProjectName YourSonarToken http://your-sonarqube-url
```

## Error Handling

The script includes basic error handling for missing or invalid arguments:
- If the handle or project name is not provided, the script will output an error and terminate.
- If an invalid handle is used (anything other than `.netframework` or `.net`), the script will notify the user.

## Requirements

- **SonarQube**: Ensure that SonarQube is running and accessible.
- **SonarScanner**: Make sure the relevant SonarScanner tools are installed and available in your system's PATH for both .NET and .NET Framework.
- **MSBuild**: Required for building .NET and .NET Framework projects.
- **Coverlet**: For .NET Framework projects, the `Coverlet` tool is used to generate coverage reports.

## License

This project is licensed under the MIT License.
