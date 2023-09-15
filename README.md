# previsao_alagamento

Esse é um repositório temporário para o projeto de previsão de alagamento realizado em parceria com a FGV.

### Requisitos

- Um editor de texto (recomendado VS Code)
- Python 3.9.x
- `pip`
- (Opcional, mas recomendado) Um ambiente virtual para desenvolvimento (`miniconda`, `virtualenv` ou similares)

### Licenças

Este repositório contém parte do código sob a licença GPL-3.0 e parte sob uma licença EULA.
Todo código sob a licença EULA terá um cabeçalho indicando que é proprietário.
Consulte os respectivos tópicos em LICENÇA para os termos e condições de cada licença.

### Procedimentos

- Clonar esse repositório

```
git clone https://github.com/prefeitura-rio/pipelines
```

- Abrí-lo no seu editor de texto

- No seu ambiente de desenvolvimento, instalar [poetry](https://python-poetry.org/) para gerenciamento de dependências

```
pip3 install poetry
```

- Instalar as dependências para desenvolvimento

```
poetry install
```

### Adicionando dependências para execução

- Requisitos de pipelines devem ser adicionados com

```
poetry add <package>
```