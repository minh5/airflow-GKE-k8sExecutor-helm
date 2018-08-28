#! /usr/bin/env bash
set -Eeuxo pipefail

kubectl --namespace kube-system create serviceaccount tiller || true
kubectl create clusterrolebinding tiller \
                --clusterrole cluster-admin \
                --serviceaccount=kube-system:tiller || true
helm init --upgrade --wait --service-account tiller || true

AIRFLOW_NAMESPACE=default

AIRFLOW_DATABASE_USER=airflow
POSTGRES_ADMIN_PASSWORD=airflow
AIRFLOW_DATABASE_NAME=airflow
POSTGRES_SERVICE=airflow-postgres-postgresql
POSTGRES_PORT=5432
AIRFLOW_DATABASE_USER_PASSWORD=airflow

KUBECONFIG_FILE_OUTPUT=/tmp/kubeconfig

helm upgrade \
    --install \
    airflow-postgres \
    stable/postgresql \
    --version 0.15.0 \
    --namespace $AIRFLOW_NAMESPACE \
    --set postgresPassword=$POSTGRES_ADMIN_PASSWORD \
    --set postgresUser=$AIRFLOW_DATABASE_USER \
    --set postgresDatabase=$AIRFLOW_DATABASE_USER_PASSWORD

SQL_ALCHEMY_CONN=postgresql+psycopg2://$AIRFLOW_DATABASE_USER:$AIRFLOW_DATABASE_USER_PASSWORD@$POSTGRES_SERVICE:$POSTGRES_PORT/$AIRFLOW_DATABASE_NAME

FERNET_KEY=tpiIe17JmQ8slUcYBlHDLFEkgXkSAkLOP3wAdl+5s+4=

cat <<EOF > /tmp/kubeconfig
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://localhost:6443
  name: docker-for-desktop-cluster
current-context: docker-for-desktop
kind: Config
preferences: {}
users:
- name: docker-for-desktop
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM5RENDQWR5Z0F3SUJBZ0lJRlRxQytBTW9tUVF3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB4T0RBNE1EUXdPVEE1TlRWYUZ3MHhPVEE0TVRReE5ESTRNalphTURZeApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sc3dHUVlEVlFRREV4SmtiMk5yWlhJdFptOXlMV1JsCmMydDBiM0F3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRREhPNi9Rb1pXQlAzTVYKN1ZlZ0NKZSsyK1NqRTJJR3VCbnpBU3RLcmVCSEIxUjcvcm1NbCsyVDU4RmNFVkgxUmUrVXNwYXhpdVZFR2ptOApYS2VrWWtYNmpOZXpPcm1CSkZWcy9xZ2NLOXdTNi92Z0MvSmFTU2tiSnUxRnZPQlZtZVcxWjhkajRwL0FLNTg5ClVvRzlhZ0RHQTUyWVJsUVpaNSt5Y2NienRtNmY1Vy9PZUpGb0h3UGRsUWVqNmRxRll2a1RSMVlEQ2dNTks4WXQKUUU2NzMyMis2ZXREUTNEOHJxSlJlTjl6MGdjS1RKWkNZbC94Mk1MTDNyeHp3amdHRkp2ejJxci9CRGtNK0MyRgo5b1dOZ0pqd01FZWR2UCtYbjNzdngxZG8vZkM2ak90dmQrMkNQU0g4eDVCc3A2MzNkY0lxUExGc2xta1NWaitmCmsvb3RIU1Q3QWdNQkFBR2pKekFsTUE0R0ExVWREd0VCL3dRRUF3SUZvREFUQmdOVkhTVUVEREFLQmdnckJnRUYKQlFjREFqQU5CZ2txaGtpRzl3MEJBUXNGQUFPQ0FRRUFKYlk1SFhnWlNQODRaOVhrNGpudWdiWWZuOEk5VUFOKwpsODUxdDV2ZFNLVWdXbjZWcitoa3A5cW1lRVJQYkUwaXJrZHZ3TjJuOHRod0tVTlAzYkI3Qy90TXJyWTFWQVhrCnB4MUZhQzdCT094Z2RxblJpOUE3SWxjdkl5cS83eVpoSWFNNUE1ZitldVQrOXlzdnk0Z3Z6OG4veVN0WnA1QUEKZzA5bks0dGRzVjBOaktlMmorWkFLSzNEd3RQa1dNS2UxcGF0RHo2cFBTUllveXpPMVpLcnU4NlZEeFgxbWxXNApOYWk4ZWNGV2hwVUZzK1JlL2REejljTDNkUDYwNUlzTEhzQlgyam1jYk9PczFsVFJmWlNlbDQxdk1rcE5EVVhqCkhmY3lGZGgrSGprbG5LcjNIaTJCb2taM3ArM1ZaejRNVWJPWURFYTd6YmJzRE40QUF4eUdXZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBeHp1djBLR1ZnVDl6RmUxWG9BaVh2dHZrb3hOaUJyZ1o4d0VyU3EzZ1J3ZFVlLzY1CmpKZnRrK2ZCWEJGUjlVWHZsTEtXc1lybFJCbzV2RnlucEdKRitvelhzenE1Z1NSVmJQNm9IQ3ZjRXV2NzRBdnkKV2trcEd5YnRSYnpnVlpubHRXZkhZK0tmd0N1ZlBWS0J2V29BeGdPZG1FWlVHV2Vmc25IRzg3WnVuK1Z2em5pUgphQjhEM1pVSG8rbmFoV0w1RTBkV0F3b0REU3ZHTFVCT3U5OXR2dW5yUTBOdy9LNmlVWGpmYzlJSENreVdRbUpmCjhkakN5OTY4YzhJNEJoU2I4OXFxL3dRNURQZ3RoZmFGallDWThEQkhuYnovbDU5N0w4ZFhhUDN3dW96cmIzZnQKZ2owaC9NZVFiS2V0OTNYQ0tqeXhiSlpwRWxZL241UDZMUjBrK3dJREFRQUJBb0lCQUVLTHV5UFNkTjlnMUEzawo0cm0vWlFBSTdvdFJ0QkpPZDh4ay9aTEtGUGxraDJHTEtXcStiRXBVeEk3OThnUWN3Zk5HMjNLZDFBbzFRRWVjCkl4cVRBSkM1Ym1xZEdNejcxOVM2RW1pbWRiR1VST01HMm9JeG9adENHMHFKMWR5QnRPb3NxYnJCUFY2d3MxV0cKTTNPUzdvTTFQZlJZdVVwckJEcFVLb0hJMDVad010cUp1UkpCMUl0TDMvWXNZUFpZcFRwRXdKWVZLd3d5QXppVgp4RG9HZ29BNzcxYjN0MUlTMTVOSTQxOWFzNEVRVUJrNUJDdW5URlJWUVplclArUmN4RkZMSlk2emxkZ2NIYlpXClprUXhyYTR1WWFsMVR2THByVWF6YlAzUlFGRkJmalpoR2JBWktYM2V1Y1lCT1dTSTM2M2h1QmE3dVJzZ3lWaDUKc3hVSjNWRUNnWUVBOUhrUDM2c2hqbWl0K0Q4QTIyU09kRnJOQmRRbXc4NW9ERzJSQ3FZV3N2a2ZNbEpObU5oNApHczVEN1VXQllWZytISXkzakZwdlJlOTdLWFJXVkpoSXppOXdYUVBlZ2dla3FqL0RkM2tpSkZ1TUJ4NHNuRHRMCkpIRU5JYWdEbWtjcnFsRjNLUytreU1UK2daRDhqenUySHBIc1pSWHliQVJrbzBLOWNRNWNQUDBDZ1lFQTBLQ04Kb1pPQ2QyNTlLUTFWME1MczJVTjduUEEweXl0dXFnWWZidS82VHozWWt2Z2c3TG9SbWVVMFFwR0NnUVgxRzRCZgpZT2R2TWV5NFJPT0g5ZzAyWWZDc3ZxYWdoeGxUS2YyU3ZDOTBjWEt6MU5CcEtLeGlqcnhKWWJ3NkdLd3lGV2RFCmVxMk1NTS9XMExuL3dEM3VzbEpXdXc5VDRYZlVnaXpDa09aM2gxY0NnWUJQWlZIR2JpbUR1bk5sZi9DalQ5RUQKOE1sTTcwMTNvZjBnckNUQ3RKWUNvZTJEeGo3MU9MZ28zSHdxL3J1NkJaS0dheHpoTkMyWEpPTjIzeFY2ZThxSgpTOWJPSG9lUTZ6S0xLQkl2SnVQenN0ZVRLRFdNdDZUN3ZNdHE5c25VdlBCdGErK3JMSkh6c2lhRnBiU2dQK0F4CnBXcUVtZEFWVElmeWphWkFwVTFIY1FLQmdDdDFob3RtQXdPR0RLU0VscC9LT3pSM0RrVCs5TUJ0NTd1YlV1ajEKTEp0ZE1zUkswL0Q4UWJaaFBLV3hVaEkyZjN5ZkhUOCtkcmRickhjTlBzRk90MGxuclZSNXVXN3JJNXZYcXIxdwoxVHpjdkFGVStOTDBOZ090elV1Q3ZrZHRkM0ZsOWFub2hRK1YvQlcyNlVQT291NmFvRjZQTHRZRTlFdTVyejRvCkJEWTVBb0dCQU9FRy9CQytDNGQ3NFRsbmphTzVRc0luMWhTUDVOVUE5S2kvMlpDN3U1OFpqUm9uU3BUY3lUcjkKKzVabDNwaTlIT3p4RzQvMUY5b3Nwd1JURGhuV1FVakUvcVJHQkdDVXg4TzBkYWtZQW5XeGhOb0RVTCswNENJNwpnYkN3WmdPNVl4d2djNlRuOVdTT0RDeFJ0am5US2xaNDdsa1RkMXRnLzVHbGp5YWIyTVZ6Ci0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
EOF

kubectl create secret generic airflow \
    --namespace=$AIRFLOW_NAMESPACE \
    --from-literal=fernet-key=$FERNET_KEY \
    --from-literal=sql_alchemy_conn=$SQL_ALCHEMY_CONN \
    --from-file=kubeconfig=$KUBECONFIG_FILE_OUTPUT || true

# Label the docker node the same as the workers will have in your dags in staging/production

kubectl label node  \
        docker-for-desktop \
        airflow=airflow_workers \
        pool=preemptible \
        --overwrite