# How to usage
# `Copy-SSHID user@1.1.1.1`
# Or
# `Copy-SSHID user@1.1.1.1 .\.ssh\other_id_rsa.pub`
$keyPath = $args[2]
if (!$keyPath) { $keyPath = "$env:USERPROFILE\.ssh\id_rsa.pub" }
Write-Output "Will copy '$keyPath'"
Get-Content $keyPath | ssh $args[0] "mkdir -p .ssh; chmod 700 .ssh; cat >> .ssh/authorized_keys"
