

<# =======================================================================

File Name: nutanix_vms_modify.ps1
Author: itparadox@outlook.com (spain)
Date: jun-2019

Comments: Script developed to get an input file with this syntax:

    <cores> ; <GiB ram memory> ; <vmid> ; <cluster>

and 'update' the vm's.

======================================================================= #>


#--------------------------------------------------------------------
# Load Nutanix PSSnapin
#--------------------------------------------------------------------
$LoadedSnapins = Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue
if (-not $LoadedSnapins) {   

    Try{
        Add-PsSnapin NutanixCmdletsPSSnapin -ErrorAction Stop
        }
    Catch{
        Write-Host "Nutanix PSSnapin could not be loaded"
    }
}


#-------------------------------------------------------------------
# Set path file names
#-------------------------------------------------------------------
$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$VMs_input_file = Read-host "Please enter a CSV input file"


#-------------------------------------------------------------------
# Set CREDENTIALS files to connect to Nutanix cluster (this KEY and PWD file were created using PS1 script with AES).
#   I have include this scription scripts on the repository.
#-------------------------------------------------------------------
$KeyFile = $ScriptPath + "\security_keys\ntx_admin.key"
$PasswordFile = $ScriptPath + "\security_keys\ntx_admin.pwd"


#--------------------------------------------------------
# Nutanix cluster connection
#--------------------------------------------------------
$nxUser = "ntx_admin"
$key = Get-Content $KeyFile
$nxPassword = Get-Content $PasswordFile | ConvertTo-SecureString -Key $key


#--------------------------------------------------------
# Function ConnectNtxCluster
#--------------------------------------------------------
Function ConnectNtxCluster {

    $connectionNtx = Connect-NTNXCluster -Server $nxip -UserName $nxUser -Password $nxPassword -AcceptInvalidSSLCerts   # Conect to Nutanix cluster

}


#--------------------------------------------------------
# Function DisconnectNtxCluster
#--------------------------------------------------------
Function DisconnectNtxCluster {

    Disconnect-NTNXCluster -Servers *  # Disconnect from nutanix cluster

} # end function


#--------------------------------------------------------
# Funcion Power Off Ntx VMs
#--------------------------------------------------------
Function PowerOffNtxVMs {

    $estado = Get-NTNXVirtualMachine -Vmid $item[2]
    if ($estado.state –eq ‘on’) {
        Set-NTNXVMPowerState -Vmid $item[2] -Transition "ACPI_SHUTDOWN" -verbose # beginf guest shutdown
    } 

    Do{
        write-host "... shuting down vm ..."
        Start-Sleep -s 2
        $estado = Get-NTNXVirtualMachine -Vmid $item[2]
    }While ($estado.state –eq ‘on’)
    
    # Machine power state: ON | OFF | POWERCYCLE | RESET | PAUSE | SUSPEND | RESUME | ACPI_SHUTDOWN | ACPI_REBOOT

}


#--------------------------------------------------------
# Function Power On Ntx VMs
#--------------------------------------------------------
Function PowerOnNtxVMs {

    Set-NTNXVMPowerState -Vmid $item[2] -Transition "ON" -verbose # begin power on

}


#--------------------------------------------------------
# Funcion ModifyNtxVMs
#--------------------------------------------------------
Function ModifyNtxVMs {

    [int]$intMem = [convert]::ToInt32($item[1], 10)
    $memoria = $intMem * 1024
    
    Set-NTNXVirtualMachine -Vmid $item[2] -NumCoresPerVcpu $item[0] -MemoryMb $memoria

}


# ----------------------------------------------------------------------------------------
# Get content from CSV input file whith the VMs information
# ----------------------------------------------------------------------------------------
$VMs_to_modify = get-content $VMs_input_file


# ----------------------------------------------------
# Run prodcedure with each VM inside input file
# ----------------------------------------------------

foreach ($vm in $VMs_to_modify){
    
    # allocate each line in a array to manage -> <cores> ; <GiB ram memory> ; <vmid> ; <cluster>
    $item = $vm.split(";")
   
    ConnectNtxCluster # connect to nutanix cluster
    PowerOffNtxVMs  # shutdown VM
    ModifyNtxVMs  # modify VM
    PowerOnNtxVMs  # power on vm
    DisconnectNtxCluster  # disconnect from nutanix cluster

}
