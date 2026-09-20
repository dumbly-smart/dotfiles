if [[ -n "${SSH_CONNECTION:-}" ]]; then
    remote_ip="${SSH_CONNECTION%% *}"
    if [[ "$remote_ip" != "100.109.204.93" ]]; then
        print -u2 "Remote login rejected."
        exit 1
    fi
fi
