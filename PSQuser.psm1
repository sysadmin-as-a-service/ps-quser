function Get-LoggedOnUsers {
    param(
        [string[]]$servers = "localhost"
    )
 
    if($null -eq $server){
        $server = $env:computername
    }
     
    $users = @()

    foreach($server in $servers){
        # Query using quser, 2>$null to hide "No users exists...", then skip to the next server
        $quser = quser /server:$server 2>$null
        if(!($quser)){
            Continue
        }
        
        #Remove column headers
        $quser = $quser[1..$($quser.Count)]
        foreach($user in $quser){
            $usersObj = [PSCustomObject]@{Server=$null;Username=$null;SessionName=$null;SessionId=$Null;SessionState=$null;LogonTime=$null;IdleTime=$null}
            $quserData = $user -split "\s+"
        
            #We have to splice the array if the session is disconnected (as the SESSIONNAME column quserData[2] is empty)
            if($null -ne ($user | select-string "Disc")){
                #User is disconnected
                $quserData = ($quserData[0..1],"null",$quserData[2..($quserData.Length -1)]) -split "\s+"
            }
        
            # Server
            $usersObj.Server = $server
            # Username
            $usersObj.Username = $quserData[1]
            # SessionName
            $usersObj.SessionName = $quserData[2]
            # SessionID
            $usersObj.SessionID = $quserData[3]
            # SessionState
            $usersObj.SessionState = $quserData[4]
            # IdleTime
            $quserData[5] = $quserData[5] -replace "\.","0:0" -replace "Disc","0:0" -replace "\+","."
            if($quserData[5] -like "*:*"){
                $usersObj.IdleTime = [timespan]"$($quserData[5])"
            }elseif($quserData[5] -eq "." -or $quserData[5] -eq "none"){
                $usersObj.idleTime = [timespan]"0:0"
            }else{
                $usersObj.IdleTime = [timespan]"0:$($quserData[5])"
            }
            # LogonTime
            $usersObj.LogonTime = (Get-Date "$($quserData[6]) $($quserData[7]) $($quserData[8] )")
            
            $users += $usersObj
        
        }
    }
     
    return $users
     
    }

    function Remove-LoggedOnUsers ($server,$sessionID){
        if($null -eq $server){
            $server = $env:computername
        }
        if($null -eq $sessionID){
            Throw "You must enter a Session ID"
        }
        $rwinsta = Start-Process rwinsta.exe -ArgumentList "$($sessionID) /server:$($server)" -NoNewWindow
    }

    Export-ModuleMember Get-LoggedOnUsers
    Export-ModuleMember Remove-LoggedOnUsers
