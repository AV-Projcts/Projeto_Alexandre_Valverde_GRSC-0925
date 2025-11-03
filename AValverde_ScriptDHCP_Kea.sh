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

# intro
opcao=0
criar=0



# Failsafe ServerIP <--> DHCP
DHCPminMin=0
DHCPminMax=0
DHCPmaxMax=0

# ----------------------------- * Configuração * ----------------------------- #

# Clear e Banner vibe
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

1• Restaurar configurações do kea-dhcp4.conf
2• Instalar o serviço
3• Sair

INTRO

while true;do
	printf " -->  "
	read opcao
	case "$opcao" in
		1)
		if [ -f "/etc/kea/kea-dhcp4.conf.bak" ]; then
			echo "Ficheiro backup encontrado!"
			printf "\n===> A restaurar as configurações... <===\n\n"
			sudo mv /etc/kea/kea-dhcp4.conf.bak /etc/kea/kea-dhcp4.conf
			sleep 1
			printf "\n\n===> ! Configurações default restauradas ! <===\n\n"
		else
			while true;do
				printf "\n->O ficheiro não existe, deseja criá-lo? (S ou N):  "
				read criar
				case "$criar" in
					S|s)
					printf "\n===> A Criar o ficheiro... <===\n\n"
					sudo touch /etc/kea/kea-dhcp4.conf
					sudo cat <<- 'CREATE' > /etc/kea/kea-dhcp4.conf 
					{
					"Dhcp4": {
						"valid-lifetime": 4000,
						"renew-timer": 1000,
						"rebind-timer": 2000,

						"interfaces-config": {
							"interfaces": [ "eth0" ]
						},

						"lease-database": {
							"type": "memfile",
							"persist": true,
							"name": "/var/lib/kea/dhcp4.leases"
						},

						"subnet4": [
							{
								"subnet": "192.0.2.0/24",
								"pools": [
									{
										"pool": "192.0.2.1 - 192.0.2.200"
									}
								]
							}
						]
					}
					}
					CREATE
					sleep 1
					printf "\n\n===> ! Ficheiro .conf restaurado ! <===\n\n"
					echo "! O novo ficheiro encontra-se em /etc/kea/kea-dhcp4.conf"
					exit
					;;
					N|n)
					printf "\n===> ! O ficheiro não será criado, a fechar o Script... ! <===\n\n"
					sleep 1
					exit
					;;
					*)
					echo "! Opção inválida, escolha S (sim) ou N (não)"
					;;
				esac
			done
		fi
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
printf "\n-> Escolha a interface de Internet Exterior:  "
read interfaceInternet

# Pedir ao utilizador para escolher a interface de Rede para DHCP - ! Funciona (sem failsafe) 
printf "\n-> Escolha a interface de rede para DHCP:  "
read interface

# Perguntar ao utilizador se a Gateway/IP do Server será .1 ou .254 - ! Funciona
while true;do
	printf "\n-> A Gateway/IP do Server será 1 ou 254?:  "
	read gatewayipserv

	if [ "$gatewayipserv" -eq 1 ] || [ "$gatewayipserv" -eq 254 ];then
		break
	else
		echo "! Gateway inválido, insira 1 ou 254."
	fi
done

# Pedir ao utilizador para inserir o IP de Subnet - Funciona
while true;do
	printf "\n-> Qual será o número da Subnet? (Range: 192.168. [1-255] .0/24):  "
	read subnet
	if [ "$subnet" -ge 1 ] && [ "$subnet" -le 255 ];then
		break
	else
		echo "Subnet inválida, insira um número entre 1-255."
	fi
done

# ------------------------------------------------------------------------- #

# Variáveis - Failsafe de colisão ServerIP <--> DHCP
if [ "$gatewayipserv" -eq 1 ];then
	DHCPminMin=2
	DHCPminMax=253
	DHCPmaxMax=254
else
	DHCPminMin=1
	DHCPminMax=252
	DHCPmaxMax=253
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
		echo "! Este IP está a ser usado pela Gateway!"
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
		echo "! Este IP está a ser usado pela Gateway!"
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
echo "• Interface da rede DHCP: $interface"
echo "• IP da Gateway/Server: 192.168.$subnet.'$gatewayipserv'/24"
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

printf "\n\n# ---------- A atualizar o sistema ---------- #"
# Dar update ao sistema
sudo yum update -y

printf "\n\n# ---------- A instalar o serviço DHCP ---------- #"
# Instalar dhcpd
sudo yum install kea -y

# ----------------------------- * Aplicar Settings * ----------------------------- #

# Configurar a placa de rede
sudo nmcli connection modify "$interface" ipv4.addresses 192.168.$subnet.$gatewayipserv/24
sudo nmcli connection modify "$interface" ipv4.method manual ipv4.gateway 192.168.$subnet.$gatewayipserv
sudo nmcli connection modify "$interface" ipv4.dns 8.8.8.8	# Google DNS
sudo nmcli connection up "$interface"

# Adicionar configurações ao ficheiro kea-dhcp4.conf
sudo cat <<CONFIG > /etc/kea/kea-dhcp4.conf
{
"Dhcp4": {
    "interfaces-config": {
        "interfaces": [ "$interface" ]	# Especificar interface para DHCP
	},
    "expired-leases-processing": {					# Configs de processamento das Leases DHCP
		"reclaim-timer-wait-time": 10,			#
        "flush-reclaimed-timer-wait-time": 25,	#
        "hold-reclaimed-time": 3600,			#
        "max-reclaim-leases": 100,				#
        "max-reclaim-time": 250,				#
        "unwarned-reclaim-cycles": 5			#
    },
    "renew-timer": 900,		# Timer do T1 - Ao chegar a este valor, se o cliente responder ao server DHCP (unicast), a Lease renova, caso contrário continua a tentar até ao Timer T2
    "rebind-timer": 1800,	# Timer do T2 - Ao chegar a este valor, se o cliente responder a qualquer server DHCP na rede (Broadcast porque IPV4), a Lease renova, caso contrário continua a tentar até a Lease expirar
    "valid-lifetime": 3600,	# Lifetime da Lease DHCP, ao chegar aqui a Lease expira
    "option-data": [
        {
            # specify your DNS server
            "name": "domain-name-servers",
            "data": "$gatewayipserv"	# IP do server DNS
        },
        {
            # specify your domain name
            "name": "domain-name",
            "data": "srv.world"		# Adicionar quando DNS tiver feito
        },
        {
            # specify your domain-search base
            "name": "domain-search",
            "data": "srv.world"		# Mesma merda que acima
        }
    ],
    "subnet4": [
        {
            "id": 1,
            "subnet": "192.168.$subnet.0/24",	# Subnet que utilizará DHCP
            "pools": [ { "pool": "192.168.$subnet.$DHCPmin - 192.168.$subnet.$DHCPmax" } ],		# Range DHCP
            "option-data": [
                {
                    "name": "routers",
                    "data": "$gatewayipserv"	# IP da Gateway/Server
                }
            ]
        }
    ],
# Escolher local para guardar logs + o que guardar nas logs
    "loggers": [
    {
        "name": "kea-dhcp4",	# Pede ao kea para dar log apenas de DHCPv4
        "output-options": [
            {
                "output": "/var/log/kea/kea-dhcp4.log"		# Local e nome do ficheiro log
            }
        ],
        "severity": "INFO",		# Define os logs para mostrar erros, conflitos e leases
        "debuglevel": 0			# Desligado - Quando ativo mostra logs super detalhados sobre tudo o que esteja conectado ao Kea e ele próprio
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
