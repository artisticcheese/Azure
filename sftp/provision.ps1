foreach ($user in (Get-Content $env:configLocation\users.json | convertfrom-JSON).users) { 
   net user /add $user.username $user.password ; 
   write-output "$env:sftpLocation\$($user.username)"; 
   (Test-Path "$env:sftpLocation\$($user.username)") ? "Folder already exists" : (New-Item -ItemType Directory -path "$env:sftpLocation\$($user.username)")
} 