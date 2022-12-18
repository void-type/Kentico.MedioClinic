#Requires -RunAsAdministrator

# Install the .NET 3.1 hosting bundle by hand https://dotnet.microsoft.com/en-us/download/dotnet/3.1
# Install SQL Server Developer and SSMS by hand using defaults or desired settings.
# Restore the db bacpac

# Allow SQL Firewall port if needed externally
# netsh advfirewall firewall add rule name = SQLPort dir = in protocol = tcp action = allow localport = 1433 remoteip = localsubnet profile = PRIVATE

# Setup IIS Web Server
$features = @(
  'IIS-ManagementConsole'
  'IIS-ASPNET45'
  'IIS-NetFxExtensibility45'
  'IIS-ISAPIExtensions'
  'IIS-ISAPIFilter'
  'IIS-StaticContent'
)

Enable-WindowsOptionalFeature -Online -All -FeatureName $features -LogLevel Errors
