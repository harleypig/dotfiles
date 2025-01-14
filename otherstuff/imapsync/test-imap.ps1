# IMAP Command Testing Script in PowerShell

# Suppress PSUseApprovedVerbs warnings for the entire file
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]

# Variables
$server = "imap.gmail.com"
$port = 993
$username = "alansyoungiii@gmail.com"
$password = ""

# IMAP command to list mailboxes. Will be used by List-Mailboxes.
#$listCommand = 'LIST "" "[Gmail]/*"'
$listCommand = 'LIST "" *'
#$listCommand = 'XLIST "" *'
#$listcommand = 'LIST (SPECIAL-USE) "" *'

# IMAP command to select and search. Will be used by Select-and-Search.
#$selectCommand = 'SELECT "[Gmail]/Sent Mail"'
#$selectCommand = 'SELECT "[Gmail]"'
$selectCommand = 'SELECT "Gmail"'
$searchCommand = 'SEARCH ALL'

# Variable to keep track of command tag
$global:commandTagCounter = 1

# Define global variables for writer and reader
$global:writer = $null
$global:reader = $null

# Function to establish connection and return the writer and reader objects
function Connect-To-IMAP {
    $client = New-Object System.Net.Sockets.TcpClient($server, $port)
    $client.ReceiveTimeout = 10000

    $sslStream = New-Object System.Net.Security.SslStream($client.GetStream(), $false,
        { param($sender, $cert, $chain, $errors) return $true })
    $sslStream.AuthenticateAsClient($server)

    $global:writer = New-Object System.IO.StreamWriter($sslStream)
    $global:reader = New-Object System.IO.StreamReader($sslStream)
    $global:reader.BaseStream.ReadTimeout = 10000
}

# Function to send an IMAP command and handle response
function Send-ImapCommand {
    param (
        [string]$command
    )

    # Generate command tag based on the counter and increment it
    $commandTag = "a$([string]::Format("{0:D3}", $global:commandTagCounter))"
    $global:commandTagCounter++

    Write-Output "Sending command to server: $commandTag $command"
    $global:writer.WriteLine("$commandTag $command")
    $global:writer.Flush()

    while ($null -ne ($response = $global:reader.ReadLine())) {
        Write-Output "Server Response: $response"
        if ($response -match "^$commandTag OK") {
            break
        }
    }
}

# Function to login to IMAP server
function Login-IMAP {
    Send-ImapCommand  -command ("LOGIN ""$username"" ""$password""")
}

# Function to gracefully logout from IMAP server
function Logout-IMAP {
    Send-ImapCommand -command "LOGOUT"
}

# Function to get IMAP namespaces
function Get-Namespaces {
    Send-ImapCommand -command "NAMESPACE"
}

# Function to send LIST command
function List-Mailboxes {
    Send-ImapCommand -command $listCommand
}

# Function to send SELECT and SEARCH commands
function Select-And-Search {
    Send-ImapCommand -command $selectCommand
    Send-ImapCommand -command $searchCommand
}

# Call Connect-To-IMAP to get writer and reader
Connect-To-IMAP

try {
    Login-IMAP
    #Get-Namespaces
    List-Mailboxes
    #Select-And-Search
} catch {
    Write-Output "An error occurred: $_"
} finally {
    # Gracefully logout
    if ($null -ne $global:writer -and $null -ne $global:reader) {
        Logout-IMAP
    }
    
    # Forcefully Cleanup
    if ($null -ne $global:writer) { $global:writer.Close() }
    if ($null -ne $global:reader) { $global:reader.Close() }
}