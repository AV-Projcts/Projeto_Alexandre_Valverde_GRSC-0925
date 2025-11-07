#!/bin/bash

# -------------------- Script bué fixe - versão DNS BIND -------------------- !

# ---------- Variavéis ---------- !
subnet=0
dominioDNS=""
interface=""
ipserver=0




# Instalar Bind/Bind-utils

#sudo yum install bind bind-utils


# Clear e nmcli print
clear
nmcli

# Pedir ao user a Interface LAN
printf "\nInsira a Interface LAN:  "
read interface

# Pedir ao user se o IP do Server DNS/Gateway será .1 ou .254
while true;do
	printf "\nO IP do Server DNS/Gateway será 1 ou 254?:  "
	read ipserver
	if [ $ipserver -eq 1 ] || [ $ipserver -eq 254 ];then
		break;
	else
		echo "IP inválido, insira 1 ou 254"
	fi
done

# Pedir ao user para inserir a subnet
while true;do
	printf "\nInsira a subnet da rede LAN (192.168. [1-255] .0/24):  "
	read subnet
	if [ $subnet -ge 1 ] && [ $subnet -le 255 ];then
		break;
	else
		echo "Subnet inválida, insira um número entre 1-255"
	fi
done

# Pedir ao user para inserir o Dominio DNS - Sem failsafe
printf "\nInsira o Dominio DNS:  "
read dominioDNS

# Perguntar ao user se quer usar DNS google ou Cloudflare - Maybe depois
#while true;do
#	printf "\nEscolha um DNS Externo (1 - Google   2 - Cloudflare):  "


# Pedir ao user para verificar as configurações
printf "\n\n\n************************************"
printf "\n***** - Confirmar alteracões - *****"
printf "\n************************************\n"
echo "• Serviço DNS: BIND"
echo "• Interface LAN: $interface"
echo "• IP do Server DNS/Gateway: 192.168.$subnet.'$ipserver'/24"
echo "• Subnet da rede: 192.168.'$subnet'.0/24"
echo "• Dominio DNS: $dominioDNS"

# Aplicar configs
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

echo "vroom vroom"

# --------------------------- * Instalar dependencies * --------------------------

printf "\n\n# ---------- A atualizar o sistema ---------- #"
# Dar update ao sistema
sudo yum update -y

printf "\n\n# ---------- A instalar serviço DNS-BIND ---------- #"
# Instalar bind + bind-utild
sudo yum install bind bind-utils -y

# --------------------------------------------------------------------------------

# Configurar interface LAN
sudo nmcli connection modify "$interface" ipv4.addresses 192.168.$subnet.$ipserver/24
sudo nmcli connection modify "$interface" ipv4.method manual ipv4.gateway 192.168.$subnet.$ipserver
sudo nmcli connection modify "$interface" ipv4.dns "192.168.$subnet.$ipserver"
sudo nmcli connection up "$interface"


# Configurar Bind

sudo cat <<- BIND > /etc/named.conf
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
acl internal-network {
        192.168.$subnet.0/24;
};

options {
        listen-on port 53 { any; };
        listen-on-v6 { none; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
		allow-query     { localhost; internal-network; };
        allow-transfer     { localhost; };
        recursion yes;
		
		forward only;
		forwarders { 8.8.8.8; 1.1.1.1; };
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

// Reverse network zone e DNS Domain
zone "$dominioDNS" IN {
        type primary;
        file "$dominioDNS";
        allow-update { none; };
};
zone "$subnet.168.192.in-addr.arpa" IN {
        type primary;
        file "$subnet.168.192.db";
        allow-update { none; };
};
BIND

# Meter o serviço DNS BIND em IPv4
# - Pelos vistos como o script abre como root isto não precisa de sudo, oops
# - Nem ia funcionar, "sudo bash -c" better
# - (acabei de perceber que o script dhcp fica todo partido sem sudo)
# - Agora já tá por isso vai ficar
cat <<- BIND2 >> /etc/sysconfig/named
OPTIONS="-4"
BIND2

# Configurar forward zone
cat <<- ZONE > /var/named/$dominioDNS
\$TTL 86400
@   IN  SOA     DNS.$dominioDNS. root.$dominioDNS. (
        1760948755  ; Serial
        3600        ; Refresh
        1080        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)
@               IN  NS      DNS.$dominioDNS.
DNS				IN  A       192.168.$subnet.$ipserver
@               IN  MX 10   DNS.$dominioDNS.
servidor1		IN  A		192.168.$subnet.200
ZONE

# Configurar reverse lookup
cat <<- ZONE > /var/named/$subnet.168.192.db
\$TTL 86400
@   IN  SOA     DNS.$dominioDNS. root.$dominioDNS. (
        1760948755  ; Serial
        3600        ; Refresh
        1080        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)
@               IN  NS      DNS.$dominioDNS.
$ipserver		IN  PTR		DNS.$dominioDNS.
10				IN  PTR		servidor1.$dominioDNS.
ZONE

# Fazer o named dono dos ficheiros de zona
sudo chown named:named /var/named/$dominioDNS
sudo chown named:named /var/named/$subnet.168.192.db

# Adicionar service + permanent runtime á firewall
sudo firewall-cmd --add-service=dns --permanent
sudo firewall-cmd --reload

# Ativar e ligar serviço DNS BIND
systemctl enable named
systemctl start named
systemctl status named
sleep 1

# Dig ao dominio DNS
echo "! Dig !"
dig @192.168.$subnet.$ipserver $dominioDNS
read -p ">-----| Pressione Enter para continuar |-----<" enter

# NSLOOKUP
echo "! NSLOOKUP !"
nslookup DNS.$dominioDNS 192.168.$subnet.$ipserver
read -p ">-----| Pressione Enter para continuar |-----<" enter

# Dig Reverse
echo "! Reverse dig !"
dig -x 192.168.$subnet.$ipserver
read -p ">-----| Pressione Enter para continuar |-----<" enter

# Ping exterior
echo "! Ping !"
ping -c 5 www.google.com