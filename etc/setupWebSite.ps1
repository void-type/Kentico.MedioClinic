#Requires -RunAsAdministrator
#Requires -Modules WebAdministration

[CmdletBinding()]
param (
  # Add your certificate to the Local Machine store along with all intermediate and CA certs in the chain. Then put the thumbprint here.
  [Parameter(Mandatory = $true)]
  [string]
  $CertificateThumbprint,

  [Parameter()]
  [string]
  $CmsDomain = 'medioclinic-cms.kentico.home',

  [Parameter()]
  [string]
  $LiveSiteDomain = 'medioclinic.kentico.home'
)

# TODO: This doesn't work with the trial license, but might be useful to go to prod.

$filePathBase = Resolve-Path -Path "$PSScriptRoot\..\"

$cmsAppPool = New-WebAppPool -Name $CmsDomain

New-WebSite -Name $CmsDomain -Port 80 -HostHeader $CmsDomain -PhysicalPath "$filePathBase\CMS" -ApplicationPool $cmsAppPool.Name
New-WebBinding -Name $CmsDomain -IPAddress "*" -Port 443 -HostHeader $CmsDomain -Protocol "https" -SslFlags 1
$cmsHttpsBinding = Get-WebBinding -Name $CmsDomain -Port 443 -Protocol "https"
$cmsHttpsBinding.AddSslCertificate($CertificateThumbprint, "my")

# Optional, if you want to run the live site. You'll need to install the .NET Core 3.1 Hosting Bundle.
$liveSiteAppPool = New-WebAppPool -Name $LiveSiteDomain
$liveSiteAppPool.managedRuntimeVersion = ""
$liveSiteAppPool | Set-Item

New-WebSite -Name $LiveSiteDomain -Port 80 -HostHeader $LiveSiteDomain -PhysicalPath "$filePathBase\MedioClinic" -ApplicationPool $liveSiteAppPool.Name
New-WebBinding -Name $LiveSiteDomain -IPAddress "*" -Port 443 -HostHeader $LiveSiteDomain -Protocol "https"
$cmsHttpsBinding = Get-WebBinding -Name $LiveSiteDomain -Port 443 -Protocol "https"
$cmsHttpsBinding.AddSslCertificate($CertificateThumbprint, "my")
