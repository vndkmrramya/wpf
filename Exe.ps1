# .NET Framework classes
Add-Type -AssemblyName PresentationFramework

#Import functions
. "$PSScriptRoot\Connect-VIServerCMDLet.ps1"

#Create Synchronized Hashtable for sharing variables between threads
$syncHash = [hashtable]::Synchronized(@{})

# Get XAML
[xml]$xaml = Get-Content "$PSScriptRoot\UI.xaml" -ErrorAction Stop

#Load XAML content in to XAML reader
$syncHash.Window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml -ErrorAction Stop))

#Make Connect-VIServerCMDLet function available to Runspace
$Connect_VIServerCMDLetDefinition = Get-Content Function:\Connect-VMWare -ErrorAction Stop
$Connect_VIServerCMDLetSessionStateFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList 'Connect-VIServerCMDLet', $Connect-VIServerCMDLetDefinition


#Create a SessionStateFunction
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$InitialSessionState.Commands.Add($Connect_VIServerCMDLetSessionStateFunction)

#Create variables for the elements in the UI (Buttons and Text boxes)
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | Where-Object { ($_.TargetName -ne "Border") -and ($_.Name -ne "Border") -and ($_.Name -ne "ContentSite") } | ForEach-Object {
    $syncHash.Add($_.Name,$syncHash.Window.FindName($_.Name))
}


$SyncHash.btnConnect.Add_Click({
        #Check if Remedy credentails are entered
        if (($syncHash.txtServer.Text.Length -eq 0) -or ($syncHash.txtUser.Length -eq 0) -or ($syncHash.txtPassword.Length -eq 0)) {
         [System.Windows.MessageBox]::Show("Please enter server, user name and password","Inputs Required",[System.Windows.MessageBoxButton]::Ok,[System.Windows.MessageBoxImage]::Information)
         return
        }        
        $SyncHash.btnConnect.IsEnabled = $false
        $syncHash.Host = $host
        $Runspace = [runspacefactory]::CreateRunspace($InitialSessionState)
        $Runspace.ApartmentState = "STA"
        $Runspace.ThreadOptions = "ReuseThread"
        $Runspace.Open()
        $Runspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
        $Runspace.SessionStateProxy.SetVariable("server",$SyncHash.txtServer.Text)
        $Runspace.SessionStateProxy.SetVariable("user",$SyncHash.txtUser.Text)
        $Runspace.SessionStateProxy.SetVariable("password",$SyncHash.txtPassword.Text)
        #Wait-Debugger
        $code1 = {
            #Wait-Debugger
            Connect-VMWare -syncHash $syncHash -server $server -user $user -password $password
            $SyncHash.Window.Dispatcher.invoke( [action]{ $syncHash.btnConnect.IsEnabled = $true } )           
        }
        $PSinstance = [powershell]::Create().AddScript($Code1)
        $PSinstance.Runspace = $Runspace
        $job = $PSinstance.BeginInvoke()
})


$syncHash.Window.ShowDialog() | Out-Null