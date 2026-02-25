# ERPNext Fiscal BR - Imagem customizada para Dokploy
# Estende frappe/erpnext e adiciona o app erpnext_fiscal_br

FROM frappe/erpnext:version-15

USER root
# Dependências do sistema para assinatura XML (NFe/NFCe)
RUN apt-get update && apt-get install -y \
    libxmlsec1-dev \
    libxmlsec1-openssl \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

USER frappe
WORKDIR /home/frappe/frappe-bench
RUN bench get-app https://github.com/brunoobueno/erpnext_fiscal_br --branch main
