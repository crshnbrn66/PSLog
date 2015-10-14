
  <#
  .Synopsis
     Gathers information for the currently logged in user.
  .DESCRIPTION
     This script gathers information from the currently logged in user and logs it to the log passed to it.
  .EXAMPLE
     Write-user -filename 'c:\temp\mylog'

  .INPUTS
     Filename - this the name of the file to log the information to.
  .OUTPUTS
     returns a true if the logging happened. 
     If it returns false then the logging did not happen.
  .NOTES
     
  .COMPONENT
     The component this cmdlet belongs to
  .ROLE
     The role this cmdlet belongs to
  .FUNCTIONALITY
     The functionality that best describes this cmdlet
  #>
  function Write-User
  {
  param(
    [parameter(mandatory)]
     [string]$fileName
     )
    
      write-log -fileName $fileName "Username: $env:UserName"
      write-log -fileName $fileName "Current Command: $($MyInvocation.MyCommand.Path)"
      write-log -fileName $fileName "Current Script: $($MyInvocation.MyCommand.ScriptName)"
      write-log -fileName $fileName "Script Running on: $env:COMPUTERNAME"
      write-log -fileName $fileName "Current Version of Powershell: $($psversiontable.psversion)"

  }
    <#
  .Synopsis
     Writes a message to a log file. 
  .DESCRIPTION
     for the parameter message if it detects that the message type is of type [datetime] it will write a message to the file in this format: 
     "------------------ DateTime -------------`n"
     If the switch -writetoScreen is passed the function will write to the screen via Write-debug and to the logfile passed for any message.
     the default for writetoscreen is that it is turned off.
  .EXAMPLE
     Write-log -filename c:\temp\test.log -message '----Beginning file move----'
  .EXAMPLE
     write-log -filename c:\temp\test.log -message $date
  .EXAMPLE
     write-log -filename c:\temp\test.log -message 'this is a test message' -writetoscreen
  .INPUTS
     -filename = this is the file name that the function will write the file to. 
     -message = this is either a string message or a [datetime] 
     -writetoscreen = this is a swtich for the fucntion to write to screen and to the log file.
  .OUTPUTS
     Output from this cmdlet (if any)
  .NOTES
     General notes
  .COMPONENT
     The component this cmdlet belongs to
  .ROLE
     The role this cmdlet belongs to
  .FUNCTIONALITY
     The functionality that best describes this cmdlet
  #>

function Write-Log
{ 
   [CmdletBinding()]
    param(
     [parameter(mandatory)]
     [string]$fileName,
     [parameter(mandatory)]
     [string]$message,
     [switch]$writetoScreen
     )
     $func = 'func Write-Log:'
    try
    {
      if((test-path $fileName) -eq $false )
      {
           new-item -Path $filename -itemtype file -Force
      }
      if($message -is [datetime])
      {
        "------------------$message-------------`n" | out-file -FilePath $fileName -Append
        if($writetoScreen)
        {Write-verbose "------------------$message-------------`n" -Debug }
        
      }
      else
      {
        "$message" | out-file -FilePath $fileName -Append
        #Write-Debug "$message" -Debug #$writetoScreen.IsPresent
        if($writetoScreen)
        {Write-verbose "$message" -verbose }
      }
    }
    catch
    {
      "Error was $_"
      $line = $_.InvocationInfo.ScriptLineNumber
      "Error was in Line $line"
    
    }
    
}
  <#
  .Synopsis
     Based on filename ensures only x files exist of y size.
  .DESCRIPTION
     The purpose of this script is to only keep the number of log files with the .number extension based on the value passed for log count.  In addition it will ensure that the file size does not exceed the value specified by the Logsize parameter.
     -filename = logfile that this function will write to.
     -filesize = filesize limit. this will be checked by powershell to ensure that the file doesn't exceed this amount if it does exceed the amount then this script will roll the current log file to: 
     logfilename.1 
     if Logfilename.1 exists then logfilename.1 will change to logfilename.2 and the most recent file will be numbered logfilename.1.  
     This .1 or .x extension will not exceed the number specified by the logcount
     When this utility rolls a log from its name to .1 if reset-log is called again on the same log file it will not roll the log if the file doesn't exist. 

  .EXAMPLE
     Reset-Log -fileName c:\temp\test.log -filesize 1mb -logcount 5
     This will roll the log file c:\temp\test.log if the log file is greater that 1megabyte (1mb) bytes.
  .EXAMPLE
     Reset-Log -fileName c:\temp\test.log -filesize 1tb -logcount 20
     This will roll the log file c:\temp\test.log if the log file is greater that 1terabyte (1tb) bytes.
  .EXAMPLE
    Reset-Log -fileName c:\temp\test.log -filesize 1kb -logcount 20
    This will roll the log file c:\temp\test.log if the log file is greater that 1kiloByte (1kb) bytes.
  .EXAMPLE
    Reset-Log -fileName c:\temp\test.log -filesize 150 -logcount 5 
    This will roll the log file c:\temp\test.log if the log file is greater that 150 bytes.
  .INPUTS
     -filename = logfile that this function will write to.
     -filesize = filesize limit. this will be checked by powershell to ensure that the file doesn't exceed this amount if it does exceed the amount then this script will roll the current log file to: 
     logfilename.1 
     if Logfilename.1 exists then logfilename.1 will change to logfilename.2 and the most recent file will be numbered logfilename.1.  
     This .1 or .x extension will not exceed the number specified by the logcount
  .OUTPUTS
     [boolean] this indicates whether the function rolled to a new log number.
  .FUNCTIONALITY
     Log Rolling utility - function
  #>
function Reset-Log
{
    #function checks to see if file in question is larger than the paramater specified if it is it will roll a log and delete the oldes log if there are more than x logs.
     [CmdletBinding()]
    param(
    [parameter(mandatory)]
    [string]$fileName, 
    [ValidateNotNullOrEmpty()]
    [int64]$filesize = 1mb, 
    [ValidateNotNullOrEmpty()]
    [int] $logcount = 5)
    $func = 'func Reset-Log:'
    $logRollStatus = $true
    if(test-path $filename)
    {
        $file = Get-ChildItem $filename
        if((($file).length) -ige $filesize) #this starts the log roll
        {
            $fileDir = $file.Directory
            $fn = $file.name #this gets the name of the file we started with
            $files = Get-ChildItem $filedir | Where-Object{$_.name -like "$fn*"} | Sort-Object lastwritetime
            $filefullname = $file.fullname #this gets the fullname of the file we started with
            for ($i = ($files.count); $i -gt 0; $i--)
            { 
                $files = Get-ChildItem $filedir | Where-Object{$_.name -like "$fn*"} | Sort-Object lastwritetime
                $operatingFile = $files | Where-Object{($_.name).trim($fn) -eq $i}
                if ($operatingfile)
                 {$operatingFilenumber = ($files | Where-Object{($_.name).trim($fn) -eq $i}).name.trim($fn)}
                else
                {$operatingFilenumber = $null}

                if(($operatingFilenumber -eq $null) -and ($i -ne 1) -and ($i -lt $logcount))
                {
                    $operatingFilenumber = $i
                    $newfilename = "$filefullname.$operatingFilenumber"
                    $operatingFile = $files | Where-Object{($_.name).trim($fn) -eq ($i-1)}
                    write-debug "moving to $newfilename"
                    move-item ($operatingFile.FullName) -Destination $newfilename -Force
                }
                elseif($i -ge $logcount)
                {
                    if($operatingFilenumber -eq $null)
                    { 
                        $operatingFilenumber = $i - 1
                        $operatingFile = $files | Where-Object{($_.name).trim($fn) -eq $operatingFilenumber}
                       
                    }
                    write-debug "deleting  $($operatingFile.FullName)"
                    remove-item ($operatingFile.FullName) -Force
                }
                elseif($i -eq 1)
                {
                    $operatingFilenumber = 1
                    $newfilename = "$filefullname.$operatingFilenumber"
                    write-debug "moving to $newfilename"
                    move-item $filefullname -Destination $newfilename -Force
                }
                else
                {
                    $operatingFilenumber = $i +1 
                    $newfilename = "$filefullname.$operatingFilenumber"
                    $operatingFile = $files | Where-Object{($_.name).trim($fn) -eq ($i-1)}
                    write-debug "moving to $newfilename"
                    move-item ($operatingFile.FullName) -Destination $newfilename -Force   
                }
                    
            }

                    
          }
         else
         { $logRollStatus = $false}
    }
    else
    {
        $logrollStatus = $false
    }
    $logRollStatus
}

Export-ModuleMember -Function Write-User, Write-Log, Reset-Log  -Alias wuser, wlog, rlog
