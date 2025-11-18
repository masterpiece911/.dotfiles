# Optional chroot indicator (Starship also shows containers)
[[ -z "${debian_chroot:-}" && -r /etc/debian_chroot ]] && debian_chroot="$(</etc/debian_chroot)"
export debian_chroot
