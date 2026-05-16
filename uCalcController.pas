unit uCalcController;

{
  ---------------------------------------------------------------------------
  UNIDADE: uCalcController (camada CONTROLLER do padrão MVC)

  O que faz o Controller aqui?
  - Recebe "intenções" vindas da interface (cliques, teclas).
  - Chama métodos do MODEL na ordem correta (regras de uso).
  - Atualiza a VIEW através de ICalcViewPort (não conhece TLabel/TButton).

  Por que ICalcViewPort (interface)?
  - "interface" em Delphi também pode significar contrato COM-like: IUnknown.
  - A View implementa essa interface; o Controller só chama métodos abstratos.
  - Benefício: testes e manutenção mais simples (baixo acoplamento).
  ---------------------------------------------------------------------------
}

interface

uses
  System.SysUtils,
  uCalcModel;

type
  {
    ICalcViewPort
    - Contrato mínimo que a tela precisa expor para o Controller atualizar textos.
  }
  ICalcViewPort = interface
    ['{B2F6C8A1-4D0E-4F1A-9C2B-0E1D2A3B4C5D}']
    procedure SetMainDisplay(const AText: string);
    procedure SetExpressionLine(const AText: string);
    procedure SetAngleModeBadge(const AText: string);
    procedure SetMemoryBadge(const AVisible: Boolean);
  end;

  {
    TCalcController
    - Orquestra o fluxo: View -> Controller -> Model -> View.
  }
  TCalcController = class
  private
    FModel: TCalcModel;
    FView: ICalcViewPort;
    procedure RefreshView;
  public
    {
      Create
      - Construtor: inicializa o controller com Model e porta de visualização.
      - "const AView: ICalcViewPort" passa a interface por referência contada.
    }
    constructor Create(const AView: ICalcViewPort);

    {
      Destroy
      - Destrutor: libera o MODEL (a interface da View é gerenciada pelo formulário).
    }
    destructor Destroy; override;

    { --- Ações básicas (o utilizador está a compor um número ou operar) --- }
    /// <summary>Acrescenta um dígito (0..9) ao texto do número atual no Model.</summary>
    procedure ActionDigit(const ADigit: Char);
    /// <summary>Insere o ponto decimal no número em edição (se ainda não existir).</summary>
    procedure ActionDecimal;
    /// <summary>Apaga o último carácter do número em edição (tecla backspace).</summary>
    procedure ActionBackspace;
    /// <summary>Inverte o sinal positivo/negativo do número mostrado.</summary>
    procedure ActionToggleSign;
    /// <summary>Limpa tudo: memória de cálculo, operação pendente e dígitos.</summary>
    procedure ActionClearAll;
    /// <summary>Limpa só o número atual (mantém o resto do estado, conforme Model).</summary>
    procedure ActionClearEntry;
    /// <summary>Escolhe soma como operação pendente entre acumulador e próximo valor.</summary>
    procedure ActionAdd;
    /// <summary>Escolhe subtração como operação pendente.</summary>
    procedure ActionSubtract;
    /// <summary>Escolhe multiplicação como operação pendente.</summary>
    procedure ActionMultiply;
    /// <summary>Escolhe divisão como operação pendente.</summary>
    procedure ActionDivide;
    /// <summary>Escolhe resto inteiro (mod) como operação pendente.</summary>
    procedure ActionMod;
    /// <summary>Conclui a operação pendente e mostra o resultado.</summary>
    procedure ActionEquals;
    /// <summary>Divide o número atual por 100 (interpretação simples de percentagem).</summary>
    procedure ActionPercent;

    { --- Funções científicas (pedem cálculo ao Model e refrescam a View) --- }
    /// <summary>Operação binária potência: guarda base e espera expoente.</summary>
    procedure ActionPower;
    /// <summary>Seno do número atual (respeita modo Graus/Rad no Model).</summary>
    procedure ActionSin;
    /// <summary>Cosseno do número atual.</summary>
    procedure ActionCos;
    /// <summary>Tangente do número atual.</summary>
    procedure ActionTan;
    /// <summary>Arco seno; devolve resultado no modo angular configurado.</summary>
    procedure ActionASin;
    /// <summary>Arco cosseno.</summary>
    procedure ActionACos;
    /// <summary>Arco tangente.</summary>
    procedure ActionATan;
    /// <summary>Logaritmo natural (base e).</summary>
    procedure ActionLn;
    /// <summary>Logaritmo na base 10.</summary>
    procedure ActionLog10;
    /// <summary>Raiz quadrada (número não negativo).</summary>
    procedure ActionSqrt;
    /// <summary>Eleva o número ao quadrado.</summary>
    procedure ActionSquare;
    /// <summary>Calcula 1 dividido pelo número atual.</summary>
    procedure ActionInverse;
    /// <summary>Valor absoluto (remove sinal negativo).</summary>
    procedure ActionAbs;
    /// <summary>Exponencial e^x.</summary>
    procedure ActionExp;
    /// <summary>Parte inteira (trunca em direção a zero).</summary>
    procedure ActionInt;
    /// <summary>Parte fracionária.</summary>
    procedure ActionFrac;
    /// <summary>Fatorial para inteiros pequenos.</summary>
    procedure ActionFactorial;
    /// <summary>Insere a constante Pi.</summary>
    procedure ActionPi;
    /// <summary>Insere a constante e (base dos logaritmos naturais).</summary>
    procedure ActionE;

    { --- Memória da calculadora (valor guardado em paralelo) --- }
    /// <summary>Zera a memória independente.</summary>
    procedure ActionMemoryClear;
    /// <summary>Recupera o valor memorizado para o ecrã.</summary>
    procedure ActionMemoryRecall;
    /// <summary>Guarda o número atual na memória.</summary>
    procedure ActionMemoryStore;
    /// <summary>Soma o número atual à memória.</summary>
    procedure ActionMemoryAdd;
    /// <summary>Subtrai o número atual da memória.</summary>
    procedure ActionMemorySubtract;

    { --- Modo de ângulo para funções trigonométricas --- }
    /// <summary>Passa a interpretar entradas trigonométricas em graus.</summary>
    procedure ActionAngleDegrees;
    /// <summary>Passa a interpretar entradas trigonométricas em radianos.</summary>
    procedure ActionAngleRadians;
  end;

implementation

{ TCalcController }

constructor TCalcController.Create(const AView: ICalcViewPort);
begin
  inherited Create;
  FView := AView;
  FModel := TCalcModel.Create;
  RefreshView;
end;

destructor TCalcController.Destroy;
begin
  FModel.Free;
  inherited Destroy;
end;

procedure TCalcController.RefreshView;
var
  LAngle: string;
begin
  { Atualiza todos os elementos visuais a partir do estado do Model. }
  FView.SetMainDisplay(FModel.GetDisplayText);
  FView.SetExpressionLine(FModel.GetExpressionHint);

  case FModel.GetAngleMode of
    camDegrees:
      LAngle := 'Graus';
    camRadians:
      LAngle := 'Rad';
  end;
  FView.SetAngleModeBadge(LAngle);
  FView.SetMemoryBadge(FModel.IsMemoryActive);
end;

procedure TCalcController.ActionDigit(const ADigit: Char);
begin
  FModel.InputDigit(ADigit);
  RefreshView;
end;

procedure TCalcController.ActionDecimal;
begin
  FModel.InputDecimalSeparator;
  RefreshView;
end;

procedure TCalcController.ActionBackspace;
begin
  FModel.Backspace;
  RefreshView;
end;

procedure TCalcController.ActionToggleSign;
begin
  FModel.ToggleSign;
  RefreshView;
end;

procedure TCalcController.ActionClearAll;
begin
  FModel.ClearAll;
  RefreshView;
end;

procedure TCalcController.ActionClearEntry;
begin
  FModel.ClearEntry;
  RefreshView;
end;

procedure TCalcController.ActionAdd;
begin
  FModel.PressBinaryOperator(aoAdd);
  RefreshView;
end;

procedure TCalcController.ActionSubtract;
begin
  FModel.PressBinaryOperator(aoSub);
  RefreshView;
end;

procedure TCalcController.ActionMultiply;
begin
  FModel.PressBinaryOperator(aoMul);
  RefreshView;
end;

procedure TCalcController.ActionDivide;
begin
  FModel.PressBinaryOperator(aoDiv);
  RefreshView;
end;

procedure TCalcController.ActionMod;
begin
  FModel.PressBinaryOperator(aoMod);
  RefreshView;
end;

procedure TCalcController.ActionEquals;
begin
  FModel.Equals;
  RefreshView;
end;

procedure TCalcController.ActionPercent;
begin
  FModel.UnaryPercent;
  RefreshView;
end;

procedure TCalcController.ActionPower;
begin
  FModel.PressPowerOperator;
  RefreshView;
end;

procedure TCalcController.ActionSin;
begin
  FModel.UnarySin;
  RefreshView;
end;

procedure TCalcController.ActionCos;
begin
  FModel.UnaryCos;
  RefreshView;
end;

procedure TCalcController.ActionTan;
begin
  FModel.UnaryTan;
  RefreshView;
end;

procedure TCalcController.ActionASin;
begin
  FModel.UnaryASin;
  RefreshView;
end;

procedure TCalcController.ActionACos;
begin
  FModel.UnaryACos;
  RefreshView;
end;

procedure TCalcController.ActionATan;
begin
  FModel.UnaryATan;
  RefreshView;
end;

procedure TCalcController.ActionLn;
begin
  FModel.UnaryLn;
  RefreshView;
end;

procedure TCalcController.ActionLog10;
begin
  FModel.UnaryLog10;
  RefreshView;
end;

procedure TCalcController.ActionSqrt;
begin
  FModel.UnarySqrt;
  RefreshView;
end;

procedure TCalcController.ActionSquare;
begin
  FModel.UnarySquare;
  RefreshView;
end;

procedure TCalcController.ActionInverse;
begin
  FModel.UnaryInverse;
  RefreshView;
end;

procedure TCalcController.ActionAbs;
begin
  FModel.UnaryAbs;
  RefreshView;
end;

procedure TCalcController.ActionExp;
begin
  FModel.UnaryExp;
  RefreshView;
end;

procedure TCalcController.ActionInt;
begin
  FModel.UnaryInt;
  RefreshView;
end;

procedure TCalcController.ActionFrac;
begin
  FModel.UnaryFrac;
  RefreshView;
end;

procedure TCalcController.ActionFactorial;
begin
  FModel.UnaryFactorial;
  RefreshView;
end;

procedure TCalcController.ActionPi;
begin
  FModel.InsertPi;
  RefreshView;
end;

procedure TCalcController.ActionE;
begin
  FModel.InsertE;
  RefreshView;
end;

procedure TCalcController.ActionMemoryClear;
begin
  FModel.MemoryClear;
  RefreshView;
end;

procedure TCalcController.ActionMemoryRecall;
begin
  FModel.MemoryRecall;
  RefreshView;
end;

procedure TCalcController.ActionMemoryStore;
begin
  FModel.MemoryStore;
  RefreshView;
end;

procedure TCalcController.ActionMemoryAdd;
begin
  FModel.MemoryAdd;
  RefreshView;
end;

procedure TCalcController.ActionMemorySubtract;
begin
  FModel.MemorySubtract;
  RefreshView;
end;

procedure TCalcController.ActionAngleDegrees;
begin
  FModel.SetAngleModeDegrees;
  RefreshView;
end;

procedure TCalcController.ActionAngleRadians;
begin
  FModel.SetAngleModeRadians;
  RefreshView;
end;

end.
