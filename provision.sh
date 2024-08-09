#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.
set -u  # Treat unset variables as an error when substituting.
set -v  # Print shell input lines as they are read.
set -x  # Print commands and their arguments as they are executed.

# изменим пароль root на случайный и заблокируем учётную запись:
yes "$(openssl rand -base64 30)" | sudo passwd root
sudo passwd --lock root

# включаем serial console в GRUB:
sudo sed 's|^\(GRUB_TERMINAL_OUTPUT=\).*|\1"console serial"|' \
  -i /etc/default/grub
echo 'GRUB_TERMINAL_INPUT="console serial"' \
  | sudo tee --append /etc/default/grub
echo 'GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200"' \
  | sudo tee --append /etc/default/grub

# включаем отображение меню GRUB:
sudo sed 's|^\(GRUB_TIMEOUT=\).*|\110|' -i /etc/default/grub
sudo sed 's|^\(GRUB_ENABLE_BLSCFG=\).*|\1false|' -i /etc/default/grub
sudo grub2-editenv - set menu_auto_hide=0

# обновляем конфигурацию GRUB:
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# переименовываем lvm volume group centos9s:
sudo lvmdevices --yes --deldev "/dev/sda2"
sudo lvmdevices --yes --adddev "/dev/sda2"
sudo sudo vgrename "centos9s" "centos9s-otus"
# обновляем конфигурацию systemd в /etc/fstab:
sudo sed 's|^/dev/mapper/centos9s-|/dev/mapper/centos9s--otus-|g' \
  -i /etc/fstab
sudo systemctl daemon-reload  # иначе система зависнет на перезагрузке
# обновляем конфигурацию grub:
# (grub2-mkconfig не работает после переименования vg)
sudo sed 's|=/dev/mapper/centos9s-|=/dev/mapper/centos9s--otus-|g' \
  -i /etc/default/grub /boot/grub2/grub.cfg
sudo sed 's|lv=centos9s/|lv=centos9s-otus/|g' \
  -i /etc/default/grub /boot/grub2/grub.cfg

# перезагружаем виртуальную машину:
sudo reboot
