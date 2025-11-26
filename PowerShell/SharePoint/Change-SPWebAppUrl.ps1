## Rename server
## First rename the server hostname itself
Rename-SPServer -Identity "oldhostname" -Name "newhostname"

## Continue with configure alternate access mapping that still point to the old hostname from central admin