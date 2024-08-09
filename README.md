# Работа с загрузчиком

## Задание

1. Включить отображение меню **GRUB**.
2. Попасть в систему без пароля несколькими способами.
3. Установить систему с **LVM**, после чего переименовать **VG**.

## Реализация

Задание сделано на **generic/centos9s** версии **v4.3.12**. После загрузки запускается скрипт **[provision.sh](https://github.com/abegorov/linux11/blob/main/provision.sh)**, который выполняет настройку. Помимо **SSH** на машине настраивается доступ, через порт **COM1**, чтобы можно было из консоли подключиться к загрузчику **GRUB** через утилиту **screen** и написанный скрипт **[serial_socket.sh](https://github.com/abegorov/linux11/blob/main/serial_socket.sh)**.

**[Vagrantfile](https://github.com/abegorov/linux11/blob/main/Vagrantfile)**:

1. Получает директорию в которой находится **Vagrantfile** и записывает её в переменную **current_dir**.
2. С помощью **vb.customize** в виртуальную машине настравивается последовательный порт **COM1** в режиме **Host Pipe**, отображаемым в файл **serial_socket** в директории **current_dir**.

Скрипт **[provision.sh](https://github.com/abegorov/linux11/blob/main/provision.sh)**:

1. Изменяет пароль **root** на случайный и отключает учётную запись **root**.
2. Настраивает поддержку **serial console** в **GRUB** (она будет использоваться, для подключения к загрузчику через скрипт **[serial_socket.sh](https://github.com/abegorov/linux11/blob/main/serial_socket.sh)**). При этом он не настраивает **serial console** в ядре, чтобы не блокировать его загрузку при отсутствии консоли (будем добавлять нужные настройки при необходимости в настройках **GRUB**).
3. Включает отображение меню **GRUB**.
4. Переименовывает **LVM Volume Group** **centos9s** в **centos9s-otus**.
5. Перезагружает виртуальную машину.

## Способы попасть в систему

Для того, чтобы попасть в систему через последовательную консоль запустим скрипт **[serial_socket.sh](https://github.com/abegorov/linux11/blob/main/serial_socket.sh)** и перезагрузим сервер.

Отобразится меню загрузчика:

```text
                               GRUB version 2.06

 +----------------------------------------------------------------------------+
 |*CentOS Stream (5.14.0-391.el9.x86_64) 9                                    |
 | CentOS Stream (0-rescue-8da7499831c644a88a0bff47c0d1447f) 9                |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 +----------------------------------------------------------------------------+

      Use the ^ and v keys to select which entry is highlighted.
      Press enter to boot the selected OS, `e' to edit the commands
      before booting or `c' for a command-line.
```

Нажмём клавишу **e**, и добавим параметры **rd.break console=ttyS0,115200** в параметры загрузки ядра, начинающиеся со слова **linux** (параметр **console** позволяет включить поддержку последовательной консоли в ядре):

```text
                               GRUB version 2.06

 +----------------------------------------------------------------------------+
 |        else                                                                |^
 |          search --no-floppy --fs-uuid --set=root 81ffcd12-5bfa-4eae-942f-b\|
 |daca4747f65                                                                 |
 |        fi                                                                  |
 |        echo        'Loading Linux 5.14.0-391.el9.x86_64 ...'               |
 |        linux        /vmlinuz-5.14.0-391.el9.x86_64 root=/dev/mapper/centos\|
 |9s--otus-root ro biosdevname=0 no_timer_check vga=792 nomodeset text crashk\|
 |ernel=1G-4G:192M,4G-64G:256M,64G-:512M resume=/dev/mapper/centos9s--otus-sw\|
 |ap rd.lvm.lv=centos9s-otus/root rd.lvm.lv=centos9s-otus/swap net.ifnames=0 \|
 |rd.break console=ttyS0,115200                                               |
 |        echo        'Loading initial ramdisk ...'                           |
 |        initrd        /initramfs-5.14.0-391.el9.x86_64.img                  |v
 +----------------------------------------------------------------------------+

      Minimum Emacs-like screen editing is supported. TAB lists
      completions. Press Ctrl-x or F10 to boot, Ctrl-c or F2 for
      a command-line or ESC to discard edits and return to the GRUB menu.
```

Нажмём **Ctrl+x** для загрузки системы с новыми параметрами. Мы попали в **emergency** режим:

```text
         Starting Dracut Emergency Shell...

Generating "/run/initramfs/rdsosreport.txt"


Entering emergency mode. Exit the shell to continue.
Type "journalctl" to view system logs.
You might want to save "/run/initramfs/rdsosreport.txt" to a USB stick or /boot
after mounting them and attach it to a bug report.


switch_root:/#
```

Корневая файловая система смонтирована в **RO** режиме в **/sysroot**, перемонтируем её в **RW** режиме и сделаем **chroot**:

```shell
switch_root:/# mount | grep root
none on / type rootfs (rw)
/dev/mapper/centos9s--otus-root on /sysroot type xfs (ro,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota)
switch_root:/# mount -o remount,rw /sysroot
switch_root:/# chroot /sysroot /bin/bash
sh-5.1#
```

Поменяем пароль пользователя **root** на любой другой и разблокируем его. При этом важно не забыть восстановить **security context** файла **/etc/shadow** (в противном случае **SELinux** заблокирует чтение файла и систему нельзя будет войти ни по паролю, ни по **SSH**):

```shell
sh-5.1# passwd root
Changing password for user root.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
sh-5.1# chcon system_u:object_r:shadow_t:s0 /etc/shadow
```

Теперь можно перезагрузить виртуальную машину и зайти в неё под пользователем **root**:

```shell
sh-5.1# exit
exit
switch_root:/# reboot
```

Альтернативно вместо **rd.break console=ttyS0,115200** можно указать **init=/bin/bash console=ttyS0,115200**. В этом случае корневая файловая система окажется уже примонтированной в **/** (также в режиме **ro**), но команда **/sbin/reboot** не будет работать. Для перезагрузки необходимо выполнять **/sbin/reboot -f**.

Если указать **single console=ttyS0,115200**, то корневая файловая система будет примонтирована в режиме **rw**, но система спросит пароль **root** для входа в систему.

Также с помощью опции **CentOS Stream (0-rescue-8da7499831c644a88a0bff47c0d1447f) 9** в загрузочном меню можно запустить **rescue** ядро и **rescue initramfs**.

## Запуск

Необходимо скачать **VagrantBox** для **generic/centos9s** версии **v4.3.12** и добавить его в **Vagrant** под именем **generic/centos9s**. Сделать это можно командами:

```shell
curl -OL https://app.vagrantup.com/generic/boxes/centos9s/versions/4.3.12/providers/virtualbox/amd64/vagrant.box
vagrant box add vagrant.box --name "generic/centos9s"
```

После этого достаточно сделать **vagrant up**, при запуске будет автоматически запущен скрипт **[provision.sh](https://github.com/abegorov/linux11/blob/main/provision.sh)**, который сделает все указанные выше настройки. Протестировано в **Vagrant 2.3.7** в текущей версии **OpenSUSE Tumbleweed**.
