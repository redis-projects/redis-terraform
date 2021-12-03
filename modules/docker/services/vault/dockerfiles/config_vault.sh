apk add openssl jq curl

export VAULT_ADDR=http://127.0.0.1:8200

export VAULT_TOKEN=$1

## https://learn.hashicorp.com/tutorials/vault/pki-engine

vault secrets enable pki

vault secrets tune -max-lease-ttl=87600h pki

vault write -field=certificate pki/root/generate/internal \
	     common_name="redislabs.local" \
	          ttl=87600h > CA_cert.crt

# see the cert text format
#openssl x509 -in CA_cert.crt -text -noout


##Generate intermediate CA

vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int

#execute the following command to generate an intermediate and save the CSR as pki_intermediate.csr.

vault write -format=json pki_int/intermediate/generate/internal \
	     common_name="redislabs.local Intermediate Authority" \
	          | jq -r '.data.csr' > pki_intermediate.csr

# Sign the intermediate certificate with the root CA private key, and 
# save the generated certificate as intermediate.cert.pem.

vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate.csr \
	     format=pem_bundle ttl="43800h" \
	          | jq -r '.data.certificate' > intermediate.cert.pem

vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem


## Create a role

vault write pki_int/roles/redislabs-dot-com \
	     allowed_domains="redislabs.local" \
	          allow_subdomains=true \
		       max_ttl="720h"


vault write pki_int/issue/redislabs-dot-com common_name="north.redislabs.local" ttl="24h"