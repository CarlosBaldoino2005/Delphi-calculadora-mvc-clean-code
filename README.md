# Calculadora Científica (Delphi · MVC · Clean Code)

Aplicação de **calculadora científica** para **Windows**, desenvolvida em **Embarcadero Delphi** com **VCL**, organizada segundo o padrão **MVC** (Model–View–Controller) e boas práticas de **código legível** (responsabilidades separadas, nomes explícitos, comentários didáticos no código-fonte).

**Repositório:** [github.com/CarlosBaldoino2005/Delphi-calculadora-mvc-clean-code](https://github.com/CarlosBaldoino2005/Delphi-calculadora-mvc-clean-code)

---

## Sumário

| Secção | Conteúdo |
|--------|----------|
| [Funcionalidades](#funcionalidades) | Operações básicas, científicas, memória, ângulos |
| [Arquitetura](#arquitetura) | MVC, interfaces, unidades |
| [Requisitos](#requisitos) | Delphi / RAD Studio, plataforma |
| [Como executar](#como-executar) | Abrir projeto e compilar |
| [Atalhos de teclado](#atalhos-de-teclado) | Esc, Enter, teclado numérico, etc. |
| [Estrutura do projeto](#estrutura-do-projeto) | Ficheiros principais |

---

## Funcionalidades

- **Aritmética:** adição, subtração, multiplicação, divisão, resto (`mod`), potência (`x^y`), percentagem.
- **Funções científicas:** seno, cosseno, tangente, arco-funções, logaritmo natural e decimal, raiz quadrada, quadrado, inverso, valor absoluto, parte inteira/fracionária, fatorial, exponencial.
- **Constantes:** π e *e*.
- **Memória:** MC, MR, MS, M+, M− com indicador visual.
- **Ângulos:** modo **graus** ou **radianos** para funções trigonométricas e inversas.
- **Interface:** tema escuro, teclado dinâmico, linha de expressão auxiliar.
- **Teclado:** atalhos para operações frequentes (ver secção dedicada).

---

## Arquitetura

O projeto segue **MVC** de forma explícita:

| Camada | Unidade / componente | Responsabilidade |
|--------|----------------------|------------------|
| **Model** | `uCalcModel.pas` | Estado da calculadora (entrada, acumulador, operação pendente, memória, modo angular) e regras matemáticas. Sem dependência de UI. |
| **View** | `Calculadora.pas` / `Calculadora.dfm` | Formulário VCL: painéis, etiquetas, botões e captura de eventos (rato e teclado). |
| **Controller** | `uCalcController.pas` | Orquestra pedidos da View, invoca o Model e atualiza a View através da interface **`ICalcViewPort`** (desacoplamento da implementação concreta do formulário). |

A **View** implementa `ICalcViewPort`; os métodos dessa interface estão declarados na secção **`public`** do formulário, conforme exigido pelo compilador Delphi para o mapeamento correto de interfaces em classes `TForm`.

---

## Requisitos

- **Embarcadero RAD Studio** (Delphi) com suporte a **VCL** para Windows (ex.: Delphi 11 / 12 Community ou superior).
- **Windows** (Win32 e/ou Win64, conforme configuração da plataforma no projeto).

---

## Como executar

1. Clonar este repositório.
2. Abrir **`Calc.dproj`** no RAD Studio.
3. Selecionar a plataforma desejada (**Win32** ou **Win64**).
4. Compilar (**Project → Build**) e executar (**Run** ou **F9**).

Na primeira abertura, o IDE pode gerar ficheiros locais (por exemplo `*.dcu`, pastas `Win32\Debug`); estes estão referidos no `.gitignore` e não devem ser versionados.

---

## Atalhos de teclado

Com **`KeyPreview`** ativo no formulário, é possível operar sem rato:

| Tecla | Ação |
|--------|------|
| **Esc** | Limpar tudo (equivalente a **C**) |
| **Enter** | Igual (**=**) |
| **Backspace** | Apagar último dígito |
| **Delete** | Limpar entrada (**CE**) |
| **0–9** | Dígitos (fila principal) |
| **.** ou **,** | Separador decimal |
| **+ − * /** | Operações |
| **%** | Percentagem |
| **=** | Igual |
| **^** | Potência (**x^y**) |
| **Teclado numérico** | Dígitos, operadores e tecla decimal |

Combinações com **Ctrl** ou **Alt** não são interceptadas, para não conflituar com atalhos do sistema ou do IDE quando a janela não está isolada.

---

## Estrutura do projeto

```
Calc.dpr              # Programa principal
Calc.dproj            # Projeto RAD Studio
Calculadora.pas       # View: formulário, tema, teclado, atalhos
Calculadora.dfm       # Definição visual do formulário
uCalcModel.pas        # Model: estado e cálculos
uCalcController.pas   # Controller + interface ICalcViewPort
README.md             # Esta documentação
.gitignore            # Exclusões para controlo de versões
```

---

## Notas técnicas

- O teclado numérico é criado em **tempo de execução** após o layout estar estável (`OnShow` / `OnResize`), para evitar área útil do painel com altura zero durante `OnCreate`.
- O **separador decimal** na lógica interna usa formato **invariante** (ponto), independentemente da região do Windows.
- Comentários no código orientam quem está a familiarizar-se com **Object Pascal** e com a **VCL**.

---

## Autor

**Carlos Baldoino** — projeto académico / portefólio em Delphi com MVC e boas práticas de estruturação.

Se utilizar ou referenciar este repositório, mantenha a menção ao autor e ao repositório de origem.
