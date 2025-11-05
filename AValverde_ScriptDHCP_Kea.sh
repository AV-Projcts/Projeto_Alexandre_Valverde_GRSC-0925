#!/bin/bash
# ------------------ * Script bué fixe para instalar DHCP (Versão Kea) * ------------------ #

# ---- ! - Variáveis - ! ---- #
interface=""
interfaceInternet=""
DHCPmin=0
DHCPmax=0
subnet=0
gatewayipserv=0
confirmar=0

# DNS
dominioDNS=""
ipserverDNS=""

# Menus
opcao=""
criar=""
restBak=""
restBakError=""
createBak=""
createBakError=""



# Failsafe ServerIP <--> DHCP
DHCPminMin=0
DHCPminMax=0
DHCPmaxMax=0

# ----------------------------- * Configuração * ----------------------------- #

# Clear e Banner vibe coded
clear
cat <<'BANNER'
 __    __  ________   ______
|  \  /  \|        \ /      \
| ## /  ##| ########|  ######\
| ##/  ## | ##__    | ##__| ##
| ##  ##  | ##  \   | ##    ##
| #####\  | #####   | ########
| ## \##\ | ##_____ | ##  | ##
| ##  \##\| ##     \| ##  | ##
 \##   \## \######## \##   \##
BANNER
printf "\n\n\n\n"

# Perguntar ao user se quer restaurar as configurações default do Kea, ou se quer instalar e configurar o serviço
cat <<INTRO
Escolha uma das seguintes opções:

1• Restaurar/Backup - kea-dhcp4.conf
2• Instalar o serviço
3• Sair

INTRO

while true;do
	printf " -->  "
	read opcao
	case "$opcao" in
		1)
		while true;do
			clear
			cat <<- OPT
			Escolha uma das seguintes opções:
			1• Restaurar
			2• Criar backup
			3• Sair

			OPT
			printf " -->  "
			read restBak
			case "$restBak" in
				1)
				if sudo test "/etc/kea/kea-dhcp4.conf.bak"; then
					echo "Ficheiro backup encontrado!"
					printf "\n===> A restaurar as configurações... <===\n\n"
					sudo cp /etc/kea/kea-dhcp4.conf.bak /etc/kea/kea-dhcp4.conf
					sleep 1
					printf "\n\n===> ! Configurações restauradas ! <===\n\n"
					exit
				else
					while true;do
						printf "\n->Não existe backup, deseja instalar o serviço DHCP? (S ou N):  "
						read restBakError
						case "$restBakError" in:
							S|s)
							printf "\n===> ! A iniciar o script de configuração ! <===\n\n"
                			sleep 1
                			break
							;;
							N|n)
                			printf "\n===> ! A encerrar o script... ! <===\n\n"
                			sleep 1
                			exit
                			;;
							*)
							echo " - ? Opção inválida, escolha S ou N ? - "
                			;;
						esac
					done
				fi
				2)
				echo "->Criar backup? (S ou N)"
				read createBak
				case "$createBak" in
					S|s)
					if sudo test "/etc/kea/kea-dhcp4.conf"; then
						echo "Ficheiro .conf encontrado!"
						printf "\n===> A criar Backup... <===\n\n"
						sudo cp /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.bak
						sleep 1
						printf "\n\n===> ! Ficheiro backup criado ! <===\n\n"
						printf '\n\n===> O ficheiro encontra-se em "/etc/kea/kea-dhcp4.conf.bak" <===\n\n'
						exit
					else
						while true;do
							printf "\n->Não existe ficheiro .conf, deseja instalar o serviço DHCP? (S ou N):  "
                            read createBakError
                            case "$createBakError" in:
                                S|s)
                                printf "\n===> ! A iniciar o script de configuração ! <===\n\n"
                                sleep 1
                                break
                                ;;
                                N|n)
                                printf "\n===> ! A encerrar o script... ! <===\n\n"
                                sleep 1
                                exit
                                ;;
                                *)
                                echo " - ? Opção inválida, escolha S ou N ? - "
                                ;;
							esac
						done
					fi
					N|n)
					printf "\n===> ! A encerrar o script... ! <===\n\n"
                	sleep 1
                	exit
					;;
				esac
				3)
				printf "\n===> ! Opção de saída escolhida, a encerrar o script... ! <===\n\n"
				sleep 1
				exit
				;;
				*)
				echo " - ? Opção inválida, escolha uma opçao de 1-3 ? - "
				;;
			esac
		done
		break
		;;
		2)
		printf "\n===> ! A iniciar o script de configuração ! <===\n\n"
		sleep 1
		break
		;;
		3)
		printf "\n===> ! Opção de saída escolhida, a encerrar o script... ! <===\n\n"
		sleep 1
		exit
		;;
		*)
		echo " - ? Opção inválida, escolha uma opçao de 1-3 ? - "
		;;
	esac
done

# Dar clear e ver interfaces de Rede/IPs - ! Se isto não funcionasse entregava a bata (outra vez)
clear
nmcli

# Banner para configs gerais do server pre-DHCP
printf "\n\n*********************************"
printf "\n***** - Configs do Server - *****"
printf "\n*********************************\n"

# Pedir ao utilizador para escolher a interface de Internet Exterior - ! Funciona (sem failsafe)
#printf "\n-> Escolha a interface de Internet Exterior:  "
#read interfaceInternet

# Pedir ao utilizador para escolher a interface de Rede para DHCP - ! Funciona (sem failsafe) 
printf "\n-> Escolha a interface de rede para DHCP:  "
read interface

# Perguntar ao utilizador se o IP do Server DHCP será .2 ou .253 - ! Funciona
while true;do
	printf "\n-> O IP do Server DHCP será 2 ou 253?:  "
	read gatewayipserv

	if [ "$gatewayipserv" -eq 2 ] || [ "$gatewayipserv" -eq 253 ];then
		break
	else
		echo "! IP inválido, insira 2 ou 253."
	fi
done

# Perguntar qual vai ser o IP do Server DNS/Gateway será .1 ou .254
while true; do
	printf "\n-> O IP do Server DNS/Gateway será 1 ou 254?:  "
	read ipserverDNS

	if [ "$ipserverDNS" -eq 1 ] || [ "$ipserverDNS" -eq 254];then
		break
	else
		echo "! IP DNS/Gateway inválido, insira 1 ou 254."
	fi
done

# Perguntar ao utilizador qual será o dominio DNS - ! Sem failsafe
printf "\n-> Qual será o dominio de DNS? (ex: dominio.xyz):  "
read dominioDNS

# Pedir ao utilizador para inserir o IP de Subnet - Funciona
while true;do
	printf "\n-> Qual será a Subnet? (Range: 192.168. [1-255] .0/24):  "
	read subnet
	if [ "$subnet" -ge 1 ] && [ "$subnet" -le 255 ];then
		break
	else
		echo "Subnet inválida, insira um número entre 1-255."
	fi
done

# ------------------------------------------------------------------------- #

# Variáveis - Failsafe de colisão ServerIP <--> DHCP
if [ "$gatewayipserv" -eq 2 ];then
	DHCPminMin=3
	DHCPminMax=252
	DHCPmaxMax=253
else
	DHCPminMin=2
	DHCPminMax=251
	DHCPmaxMax=252
fi

# Pedir range de IPs para o DHCP - ! Funciona
printf "\n\n*****************************"
printf "\n***** - IP Range DHCP - *****"
printf "\n*****************************\n"
while true;do
	printf "\n-> DHCP - IP Minimo (range: $DHCPminMin-$DHCPminMax):  "
	read DHCPmin

	if [ "$DHCPmin" -ge "$DHCPminMin" ] && [ "$DHCPmin" -le "$DHCPminMax" ];then
		break
	elif [ "$DHCPmin" -eq $gatewayipserv ];then
		echo "! Este IP está a ser usado pelo Server DHCP!"
	elif [ "$DHCPmin" -eq 255 ];then
		echo "! Não é possivel utilizar o endereco de Broadcast!"
	else
		echo "! Range inválido, insira um número entre $DHCPminMin-$DHCPminMax."
	fi
done
while true;do
	printf "\n-> DHCP - IP Máximo (range: $DHCPmin-$DHCPmaxMax):  "
	read DHCPmax

	if [ "$DHCPmax" -ge "$DHCPmin" ] && [ "$DHCPmax" -le $DHCPmaxMax ];then
		break
	elif [ "$DHCPmax" -eq $gatewayipserv ];then
		echo "! Este IP está a ser usado pelo Server DHCP!"
	elif [ "$DHCPmax" -eq 255 ];then
		echo "! Não é possivel utilizar o endereco de Broadcast!"
	else
		echo "! Range inválido, insira um número entre $DHCPmin-$DHCPmaxMax."
	fi
done

# Echo para o utilizador verificar se as configurações estão corretas

printf "\n\n\n************************************"
printf "\n***** - Confirmar alteracões - *****"
printf "\n************************************\n"
echo "• Serviço DHCP: Kea-DHCP4"
echo "-----------------------------------------------------------------"
echo "• Dominio DNS: $dominioDNS"
echo "• IP do Server DNS/Gateway: 192.168.$subnet.'$ipserverDNS'/24"
echo "-----------------------------------------------------------------"
echo "• Interface da rede DHCP: $interface"
echo "• IP do Server DHCP (este): 192.168.$subnet.'$gatewayipserv'/24"
echo "• DHCP ativo de: $DHCPmin até $DHCPmax"
echo "• Subnet da rede: 192.168.'$subnet'.0/24"

# Confirmar aplicação das configurações
while true;do
	printf "\n-> Aplicar configurações? (S ou N):  "
	read confirmar
	case "$confirmar" in
		S|s)
		printf "\n===> ! A aplicar as configurações... ! <===\n\n"
		break
		;;
		N|n)
		printf "\n===> ! Configurações não foram aplicadas, a fechar o Script... ! <===\n\n"
		exit
		;;
		*)
		echo "! Opção inválida, escolha S (sim) ou N (não)"
		;;
	esac
done

# --------------------------- * Instalar dependencies * --------------------------

#printf "\n\n# ---------- A atualizar o sistema ---------- #"
# Dar update ao sistema
#sudo yum update -y

#printf "\n\n# ---------- A instalar o serviço DHCP ---------- #"
# Instalar dhcpd
#sudo yum install kea -y

# ----------------------------- * Aplicar Settings * ----------------------------- #

# Configurar a placa de rede
sudo nmcli connection modify "$interface" ipv4.addresses 192.168.$subnet.$gatewayipserv/24
sudo nmcli connection modify "$interface" ipv4.method manual ipv4.gateway 192.168.$subnet.$ipserverDNS
sudo nmcli connection modify "$interface" ipv4.dns 8.8.8.8	# Google DNS
sudo nmcli connection up "$interface"

# Adicionar configurações ao ficheiro kea-dhcp4.conf
sudo cat <<CONFIG > /etc/kea/kea-dhcp4.conf
{
"Dhcp4": {
    "interfaces-config": {
        "interfaces": [ "$interface" ]
	},
    "expired-leases-processing": {
		"reclaim-timer-wait-time": 10,
        "flush-reclaimed-timer-wait-time": 25,
        "hold-reclaimed-time": 3600,
        "max-reclaim-leases": 100,
        "max-reclaim-time": 250,
        "unwarned-reclaim-cycles": 5
    },
    "renew-timer": 900,
    "rebind-timer": 1800,
    "valid-lifetime": 3600,
    "option-data": [
        {
            "name": "domain-name-servers",
            "data": "192.168.$subnet.$ipserverDNS"
        },
        {
            "name": "domain-name",
            "data": "$dominioDNS"
        },
        {
            "name": "domain-search",
            "data": "$dominioDNS"
        }
    ],
    "subnet4": [
        {
            "id": 1,
            "subnet": "192.168.$subnet.0/24",
            "pools": [ { "pool": "192.168.$subnet.$DHCPmin - 192.168.$subnet.$DHCPmax" } ],
            "option-data": [
                {
                    "name": "routers",
                    "data": "192.168.$subnet.$ipserverDNS"
                }
            ]
        }
    ],
    "loggers": [
    {
	"name": "kea-dhcp4",
        "output-options": [
            {
		"output": "/var/log/kea/kea-dhcp4.log"
            }
        ],
        "severity": "INFO",
        "debuglevel": 0
    }
  ]
}
}
CONFIG

# Abrir portas para o serviço DHCP no firewalld
sudo firewall-cmd --permanent --add-service=dhcp
sudo firewall-cmd --runtime-to-permanent

# Reload no firewalld
sudo firewall-cmd --reload

# Ativar inicio automático, iniciar, e verificar o status do serviço kea-dhcp4
sudo systemctl enable kea-dhcp4
sudo systemctl restart kea-dhcp4
sudo systemctl status kea-dhcp4
