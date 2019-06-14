<# =======================================================================

File Name: UserPassword_cipher.ps1
Author: itparadox@outlook.com (Spain)
Date: 26-mar-2017

Comments: Script to cipher user's password using AES 32bits Key

======================================================================= #>

Clear-Host

$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#-------------------------------------------------------------------
# Request information from the user
#-------------------------------------------------------------------
$domain = Read-Host "Enter domain" # it is only useful if you need to cipher different domain user accounts.
$User = Read-Host "Enter user"
$password = Read-Host "Enter password" | ConvertTo-SecureString -AsPlainText -Force

#-------------------------------------------------------------------
# Define output file names
#-------------------------------------------------------------------
$KeyFile = $ScriptPath + "\" + $domain + "_" + $user + ".key"
$PasswordFile = $ScriptPath + "\" + $domain + "_" + $user + ".pwd"


#-------------------------------------------------------------------
# AES 32bits Creation Key
#-------------------------------------------------------------------
$Key = New-Object Byte[] 32   # for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile


#-------------------------------------------------------------------
# Password file creation using AES 32bits Key
#-------------------------------------------------------------------
$Key = Get-Content $KeyFile
$password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile

