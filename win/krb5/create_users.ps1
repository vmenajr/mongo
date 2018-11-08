$mdb = Read-Host "MongoDB host"
$port= 27017
$spn = "mongodb/${mdb}"
$usr = "mongo"
$ss  = Read-Host "Password for all users" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)
$pwd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
$kt  = "${usr}.keytab"

# $ss  = ConvertTo-SecureString $pwd -AsPlainText -Force

Get-ADUser -Identity test | Remove-ADUser -Confirm:$false
Get-ADUser -Identity $usr | Remove-ADUser -Confirm:$false

New-ADUser -Name test -AccountPassword $ss -CannotChangePassword $false -ChangePasswordAtLogon $false -Enabled $true -PasswordNeverExpires $true 
Add-ADGroupMember -Identity "Administrators" -Members test

New-ADUser -Name $usr -AccountPassword $ss -CannotChangePassword $false -ChangePasswordAtLogon $false -Enabled $true -PasswordNeverExpires $true -ServicePrincipalNames $spn
# New-ADUser -Name $usr -AccountPassword $ss -CannotChangePassword $false -ChangePasswordAtLogon $false -Enabled $true -PasswordNeverExpires $true

# setspn -S ${spn} ${usr}
setspn -L $usr

ktpass /princ ${spn}@MDB.ORG /mapuser ${usr}@MDB.ORG /pass $pwd /out $kt /crypto all /ptype KRB5_NT_PRINCIPAL /mapop set
# ktpass /in $kt

