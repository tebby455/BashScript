#Global Variables
#auto gen password sql & create shortcut
$DesktopPath = [Environment]::GetFolderPath("Desktop")


function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}
 
function Scramble-String([string]$inputString){     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}

function Create-Password(){
    $password = Get-RandomCharacters -length 7 -characters 'abcdefghiklmnoprstuvwxyz'
    $password += Get-RandomCharacters -length 5 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $password += Get-RandomCharacters -length 5 -characters '1234567890'
    $password += Get-RandomCharacters -length 3 -characters '$%=?}][{@#*+'

    $password = Scramble-String $password
    return $password
}

function Change-SAPass([string]$newPassword) {
    $hostname = [System.Net.Dns]::GetHostName()
	$command = "exit(ALTER LOGIN [sa] WITH PASSWORD=N'$newPassword')"
	sqlcmd -S $hostname -q $command
}

function Create-DesktopFile([string]$newPassword) {
	New-Item -Path $DesktopPath -Name "sql.txt" -ItemType "file" -Value "$newPassword"
}

function Create-Symlink() {
    $SourceFileLocation = "C:\Program Files (x86)\Microsoft SQL Server\100\Tools\Binn\VSShell\Common7\IDE\Ssms.exe"
    $ShortcutLocation = $DesktopPath + "\SQL Server Management Studio.lnk"

    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
    $Shortcut.TargetPath = $SourceFileLocation

    #Save the Shortcut to the TargetPath
    $Shortcut.Save()
}

function main() {
	$passSA = Create-Password
	Change-SAPass $passSA
	Create-Symlink
	Create-DesktopFile $passSA
}

main
