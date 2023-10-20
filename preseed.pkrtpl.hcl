#_preseed_V1
d-i debian-installer/locale string en_US
d-i keyboard-configuration/xkb-keymap select us
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string unassigned-hostname
d-i netcfg/get_domain string unassigned-domain
d-i netcfg/wireless_wep string
d-i mirror/country string manual
d-i mirror/http/hostname string http.us.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string
d-i passwd/root-login boolean false
d-i passwd/user-fullname string Red Hat Ansible
d-i passwd/username string ansible
d-i passwd/user-password-crypted password ${password}
d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern
d-i clock-setup/ntp boolean true
d-i partman-auto/disk string /dev/vda
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/choose_label select gpt
d-i partman-partitioning/default_label string gpt
d-i partman-md/confirm boolean true
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
d-i apt-setup/cdrom/set-first boolean false
d-i apt-setup/services-select multiselect security, updates
d-i apt-setup/security_host string security.debian.org
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string \
    python3\
    sudo

popularity-contest popularity-contest/participate boolean true
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string default
d-i finish-install/reboot_in_progress note
d-i preseed/early_command string \
    printf "%s\n" "$(debconf-get preseed/url)" > "/var/run/preseed.last_location";

d-i preseed/late_command string \
    preseed_fetch /late_commands /target/tmp/late_commands; \
    preseed_fetch /authorized_keys /target/tmp/authorized_keys; \
    in-target /bin/sh /tmp/late_commands;
