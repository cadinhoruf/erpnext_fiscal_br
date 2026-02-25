# Instalação no Dokploy

## Pré-requisitos

- Dokploy instalado e rodando
- Rede `dokploy-network` criada (Dokploy cria automaticamente ao fazer deploy)
- Para teste local: `docker network create dokploy-network`

## Opção 1: Adicionar ao compose existente do ERPNext (Recomendado)

Se você já tem um compose do ERPNext (ex.: do template Dokploy), use o **override** para adicionar o erpnext_fiscal_br:

1. Clone ou adicione o repositório erpnext_fiscal_br ao seu projeto
2. No Dokploy, configure o **Compose Path** com os dois arquivos:
   ```
   compose.yml,docker-compose.fiscal-override.yml
   ```
   (substitua `compose.yml` pelo nome do seu compose do ERPNext)

3. O override fará:
   - Build da imagem customizada (Dockerfile) com erpnext_fiscal_br
   - Instalação automática do app no create-site (`--install-app erpnext --install-app erpnext_fiscal_br`)

4. Remova ou ajuste no seu `.env`:
   - `IMAGE_NAME` e `VERSION` (o override usa build local)
   - Ou mantenha; o override tem prioridade com `pull_policy: never`

**Estrutura esperada no repositório:**
```
seu-projeto/
├── compose.yml              # seu compose do ERPNext
├── docker-compose.fiscal-override.yml  # deste repo (copie ou use como submodule)
├── Dockerfile               # deste repo
└── .env
```

## Opção 2: Deploy via Docker Compose completo

### 1. Adicione o repositório no Dokploy

1. Crie um novo projeto no Dokploy
2. Selecione **Compose** como tipo de aplicação
3. Conecte o repositório (GitHub, GitLab, etc.) ou use o repositório local
4. Defina o **Compose Path**: `./docker-compose.yml`
5. Selecione o branch (ex: `main`)

### 2. Variáveis de Ambiente

Configure as variáveis no painel do Dokploy:

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `DB_PASSWORD` | Senha root do MariaDB | `admin` |
| `ADMIN_PASSWORD` | Senha do usuário Administrator do ERPNext | `admin` |
| `SITE_NAME` | Nome do site (usado no create-site) | `frontend` |
| `DOMAIN` | Domínio para Traefik (ex: `erp.empresa.com`) | `localhost` |
| `FRAPPE_SITE_NAME_HEADER` | Header para resolver o site (use `frontend` se acessar por IP) | `$host` |

**Importante:** Se acessar por IP (ex: `http://192.168.1.10`), defina `FRAPPE_SITE_NAME_HEADER=frontend` para que o ERPNext resolva o site corretamente.

### 3. Domínio no Dokploy

No Dokploy, configure o domínio na interface:

1. Acesse a aplicação > **Domains**
2. Adicione seu domínio (ex: `erp.empresa.com`)
3. O Dokploy configurará o Traefik automaticamente

### 4. Deploy

1. Clique em **Deploy**
2. O build da imagem pode levar alguns minutos (download da base + `bench get-app`)
3. O serviço `create-site` criará o site na primeira execução (instala ERPNext + erpnext_fiscal_br)
4. Após o `create-site` concluir, acesse a URL configurada

### 5. Primeiro Acesso

- **URL:** `https://seu-dominio.com` ou `http://localhost:8080` (se exposto)
- **Usuário:** `Administrator`
- **Senha:** valor de `ADMIN_PASSWORD` (padrão: `admin`)

## Instalação Manual do App (alternativa)

Se o `create-site` não instalar o app automaticamente, execute:

```bash
# Obtenha o nome do container backend
docker ps

# Instale o app no site
docker exec -it <container_backend> bench --site <seu-site> install-app erpnext_fiscal_br
docker exec -it <container_backend> bench --site <seu-site> migrate
docker exec -it <container_backend> bench build
docker exec -it <container_backend> bench restart
```

## Dependências do Sistema

O Dockerfile já inclui as dependências necessárias:

- `libxmlsec1-dev`
- `libxmlsec1-openssl`
- `pkg-config`

## Configuração Pós-Instalação

### 1. Configuração Fiscal

Acesse: **Fiscal BR > Configuração Fiscal**

- Selecione a empresa
- Preencha CNPJ, IE, Regime Tributário
- Configure séries de NFe/NFCe
- Defina ambiente (Homologação para testes)

### 2. Certificado Digital

Acesse: **Fiscal BR > Certificado Digital**

- Faça upload do arquivo .pfx (certificado A1)
- Informe a senha
- O sistema validará automaticamente

### 3. Dados dos Clientes

Configure nos clientes:

- CPF/CNPJ
- Inscrição Estadual (se PJ contribuinte)
- Indicador de contribuinte ICMS

### 4. Dados dos Itens

Configure nos itens:

- NCM (8 dígitos)
- CFOP de venda interna e interestadual
- Origem da mercadoria

## Teste de Funcionamento

### 1. Teste conexão SEFAZ

Na empresa, clique em **Fiscal BR > Testar SEFAZ**

### 2. Emita uma NFe de teste

1. Crie uma Sales Invoice
2. Submeta a fatura
3. Clique em **Nota Fiscal > Emitir NFe**
4. Confirme a emissão

Em ambiente de homologação, a nota será processada mas não terá valor fiscal.

## Troubleshooting

### Erro: rede dokploy-network não existe

```bash
docker network create dokploy-network
```

### Erro: create-site falha ou timeout

Verifique os logs do container `create-site`:

```bash
docker compose logs create-site
```

### Erro de certificado SSL

```
SSLError: certificate verify failed
```

Verifique se o certificado digital está válido e a senha está correta.

### Erro de timeout

```
Timeout na comunicação com a SEFAZ
```

Aumente o timeout em **Configuração Fiscal > Timeout SEFAZ**.

### Erro de assinatura

```
Erro ao assinar XML
```

Verifique se as bibliotecas `xmlsec` e `cryptography` estão instaladas corretamente. O Dockerfile já inclui as dependências de sistema.

## Build Alternativo via APPS_JSON_BASE64

Para builds que incluem o app na imagem (estilo Coolify/frappe_docker):

```bash
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)
# Use essa variável no build do frappe_docker custom/layered
```

O `apps.json` deste repositório já está configurado com erpnext_fiscal_br.

## Suporte

- Issues: https://github.com/brunoobueno/erpnext_fiscal_br/issues
- Email: contato@alquimiaindustria.com.br
