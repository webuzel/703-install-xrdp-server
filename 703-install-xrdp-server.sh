#!/bin/bash

# ПЕРЕМЕННЫЕ (можно/нужно менять по необходимости).

# Назначение скрипта:
script_purpose="УСТАНОВКА XRDP"
# Имя файла с Ansible-плейбуком (должен находиться в одной папке с этим скриптом):
yaml_filename="703-deploy-xrdp-server.yaml"

# Вспомогательные переменные.
# Для форматирования вывода в консоль (для текста: 'полужирный' и 'нормальный'):
bold=$(tput bold)
normal=$(tput sgr0)
undeln=$(tput smul)
nounderln=$(tput rmul)
blink=$(tput blink)
# setaf <value>	Set foreground color
# setab <value>	Set background color
# Value	Color
# 0	Black
# 1	Red
# 2	Green
# 3	Yellow
# 4	Blue
# 5	Magenta
# 6	Cyan
# 7	White
# 8	Not used
# 9	Reset to default color


script_name=$0

# Функция, которая показывает как запускать скрипт:
showhelp(){
  printf "Как запускать:\n \
  $script_name target_ip_address [admin_username]\n \
  где, \n \
    ${bold}$script_name${normal} -- актуальное имя файла, содержащее этот скрипт;\n \
    ${bold}target_ip_address${normal} -- IP-адрес удалённого компьютера, к которому применяется этот скрипт;\n \
    ${bold}admin_username${normal}    -- необязательный параметр, указывающий от имени какого пользователя\n \
        запускать скрипт на удалённом компьютере.\n \
        (ВАЖНО: Этот пользователь должен обладать там административными полномочиями)\n \
        (ВАЖНО: В процессе выполнения скрипта будет предложено ввести пароль этого пользователя)\n"
}

# Функция, которая показывает какие параметры будут использованы при запуске плейбука:
showruncondition(){
  printf "\nДля запуска плейбука $yaml_filename будут использованы следующие параметры:\n \
  IP-адрес целевого компьютера: ${bold}$desktop_ip${normal}\n \
  Назначение скрипта: ${bold}$script_purpose${normal}\n"
  # Если в функцию был передан параметр, то распечатать его как имя пользователя с административными полномочиями
  if [[ -n $1 ]]; then
    printf "  Уч.запись администратора: ${bold}$admin_username${normal}\n"
  fi
}

# Функция вывода строки текста "в цвете" (плюс перевод строки)
IRed='\e[0;91m'         # Красный
IGreen='\e[0;92m'       # Зелёный
ICyan='\e[0;96m'        # Синий
Color_Off='\e[0m'       # Цвет по-умолчанию
printf_color() {
	printf "%b%s%b\n" "$1" "$2" "$Color_Off"
}
# Пример:
# printf_color "$IRed" "Текст красным..."


# Отладочная информация:
printf "Скрипт ${bold}$0${normal} запущен с параметрами:\n $1\n $2\n $3\n"

# Если в командной строке указан первый параметр, то принять его как IP-адрес удалённого компьютера: 
if [[ -n $1 ]]; then 
  desktop_ip=$1
# Если параметр не указан, то вывести сообщение и завершить работу скрипта:
else
  showhelp
  exit 1
fi

# Для работы Ansible понадобится:
# pip install 
#  wheel
#  PyMySQL

# ansible-galaxy collection install community.general
# ansible-galaxy collection install community.mysql


# Если в командной строке был указан второй параметр, то принять его как имя администратора на удалённой машине,
# дополнительно запросить пароль и запустить Ansible плейбук в варианте с явным указанием sudo-пользователя:
if [[ -n $2 ]]; then 
  admin_username=$2

  # Получение пароля администратора:
  printf "Указано имя администратора ($admin_username), под которым скрипт будет выполнен на удалённом компьютере.\n"
  read -p "Введите его пароль (или нажмите [Enter] для выхода): " -s admin_pass

  if [[ -n $admin_pass ]]; then
    ssh_pass=$admin_pass
    ssh_user=$admin_username
  else
    # Если пароль указан не был, то прервать выполнение скрипта
    printf_color "$IRed" "Пароль администратора не введён. Выход из скрипта."
    exit 1
  fi

  showruncondition $admin_username
  ansible-playbook --ssh-extra-args "-o IdentitiesOnly=yes -o StrictHostKeyChecking=no" \
                   --extra-vars "desktop_ip=$desktop_ip \
                   ansible_user=$ssh_user \
                   ansible_ssh_pass=$ssh_pass \
                   ansible_sudo_pass=$ssh_pass" \
                   $yaml_filename

# Если административная уч.запись не указана, то запустить плейбук в расчёте на наличие на целевом компьютере ssh-ключа:
else
  showruncondition
  ansible-playbook --user root \
                   --ssh-extra-args "-o IdentitiesOnly=yes -o StrictHostKeyChecking=no" \
                   --extra-vars "desktop_ip=$desktop_ip \
                   " \
                   $yaml_filename

fi

echo "..."