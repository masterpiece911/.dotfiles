if [[ -r "$HOME/certs/franka-ca.crt" ]]; then
  export NODE_EXTRA_CA_CERTS="$HOME/certs/franka-ca.crt"
fi
