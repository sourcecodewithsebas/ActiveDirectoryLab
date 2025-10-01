#>

# ------------------ CONFIGURATION ------------------ #
$PASSWORD_FOR_USERS          = "Password1"   # Lab/demo password
$NUMBER_OF_ACCOUNTS_TO_CREATE = 100          # Adjust as needed
$OU_NAME                     = "_EMPLOYEES"  # Target OU for accounts
$LOG_FILE                    = ".\user_creation_log.txt"
# --------------------------------------------------- #

# Ensure OU exists
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OU_NAME'" -ErrorAction SilentlyContinue)) {
    Write-Host "OU '$OU_NAME' not found. Creating it..." -ForegroundColor Yellow
    New-ADOrganizationalUnit -Name $OU_NAME -ProtectedFromAccidentalDeletion $false
}

# Function to generate random names
Function Generate-Random-Name {
    $consonants = @('b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','w','x','z')
    $vowels     = @('a','e','i','o','u','y')
    $nameLength = Get-Random -Minimum 3 -Maximum 7
    $count      = 0
    $name       = ""

    while ($count -lt $nameLength) {
        if ($($count % 2) -eq 0) {
            $name += $consonants[(Get-Random -Minimum 0 -Maximum ($consonants.Count - 1))]
        }
        else {
            $name += $vowels[(Get-Random -Minimum 0 -Maximum ($vowels.Count - 1))]
        }
        $count++
    }
    return $name.Substring(0,1).ToUpper() + $name.Substring(1) # Capitalize
}

# Convert password to secure string once
$password = ConvertTo-SecureString $PASSWORD_FOR_USERS -AsPlainText -Force

# Log header
"---- User Creation Log ($(Get-Date)) ----" | Out-File $LOG_FILE

# Main loop
for ($count = 1; $count -le $NUMBER_OF_ACCOUNTS_TO_CREATE; $count++) {
    $firstName = Generate-Random-Name
    $lastName  = Generate-Random-Name
    $username  = "$firstName.$lastName"

    Write-Host "[$count/$NUMBER_OF_ACCOUNTS_TO_CREATE] Creating user: $username" `
        -BackgroundColor Black -ForegroundColor Cyan
    
    try {
        New-ADUser -AccountPassword $password `
                   -GivenName $firstName `
                   -Surname $lastName `
                   -DisplayName $username `
                   -Name $username `
                   -EmployeeID $username `
                   -PasswordNeverExpires $true `
                   -Path "OU=$OU_NAME,$(([ADSI]'').distinguishedName)" `
                   -Enabled $true

        "SUCCESS: Created user $username" | Out-File -Append $LOG_FILE
    }
    catch {
        "ERROR: Failed to create user $username - $_" | Out-File -Append $LOG_FILE
    }
}

Write-Host "User creation complete! Log saved to $LOG_FILE" -ForegroundColor Green
