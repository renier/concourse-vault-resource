# Vault resource for concourse

Used app roles for authentication.

* approle_id (required)
* path (required) - paths to secrets to retrieve
* host - vault host name. defaults to gateway ip on the container network.
* port - vault port. defaults to 8200.
* insecure - whether to use curl with -k
* scheme - https (default) or http 
