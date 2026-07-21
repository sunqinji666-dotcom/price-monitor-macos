# Monitor de preços

> Ferramenta local para macOS que acompanha preços e estoque de lojas selecionadas e mostra o saldo e o uso recente da API WOYAO na barra de menus.

[简体中文](../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Português**

## Recursos

- Agrupa produtos comparáveis e os ordena do menor para o maior preço.
- Verifica as lojas a cada minuto e anuncia por voz novos itens ou reposições.
- Mostra o saldo atual da WOYAO diretamente na barra de menus.
- Atualiza o uso a cada hora e anuncia saldo, cota usada e custo do dia.
- Lista as dez chamadas mais recentes com modelo, custo, tokens e horário.

## Início rápido

1. Baixe `PriceMonitor-v1.4-macOS-arm64.zip` em [Releases](../../releases/latest), descompacte e mova o app para Aplicativos.
2. Abra o app uma vez. Para iniciar no login, instale o modelo de usuário `LaunchAgent.plist`.
3. Abra **Uso WOYAO**, cole sua API Key e escolha **Salvar em Documentos e ler**.

## Privacidade

Os dados das lojas são lidos de APIs públicas. A chave WOYAO é armazenada apenas em `Documents/价格监控/woyao-api-key.txt`; ela não é gravada no Git, em logs comuns nem em dados do navegador. Não sincronize esse arquivo de texto simples para uma nuvem pública.

## Compilação e licença

São necessários macOS, Xcode Command Line Tools e Swift 6. Execute `./build_app.sh` para criar `价格监控.app`.

Este projeto usa a [MIT License](../LICENSE). Autor e contato: Jacksun（孙秦吉）· [qinji@jack-sun.com](mailto:qinji@jack-sun.com).
